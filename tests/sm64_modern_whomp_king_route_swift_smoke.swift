import Foundation

private let routeShardID: UInt64 = 0x28e0_617b_fc28_6cbe
private let sourceID: UInt64 = 0x425f_2ecc_0685_117a
private let ownerID: UInt64 = 0xa811_7849_8255_6e63
private let behaviorID: UInt64 = 0x43b2_4705_3d2e_adb4
private let rewardBehaviorID: UInt64 = 0x8ed4_2eb7_e560_58a1
private let collisionIdentity: UInt64 = 0xa316_d232_3396_c7de
private let genericWhompIdentity: UInt64 = 0x6268_765f_7768_6d
private let routeFlags: UInt32 = 1 | 2 | 4 | 8 | 16 | 32
private let modelWhomp: UInt32 = 0x67
private let modelStar: UInt32 = 0x7a
private let levelWF: UInt32 = 24
private let areaWF: UInt32 = 1
private let act1: UInt32 = 1
private let stateID = sourceID
private let motionID = sourceID &+ 1
private let objectID = sourceID &+ 2
private let collisionID = sourceID &+ 3
private let effectID = sourceID &+ 4

private let homeXBits: UInt32 = 0
private let homeYBits: UInt32 = 0x4560_0000
private let homeZBits: UInt32 = 0
private let rewardXBits: UInt32 = 0x4334_0000
private let rewardYBits: UInt32 = 0x4572_8000
private let rewardZBits: UInt32 = 0x43aa_0000

private func require(
    _ condition: @autoclosure () -> Bool,
    _ message: String
) throws {
    guard condition() else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    _ = message
}

private func low(_ value: UInt64) -> UInt32 {
    UInt32(truncatingIfNeeded: value)
}

private func high(_ value: UInt64) -> UInt32 {
    UInt32(truncatingIfNeeded: value >> 32)
}

private func pack(_ low: UInt32, _ high: UInt32) -> UInt64 {
    UInt64(low) | (UInt64(high) << 32)
}

private func isRoute(_ record: SM64OracleTraceRecord) -> Bool {
    guard record.subjectID == ownerID, record.flags == routeFlags else {
        return false
    }
    if record.domain == 6 && record.recordKind == 3 {
        return record.recordID == stateID || record.recordID == motionID
    }
    if record.domain == 3 && record.recordKind == 1 {
        return record.recordID == objectID
    }
    if record.domain == 7 && record.recordKind == 3 {
        return record.recordID == collisionID
    }
    return record.domain == 12
        && record.recordKind == 4
        && record.recordID == effectID
}

private struct RouteFrames {
    let records: [SM64OracleTraceRecord]
    let subject: UInt32
    let state: [SM64OracleTraceRecord]
    let motion: [SM64OracleTraceRecord]
    let object: [SM64OracleTraceRecord]
    let collision: [SM64OracleTraceRecord]
    let effect: [SM64OracleTraceRecord]
}

