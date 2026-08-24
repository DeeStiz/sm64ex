import Darwin
import Foundation

private let snapshotByteCount = 48

private struct SnapshotCursor {
    let data: Data
    var offset: Int = 0

    mutating func readUInt32() throws -> UInt32 {
        guard offset + 4 <= data.count else { throw SM64OracleTraceCodecError.truncated }
        let value = data[offset..<offset + 4].enumerated().reduce(UInt32(0)) {
            $0 | (UInt32($1.element) << UInt32($1.offset * 8))
        }
        offset += 4
        return value
    }

    mutating func readUInt64() throws -> UInt64 {
        guard offset + 8 <= data.count else { throw SM64OracleTraceCodecError.truncated }
        let value = data[offset..<offset + 8].enumerated().reduce(UInt64(0)) {
            $0 | (UInt64($1.element) << UInt64($1.offset * 8))
        }
        offset += 8
        return value
    }

    mutating func skip(_ count: Int) throws {
        guard offset + count <= data.count else {
            throw SM64OracleTraceCodecError.truncated
        }
        offset += count
    }
}

private func nativeSnapshots(from url: URL) throws -> [SM64ModernGlobalStateSnapshotV1] {
    guard MemoryLayout<SM64ModernGlobalStateSnapshotV1>.size == snapshotByteCount else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    guard data.count > 0, data.count % snapshotByteCount == 0 else {
        throw SM64OracleTraceCodecError.truncated
    }
    var cursor = SnapshotCursor(data: data)
    var snapshots: [SM64ModernGlobalStateSnapshotV1] = []
    snapshots.reserveCapacity(data.count / snapshotByteCount)
    while cursor.offset < data.count {
        let abiVersion = try cursor.readUInt32()
        let structSize = try cursor.readUInt32()
        let tick = try cursor.readUInt64()
        let timer = try cursor.readUInt32()
        let level = try cursor.readUInt32()
        let area = try cursor.readUInt32()
        let act = try cursor.readUInt32()
        let course = try cursor.readUInt32()
        let seed = try cursor.readUInt32()
        let reserved = try cursor.readUInt32()
        try cursor.skip(4) // tail padding keeps the C struct 8-byte aligned
        var snapshot = SM64ModernGlobalStateSnapshotV1()
        snapshot.header.abi_version = abiVersion
        snapshot.header.struct_size = structSize
        snapshot.simulation_tick = tick
        snapshot.global_timer = timer
        snapshot.level_number = level
        snapshot.area_index = area
        snapshot.act_number = act
        snapshot.course_number = course
        snapshot.random_seed = seed
        snapshot.reserved = reserved
        snapshots.append(snapshot)
    }
    return snapshots
}

private func validOrdering(_ records: [SM64OracleTraceRecord]) -> Bool {
    guard !records.isEmpty else { return false }
    var lastTick: UInt64?
    var lastSequence: UInt32 = 0
    for record in records {
        if let lastTick {
            if record.simulationTick < lastTick { return false }
            if record.simulationTick == lastTick,
               record.sequence != lastSequence &+ 1 { return false }
            if record.simulationTick > lastTick, record.sequence != 0 { return false }
        } else if record.sequence != 0 {
            return false
        }
        lastTick = record.simulationTick
        lastSequence = record.sequence
    }
    return true
}

private func writeTrace(
    snapshotsURL: URL,
    cTraceURL: URL,
    swiftTraceURL: URL
) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cTraceURL)
    let native = try nativeSnapshots(from: snapshotsURL)
    // The smoke is a single owner-thread process; use the construction token
    // captured by the service rather than fabricating a seed or global value.
    let ownerToken = currentThreadToken()
    let service = SwiftGlobalStateMigrationService(ownerThreadToken: ownerToken)
    let api = service.makeAPI()
    for var snapshot in native {
        let status = withUnsafePointer(to: &snapshot) { pointer in
            api.observe_snapshot?(api.context, pointer) ?? SM64_MODERN_STATUS_INVALID_STATE
        }
        guard status == SM64_MODERN_STATUS_OK else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
    }
    guard service.mirror.snapshots.count == 2,
          service.mirror.traceRecords.count == 12 else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    try SM64OracleTraceFile.write(
        configuration: cTrace.configuration,
        records: service.mirror.traceRecords,
        to: swiftTraceURL
    )
    print(
        "swift_global_state_route_recorded snapshots=\(service.mirror.snapshots.count) "
            + "records=\(service.mirror.traceRecords.count) ticks=2,3 "
            + "timer=\(service.mirror.snapshots.map { String($0.globalTimer) }.joined(separator: ",")) "
            + "seed=\(service.mirror.snapshots.first?.randomSeed ?? 0)"
    )
}

private func currentThreadToken() -> UInt64 {
    // The service's callback path asserts the owner token. This process never
    // leaves the construction thread while building the independent mirror.
    var token: UInt64 = 0
    pthread_threadid_np(nil, &token)
    return token
}

private func audit(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if !validOrdering(cTrace.records) || !validOrdering(swiftTrace.records) {
        blockers.append("ordering")
    }
    let cGlobal = cTrace.records.filter {
        $0.domain == SM64_MODERN_ORACLE_DOMAIN_GLOBAL
            && $0.recordKind == SM64_MODERN_ORACLE_RECORD_STATE
            && (1...6).contains($0.recordID)
    }
    let swiftGlobal = swiftTrace.records.filter {
        $0.domain == SM64_MODERN_ORACLE_DOMAIN_GLOBAL
            && $0.recordKind == SM64_MODERN_ORACLE_RECORD_STATE
            && (1...6).contains($0.recordID)
    }
    if cGlobal.count != 12 || swiftGlobal.count != 12 { blockers.append("record_count") }
    if cTrace.records != swiftTrace.records {
        // C retains unrelated lifecycle records in the raw trace while the
        // Swift mirror intentionally emits only the six published records.
        // Compare the canonical route window independently.
        if cGlobal != swiftGlobal { blockers.append("record_bytes") }
    }
    let firstDivergence = zip(cGlobal, swiftGlobal)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "global_state_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cGlobal.count) swift_records=\(swiftGlobal.count) "
            + "blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence)"
    )
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard data.count >= 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    let last = data.index(data.startIndex, offsetBy: 72 + 128 - 1)
    data[last] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("global_state_pairing_tamper_rejected=0")
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("global_state_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernGlobalStateRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else { throw SM64OracleTraceCodecError.truncated }
        switch mode {
        case "write":
            guard arguments.count == 4 else { throw SM64OracleTraceCodecError.truncated }
            try writeTrace(
                snapshotsURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                cTraceURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL,
                swiftTraceURL: URL(fileURLWithPath: arguments[3]).standardizedFileURL
            )
        case "audit":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try audit(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "tamper":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try tamper(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
