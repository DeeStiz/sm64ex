import Foundation

private let routeShardID: UInt64 = 0xdc93_7431_1680_7bec
private let sourceID: UInt64 = 0x4b8e_5a73_4fe7_6b34
private let ownerID: UInt64 = 0x4b43_7886_1cfa_bced
private let semanticBehaviorID: UInt64 = 0x7896_01af_8431_58ee
private let genericTumblingBridgeIdentity: UInt64 = 0x0062_6876_5f73_706c
private let routeFlags: UInt32 = 1 | 2 | 4 | 8 | 16
private let modelSpindel: UInt32 = 0x37
private let levelSSL: UInt32 = 10
private let areaSSL: UInt32 = 2
private let sourceOrder: UInt32 = 5
private let homeYBits: UInt32 = 0x4503_d000
private let collisionIdentity: UInt64 = 0xbd5e_6c39_845f_e70b
private let rollSoundID: UInt32 = 0x8048_2081
private let shakeID: UInt32 = 1
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
    let stateValues = state.values
    let motionValues = motion.values
    let collisionValues = collision.values
    let effectValues = effect.values
    try require(stateValues.count == 8, "state values")
    try require(motionValues.count == 8, "motion values")
    try require(collisionValues.count == 8, "collision values")
    try require(effectValues.count == 8, "effect values")

    let subject = low(stateValues[0])
    let generation = high(stateValues[0])
    let timerBefore = low(stateValues[4])
    let timerAfter = high(stateValues[4])
    let phaseBefore = signed(low(stateValues[5]))
    let phaseAfter = signed(high(stateValues[5]))
    let directionBefore = signed(low(stateValues[6]))
    let directionAfter = signed(high(stateValues[6]))
    let movePitchBefore = signed(low(stateValues[7]))
    let movePitchAfter = signed(high(stateValues[7]))
    let velocityBeforeBits = high(motionValues[4])
    let velocityAfterBits = low(motionValues[5])
    let angleAfter = signed(low(motionValues[6]))
    let rollSound = low(motionValues[6])
    let cameraShake = low(motionValues[7])
    let collisionLoaded = high(motionValues[7])

    try require(subject != 0 && generation == 1, "source subject")
    try require(phaseBefore == -1 || (0...19).contains(phaseBefore), "phase before")
    try require(phaseAfter == -1 || (0...19).contains(phaseAfter), "phase after")
    try require((0...1).contains(directionBefore), "direction before")
    try require((0...1).contains(directionAfter), "direction after")
    try require((0...1).contains(rollSound), "roll sound bit")
    try require((0...1).contains(cameraShake), "camera shake bit")
    try require(collisionLoaded == 1, "collision owner")
    try require(low(collisionValues[0]) == subject, "collision subject")
    try require(high(collisionValues[0]) == 1, "collision generation")
    try require(collisionValues[1] == collisionIdentity, "named collision")
    try require(low(effectValues[0]) == subject, "effect subject")
    try require(high(effectValues[1]) == shakeID, "shake identity")
    try require(high(effectValues[2]) == rollSoundID, "sound identity")
    try require(effectValues[3] == collisionIdentity, "effect collision")
    try require(high(collisionValues[6]) == 1, "collision receipt")
    try require(low(collisionValues[6]) == sourceOrder, "source order")
    try require(low(motionValues[3]) == homeYBits, "home Y")

    /* Independent scalar checks for bhv_spindel_loop. */
    if phaseBefore == -1 && timerBefore != 32 {
        try require(phaseAfter == -1, "cooldown phase")
        try require(directionAfter == directionBefore, "cooldown direction")
        try require(velocityAfterBits == 0, "cooldown velocity")
        try require(angleAfter == 0, "cooldown pitch velocity")
        try require(timerAfter == timerBefore, "cooldown timer")
    } else {
        try require(directionAfter == directionBefore
                    || (phaseAfter == -1 && phaseBefore == 19),
                    "direction transition")
        try require(movePitchAfter == movePitchBefore
                    || angleAfter != 0,
                    "pitch transition")
        try require(velocityBeforeBits != UInt32.max, "velocity receipt")
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

    try require(low(firstState.values[1]) == levelSSL
                && high(firstState.values[1]) == areaSSL,
                "SSL area 2")
    try require(low(firstState.values[2]) == modelSpindel
                && high(firstState.values[2]) == 0,
                "Spindel model and parameter")
    try require(low(firstState.values[3]) == sourceOrder
                && high(firstState.values[3]) == 0,
                "authored source order and yaw")
    try require(low(motion[0].values[0]) == subject, "motion subject")
    try require(low(motion[3].values[0]) == homeYBits, "authored home Y")

    var semanticBehaviorFound = false
    for record in object where record.recordID == actorBehaviorField {
        try require(record.values.count == 1
                    && record.values[0] == semanticBehaviorID,
                    "semantic behavior identity")
        semanticBehaviorFound = true
    }
    try require(semanticBehaviorFound, "semantic behavior record")

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
    guard !FileManager.default.fileExists(atPath: swiftURL.path) else {
        print("spindel_persistent_rerun_rejected=1")
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
        "swift_spindel_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "records=\(selected.records.count) route_records=\(selected.state.count * 4) "
            + "subject=\(selected.subject) domains=script,object,collision,effect fixture_only=0"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    guard cURL.resolvingSymlinksInPath().standardizedFileURL.path
        != swiftURL.resolvingSymlinksInPath().standardizedFileURL.path else {
        print("spindel_single_artifact_rejected=1")
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
        "spindel_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cSelected.records.count) swift_records=\(swiftSelected.records.count) "
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
        print("spindel_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("spindel_tamper_rejected=1")
    }
}

private func partial(input: URL, output: URL) throws {
    let data = try Data(contentsOf: input)
    guard data.count > 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    try data.prefix(72 + SM64OracleTraceRecord.encodedSize)
        .write(to: output, options: .atomic)
    print("spindel_partial_written=1")
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
    print("spindel_wrong_subject_written=1")
}

private func fixtureOnly(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    let selected = try selectedFrames(from: native)
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: try canonicalRecords(selected.records.filter(isRoute)),
        to: output
    )
    print("spindel_fixture_only_written=1")
}

private func genericBridge(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    var records = native.records
    guard let index = records.firstIndex(where: {
        $0.domain == 3 && $0.recordKind == 1
            && $0.recordID == actorBehaviorField
    }) else {
        throw SM64OracleTraceCodecError.truncated
    }
    let record = records[index]
    records[index] = try SM64OracleTraceRecord(
        simulationTick: record.simulationTick,
        domain: record.domain,
        recordKind: record.recordKind,
        subjectID: record.subjectID,
        recordID: record.recordID,
        sequence: record.sequence,
        flags: record.flags,
        values: [genericTumblingBridgeIdentity]
    )
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: try canonicalRecords(records),
        to: output
    )
    print("spindel_generic_bridge_written=1")
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
    print("spindel_duplicate_written=1")
}

@main
struct SM64ModernSpindelRouteSwiftSmoke {
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
        case "wrong-subject": try wrongSubject(input: first, output: second)
        case "fixture-only": try fixtureOnly(input: first, output: second)
        case "generic-bridge": try genericBridge(input: first, output: second)
        case "duplicate": try duplicate(input: first, output: second)
        default: throw SM64OracleTraceCodecError.truncated
        }
    }
}