private func validateFrame(
    state: SM64OracleTraceRecord,
    motion: SM64OracleTraceRecord,
    object: SM64OracleTraceRecord,
    collision: SM64OracleTraceRecord,
    effect: SM64OracleTraceRecord
) throws {
    try require(state.values.count == 8, "state values")
    try require(motion.values.count == 8, "motion values")
    try require(object.values.count == 8, "object values")
    try require(collision.values.count == 8, "collision values")
    try require(effect.values.count == 8, "effect values")

    let subject = low(state.values[0])
    try require(high(state.values[0]) == 1, "source generation")
    try require(low(state.values[1]) == levelWF
                && high(state.values[1]) == areaWF, "WF area 1")
    try require(low(state.values[2]) == act1
                && high(state.values[2]) == modelWhomp, "ACT_1 Whomp")
    try require(low(state.values[3]) == 0
                && high(state.values[3]) == 0, "source ordinal and yaw")
    try require(low(state.values[4]) == 0
                && high(state.values[4]) == 1,
                "authored parameter and King variant")
    try require(low(state.values[5]) <= 9, "action before")
    try require(high(state.values[5]) <= 9, "action after")
    try require(low(state.values[6]) <= 10, "sub-action before")
    try require(high(state.values[6]) <= 10, "sub-action after")
    try require(low(object.values[0]) == subject
                && high(object.values[0]) == 1, "object subject")
    try require(object.values[1] == behaviorID, "semantic King identity")
    try require(low(object.values[2]) == modelWhomp
                && high(object.values[2]) == 0, "King object tuple")
    try require(low(object.values[3]) == 1
                && high(object.values[3]) == low(state.values[5]),
                "King object variant")
    try require(low(collision.values[0]) == subject
                && high(collision.values[0]) == 1, "collision subject")
    try require(collision.values[1] == collisionIdentity,
                "named Whomp collision identity")
    try require(low(effect.values[0]) == subject, "effect subject")

    try require(low(motion.values[0]) == homeXBits
                && high(motion.values[0]) == homeYBits, "authored home XY")
    try require(low(motion.values[1]) == homeZBits, "authored home Z")
    try require(low(effect.values[1]) == low(state.values[5])
                && high(effect.values[1]) == high(state.values[5]),
                "effect action pair")

    let rewardSpawned = low(object.values[6])
    let rewardOrdinal = high(object.values[6])
    try require(rewardSpawned <= 1 && rewardOrdinal <= 1,
                "reward cardinality")
    if rewardSpawned == 1 {
        try require(rewardOrdinal == 1, "reward source child ordinal")
        try require(object.values[7] == rewardBehaviorID,
                    "reward semantic behavior")
        try require(low(effect.values[3]) == 1
                    && high(effect.values[3]) == 1,
                    "reward effect child")
        try require(effect.values[4] == rewardBehaviorID,
                    "reward effect identity")
        try require(low(effect.values[5]) == modelStar
                    && high(effect.values[5]) == rewardXBits,
                    "reward model and X")
        try require(low(effect.values[6]) == rewardYBits
                    && high(effect.values[6]) == rewardZBits,
                    "reward YZ")
    } else {
        try require(rewardOrdinal == 0 && object.values[7] == 0,
                    "missing reward remains absent")
    }
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
    let state = route.filter { $0.recordID == stateID }
    let motion = route.filter { $0.recordID == motionID }
    let object = route.filter { $0.recordID == objectID }
    let collision = route.filter { $0.recordID == collisionID }
    let effect = route.filter { $0.recordID == effectID }
    try require(!state.isEmpty, "state receipts")
    try require(state.count == motion.count, "state/motion receipts")
    try require(state.count == object.count, "state/object receipts")
    try require(state.count == collision.count, "state/collision receipts")
    try require(state.count == effect.count, "state/effect receipts")
    try require(route.count == state.count * 5, "complete route domains")

    for index in state.indices {
        try validateFrame(
            state: state[index],
            motion: motion[index],
            object: object[index],
            collision: collision[index],
            effect: effect[index]
        )
    }
    return RouteFrames(
        records: route,
        subject: subject,
        state: state,
        motion: motion,
        object: object,
        collision: collision,
        effect: effect
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

private func writeTrace(cURL: URL, swiftURL: URL) throws {
    guard !FileManager.default.fileExists(atPath: swiftURL.path) else {
        print("whomp_king_persistent_rerun_rejected=1")
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let native = try SM64OracleTraceFile.read(from: cURL)
    let selected = try selectedFrames(from: native)
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: try canonicalRecords(selected.records),
        to: swiftURL
    )
    print(
        "swift_whomp_king_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "records=\(selected.records.count) "
            + "route_records=\(selected.state.count * 5) "
            + "subject=\(selected.subject) domains=script,object,collision,effect "
            + "fixture_only=0"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    guard cURL.resolvingSymlinksInPath().standardizedFileURL.path
        != swiftURL.resolvingSymlinksInPath().standardizedFileURL.path else {
        print("whomp_king_single_artifact_rejected=1")
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    let cSelected = try selectedFrames(from: cTrace)
    let swiftSelected = try selectedFrames(from: swiftTrace)
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if cSelected.records.count != swiftSelected.records.count {
        blockers.append("record_count")
    }
    if cSelected.records != swiftSelected.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cSelected.records, swiftSelected.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "whomp_king_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cSelected.records.count) "
            + "swift_records=\(swiftSelected.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence) fixture_only=0"
    )
    try require(blockers.isEmpty, "exact C/Swift route pair")
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard data.count >= 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    data[data.index(before: data.endIndex)] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("whomp_king_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("whomp_king_tamper_rejected=1")
    }
}

private func partial(input: URL, output: URL) throws {
    let data = try Data(contentsOf: input)
    guard data.count > 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    try data.prefix(72 + SM64OracleTraceRecord.encodedSize)
        .write(to: output, options: .atomic)
    print("whomp_king_partial_written=1")
}

private func wrongVariant(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    var records = native.records
    guard let index = records.firstIndex(where: { $0.recordID == stateID }) else {
        throw SM64OracleTraceCodecError.truncated
    }
    var values = records[index].values
    values[4] = pack(0, high(values[4]))
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
        records: try canonicalRecords(records),
        to: output
    )
    print("whomp_king_wrong_variant_written=1")
}

private func wrongSubject(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    var records = native.records
    guard let index = records.firstIndex(where: { $0.recordID == stateID }) else {
        throw SM64OracleTraceCodecError.truncated
    }
    let record = records[index]
    records[index] = try SM64OracleTraceRecord(
        simulationTick: record.simulationTick,
        domain: record.domain,
        recordKind: record.recordKind,
        subjectID: ownerID ^ 1,
        recordID: record.recordID,
        sequence: record.sequence,
        flags: record.flags,
        values: record.values
    )
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: try canonicalRecords(records),
        to: output
    )
    print("whomp_king_wrong_subject_written=1")
}

private func genericBridge(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    var records = native.records
    guard let index = records.firstIndex(where: { $0.recordID == objectID }) else {
        throw SM64OracleTraceCodecError.truncated
    }
    var values = records[index].values
    values[1] = genericWhompIdentity
    let record = records[index]
    records[index] = try SM64OracleTraceRecord(
        simulationTick: record.simulationTick,
        domain: record.domain,
        recordKind: record.recordKind,
        subjectID: record.subjectID,
        recordID: record.recordID,
        sequence: record.sequence,
        flags: record.flags,
        values: values
    )
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: try canonicalRecords(records),
        to: output
    )
    print("whomp_king_generic_bridge_written=1")
}

