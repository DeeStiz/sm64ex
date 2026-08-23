import Foundation

private let routeShardID: UInt64 = 0x028a_122a_6b0f_0fa2
private let sourceID: UInt64 = 0x5e0c_9eb1_fc5e_5d4e
private let ownerID: UInt64 = 0x2c46_ca0b_cefa_8587
private let semanticBehaviorID: UInt64 = 0xa672_404b_3a35_d7c8
private let routeFlags: UInt32 = 1 | 2 | 4 | 8 | 16
private let modelSpindrift: UInt32 = 0x54
private let levelSL: UInt32 = 10
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
    if record.domain == 4 && record.recordKind == 3 {
        return record.recordID == stateID || record.recordID == motionID
    }
    if record.domain == 6 && record.recordKind == 3 {
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

    let sourceOrder = low(state.values[3])
    let actionBefore = high(state.values[3])
    let actionAfter = low(state.values[4])
    let timerBefore = high(state.values[4])
    let attacked = high(state.values[6])
    let interactionBefore = low(state.values[7])
    let interactionAfter = high(state.values[7])
    try require(sourceOrder == 0, "first source order")
    try require(attacked <= 1, "attack bit")
    try require(low(collision.values[0]) == low(state.values[0]), "collision subject")
    try require(low(effect.values[0]) == low(state.values[0]), "effect subject")
    try require(low(collision.values[3]) == attacked, "collision attack")
    try require(low(effect.values[4]) == attacked, "effect attack")
    try require(high(effect.values[4]) <= 1, "reset bit")
    try require(low(effect.values[5]) == interactionBefore, "effect interaction before")
    try require(high(effect.values[5]) == interactionAfter, "effect interaction after")

    /*
     * This is the independent value mirror of the source action boundary.
     * Movement/floor resolution stays native; the receipt only proves the
     * action/recoil/recovery bits that the Swift owner consumes.
     */
    if attacked != 0 {
        try require(actionAfter == 1, "attacked action")
        try require(high(motion.values[5]) == 0xc120_0000, "recoil velocity")
    }
    if actionBefore == 1 && timerBefore > 20 {
        try require(actionAfter == 0, "recovery action")
        try require(high(effect.values[4]) == 1, "reset interaction")
    }
    if actionBefore == 0 && attacked == 0 {
        try require(actionAfter == 0 || actionAfter == 1, "idle action")
    }
    try require(high(state.values[0]) == 1, "source generation")
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
    try require(firstState.values.count == 8, "state value count")
    let subject = low(firstState.values[0])
    let object = native.records.filter {
        $0.domain == 3 && $0.recordKind == 1 && low($0.subjectID) == subject
    }
    let state = route.filter { $0.recordID == stateID }
    let motion = route.filter { $0.recordID == motionID }
    let collision = route.filter { $0.recordID == collisionID }
    let effect = route.filter { $0.recordID == effectID }
    try require(!state.isEmpty, "state receipts")
    try require(state.count == motion.count, "state/motion receipts")
    try require(state.count == collision.count, "state/collision receipts")
    try require(state.count == effect.count, "state/effect receipts")
    try require(!object.isEmpty, "selected object state")

    for record in state + motion + collision + effect {
        try require(record.flags == routeFlags, "route flags")
        try require(record.values.count == 8, "route values")
    }
    var semanticBehaviorFound = false
    for record in object where record.recordID == actorBehaviorField {
        try require(
            record.values.count == 1 && record.values[0] == semanticBehaviorID,
            "semantic behavior identity"
        )
        semanticBehaviorFound = true
    }
    try require(semanticBehaviorFound, "semantic behavior record")
    try require(
        low(firstState.values[1]) == levelSL
            && high(firstState.values[1]) == 1,
        "Snowman Land area 1"
    )
    try require(
        low(firstState.values[2]) == modelSpindrift
            && high(firstState.values[2]) == 0,
        "Spindrift model and parameter"
    )
    for index in state.indices {
        try validateReducer(
            state: state[index],
            motion: motion[index],
            collision: collision[index],
            effect: effect[index]
        )
    }
    return RouteFrames(
        records: native.records.filter {
            isRoute($0)
                || ($0.domain == 3 && $0.recordKind == 1 && low($0.subjectID) == subject)
        },
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

private func writeTrace(cURL: URL, swiftURL: URL) throws {
    let native = try SM64OracleTraceFile.read(from: cURL)
    let selected = try selectedFrames(from: native)
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: try canonicalRecords(selected.records),
        to: swiftURL
    )
    print(
        "swift_spindrift_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "records=\(selected.records.count) route_records=\(selected.state.count * 4) "
            + "subject=\(selected.subject) domains=script,object,collision,effect"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    guard cURL.resolvingSymlinksInPath().standardizedFileURL.path
        != swiftURL.resolvingSymlinksInPath().standardizedFileURL.path else {
        print("spindrift_single_artifact_rejected=1")
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
        "spindrift_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cSelected.records.count) "
            + "swift_records=\(swiftSelected.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence)"
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
        print("spindrift_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("spindrift_tamper_rejected=1")
    }
}

private func partial(input: URL, output: URL) throws {
    let data = try Data(contentsOf: input)
    guard data.count > 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    try data.prefix(72 + SM64OracleTraceRecord.encodedSize)
        .write(to: output, options: .atomic)
    print("spindrift_partial_written=1")
}

private func wrongSibling(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    var records = native.records
    guard let index = records.firstIndex(where: { $0.recordID == stateID }) else {
        throw SM64OracleTraceCodecError.truncated
    }
    var values = records[index].values
    values[3] = pack(1, high(values[3]))
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
    print("spindrift_wrong_sibling_written=1")
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
    print("spindrift_duplicate_written=1")
}

@main
struct SM64ModernSpindriftRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else {
            throw SM64OracleTraceCodecError.truncated
        }
        switch mode {
        case "write", "audit", "tamper", "partial", "wrong-sibling", "duplicate":
            guard arguments.count == 3 else {
                throw SM64OracleTraceCodecError.truncated
            }
            let first = URL(fileURLWithPath: arguments[1]).standardizedFileURL
            let second = URL(fileURLWithPath: arguments[2]).standardizedFileURL
            switch mode {
            case "write": try writeTrace(cURL: first, swiftURL: second)
            case "audit": try audit(cURL: first, swiftURL: second)
            case "tamper": try tamper(input: first, output: second)
            case "partial": try partial(input: first, output: second)
            case "wrong-sibling": try wrongSibling(input: first, output: second)
            case "duplicate": try duplicate(input: first, output: second)
            default: fatalError("unreachable")
            }
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
