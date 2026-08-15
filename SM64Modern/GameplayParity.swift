import Foundation
import Darwin
import os

private let parityLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "GameplayParity")
private let parityFingerprintOffset: UInt64 = 1_469_598_103_934_665_603
private let parityFingerprintPrime: UInt64 = 1_099_511_628_211

private func parityCoordinator(from context: UnsafeMutableRawPointer?) -> GameplayParityCoordinator? {
    guard let context else { return nil }
    return Unmanaged<GameplayParityCoordinator>.fromOpaque(context).takeUnretainedValue()
}

private let parityTraceWrite: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernGameplayTraceRecordV1>?
) -> SM64ModernStatus = { context, record in
    guard let coordinator = parityCoordinator(from: context), let record else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return coordinator.write(record: record)
}

private let parityTraceRead: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<SM64ModernGameplayTraceRecordV1>?
) -> SM64ModernStatus = { context, record in
    guard let coordinator = parityCoordinator(from: context), let record else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return coordinator.read(record: record)
}

/// Engine-owner-thread parity session. The mutable trace handle and C parity
/// API are driven only by the engine thread; the stream callbacks are the
/// narrow unsafe ABI leaf recovered from the C-owned context pointer.
final class GameplayParityCoordinator {
    private let ownerThreadIdentity: UInt64
    private let mode: SM64ModernGameplayParityMode
    private let traceURL: URL
    private let handle: FileHandle
    private let gameplayService: SwiftGameplayService
    private let swiftSubsystems: [SM64ModernGameplaySubsystem]
    private let promoteAfterShadow: Bool
    private let swiftAuthorityTicks: UInt64?
    private var api = SM64ModernGameplayParityApiV1()
    private var gameplayAPI = SM64ModernGameplayApiV1()
    private var sessionActive = false
    private var promotionStep: UInt64?

    private(set) var tickLimit: UInt64?

    private init(
        mode: SM64ModernGameplayParityMode,
        traceURL: URL,
        handle: FileHandle,
        tickLimit: UInt64?,
        gameplayService: SwiftGameplayService,
        swiftSubsystems: [SM64ModernGameplaySubsystem],
        promoteAfterShadow: Bool,
        swiftAuthorityTicks: UInt64?
    ) {
        var ownerThreadIdentity: UInt64 = 0
        precondition(
            pthread_threadid_np(nil, &ownerThreadIdentity) == 0,
            "pthread_threadid_np must produce an owner token"
        )
        self.ownerThreadIdentity = ownerThreadIdentity
        self.mode = mode
        self.traceURL = traceURL
        self.handle = handle
        self.tickLimit = tickLimit
        self.gameplayService = gameplayService
        self.swiftSubsystems = swiftSubsystems
        self.promoteAfterShadow = promoteAfterShadow
        self.swiftAuthorityTicks = swiftAuthorityTicks
    }

    private func assertOwnerThread() {
        var currentThreadIdentity: UInt64 = 0
        precondition(
            pthread_threadid_np(nil, &currentThreadIdentity) == 0,
            "pthread_threadid_np must produce an owner token"
        )
        precondition(
            currentThreadIdentity == ownerThreadIdentity,
            "GameplayParityCoordinator is engine-owner-thread-only"
        )
    }

