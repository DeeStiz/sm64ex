import Foundation

private let routeShardID: UInt64 = 0xa98d_ae7d_4d45_59ab
private let sourceID: UInt64 = 0x5577_0e09_d66b_130b
private let ownerID: UInt64 = 0x7bd3_1878_5492_2858
private let semanticBehaviorID: UInt64 = 0xcdef_b84f_e8f4_4059
private let genericWindIdentity: UInt64 = 0x0062_6876_5f73_6c77
private let routeFlags: UInt32 = 1 | 2 | 4 | 8 | 16
private let levelSL: UInt32 = 10
private let areaSL: UInt32 = 1
private let sourceOrder: UInt32 = 1
private let modelNone: UInt32 = 0
private let faceYaw: Int32 = 30
private let dialogID: UInt32 = 153
private let particleCount: UInt32 = 12
private let particleScaleBits: UInt32 = 0x4040_0000
private let soundID: UInt32 = 0x6004_4001
private let homeXBits: UInt32 = 0x442f_0000
private let homeYBits: UInt32 = 0x4556_4000
private let homeZBits: UInt32 = 0x442f_0000
private let textboxXBits: UInt32 = 0x4489_8000
private let textboxYBits: UInt32 = 0x4550_0000
private let textboxZBits: UInt32 = 0x4491_8000
private let actorBehaviorField: UInt64 = 400
private let stateID = sourceID
private let motionID = sourceID &+ 1
private let collisionID = sourceID &+ 2
private let effectID = sourceID &+ 3

private func require(
    _ condition: @autoclosure () -> Bool,
    _ message: String
) throws {
    guard condition() else {
        _ = message
        throw SM64OracleTraceCodecError.invalidHeader
    }
}

private func low(_ value: UInt64) -> UInt32 {
    UInt32(truncatingIfNeeded: value)
}

private func high(_ value: UInt64) -> UInt32 {
    UInt32(truncatingIfNeeded: value >> 32)
}

private func signed(_ value: UInt32) -> Int32 {
    Int32(bitPattern: value)
}

private func isRoute(_ record: SM64OracleTraceRecord) -> Bool {
    guard record.subjectID == ownerID,
          record.flags == routeFlags,
          record.values.count == 8 else { return false }
    switch (record.domain, record.recordKind, record.recordID) {
    case (6, 3, stateID), (6, 3, motionID),
         (7, 3, collisionID), (12, 4, effectID):
        return true
    default:
        return false
    }
}

private func isSelectedObject(
    _ record: SM64OracleTraceRecord,
    subject: UInt32
) -> Bool {
    record.domain == 3
        && record.recordKind == 1
        && low(record.subjectID) == subject
}

private struct RouteFrames {
    let records: [SM64OracleTraceRecord]
    let subject: UInt32
    let state: [SM64OracleTraceRecord]
    let motion: [SM64OracleTraceRecord]
    let collision: [SM64OracleTraceRecord]
    let effect: [SM64OracleTraceRecord]
    let object: [SM64OracleTraceRecord]
}

private func validateReducer(
    state: SM64OracleTraceRecord,
    motion: SM64OracleTraceRecord,
    collision: SM64OracleTraceRecord,
    effect: SM64OracleTraceRecord
) throws {
    try require(state.values.count == 8, "state values")
    try require(motion.values.count == 8, "motion values")
    try require(collision.values.count == 8, "collision values")
    try require(effect.values.count == 8, "effect values")

    let stateValues = state.values
    let motionValues = motion.values
    let collisionValues = collision.values
    let effectValues = effect.values
    let subject = low(stateValues[0])
    let generation = high(stateValues[0])
    try require(subject != 0 && generation == 1, "source subject")
    try require(low(stateValues[1]) == levelSL && high(stateValues[1]) == areaSL,
                "Snowman Land area 1")
    try require(low(stateValues[2]) == sourceOrder
                    && high(stateValues[2]) == modelNone,
                "source tuple order/model")
    try require(low(stateValues[3]) == 0 && signed(high(stateValues[3])) == faceYaw,
                "behavior parameter/yaw")
    try require(high(stateValues[7]) == dialogID, "dialog identity")

    try require(low(motionValues[0]) == homeXBits
                    && high(motionValues[0]) == homeYBits,
                "home position")
    try require(low(motionValues[1]) == homeZBits
                    && high(motionValues[1]) == textboxXBits,
                "source/textbox x")
    try require(low(motionValues[2]) == textboxYBits
                    && high(motionValues[2]) == textboxZBits,
                "textbox position")
    try require(low(motionValues[3]) <= 1 && high(motionValues[3]) <= 1,
                "textbox/dialog result")
    try require(high(motionValues[7]) == homeYBits, "source home y")

    try require(low(collisionValues[0]) == subject
                    && high(collisionValues[0]) == 1,
                "collision subject")
    try require(low(collisionValues[1]) <= 1
                    && high(collisionValues[1]) <= 1,
                "collision result")
    try require(low(collisionValues[4]) == dialogID, "collision dialog")
    try require(low(collisionValues[6]) == levelSL
                    && high(collisionValues[6]) == areaSL,
                "collision level")
    try require(low(collisionValues[7]) == sourceOrder
                    && signed(high(collisionValues[7])) == faceYaw,
                "collision source tuple")

    try require(low(effectValues[0]) == subject
                    && high(effectValues[0]) == 1,
                "effect subject")
    let count = low(effectValues[1])
    let effectSound = high(effectValues[3])
    try require(count == 0 || count == particleCount, "particle count")
    try require(high(effectValues[1]) == particleScaleBits, "particle scale")
    try require(effectValues[2] == 0 && low(effectValues[3]) == 0,
                "particle offsets")
    try require(effectSound <= 1, "sound edge")
    try require(low(effectValues[4]) == (effectSound == 1 ? soundID : 0),
                "sound identity")
    try require(high(effectValues[4]) == dialogID, "effect dialog")
    try require((count == particleCount) == (effectSound == 1),
                "wind effect edge")
}

