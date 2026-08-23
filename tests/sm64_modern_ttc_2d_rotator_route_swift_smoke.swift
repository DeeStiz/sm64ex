import Foundation

private let routeShardID: UInt64 = 0x1af5_669b_0693_1d93
private let sourceID: UInt64 = 0x8e76_517f_4660_8f58
private let ownerID: UInt64 = 0xef39_eb82_1eba_1fe3
private let variantSourceID: UInt64 = 0xa767_fa6b_5b35_28c5
private let variantOwnerID: UInt64 = 0x6ac5_8d86_5b35_ba3d
private let semanticBehaviorID: UInt64 = 0xec14_5f4c_8aae_c281
private let routeFlags: UInt32 = 1 | 2 | 4 | 8 | 16
private let modelClockHand: UInt32 = 0x41
private let levelTTC: UInt32 = 14
private let actorBehaviorField: UInt64 = 400
private let stateID = sourceID
private let motionID = sourceID &+ 1
private let collisionID = sourceID &+ 2
private let effectID = sourceID &+ 3

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        _ = message
        throw SM64OracleTraceCodecError.invalidHeader
    }
}

private func low(_ value: UInt64) -> UInt32 { UInt32(truncatingIfNeeded: value) }
private func high(_ value: UInt64) -> UInt32 { UInt32(truncatingIfNeeded: value >> 32) }
private func pack(_ low: UInt32, _ high: UInt32) -> UInt64 {
    UInt64(low) | (UInt64(high) << 32)
}

private func signed(_ value: UInt32) -> Int32 { Int32(bitPattern: value) }
private func signed16(_ value: Int32) -> Int16 { Int16(truncatingIfNeeded: value) }

private struct RouteFrames {
    var records: [SM64OracleTraceRecord]
    var subject: UInt64
    var state: [SM64OracleTraceRecord]
    var motion: [SM64OracleTraceRecord]
    var collision: [SM64OracleTraceRecord]
    var effect: [SM64OracleTraceRecord]
    var object: [SM64OracleTraceRecord]
}

private func isRoute(_ record: SM64OracleTraceRecord) -> Bool {
    guard record.subjectID == ownerID, record.flags == routeFlags,
          record.values.count == 8 else { return false }
    switch (record.domain, record.recordKind, record.recordID) {
    case (6, 3, stateID), (6, 3, motionID), (7, 3, collisionID), (12, 4, effectID):
        return true
    default:
        return false
    }
}

private func approach(_ value: Int16, target: Int16, increment: Int16)
    -> (value: Int16, reached: Bool)
{
    let distance = Int16(truncatingIfNeeded: Int32(target) - Int32(value))
    if distance >= 0 {
        if distance > increment {
            return (Int16(truncatingIfNeeded: Int32(value) + Int32(increment)), false)
        }
    } else if distance < -increment {
        return (Int16(truncatingIfNeeded: Int32(value) - Int32(increment)), false)
    }
    return (target, true)
}

private func validateReducer(
    state: SM64OracleTraceRecord,
    motion: SM64OracleTraceRecord
) throws {
    let stateValues = state.values
    let motionValues = motion.values
    try require(low(stateValues[0]) != 0 && high(stateValues[0]) == 1, "source slot/generation")
    try require(low(stateValues[1]) == levelTTC && high(stateValues[1]) == 1, "TTC area 1")
    try require(low(stateValues[2]) == modelClockHand && high(stateValues[2]) == 0, "clock hand variant")

    let speedSetting = low(stateValues[3])
    let timerBefore = high(stateValues[3])
    let timerAfter = low(stateValues[4])
    let minBefore = high(stateValues[4])
    let minAfter = low(stateValues[5])
    let faceBefore = signed(high(stateValues[5]))
    let faceAfter = signed(low(stateValues[6]))
    let targetBefore = signed(high(stateValues[6]))
    let targetAfter = signed(low(stateValues[7]))
    let incrementBefore = signed(high(stateValues[7]))
    let incrementAfter = signed(low(motionValues[0]))
    let speed = signed(high(motionValues[0]))
    let randomBefore = low(motionValues[1])
    let randomAfter = high(motionValues[1])
    let randomU16 = low(motionValues[2])
    let randomSpeedTimer = low(motionValues[3])
    let randomReverseTimer = low(motionValues[4])
    let randomMinTime = low(motionValues[5])

    var expectedTimer = timerBefore
    var expectedTarget = targetBefore
    var expectedIncrement = incrementBefore
    var expectedRandom = randomBefore
    var expectedMin = minBefore
    let approached = approach(
        signed16(faceBefore),
        target: signed16(targetBefore),
        increment: 0xC8
    )
    let expectedFace = approached.value
    if randomBefore != 0 { expectedRandom &-= 1 }
    if minBefore != 0 && approached.reached && timerBefore > minBefore {
        expectedTarget = targetBefore &+ incrementBefore
        expectedTimer = 0
        if speedSetting == 2 {
            if randomBefore == 0 {
                if randomU16 != UInt32.max && randomU16 & 3 != 0 {
                    expectedIncrement = speed
                    expectedRandom = randomSpeedTimer
                } else {
                    expectedIncrement = -speed
                    expectedRandom = randomReverseTimer
                }
            }
            expectedMin = randomMinTime
        }
    }
    try require(Int32(expectedTimer) == Int32(timerAfter), "timer reducer")
    try require(expectedTarget == targetAfter, "target reducer")
    try require(expectedIncrement == incrementAfter, "increment reducer")
    try require(expectedRandom == randomAfter, "random timer reducer")
    try require(expectedMin == Int32(minAfter), "minimum timer reducer")
    try require(Int32(expectedFace) == faceAfter, "face yaw reducer")
    try require(motionValues[6] >> 32 == 1, "collision branch receipt")
}

