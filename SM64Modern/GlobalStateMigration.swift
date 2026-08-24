import Darwin
import Foundation
import os

private let globalStateMigrationLogger = Logger(
    subsystem: "io.github.deestiz.sm64modern",
    category: "GlobalStateMigration"
)

/// Fixed-width value copy of the native global snapshot. C remains the
/// authority; no value is inferred from the Swift simulation frame or a local
/// random stream.
struct SM64GlobalStateSnapshot: Equatable, Sendable {
    let simulationTick: UInt64
    let globalTimer: UInt32
    let levelNumber: UInt32
    let areaIndex: UInt32
    let actNumber: UInt32
    let courseNumber: UInt32
    let randomSeed: UInt32

    init(native: SM64ModernGlobalStateSnapshotV1) {
        simulationTick = native.simulation_tick
        globalTimer = native.global_timer
        levelNumber = native.level_number
        areaIndex = native.area_index
        actNumber = native.act_number
        courseNumber = native.course_number
        randomSeed = native.random_seed
    }

    var values: [[UInt64]] {
        [
            [UInt64(globalTimer)],
            [UInt64(levelNumber)],
            [UInt64(areaIndex)],
            [UInt64(actNumber)],
            [UInt64(courseNumber)],
            [UInt64(randomSeed)],
        ]
    }
}

/// Owner-thread mirror for the six global schema-4 records. Each publication
/// creates one complete ordered window; a partial window is never exposed.
struct SM64GlobalStateMirror: Equatable, Sendable {
    private(set) var snapshots: [SM64GlobalStateSnapshot] = []
    private(set) var traceRecords: [SM64OracleTraceRecord] = []

    mutating func observe(native: SM64ModernGlobalStateSnapshotV1) throws {
        guard native.header.abi_version == SM64_MODERN_ABI_VERSION_1,
              native.header.struct_size >= UInt32(
                MemoryLayout<SM64ModernGlobalStateSnapshotV1>.size
              ),
              native.reserved == 0 else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        let snapshot = SM64GlobalStateSnapshot(native: native)
        if let previous = snapshots.last {
            guard snapshot.simulationTick > previous.simulationTick else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
        }
        let records = try snapshot.values.enumerated().map { offset, values in
            try SM64OracleTraceRecord(
                simulationTick: snapshot.simulationTick,
                domain: SM64_MODERN_ORACLE_DOMAIN_GLOBAL,
                recordKind: SM64_MODERN_ORACLE_RECORD_STATE,
                recordID: UInt64(SM64_MODERN_FIELD_GLOBAL_TIMER) + UInt64(offset),
                sequence: UInt32(offset),
                values: values
            )
        }
        guard records.count == 6 else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        snapshots.append(snapshot)
        traceRecords.append(contentsOf: records)
    }
}

private func currentGlobalStateThreadIdentity() -> UInt64 {
    var identifier: UInt64 = 0
    let result = pthread_threadid_np(nil, &identifier)
    precondition(result == 0, "pthread_threadid_np must produce an owner token")
    return identifier
}

private func globalStateMigrationService(
    from context: UnsafeMutableRawPointer?
) -> SwiftGlobalStateMigrationService? {
    guard let context else { return nil }
    return Unmanaged<SwiftGlobalStateMigrationService>.fromOpaque(context)
        .takeUnretainedValue()
}

private let swiftGlobalStateObserve: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernGlobalStateSnapshotV1>?
) -> SM64ModernStatus = { context, snapshot in
    guard let service = globalStateMigrationService(from: context), let snapshot else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.observe(native: snapshot.pointee)
}

/// Owner-thread adapter for the native global-state publication boundary.
/// This service only mirrors copied values and records; it never reads C
/// globals directly and never emits a default timer or seed.
final class SwiftGlobalStateMigrationService {
    private let ownerThreadToken: UInt64
    private let constructionThreadToken: UInt64
    private var lastError: SM64ModernStatus = SM64_MODERN_STATUS_OK
    private(set) var mirror = SM64GlobalStateMirror()

    init(ownerThreadToken: UInt64) {
        self.ownerThreadToken = ownerThreadToken
        self.constructionThreadToken = currentGlobalStateThreadIdentity()
    }

    func makeAPI() -> SM64ModernGlobalStateMigrationApiV1 {
        assertOwnerThread()
        var api = SM64ModernGlobalStateMigrationApiV1()
        api.header.abi_version = SM64_MODERN_ABI_VERSION_1
        api.header.struct_size = UInt32(
            MemoryLayout<SM64ModernGlobalStateMigrationApiV1>.size
        )
        api.context = Unmanaged.passUnretained(self).toOpaque()
        api.observe_snapshot = swiftGlobalStateObserve
        return api
    }

    func observe(native: SM64ModernGlobalStateSnapshotV1) -> SM64ModernStatus {
        assertOwnerThread()
        guard lastError == SM64_MODERN_STATUS_OK else { return lastError }
        do {
            try mirror.observe(native: native)
            if mirror.snapshots.count == 1 {
                globalStateMigrationLogger.notice(
                    "swift_global_state_snapshot tick=\(native.simulation_tick, privacy: .public) timer=\(native.global_timer, privacy: .public) seed=\(native.random_seed, privacy: .public)"
                )
            }
            return SM64_MODERN_STATUS_OK
        } catch {
            lastError = SM64_MODERN_STATUS_INVALID_ARGUMENT
            return lastError
        }
    }

    func summary() -> (snapshots: Int, records: Int, lastTick: UInt64?) {
        assertOwnerThread()
        return (
            mirror.snapshots.count,
            mirror.traceRecords.count,
            mirror.snapshots.last?.simulationTick
        )
    }

    private func assertOwnerThread() {
        precondition(currentGlobalStateThreadIdentity() == constructionThreadToken)
        precondition(currentGlobalStateThreadIdentity() == ownerThreadToken)
    }
}