private func selectedFrames(
    from native: (
        configuration: SM64OracleTraceConfiguration,
        records: [SM64OracleTraceRecord]
    )
) throws -> RouteFrames {
    let route = native.records.filter(isRoute)
    guard let firstState = route.first(where: { $0.recordID == stateID }) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let subject = low(firstState.values[0])
    try require(subject != 0 && high(firstState.values[0]) == 1, "route subject")
    let state = route.filter { $0.recordID == stateID }
    let motion = route.filter { $0.recordID == motionID }
    let collision = route.filter { $0.recordID == collisionID }
    let effect = route.filter { $0.recordID == effectID }
    try require(!state.isEmpty, "state receipts")
    try require(state.count == motion.count, "state/motion receipts")
    try require(state.count == collision.count, "state/collision receipts")
    try require(state.count == effect.count, "state/effect receipts")
    for index in state.indices {
        try validateReducer(
            state: state[index],
            motion: motion[index],
            collision: collision[index],
            effect: effect[index]
        )
    }

    let object = native.records.filter { isSelectedObject($0, subject: subject) }
    let behavior = object.filter { $0.recordID == actorBehaviorField }
    try require(!behavior.isEmpty, "semantic behavior record")
    try require(
        behavior.allSatisfy {
            $0.values.count == 1 && $0.values[0] == semanticBehaviorID
        },
        "semantic behavior identity"
    )
    try require(
        object.contains {
            $0.recordID == actorBehaviorField
                && $0.values.count == 1
                && $0.values[0] == semanticBehaviorID
        },
        "selected object state"
    )

    let records = native.records.filter {
        isRoute($0) || isSelectedObject($0, subject: subject)
    }
    try require(records.count == state.count * 4 + object.count,
                "selected record count")
    return RouteFrames(
        records: records,
        subject: subject,
        state: state,
        motion: motion,
        collision: collision,
        effect: effect,
        object: object
    )
}

private func canonicalRecords(
    _ records: [SM64OracleTraceRecord]
) throws -> [SM64OracleTraceRecord] {
    try records.map {
        try SM64OracleTraceRecord(
            simulationTick: $0.simulationTick,
            domain: $0.domain,
            recordKind: $0.recordKind,
            subjectID: $0.subjectID,
            recordID: $0.recordID,
            sequence: $0.sequence,
            flags: $0.flags,
            values: $0.values
        )
    }
}

private func writeTrace(input: URL, output: URL) throws {
    guard !FileManager.default.fileExists(atPath: output.path) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let native = try SM64OracleTraceFile.read(from: input)
    let selected = try selectedFrames(from: native)
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: try canonicalRecords(selected.records),
        to: output
    )
    print(
        "swift_snowman_wind_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "records=\(selected.records.count) route_records=\(selected.state.count * 4) "
            + "subject=\(selected.subject) domains=script,object,collision,effect"
    )
}