private func fixtureOnly(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    let selected = try selectedFrames(from: native)
    let records = selected.records.filter { $0.recordID != objectID }
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: try canonicalRecords(records),
        to: output
    )
    print("whomp_king_fixture_only_written=1")
}

private func duplicate(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    let selected = try selectedFrames(from: native)
    guard let first = selected.state.first else {
        throw SM64OracleTraceCodecError.truncated
    }
    var records = selected.records
    records.append(first)
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: try canonicalRecords(records),
        to: output
    )
    print("whomp_king_duplicate_written=1")
}

@main
struct SM64ModernWhompKingRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first, arguments.count == 3 else {
            throw SM64OracleTraceCodecError.truncated
        }
        let first = URL(fileURLWithPath: arguments[1]).standardizedFileURL
        let second = URL(fileURLWithPath: arguments[2]).standardizedFileURL
        switch mode {
        case "write": try writeTrace(cURL: first, swiftURL: second)
        case "audit": try audit(cURL: first, swiftURL: second)
        case "tamper": try tamper(input: first, output: second)
        case "partial": try partial(input: first, output: second)
        case "wrong-variant": try wrongVariant(input: first, output: second)
        case "wrong-subject": try wrongSubject(input: first, output: second)
        case "generic-bridge": try genericBridge(input: first, output: second)
        case "fixture-only": try fixtureOnly(input: first, output: second)
        case "duplicate": try duplicate(input: first, output: second)
        default: throw SM64OracleTraceCodecError.truncated
        }
    }
}
