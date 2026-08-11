import Foundation
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

final class GameplayParityCoordinator: @unchecked Sendable {
    private let mode: SM64ModernGameplayParityMode
    private let traceURL: URL
    private let handle: FileHandle
    private var api = SM64ModernGameplayParityApiV1()
    private var sessionActive = false

    let tickLimit: UInt64?

    private init(
        mode: SM64ModernGameplayParityMode,
        traceURL: URL,
        handle: FileHandle,
        tickLimit: UInt64?
    ) {
        self.mode = mode
        self.traceURL = traceURL
        self.handle = handle
        self.tickLimit = tickLimit
    }

    static func beginFromEnvironment(
        saveDirectory: String
    ) -> (coordinator: GameplayParityCoordinator?, status: SM64ModernStatus) {
        let environment = ProcessInfo.processInfo.environment
        guard let modeName = environment["SM64_MODERN_PARITY_MODE"], !modeName.isEmpty else {
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
        let coordinator = GameplayParityCoordinator(
            mode: mode,
            traceURL: traceURL,
            handle: handle,
            tickLimit: tickLimit
        )
        let status = coordinator.begin(saveDirectory: saveDirectory)
        guard status == SM64_MODERN_STATUS_OK else {
            try? handle.close()
            return (nil, status)
        }
        return (coordinator, SM64_MODERN_STATUS_OK)
    }

    private func begin(saveDirectory: String) -> SM64ModernStatus {
        var status = sm64_modern_get_gameplay_parity_api(
            SM64_MODERN_ABI_VERSION_1,
            UInt32(MemoryLayout<SM64ModernGameplayParityApiV1>.size),
            &api
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
            parityLogger.notice(
                "parity_session_started mode=\(self.mode) schema=\(SM64_MODERN_GAMEPLAY_PARITY_SCHEMA_VERSION) trace=\(self.traceURL.lastPathComponent, privacy: .public) ticks=\(self.tickLimit ?? 0)"
            )
        }
        return status
    }

    func endAndReport() -> SM64ModernStatus {
        guard sessionActive else { return SM64_MODERN_STATUS_OK }
        let status = api.end_session()
        sessionActive = false
        if mode == SM64_MODERN_GAMEPLAY_PARITY_RECORD {
            try? handle.synchronize()
        }
        try? handle.close()

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
                    "parity_first_divergence subsystem=\(subsystem) tick=\(divergence.simulation_tick) reason=\(divergence.reason) expected_id=\(divergence.expected_record_id) actual_id=\(divergence.actual_record_id) value_index=\(divergence.value_index)"
                )
            }
        }
        parityLogger.notice("parity_session_finished status=\(status)")
        return status
    }

    fileprivate func write(record: UnsafePointer<SM64ModernGameplayTraceRecordV1>) -> SM64ModernStatus {
        do {
            try handle.write(contentsOf: Data(bytes: record, count: MemoryLayout<SM64ModernGameplayTraceRecordV1>.size))
            return SM64_MODERN_STATUS_OK
        } catch {
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }
    }

    fileprivate func read(record: UnsafeMutablePointer<SM64ModernGameplayTraceRecordV1>) -> SM64ModernStatus {
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
}