private func audit(input: URL, output: URL) throws {
    guard input.standardizedFileURL != output.standardizedFileURL else {
        print("snowman_wind_single_artifact_rejected=1")
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let native = try SM64OracleTraceFile.read(from: input)
    let swift = try SM64OracleTraceFile.read(from: output)
    let nativeSelected = try selectedFrames(from: native)
    let swiftSelected = try selectedFrames(from: swift)
    var blockers: [String] = []
    if native.configuration != swift.configuration { blockers.append("header") }
    if nativeSelected.records != swiftSelected.records {
        blockers.append("record_bytes")
    }
    let firstDivergence = zip(nativeSelected.records, swiftSelected.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "snowman_wind_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(nativeSelected.records.count) "
            + "swift_records=\(swiftSelected.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence)"
    )
    try require(blockers.isEmpty, "exact C/Swift route pair")
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard !data.isEmpty else { throw SM64OracleTraceCodecError.truncated }
    data[data.index(before: data.endIndex)] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("snowman_wind_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("snowman_wind_tamper_rejected=1")
    }
}

private func partial(input: URL, output: URL) throws {
    let data = try Data(contentsOf: input)
    guard data.count > 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    try data.prefix(72 + SM64OracleTraceRecord.encodedSize)
        .write(to: output, options: .atomic)
    print("snowman_wind_partial_written=1")
}

private func wrongSubject(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    guard let index = native.records.firstIndex(where: {
        isRoute($0) && $0.recordID == stateID
    }) else { throw SM64OracleTraceCodecError.truncated }
    var records = native.records
    var values = records[index].values
    values[0] = (values[0] & 0xffff_ffff_0000_0000) | 0xdead
    records[index] = try SM64OracleTraceRecord(
        simulationTick: records[index].simulationTick,
        domain: records[index].domain,
        recordKind: records[index].recordKind,
        subjectID: records[index].subjectID,
        recordID: records[index].recordID,
        sequence: records[index].sequence,
        flags: records[index].flags,
        values: values
    )
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: records,
        to: output
    )
    print("snowman_wind_wrong_subject_written=1")
}

private func genericBridge(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    let records = try native.records.map { record -> SM64OracleTraceRecord in
        guard record.domain == 3 && record.recordKind == 1
                && record.recordID == actorBehaviorField else { return record }
        return try SM64OracleTraceRecord(
            simulationTick: record.simulationTick,
            domain: record.domain,
            recordKind: record.recordKind,
            subjectID: record.subjectID,
            recordID: record.recordID,
            sequence: record.sequence,
            flags: record.flags,
            values: [genericWindIdentity]
        )
    }
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: records,
        to: output
    )
    print("snowman_wind_generic_bridge_written=1")
}

private func fixtureOnly(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    let records = native.records.filter { $0.domain != 3 }
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: records,
        to: output
    )
    print("snowman_wind_fixture_only_written=1")
}

private func duplicate(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    guard let first = native.records.first(where: {
        isRoute($0) && $0.recordID == stateID
    }) else { throw SM64OracleTraceCodecError.truncated }
    var records = native.records
    records.append(first)
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: records,
        to: output
    )
    print("snowman_wind_duplicate_written=1")
}

@main
struct SM64SnowmanWindRouteSmoke {
    static func main() throws {
        let arguments = CommandLine.arguments
        guard arguments.count >= 2 else { throw SM64OracleTraceCodecError.invalidHeader }
        switch arguments[1] {
        case "write":
            guard arguments.count == 4 else { throw SM64OracleTraceCodecError.invalidHeader }
            try writeTrace(input: URL(fileURLWithPath: arguments[2]),
                           output: URL(fileURLWithPath: arguments[3]))
        case "audit":
            guard arguments.count == 4 else { throw SM64OracleTraceCodecError.invalidHeader }
            try audit(input: URL(fileURLWithPath: arguments[2]),
                      output: URL(fileURLWithPath: arguments[3]))
        case "tamper":
            guard arguments.count == 4 else { throw SM64OracleTraceCodecError.invalidHeader }
            try tamper(input: URL(fileURLWithPath: arguments[2]),
                       output: URL(fileURLWithPath: arguments[3]))
        case "partial":
            guard arguments.count == 4 else { throw SM64OracleTraceCodecError.invalidHeader }
            try partial(input: URL(fileURLWithPath: arguments[2]),
                        output: URL(fileURLWithPath: arguments[3]))
        case "wrong-subject":
            guard arguments.count == 4 else { throw SM64OracleTraceCodecError.invalidHeader }
            try wrongSubject(input: URL(fileURLWithPath: arguments[2]),
                             output: URL(fileURLWithPath: arguments[3]))
        case "generic-bridge":
            guard arguments.count == 4 else { throw SM64OracleTraceCodecError.invalidHeader }
            try genericBridge(input: URL(fileURLWithPath: arguments[2]),
                              output: URL(fileURLWithPath: arguments[3]))
        case "fixture-only":
            guard arguments.count == 4 else { throw SM64OracleTraceCodecError.invalidHeader }
            try fixtureOnly(input: URL(fileURLWithPath: arguments[2]),
                            output: URL(fileURLWithPath: arguments[3]))
        case "duplicate":
            guard arguments.count == 4 else { throw SM64OracleTraceCodecError.invalidHeader }
            try duplicate(input: URL(fileURLWithPath: arguments[2]),
                          output: URL(fileURLWithPath: arguments[3]))
        default:
            throw SM64OracleTraceCodecError.invalidHeader
        }
    }
}
