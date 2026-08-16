import Darwin
import Foundation
import os

private let progressionMigrationLogger = Logger(
    subsystem: "io.github.deestiz.sm64modern",
    category: "ProgressionMigration"
)

private func progressionMigrationService(
    from context: UnsafeMutableRawPointer?
) -> SwiftProgressionMigrationService? {
    guard let context else { return nil }
    return Unmanaged<SwiftProgressionMigrationService>.fromOpaque(context)
        .takeUnretainedValue()
}

private let swiftProgressionRecordEvent: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernProgressionEventV1>?
) -> SM64ModernStatus = { context, event in
    guard let service = progressionMigrationService(from: context), let event else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.record(event: event.pointee)
}

/// Owner-thread bridge for the progression value runtime. The C game remains
/// the compatibility authority in M17; this service receives the same
/// mutation boundaries and persists a Swift shadow bundle for differential
/// qualification before any gameplay authority cutover.
/// Mutable progression migration state owned by the engine thread. The C API
/// callback below is the only unsafe leaf; every service entry point verifies
/// the thread token captured at construction.
final class SwiftProgressionMigrationService {
    private let adapter: SM64OwnerThreadEEPROMAdapter
    private let ownerThreadToken: UInt64
    private let ownerThreadIdentity: UInt64
    private let engineAuthority: SM64ModernEngineAuthority
    private let replayArtifactURL: URL?
    private let saveAuthorityTrial: Bool
    private var runtime: SM64ProgressionRuntime
    private var eventCount: UInt64 = 0
    private var lastError: SM64ModernStatus = SM64_MODERN_STATUS_OK
    private var replayLedger: SM64SaveReplayLedger?

    init(
        saveDirectory: String,
        ownerThreadToken: UInt64,
        authority: SM64ModernEngineAuthority = .swift
    ) throws {
        self.ownerThreadToken = ownerThreadToken
        self.ownerThreadIdentity = Self.currentThreadIdentity()
        self.engineAuthority = authority
        if let path = ProcessInfo.processInfo.environment[
            "SM64_MODERN_SAVE_REPLAY_ARTIFACT"
        ], !path.isEmpty {
            self.replayArtifactURL = URL(fileURLWithPath: path)
        } else {
            self.replayArtifactURL = nil
        }
        self.saveAuthorityTrial = ProcessInfo.processInfo.environment[
            "SM64_MODERN_SAVE_AUTHORITY_TRIAL"
        ] == "1"
        self.adapter = try SM64OwnerThreadEEPROMAdapter(
            rootURL: URL(fileURLWithPath: saveDirectory)
                .appendingPathComponent("swift-progression", isDirectory: true),
            ownerThreadToken: ownerThreadToken
        )
        self.runtime = SM64ProgressionRuntime()
    }

    func initialize() throws {
        assertOwnerThread()
        if let snapshot = readSnapshot(fileIndex: runtime.saveFileIndex) {
            try adapter.commit(
                saveFileIndex: runtime.saveFileIndex,
                save: snapshot.save, menu: snapshot.menu,
                ownerThreadToken: ownerThreadToken
            )
            runtime.adoptPersistedSnapshots(
                save: snapshot.save, menu: snapshot.menu
            )
            try beginReplayArtifact(save: snapshot.save, menu: snapshot.menu)
        } else {
            let loaded = try adapter.reload(
                saveFileIndex: runtime.saveFileIndex,
                ownerThreadToken: ownerThreadToken
            )
            runtime.adoptPersistedSnapshots(save: loaded.save, menu: loaded.menu)
            try beginReplayArtifact(save: loaded.save, menu: loaded.menu)
        }
    }

    func makeAPI() -> SM64ModernProgressionMigrationApiV1 {
        assertOwnerThread()
        var api = SM64ModernProgressionMigrationApiV1()
        api.header.abi_version = SM64_MODERN_ABI_VERSION_1
        api.header.struct_size = UInt32(
            MemoryLayout<SM64ModernProgressionMigrationApiV1>.size
        )
        api.context = Unmanaged.passUnretained(self).toOpaque()
        api.record_event = swiftProgressionRecordEvent
        return api
    }

