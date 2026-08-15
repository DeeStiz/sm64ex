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
final class SwiftProgressionMigrationService: @unchecked Sendable {
    private let adapter: SM64OwnerThreadPersistenceAdapter
    private let ownerThreadToken: UInt64
    private var runtime: SM64ProgressionRuntime
    private var eventCount: UInt64 = 0
    private var lastError: SM64ModernStatus = SM64_MODERN_STATUS_OK

    init(saveDirectory: String, ownerThreadToken: UInt64) throws {
        self.ownerThreadToken = ownerThreadToken
        self.adapter = try SM64OwnerThreadPersistenceAdapter(
            rootURL: URL(fileURLWithPath: saveDirectory)
                .appendingPathComponent("swift-progression", isDirectory: true),
            ownerThreadToken: ownerThreadToken
        )
        self.runtime = SM64ProgressionRuntime()
    }

    func initialize() throws {
        _ = try runtime.reloadFromBackup(
            using: adapter, ownerThreadToken: ownerThreadToken
        )
    }

    func makeAPI() -> SM64ModernProgressionMigrationApiV1 {
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
        if requiresCourse {
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
        return SM64_MODERN_STATUS_OK
    }

    private func persist(event: SM64ModernProgressionEventV1) -> SM64ModernStatus {
        do {
            _ = try runtime.commitIfNeeded(
                using: adapter, ownerThreadToken: ownerThreadToken
            )
        } catch {
            return fail(SM64_MODERN_STATUS_PLATFORM_ERROR, message: "persist")
        }
        let saveBytes = SM64SaveFileCodec.encode(runtime.saveSnapshot())
        let menuBytes = SM64MenuDataCodec.encode(runtime.menuSnapshot())
        recordOracle(
            event: event,
            recordKind: SM64_MODERN_ORACLE_RECORD_SAVE_BYTES,
            flags: 0,
            values: [
                hash(bytes: saveBytes), hash(bytes: menuBytes), eventCount
            ]
        )
        return SM64_MODERN_STATUS_OK
    }

    private func reload(event: SM64ModernProgressionEventV1) -> SM64ModernStatus {
        do {
            _ = try runtime.reloadFromBackup(
                using: adapter, ownerThreadToken: ownerThreadToken
            )
        } catch {
            return fail(SM64_MODERN_STATUS_PLATFORM_ERROR, message: "reload")
        }
        recordOracle(
            event: event,
            recordKind: SM64_MODERN_ORACLE_RECORD_SAVE_BYTES,
            flags: 1,
            values: [
                hash(bytes: SM64SaveFileCodec.encode(runtime.saveSnapshot())),
                hash(bytes: SM64MenuDataCodec.encode(runtime.menuSnapshot())),
                eventCount
            ]
        )
        return SM64_MODERN_STATUS_OK
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

    private func fail(_ status: SM64ModernStatus, message: String) -> SM64ModernStatus {
        if lastError == SM64_MODERN_STATUS_OK {
            lastError = status
            progressionMigrationLogger.error(
                "progression_migration_failed status=\(status) boundary=\(message, privacy: .public)"
            )
        }
        return status
    }
}
