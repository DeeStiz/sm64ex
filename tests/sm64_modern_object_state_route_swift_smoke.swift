import Foundation

private let routeFNVOffset: UInt64 = 1_469_598_103_934_665_603
private let routeFNVPrime: UInt64 = 1_099_511_628_211
private let routeShardID: UInt64 = 0x862c_3d78_b60d_657c
private let routeInputSeed: UInt64 = 0x58cc_16e4_df72_5004
private let routeSaveSeed: UInt64 = 0x18fda_13f_fd33_fa7d
private let routeFirstRecord: UInt64 = 400
private let routeLastRecord: UInt64 = 413

// Source: levels/castle_inside/areas/1/collision.inc.c, the authored
// `special_wooden_door` at (-271, 0, -824), yaw 32. The C owner boundary maps
// bhvDoor to the same semantic value-only identity used by
// SM64DoorObjectBridge. This avoids build-layout-dependent pointer deltas
// while keeping the source behavior identity explicit.
private let sourceDoorBehaviorIdentity: UInt64 = 0x6268_765f_6472_6e
private let sourceDoorPosition = SM64ObjectVector3(x: -271, y: 0, z: -824)
private let sourceDoorMoveYaw: Int32 = 32 << 8
private let sourceDoorFlags: UInt32 = 0x01 | 0x08 | 0x40 | 0x80
private let sourceDoorGraphFlags: UInt16 = 0x21

private func update(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= routeFNVPrime
    }
    return hash
}

private func hashString(_ value: String) -> UInt64 {
    value.utf8.reduce(routeFNVOffset) { ($0 ^ UInt64($1)) &* routeFNVPrime }
}

private func coverageFingerprint() -> UInt64 {
    var hash = routeFNVOffset
    for recordID in routeFirstRecord...routeLastRecord {
        hash = update(hash, 3)
        hash = update(hash, 0)
        hash = update(hash, recordID)
    }
    return update(hash, routeLastRecord - routeFirstRecord + 1)
}

private func timebaseFingerprint() -> UInt64 {
    [UInt32(3), 60, 1, 30, 1, 2, 2].reduce(routeFNVOffset) { hash, value in
        var next = hash
        for byte in 0..<4 {
            next ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
            next &*= routeFNVPrime
        }
        return next
    }
}

private func configuration() throws -> SM64OracleTraceConfiguration {
    SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: hashString("sm64-modern-object-state-route-build-v1"),
        contentFingerprint: hashString(
            "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|object_state"
        ),
        timebaseFingerprint: timebaseFingerprint(),
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "shard=0x862c3d78b60d657c"
        ),
        initialSaveFingerprint: hashString(
            "save=empty-us-slot-0;seed=0x18fda13ffd33fa7d"
        ),
        coverageFingerprint: coverageFingerprint()
    )
}

private func sourceBackedSnapshot() throws -> SM64ObjectSnapshotV4 {
    let pool = SM64ObjectPool(capacity: 1)
    let door = try pool.spawn(
        in: .surface,
        behaviorIdentity: sourceDoorBehaviorIdentity,
        drawingDistance: 20_000
    )
    guard door.traceSubject == 1 else { throw SM64OracleTraceCodecError.invalidHeader }
    guard pool.mutate(door, { record in
        record.activeFlags = SM64ObjectPool.activeFlagActive
            | SM64ObjectPool.activeFlagUnknown8
        record.position = sourceDoorPosition
        record.moveAngles = SM64ObjectAngles(pitch: 0, yaw: sourceDoorMoveYaw, roll: 0)
        record.action = 0
        record.subAction = 0
        // bhvDoor's first owner update advances the closed timer once. The
        // route's area transition then keeps this object at the same native
        // snapshot boundary on ticks 2 and 3.
        record.timer = 1
        record.moveFlags = 0
        record.interactionStatus = 0
        record.heldState = 0
        record.objectFlags = sourceDoorFlags
        record.forwardVelocity = 0
        record.graphFlags = sourceDoorGraphFlags
    }) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    guard let record = pool.record(for: door) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let snapshot = SM64ObjectSnapshotV4(record: record)
    guard snapshot.subject == 1, snapshot.actorValues.count == 20 else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    return snapshot
}

private func writeTrace(to url: URL) throws {
    let snapshot = try sourceBackedSnapshot()
    let fields = Array(routeFirstRecord...routeLastRecord)
    let valueCounts = [1, 1, 1, 1, 1, 3, 3, 3, 1, 1, 1, 1, 1, 1]
    guard fields.count == valueCounts.count,
          valueCounts.reduce(0, +) == snapshot.actorValues.count else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    var records: [SM64OracleTraceRecord] = []
    records.reserveCapacity(28)
    // The vector fields occupy three values but only one schema record each;
    // preserve the C actor-field order while emitting the exact field widths.
    var offset = 0
    for tick in UInt64(2)...UInt64(3) {
        for sequence in 0..<valueCounts.count {
            let count = valueCounts[sequence]
            let values = Array(snapshot.actorValues[offset..<(offset + count)])
            records.append(try SM64OracleTraceRecord(
                simulationTick: tick,
                domain: 3,
                recordKind: 1,
                subjectID: 1,
                recordID: routeFirstRecord + UInt64(sequence),
                sequence: UInt32(sequence),
                values: values
            ))
            offset += count
        }
        offset = 0
    }
    try SM64OracleTraceFile.write(
        configuration: try configuration(), records: records, to: url
    )
    print(
        "swift_object_state_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "subject=1 records=\(records.count) ticks=2,3 "
            + "coverage=0x\(String(coverageFingerprint(), radix: 16)) "
            + "behavior=0x\(String(sourceDoorBehaviorIdentity, radix: 16))"
    )
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

private func audit(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if !validOrdering(cTrace.records) || !validOrdering(swiftTrace.records) {
        blockers.append("ordering")
    }
    if cTrace.records.count != 28 || swiftTrace.records.count != 28 {
        blockers.append("record_count")
    }
    if cTrace.records != swiftTrace.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "object_state_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cTrace.records.count) swift_records=\(swiftTrace.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) first_divergence=\(firstDivergence)"
    )
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard !data.isEmpty else { throw SM64OracleTraceCodecError.truncated }
    data[data.index(before: data.endIndex)] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("object_state_pairing_tamper_rejected=0")
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("object_state_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernObjectStateRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else { throw SM64OracleTraceCodecError.truncated }
        switch mode {
        case "write":
            guard arguments.count == 2 else { throw SM64OracleTraceCodecError.truncated }
            try writeTrace(to: URL(fileURLWithPath: arguments[1]).standardizedFileURL)
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