    static func beginFromEnvironment(
        saveDirectory: String,
        gameplayService: SwiftGameplayService
    ) -> (coordinator: GameplayParityCoordinator?, status: SM64ModernStatus) {
        let environment = ProcessInfo.processInfo.environment
        let requestedAuthority = environment["SM64_MODERN_SWIFT_AUTHORITY"]?.lowercased()
        if let requestedAuthority,
           requestedAuthority != "c" && requestedAuthority != "swift" {
            parityLogger.error("parity_configuration_invalid key=swift_authority")
            return (nil, SM64_MODERN_STATUS_INVALID_ARGUMENT)
        }
        guard let modeName = environment["SM64_MODERN_PARITY_MODE"], !modeName.isEmpty else {
            if requestedAuthority == "c" {
                // C is the safe process-wide fallback when no bounded parity
                // session is requested. Keep this explicit in telemetry so a
                // launch configuration cannot silently imply Swift authority.
                parityLogger.notice("swift_authority_fallback=c")
                return (nil, SM64_MODERN_STATUS_OK)
            }
            if requestedAuthority == "swift" {
                parityLogger.error("parity_configuration_invalid key=swift_authority_requires_shadow")
                return (nil, SM64_MODERN_STATUS_INVALID_ARGUMENT)
            }
            return (nil, SM64_MODERN_STATUS_OK)
        }

        let mode: SM64ModernGameplayParityMode
        switch modeName {
        case "record": mode = SM64_MODERN_GAMEPLAY_PARITY_RECORD
        case "replay": mode = SM64_MODERN_GAMEPLAY_PARITY_REPLAY
        case "shadow": mode = SM64_MODERN_GAMEPLAY_PARITY_SHADOW
        default:
            parityLogger.error("parity_configuration_invalid key=mode")
            return (nil, SM64_MODERN_STATUS_INVALID_ARGUMENT)
        }
        guard let tracePath = environment["SM64_MODERN_PARITY_TRACE"], !tracePath.isEmpty else {
            parityLogger.error("parity_configuration_invalid key=trace")
            return (nil, SM64_MODERN_STATUS_INVALID_ARGUMENT)
        }

        let traceURL = URL(fileURLWithPath: tracePath).standardizedFileURL
        let handle: FileHandle
        do {
            if mode == SM64_MODERN_GAMEPLAY_PARITY_RECORD {
                try FileManager.default.createDirectory(
                    at: traceURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try Data().write(to: traceURL, options: .atomic)
                handle = try FileHandle(forWritingTo: traceURL)
            } else {
                handle = try FileHandle(forReadingFrom: traceURL)
            }
        } catch {
            parityLogger.error("parity_trace_open_failed error=io")
            return (nil, SM64_MODERN_STATUS_PLATFORM_ERROR)
        }

        let tickLimit = environment["SM64_MODERN_PARITY_TICKS"]
            .flatMap(UInt64.init)
            .flatMap { $0 == 0 ? nil : $0 }
        let environmentRequestsPromotion = environment["SM64_MODERN_SWIFT_PROMOTE"] == "1"
        let swiftAuthorityTicks = environment["SM64_MODERN_SWIFT_AUTHORITY_TICKS"]
            .flatMap(UInt64.init)
            .flatMap { $0 == 0 ? nil : $0 }
        let swiftSubsystems: [SM64ModernGameplaySubsystem]
        if requestedAuthority == "c" {
            swiftSubsystems = []
        } else {
            do {
                swiftSubsystems = try parseSwiftSubsystems(environment["SM64_MODERN_SWIFT_SLICES"])
            } catch {
                parityLogger.error("parity_configuration_invalid key=swift_slices")
                try? handle.close()
                return (nil, SM64_MODERN_STATUS_INVALID_ARGUMENT)
            }
        }
        let nativeSwiftRequested = requestedAuthority == "swift"
        let promoteAfterShadow = nativeSwiftRequested || environmentRequestsPromotion
        if requestedAuthority == "c" {
            parityLogger.notice("swift_authority_fallback=c")
        } else if nativeSwiftRequested {
            parityLogger.notice("swift_authority_requested mode=native")
        }
        if promoteAfterShadow && (mode != SM64_MODERN_GAMEPLAY_PARITY_SHADOW
            || tickLimit == nil || swiftSubsystems.isEmpty) {
            parityLogger.error(
                "parity_configuration_invalid key=\(nativeSwiftRequested ? "swift_authority" : "swift_promote")"
            )
            try? handle.close()
            return (nil, SM64_MODERN_STATUS_INVALID_ARGUMENT)
        }
        let coordinator = GameplayParityCoordinator(
            mode: mode,
            traceURL: traceURL,
            handle: handle,
            tickLimit: tickLimit,
            gameplayService: gameplayService,
            swiftSubsystems: swiftSubsystems,
            promoteAfterShadow: promoteAfterShadow,
            swiftAuthorityTicks: swiftAuthorityTicks
        )
        let status = coordinator.begin(saveDirectory: saveDirectory)
        guard status == SM64_MODERN_STATUS_OK else {
            try? handle.close()
            return (nil, status)
        }
        return (coordinator, SM64_MODERN_STATUS_OK)
    }

    private func begin(saveDirectory: String) -> SM64ModernStatus {
        assertOwnerThread()
        var status = sm64_modern_get_gameplay_parity_api(
            SM64_MODERN_ABI_VERSION_1,
            UInt32(MemoryLayout<SM64ModernGameplayParityApiV1>.size),
            &api
        )
        guard status == SM64_MODERN_STATUS_OK else { return status }
        status = sm64_modern_get_gameplay_api(
            SM64_MODERN_ABI_VERSION_1,
            UInt32(MemoryLayout<SM64ModernGameplayApiV1>.size),
            &gameplayAPI
        )
        guard status == SM64_MODERN_STATUS_OK else { return status }

        var config = SM64ModernGameplayParityConfigV1()
        config.header.abi_version = SM64_MODERN_ABI_VERSION_1
        config.header.struct_size = UInt32(MemoryLayout<SM64ModernGameplayParityConfigV1>.size)
        config.mode = mode
        config.subsystem_mask = (UInt32(1) << SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT) - 1
        do {
            guard let executableURL = Bundle.main.executableURL else {
                return SM64_MODERN_STATUS_PLATFORM_ERROR
            }
            config.build_fingerprint = try Self.fingerprint(
                directory: executableURL.deletingLastPathComponent()
            )
            config.initial_state_fingerprint = try Self.fingerprint(directory: URL(fileURLWithPath: saveDirectory))
        } catch {
            parityLogger.error("parity_fingerprint_failed error=io")
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }

        var stream = SM64ModernGameplayTraceStreamApiV1()
        stream.header.abi_version = SM64_MODERN_ABI_VERSION_1
        stream.header.struct_size = UInt32(MemoryLayout<SM64ModernGameplayTraceStreamApiV1>.size)
        stream.context = Unmanaged.passUnretained(self).toOpaque()
        stream.write = parityTraceWrite
        stream.read = parityTraceRead
        status = api.begin_session(&config, &stream)
        if status == SM64_MODERN_STATUS_OK {
            sessionActive = true
            gameplayService.resetEvidence()
            for subsystem in swiftSubsystems {
                status = gameplayAPI.set_authority(
                    subsystem,
                    SM64_MODERN_AUTHORITY_SHADOW_SWIFT
                )
                if status != SM64_MODERN_STATUS_OK {
                    _ = api.end_session()
                    sessionActive = false
                    try? handle.close()
                    return status
                }
            }
            parityLogger.notice(
                "parity_session_started mode=\(self.mode) schema=\(SM64_MODERN_GAMEPLAY_PARITY_SCHEMA_VERSION) trace=\(self.traceURL.lastPathComponent, privacy: .public) ticks=\(self.tickLimit ?? 0)"
            )
            if !swiftSubsystems.isEmpty {
                parityLogger.notice(
                    "swift_shadow_started subsystems=\(self.swiftSubsystems.map(String.init).joined(separator: ","), privacy: .public) promote=\(self.promoteAfterShadow)"
                )
            }
        }
        return status
    }

    func handleTickBoundary(step: UInt64) -> (status: SM64ModernStatus, shouldStop: Bool) {
        assertOwnerThread()
        if let promotionStep, let swiftAuthorityTicks,
           step >= promotionStep + swiftAuthorityTicks {
            let evidence = gameplayService.evidence()
            for subsystem in swiftSubsystems where !evidence.exercised(subsystem: subsystem) {
                parityLogger.error("swift_authority_run_rejected subsystem=\(subsystem) reason=not_exercised")
                return (SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY, true)
            }
            parityLogger.notice("bounded_swift_authority_run_complete steps=\(step) authority_steps=\(swiftAuthorityTicks)")
            return (SM64_MODERN_STATUS_OK, true)
        }
        guard let tickLimit, step >= tickLimit else {
            return (SM64_MODERN_STATUS_OK, false)
        }
        guard promoteAfterShadow else {
            return (SM64_MODERN_STATUS_OK, true)
        }

        let parityStatus = endAndReport()
        guard parityStatus == SM64_MODERN_STATUS_OK else {
            return (parityStatus, true)
        }
        let evidence = gameplayService.evidence()
        for subsystem in swiftSubsystems {
            var result = SM64ModernGameplayParityResultV1()
            guard api.get_result(subsystem, &result) == SM64_MODERN_STATUS_OK,
                  result.eligible_for_swift != 0,
                  evidence.exercised(subsystem: subsystem) else {
                parityLogger.error("swift_promotion_rejected subsystem=\(subsystem) reason=incomplete_evidence")
                return (SM64_MODERN_STATUS_UNSUPPORTED_AUTHORITY, true)
            }
        }
        for subsystem in swiftSubsystems {
            let status = gameplayAPI.set_authority(subsystem, SM64_MODERN_AUTHORITY_SWIFT)
            guard status == SM64_MODERN_STATUS_OK else {
                parityLogger.error("swift_promotion_failed subsystem=\(subsystem) status=\(status)")
                return (status, true)
            }
        }
        self.tickLimit = nil
        promotionStep = step
        gameplayService.resetEvidence()
        parityLogger.notice(
            "swift_authority_promoted subsystems=\(self.swiftSubsystems.map(String.init).joined(separator: ","), privacy: .public) shadow_steps=\(step)"
        )
        return (SM64_MODERN_STATUS_OK, false)
    }

    func endAndReport() -> SM64ModernStatus {
        assertOwnerThread()
        guard sessionActive else { return SM64_MODERN_STATUS_OK }
        let status = api.end_session()
        sessionActive = false
        if mode == SM64_MODERN_GAMEPLAY_PARITY_RECORD {
            try? handle.synchronize()
        }
        try? handle.close()

        // Keep slice-execution evidence in the parity stream itself.  The
        // SwiftGameplay logger is useful for diagnostics, but OSLog delivery
        // can be coalesced or omitted when the app exits immediately after a
        // bounded run.  This deterministic line is emitted on the owner
        // thread while the evidence counters are still authoritative.
        let evidence = gameplayService.evidence()
        parityLogger.notice(
            "swift_gameplay_evidence mario_buttons=\(evidence.marioButtonUpdates) mario_ground_speed=\(evidence.marioGroundSpeedUpdates) bobomb_release=\(evidence.bobombReleaseUpdates)"
        )

        for index in 0..<SM64_MODERN_GAMEPLAY_SUBSYSTEM_COUNT {
            var result = SM64ModernGameplayParityResultV1()
            let subsystem = SM64ModernGameplaySubsystem(index)
            if api.get_result(subsystem, &result) == SM64_MODERN_STATUS_OK,
               result.actual_records > 0 || result.expected_records > 0 {
                parityLogger.notice(
                    "parity_result subsystem=\(subsystem) status=\(result.status) expected=\(result.expected_records) actual=\(result.actual_records) matched=\(result.matched_records) candidate=\(result.candidate_records) eligible=\(result.eligible_for_swift)"
                )
            }
            var divergence = SM64ModernGameplayDivergenceV1()
            if api.get_first_divergence(subsystem, &divergence) == SM64_MODERN_STATUS_OK,
               divergence.reason != SM64_MODERN_DIVERGENCE_NONE {
                parityLogger.error(
                    "parity_first_divergence subsystem=\(subsystem) tick=\(divergence.simulation_tick) reason=\(divergence.reason) expected_id=\(divergence.expected_record_id) actual_id=\(divergence.actual_record_id) value_index=\(divergence.value_index) expected=0x\(divergence.expected_value, format: .hex) actual=0x\(divergence.actual_value, format: .hex)"
                )
            }
        }
        parityLogger.notice("parity_session_finished status=\(status)")
        return status
    }

    fileprivate func write(record: UnsafePointer<SM64ModernGameplayTraceRecordV1>) -> SM64ModernStatus {
        assertOwnerThread()
        do {
            try handle.write(contentsOf: Data(bytes: record, count: MemoryLayout<SM64ModernGameplayTraceRecordV1>.size))
            return SM64_MODERN_STATUS_OK
        } catch {
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }
    }

    fileprivate func read(record: UnsafeMutablePointer<SM64ModernGameplayTraceRecordV1>) -> SM64ModernStatus {
        assertOwnerThread()
        do {
            let size = MemoryLayout<SM64ModernGameplayTraceRecordV1>.size
            guard let data = try handle.read(upToCount: size), !data.isEmpty else {
                return SM64_MODERN_STATUS_END_OF_STREAM
            }
            guard data.count == size else { return SM64_MODERN_STATUS_INVALID_ARGUMENT }
            data.copyBytes(to: UnsafeMutableRawBufferPointer(start: record, count: size))
            return SM64_MODERN_STATUS_OK
        } catch {
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }
    }

    private static func fingerprint(directory: URL) throws -> UInt64 {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ).filter { (try? $0.resourceValues(forKeys: Set(keys)).isRegularFile) == true }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var hash = parityFingerprintOffset
        for file in files {
            hash = updateFingerprint(hash, with: Data(file.lastPathComponent.utf8))
            hash = try updateFingerprint(hash, with: Data(contentsOf: file, options: .mappedIfSafe))
        }
        return hash
    }

    private static func updateFingerprint(_ startingHash: UInt64, with data: Data) -> UInt64 {
        data.reduce(startingHash) { hash, byte in
            (hash ^ UInt64(byte)) &* parityFingerprintPrime
        }
    }

    private static func parseSwiftSubsystems(
        _ value: String?
    ) throws -> [SM64ModernGameplaySubsystem] {
        guard let value, !value.isEmpty else { return [] }
        var subsystems: [SM64ModernGameplaySubsystem] = []
        for token in value.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            let subsystem: SM64ModernGameplaySubsystem
            switch token {
            case "mario-buttons", "mario_buttons":
                subsystem = SM64_MODERN_GAMEPLAY_SUBSYSTEM_MARIO
            case "bobomb-release", "bobomb_release":
                subsystem = SM64_MODERN_GAMEPLAY_SUBSYSTEM_ACTOR_BOBOMB_BATTLEFIELD
            default:
                throw CocoaError(.validationMissingMandatoryProperty)
            }
            if !subsystems.contains(subsystem) {
                subsystems.append(subsystem)
            }
        }
        return subsystems
    }
}