    func record(event: SM64ModernProgressionEventV1) -> SM64ModernStatus {
        assertOwnerThread()
        guard lastError == SM64_MODERN_STATUS_OK else { return lastError }
        guard event.header.abi_version == SM64_MODERN_ABI_VERSION_1,
              event.header.struct_size >= UInt32(
                MemoryLayout<SM64ModernProgressionEventV1>.size
              ) else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, message: "event_header")
        }
        guard (0..<SM64CoinScoreAgeState.fileCount).contains(
            Int(event.save_file_index)
        ) else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, message: "save_file")
        }
        guard runtime.selectSaveFile(Int(event.save_file_index)) else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, message: "save_file")
        }

        eventCount &+= 1
        let status: SM64ModernStatus
        switch event.event_kind {
        case SM64_MODERN_PROGRESSION_EVENT_RED_COIN:
            status = apply(
                .collectRedCoin,
                event: event,
                requiresCourse: true
            )
        case SM64_MODERN_PROGRESSION_EVENT_CAP_SWITCH:
            guard event.cap_switch_index < 3 else {
                return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, message: "cap_switch")
            }
            status = apply(
                .pressCapSwitch(index: UInt8(event.cap_switch_index)),
                event: event,
                requiresCourse: true
            )
        case SM64_MODERN_PROGRESSION_EVENT_LEVEL_REWARD:
            guard let kind = SM64ProgressionCollectionKind(
                rawValue: UInt8(event.collection_kind)
            ), event.collection_kind <= UInt32(UInt8.max),
                event.star_index >= 0, event.star_index < 7,
                event.coin_score >= 0, event.global_max_coin_score >= 0 else {
                return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, message: "reward")
            }
            status = apply(
                .completeLevel(
                    kind: kind,
                    starIndex: Int16(event.star_index),
                    coinScore: Int16(event.coin_score),
                    globalMaxCoinScore: Int16(event.global_max_coin_score)
                ),
                event: event,
                requiresCourse: true
            )
        case SM64_MODERN_PROGRESSION_EVENT_SAVE_MUTATION:
            status = recordMutation(event: event)
        case SM64_MODERN_PROGRESSION_EVENT_SAVE_PERSIST:
            status = persist(event: event)
        case SM64_MODERN_PROGRESSION_EVENT_SAVE_LOAD,
             SM64_MODERN_PROGRESSION_EVENT_SAVE_RELOAD:
            status = reload(event: event)
        default:
            status = fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, message: "event_kind")
        }
        return status
    }

    private func apply(
        _ actorEvent: SM64ProgressionActorEvent,
        event: SM64ModernProgressionEventV1,
        requiresCourse: Bool
    ) -> SM64ModernStatus {
        if requiresCourse && event.course_number != 0 {
            guard runtime.selectCourse(Int(event.course_number)) else {
                return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, message: "course")
            }
        }
        guard let result = runtime.apply(
            actorEvent, simulationTick: event.simulation_tick
        ) else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT, message: "reducer")
        }
        recordOracle(
            event: event,
            flags: UInt32(result.actorEffects.rawValue)
                | (UInt32(result.progressionEffects.rawValue) << 16),
            values: result.trace.values
        )
        return recordSnapshot(event: event, flags: 0)
    }

    private func recordMutation(event: SM64ModernProgressionEventV1) -> SM64ModernStatus {
        // Older producers only set the legacy mutation kind in `flags`; keep
        // their post-mutation snapshot shadow path until the payload extension
        // is present.
        guard event.mutation_kind != SM64_MODERN_PROGRESSION_SAVE_MUTATION_GENERIC else {
            return recordSnapshot(event: event, flags: event.flags)
        }
        guard event.mutation_kind <= SM64_MODERN_PROGRESSION_SAVE_MUTATION_MENU,
              event.mutation_operation <= 1 else {
            return fail(
                SM64_MODERN_STATUS_INVALID_ARGUMENT,
                message: "mutation_payload_kind"
            )
        }

        do {
            let before = try adapter.load(
                saveFileIndex: Int(event.save_file_index),
                ownerThreadToken: ownerThreadToken
            )
            let expected: (save: SM64SaveFileSnapshot, menu: SM64MenuDataSnapshot)
            switch event.mutation_kind {
            case SM64_MODERN_PROGRESSION_SAVE_MUTATION_ERASE:
                guard event.mutation_source_file_index == UInt32.max else {
                    return fail(
                        SM64_MODERN_STATUS_INVALID_ARGUMENT,
                        message: "mutation_erase_source"
                    )
                }
                try adapter.erase(
                    saveFileIndex: Int(event.save_file_index),
                    ownerThreadToken: ownerThreadToken
                )
                let loaded = try adapter.load(
                    saveFileIndex: Int(event.save_file_index),
                    ownerThreadToken: ownerThreadToken
                )
                expected = (loaded.save, loaded.menu)
            case SM64_MODERN_PROGRESSION_SAVE_MUTATION_COPY:
                guard event.mutation_source_file_index
                    < UInt32(SM64CoinScoreAgeState.fileCount) else {
                    return fail(
                        SM64_MODERN_STATUS_INVALID_ARGUMENT,
                        message: "mutation_copy_source"
                    )
                }
                try adapter.copy(
                    saveFileIndex: Int(event.mutation_source_file_index),
                    to: Int(event.save_file_index),
                    ownerThreadToken: ownerThreadToken
                )
                let loaded = try adapter.load(
                    saveFileIndex: Int(event.save_file_index),
                    ownerThreadToken: ownerThreadToken
                )
                expected = (loaded.save, loaded.menu)
            default:
                guard let mutation = mutation(from: event) else {
                    return fail(
                        SM64_MODERN_STATUS_INVALID_ARGUMENT,
                        message: "mutation_payload_values"
                    )
                }
                let result = try adapter.apply(
                    mutation,
                    saveFileIndex: Int(event.save_file_index),
                    ownerThreadToken: ownerThreadToken
                )
                expected = (result.save, result.menu)
            }

            guard let cSnapshot = readSnapshot(
                fileIndex: Int(event.save_file_index)
            ), SM64SaveFileCodec.encode(cSnapshot.save)
                == SM64SaveFileCodec.encode(expected.save),
                SM64MenuDataCodec.encode(cSnapshot.menu)
                == SM64MenuDataCodec.encode(expected.menu) else {
                return fail(
                    SM64_MODERN_STATUS_PARITY_DIVERGED,
                    message: "mutation_payload_replay"
                )
            }
            runtime.adoptPersistedSnapshots(
                save: expected.save, menu: expected.menu
            )
            try appendReplay(
                event: event,
                operation: .mutation,
                before: (before.save, before.menu),
                after: expected,
                saveRecoveryDecision: UInt32(before.saveDecision.rawValue),
                menuRecoveryDecision: UInt32(before.menuDecision.rawValue)
            )
            recordOracle(
                event: event,
                recordKind: SM64_MODERN_ORACLE_RECORD_SAVE_BYTES,
                flags: event.flags,
                values: [
                    hash(bytes: SM64SaveFileCodec.encode(expected.save)),
                    hash(bytes: SM64MenuDataCodec.encode(expected.menu)),
                    eventCount
                ]
            )
            return SM64_MODERN_STATUS_OK
        } catch {
            return fail(
                SM64_MODERN_STATUS_PLATFORM_ERROR,
                message: "mutation_payload_apply"
            )
        }
    }

    private func mutation(
        from event: SM64ModernProgressionEventV1
    ) -> SM64SaveFileMutation? {
        switch event.mutation_kind {
        case SM64_MODERN_PROGRESSION_SAVE_MUTATION_FLAGS:
            return event.mutation_operation == 0
                ? .setFlags(event.mutation_flags)
                : .clearFlags(event.mutation_flags)
        case SM64_MODERN_PROGRESSION_SAVE_MUTATION_STARS:
            let courseIndex = event.mutation_course_index == UInt32.max
                ? -1 : Int(event.mutation_course_index)
            return .setStarFlags(
                starFlags: UInt32(bitPattern: event.mutation_star_flags),
                courseIndex: courseIndex
            )
        case SM64_MODERN_PROGRESSION_SAVE_MUTATION_CANNON:
            return .setCannonUnlocked(
                currentCourseNumber: Int(event.mutation_course_index)
            )
        case SM64_MODERN_PROGRESSION_SAVE_MUTATION_CAP:
            guard event.mutation_level <= UInt32(UInt8.max),
                  event.mutation_area <= UInt32(UInt8.max),
                  (Int32(-32_768)...Int32(32_767)).contains(event.mutation_cap_x),
                  (Int32(-32_768)...Int32(32_767)).contains(event.mutation_cap_y),
                  (Int32(-32_768)...Int32(32_767)).contains(event.mutation_cap_z) else {
                return nil
            }
            return .setCapPosition(
                level: UInt8(event.mutation_level),
                area: UInt8(event.mutation_area),
                position: .init(
                    x: Int16(event.mutation_cap_x),
                    y: Int16(event.mutation_cap_y),
                    z: Int16(event.mutation_cap_z)
                )
            )
        case SM64_MODERN_PROGRESSION_SAVE_MUTATION_MENU:
            guard event.mutation_sound_mode <= UInt32(UInt16.max) else {
                return nil
            }
            return .setSoundMode(UInt16(event.mutation_sound_mode))
        default:
            return nil
        }
    }

    private func persist(event: SM64ModernProgressionEventV1) -> SM64ModernStatus {
        guard let snapshot = readSnapshot(fileIndex: Int(event.save_file_index)) else {
            return fail(SM64_MODERN_STATUS_PLATFORM_ERROR, message: "persist_snapshot")
        }
        runtime.adoptPersistedSnapshots(save: snapshot.save, menu: snapshot.menu)
        do {
            let before = try adapter.load(
                saveFileIndex: Int(event.save_file_index),
                ownerThreadToken: ownerThreadToken
            )
            try adapter.commit(
                saveFileIndex: Int(event.save_file_index),
                save: snapshot.save, menu: snapshot.menu,
                ownerThreadToken: ownerThreadToken
            )
            try appendReplay(
                event: event,
                operation: .persist,
                before: (before.save, before.menu),
                after: (snapshot.save, snapshot.menu),
                saveRecoveryDecision: UInt32(before.saveDecision.rawValue),
                menuRecoveryDecision: UInt32(before.menuDecision.rawValue)
            )
        } catch {
            return fail(SM64_MODERN_STATUS_PLATFORM_ERROR, message: "persist")
        }
        return recordSnapshot(event: event, flags: 2, captureReplay: false)
    }

    private func reload(event: SM64ModernProgressionEventV1) -> SM64ModernStatus {
        guard let snapshot = readSnapshot(fileIndex: Int(event.save_file_index)) else {
            return fail(SM64_MODERN_STATUS_PLATFORM_ERROR, message: "reload_snapshot")
        }
        runtime.adoptPersistedSnapshots(save: snapshot.save, menu: snapshot.menu)
        do {
            let before = try adapter.load(
                saveFileIndex: Int(event.save_file_index),
                ownerThreadToken: ownerThreadToken
            )
            try adapter.commit(
                saveFileIndex: Int(event.save_file_index),
                save: snapshot.save, menu: snapshot.menu,
                ownerThreadToken: ownerThreadToken
            )
            try appendReplay(
                event: event,
                operation: event.event_kind
                    == SM64_MODERN_PROGRESSION_EVENT_SAVE_RELOAD
                    ? .reload : .load,
                before: (before.save, before.menu),
                after: (snapshot.save, snapshot.menu),
                saveRecoveryDecision: UInt32(before.saveDecision.rawValue),
                menuRecoveryDecision: UInt32(before.menuDecision.rawValue)
            )
        } catch {
            return fail(SM64_MODERN_STATUS_PLATFORM_ERROR, message: "reload")
        }
        return recordSnapshot(event: event, flags: 1, captureReplay: false)
    }

    private func readSnapshot(fileIndex: Int) -> (
        save: SM64SaveFileSnapshot, menu: SM64MenuDataSnapshot
    )? {
        guard (0..<SM64CoinScoreAgeState.fileCount).contains(fileIndex) else {
            return nil
        }
        var saveBytes = [UInt8](
            repeating: 0, count: Int(SM64_MODERN_SAVE_FILE_BYTE_COUNT)
        )
        var menuBytes = [UInt8](
            repeating: 0, count: Int(SM64_MODERN_MENU_DATA_BYTE_COUNT)
        )
        let status = saveBytes.withUnsafeMutableBufferPointer { saveBuffer in
            menuBytes.withUnsafeMutableBufferPointer { menuBuffer in
                sm64_modern_progression_read_snapshot(
                    UInt32(fileIndex), saveBuffer.baseAddress,
                    UInt32(saveBuffer.count), menuBuffer.baseAddress,
                    UInt32(menuBuffer.count)
                )
            }
        }
        guard status == SM64_MODERN_STATUS_OK,
              let save = SM64SaveFileCodec.decode(saveBytes),
              let menu = SM64MenuDataCodec.decode(menuBytes) else {
            return nil
        }
        return (save, menu)
    }

    private func recordSnapshot(
        event: SM64ModernProgressionEventV1,
        flags: UInt32,
        captureReplay: Bool = true
    ) -> SM64ModernStatus {
        guard let snapshot = readSnapshot(fileIndex: Int(event.save_file_index)) else {
            return fail(SM64_MODERN_STATUS_PLATFORM_ERROR, message: "snapshot")
        }
        let before: (save: SM64SaveFileSnapshot, menu: SM64MenuDataSnapshot)
        do {
            let loaded = try adapter.load(
                saveFileIndex: Int(event.save_file_index),
                ownerThreadToken: ownerThreadToken
            )
            before = (loaded.save, loaded.menu)
            try adapter.commit(
                saveFileIndex: Int(event.save_file_index),
                save: snapshot.save, menu: snapshot.menu,
                ownerThreadToken: ownerThreadToken
            )
        } catch {
            return fail(
                SM64_MODERN_STATUS_PLATFORM_ERROR,
                message: "snapshot_shadow_commit"
            )
        }
        if saveAuthorityTrial {
            progressionMigrationLogger.notice(
                "save_authority_trial_shadow_commit event=\(event.event_kind, privacy: .public) file=\(event.save_file_index, privacy: .public)"
            )
        }
        if captureReplay {
            do {
                try appendReplay(
                    event: event,
                    operation: .mutation,
                    before: before,
                    after: (snapshot.save, snapshot.menu),
                    mutationFlags: flags
                )
            } catch {
                return fail(
                    SM64_MODERN_STATUS_PLATFORM_ERROR,
                    message: "snapshot_replay_append"
                )
            }
        }
        let saveBytes = SM64SaveFileCodec.encode(snapshot.save)
        let menuBytes = SM64MenuDataCodec.encode(snapshot.menu)
        recordOracle(
            event: event,
            recordKind: SM64_MODERN_ORACLE_RECORD_SAVE_BYTES,
            flags: flags,
            values: [hash(bytes: saveBytes), hash(bytes: menuBytes), eventCount]
        )
        return SM64_MODERN_STATUS_OK
    }

    private func beginReplayArtifact(
        save: SM64SaveFileSnapshot,
        menu: SM64MenuDataSnapshot
    ) throws {
        guard replayArtifactURL != nil, replayLedger == nil else { return }
        let imageHash = hash(image: (save, menu))
        replayLedger = SM64SaveReplayLedger(
            authority: engineAuthority,
            initialImageHash: imageHash
        )
        let event = SM64ModernProgressionEventV1()
        try appendReplay(
            event: event,
            operation: .initialize,
            before: (save, menu),
            after: (save, menu)
        )
    }

    private func appendReplay(
        event: SM64ModernProgressionEventV1,
        operation: SM64SaveReplayOperation,
        before: (save: SM64SaveFileSnapshot, menu: SM64MenuDataSnapshot),
        after: (save: SM64SaveFileSnapshot, menu: SM64MenuDataSnapshot),
        saveRecoveryDecision: UInt32 = 0,
        menuRecoveryDecision: UInt32 = 0,
        mutationFlags: UInt32? = nil,
        direction: SM64SaveReplayDirection = .cToSwift,
        status: UInt32 = 0
    ) throws {
        guard let replayArtifactURL, var replayLedger else { return }
        let record = SM64SaveReplayRecord(
            sequence: eventCount,
            simulationTick: event.simulation_tick,
            direction: direction,
            operation: operation,
            saveFileIndex: event.save_file_index,
            mutationKind: event.mutation_kind,
            mutationOperation: event.mutation_operation,
            sourceFileIndex: event.mutation_source_file_index,
            mutationFlags: mutationFlags ?? event.mutation_flags,
            mutationCourseIndex: event.mutation_course_index,
            mutationStarFlags: event.mutation_star_flags,
            mutationLevel: event.mutation_level,
            mutationArea: event.mutation_area,
            mutationCapX: event.mutation_cap_x,
            mutationCapY: event.mutation_cap_y,
            mutationCapZ: event.mutation_cap_z,
            mutationSoundMode: event.mutation_sound_mode,
            saveRecoveryDecision: saveRecoveryDecision,
            menuRecoveryDecision: menuRecoveryDecision,
            status: status,
            beforeSaveHash: hash(bytes: SM64SaveFileCodec.encode(before.save)),
            beforeMenuHash: hash(bytes: SM64MenuDataCodec.encode(before.menu)),
            afterSaveHash: hash(bytes: SM64SaveFileCodec.encode(after.save)),
            afterMenuHash: hash(bytes: SM64MenuDataCodec.encode(after.menu)),
            imageHash: hash(image: after)
        )
        replayLedger.append(record)
        try replayLedger.artifact(finalImageHash: record.imageHash).write(
            to: replayArtifactURL
        )
        self.replayLedger = replayLedger
    }

    private func recordOracle(
        event: SM64ModernProgressionEventV1,
        recordKind: SM64ModernOracleTraceRecordKind = SM64_MODERN_ORACLE_RECORD_EVENT,
        flags: UInt32,
        values: [UInt64]
    ) {
        guard sm64_modern_oracle_trace_is_active() != 0 else { return }
        let recordID = UInt64(0x1700_0000) | UInt64(event.event_kind)
        let coverageID: UInt64
        switch event.event_kind {
        case SM64_MODERN_PROGRESSION_EVENT_SAVE_PERSIST: coverageID = 2
        case SM64_MODERN_PROGRESSION_EVENT_SAVE_LOAD: coverageID = 3
        case SM64_MODERN_PROGRESSION_EVENT_SAVE_RELOAD: coverageID = 4
        default: coverageID = 1
        }
        _ = sm64_modern_oracle_trace_mark_coverage(
            SM64_MODERN_ORACLE_DOMAIN_SAVE, coverageID
        )
        let bounded = Array(values.prefix(Int(SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY)))
        bounded.withUnsafeBufferPointer { buffer in
            _ = sm64_modern_oracle_trace_record(
                SM64_MODERN_ORACLE_DOMAIN_SAVE,
                recordKind,
                UInt64(event.save_file_index),
                recordID,
                flags,
                buffer.baseAddress,
                UInt32(bounded.count)
            )
        }
    }

    private func hash(bytes: [UInt8]) -> UInt64 {
        bytes.reduce(SM64OracleTraceHash.offset) { hash, byte in
            (hash ^ UInt64(byte)) &* SM64OracleTraceHash.prime
        }
    }

    private func hash(
        image: (save: SM64SaveFileSnapshot, menu: SM64MenuDataSnapshot)
    ) -> UInt64 {
        hash(bytes: SM64SaveFileCodec.encode(image.save)
            + SM64MenuDataCodec.encode(image.menu))
    }

    private func fail(_ status: SM64ModernStatus, message: String) -> SM64ModernStatus {
        if lastError == SM64_MODERN_STATUS_OK {
            lastError = status
            progressionMigrationLogger.error(
                "progression_migration_failed status=\(status) boundary=\(message, privacy: .public)"
            )
        }
        return status
    }

    private func assertOwnerThread() {
        precondition(
            Self.currentThreadIdentity() == ownerThreadIdentity,
            "progression migration must run on its construction thread"
        )
    }

    private static func currentThreadIdentity() -> UInt64 {
        var identifier: UInt64 = 0
        let result = pthread_threadid_np(nil, &identifier)
        precondition(result == 0, "pthread_threadid_np must produce an owner token")
        return identifier
    }
}