private func selectedFrames(from native: (configuration: SM64OracleTraceConfiguration,
                                           records: [SM64OracleTraceRecord])) throws -> RouteFrames {
    let route = native.records.filter(isRoute)
    guard let firstState = route.first(where: { $0.recordID == stateID }) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let subject = UInt64(low(firstState.values[0]))
    let object = native.records.filter {
        $0.domain == 3 && $0.recordKind == 1 && $0.subjectID == subject
    }
    let state = route.filter { $0.recordID == stateID }
    let motion = route.filter { $0.recordID == motionID }
    let collision = route.filter { $0.recordID == collisionID }
    let effect = route.filter { $0.recordID == effectID }
    try require(!state.isEmpty && state.count == motion.count, "state/motion receipts")
    try require(state.count == collision.count && state.count == effect.count,
                "collision/effect receipts")
    try require(!object.isEmpty, "selected object state")
    for record in state { try require(low(record.values[0]) == subject, "route subject") }
    for record in object where record.recordID == actorBehaviorField {
        try require(record.values.count == 1 && record.values[0] == semanticBehaviorID,
                    "semantic behavior identity")
    }
    for index in state.indices {
        try validateReducer(state: state[index], motion: motion[index])
        try require(low(collision[index].values[0]) == subject, "collision source subject")
        try require(low(effect[index].values[4]) == subject, "effect source subject")
    }
    return RouteFrames(
        records: native.records.filter {
            isRoute($0) || ($0.domain == 3 && $0.recordKind == 1 && $0.subjectID == subject)
        },
        subject: subject,
        state: state,
        motion: motion,
        collision: collision,
        effect: effect,
        object: object
    )
}

private func canonicalRecords(_ records: [SM64OracleTraceRecord]) throws
    -> [SM64OracleTraceRecord]
{
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
    let records = try canonicalRecords(selected.records)
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: records,
        to: swiftURL
    )
    print(
        "swift_ttc_2d_rotator_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "records=\(records.count) route_records=\(selected.state.count * 4) "
            + "subject=\(selected.subject) domains=script,object,collision,effect"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    guard cURL.resolvingSymlinksInPath().standardizedFileURL.path
        != swiftURL.resolvingSymlinksInPath().standardizedFileURL.path else {
        print("ttc_2d_rotator_single_artifact_rejected=1")
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    let cSelected = try selectedFrames(from: cTrace)
    let swiftSelected = try selectedFrames(from: swiftTrace)
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if cSelected.records.count != swiftSelected.records.count { blockers.append("record_count") }
    if cSelected.records != swiftSelected.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cSelected.records, swiftSelected.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "ttc_2d_rotator_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cSelected.records.count) swift_records=\(swiftSelected.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) first_divergence=\(firstDivergence)"
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
        print("ttc_2d_rotator_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("ttc_2d_rotator_tamper_rejected=1")
    }
}

private func partial(input: URL, output: URL) throws {
    let data = try Data(contentsOf: input)
    guard data.count > 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    try data.prefix(72 + SM64OracleTraceRecord.encodedSize)
        .write(to: output, options: .atomic)
    print("ttc_2d_rotator_partial_written=1")
}

private func wrongVariant(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    var records = native.records
    guard let index = records.firstIndex(where: { $0.recordID == stateID }) else {
        throw SM64OracleTraceCodecError.truncated
    }
    var values = records[index].values
    values[2] = pack(0x43, 1)
    records[index] = try SM64OracleTraceRecord(
        simulationTick: records[index].simulationTick,
        domain: records[index].domain,
        recordKind: records[index].recordKind,
        subjectID: variantOwnerID,
        recordID: variantSourceID,
        sequence: records[index].sequence,
        flags: routeFlags & ~4,
        values: values
    )
    try SM64OracleTraceFile.write(configuration: native.configuration, records: records, to: output)
    print("ttc_2d_rotator_wrong_variant_written=1")
}

private func duplicate(input: URL, output: URL) throws {
    let native = try SM64OracleTraceFile.read(from: input)
    let selected = try selectedFrames(from: native)
    var records = selected.records
    guard let first = selected.state.first else { throw SM64OracleTraceCodecError.truncated }
    records.append(first)
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: try canonicalRecords(records),
        to: output
    )
    print("ttc_2d_rotator_duplicate_written=1")
}

@main
struct SM64ModernTTC2DRotatorRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else { throw SM64OracleTraceCodecError.truncated }
        switch mode {
        case "write":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try writeTrace(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
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
        case "partial":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try partial(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "wrong-variant":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try wrongVariant(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "duplicate":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try duplicate(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
