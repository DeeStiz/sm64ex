import Foundation

private let shardID: UInt64 = 0xb280_cfa2_6a34_3b48
private let sourceID: UInt64 = 0x8a2c_0d68_cbf1_e447
private let ownerID: UInt64 = 0x2fbd_5843_1e8c_7a10
private let behaviorID: UInt64 = 0x0062_6876_5f73_7377
private let routeFlags: UInt32 = 1 | 2 | 4
private let scriptDomain: UInt32 = 6
private let objectDomain: UInt32 = 3
private let collisionDomain: UInt32 = 7
private let effectDomain: UInt32 = 12
private let eventKind: UInt32 = 3
private let stateKind: UInt32 = 1
private let effectKind: UInt32 = 4
private let scriptEvent: UInt64 = 4
private let objectEvent: UInt64 = 400
private let collisionEvent: UInt64 = 4
private let effectEvent: UInt64 = 1
private let bobLevel: UInt32 = 9
private let bobModel: UInt32 = 0x37
private let bobParameter: UInt32 = 3
private let bobCollisionModel: UInt32 = 3

private func fail(_ message: String) throws -> Never {
    _ = message
    throw SM64OracleTraceCodecError.invalidHeader
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { try fail(message) }
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

private func bits(_ value: Float) -> UInt32 {
    value.bitPattern
}

private func float(_ value: UInt32) -> Float {
    Float(bitPattern: value)
}

private struct RouteState {
    let sourceSubject: UInt32
    let sourceOrder: UInt32
    let level: UInt32
    let area: UInt32
    let model: UInt32
    let parameter: UInt32
    let collisionModel: UInt32
    let collisionDistanceBits: UInt32
    let positionXBits: UInt32
    let positionYBits: UInt32
    let positionZBits: UInt32
    let faceYaw: Int32
    let facePitchBefore: Int32
    let facePitchAfter: Int32
    let pitchVelocityBeforeBits: UInt32
    let pitchVelocityAfterBits: UInt32
    let distanceToMarioBits: UInt32
    let angleToMario: Int32
    let moveAngleYaw: Int32
    let marioOnPlatform: Bool
    let soundPlayed: Bool
    let flags: UInt32
    let tick: UInt64

    var pitchVelocityBefore: Float { float(pitchVelocityBeforeBits) }
    var pitchVelocityAfter: Float { float(pitchVelocityAfterBits) }

    func scriptValues() -> [UInt64] {
        [
            pack(sourceSubject, sourceOrder),
            pack(level, area),
            pack(model, parameter),
            pack(collisionModel, collisionDistanceBits),
            pack(UInt32(bitPattern: facePitchBefore), UInt32(bitPattern: facePitchAfter)),
            pack(pitchVelocityBeforeBits, pitchVelocityAfterBits),
            pack(distanceToMarioBits, UInt32(bitPattern: angleToMario)),
            pack(UInt32(bitPattern: moveAngleYaw),
                 (marioOnPlatform ? 1 : 0) | (soundPlayed ? 2 : 0)),
        ]
    }

    func objectValues() -> [UInt64] {
        [
            pack(sourceSubject, sourceOrder),
            behaviorID,
            pack(positionXBits, positionYBits),
            pack(positionZBits, UInt32(bitPattern: faceYaw)),
            pack(model, parameter),
            pack(level, area),
            pack(collisionModel, collisionDistanceBits),
            UInt64(flags),
        ]
    }

    func collisionValues() -> [UInt64] {
        [
            pack(sourceSubject, collisionModel),
            pack(collisionDistanceBits, distanceToMarioBits),
            pack(marioOnPlatform ? 1 : 0, soundPlayed ? 1 : 0),
            pack(positionXBits, positionYBits),
            pack(positionZBits, UInt32(bitPattern: faceYaw)),
            pack(UInt32(bitPattern: facePitchAfter), pitchVelocityAfterBits),
            pack(model, parameter),
            UInt64(flags),
        ]
    }

    func effectValues() -> [UInt64] {
        [
            pack(sourceSubject, soundPlayed ? 1 : 0),
            pack(pitchVelocityBeforeBits, pitchVelocityAfterBits),
            pack(UInt32(bitPattern: facePitchBefore), UInt32(bitPattern: facePitchAfter)),
            pack(model, parameter),
            pack(level, area),
            pack(distanceToMarioBits, UInt32(bitPattern: angleToMario)),
            pack(UInt32(bitPattern: moveAngleYaw), marioOnPlatform ? 1 : 0),
            UInt64(flags),
        ]
    }
}

private struct RouteTick {
    let script: SM64OracleTraceRecord
    let object: SM64OracleTraceRecord
    let collision: SM64OracleTraceRecord
    let effect: SM64OracleTraceRecord
    let state: RouteState

    var records: [SM64OracleTraceRecord] { [script, object, collision, effect] }
}

private func checkRecord(
    _ record: SM64OracleTraceRecord,
    domain: UInt32,
    kind: UInt32,
    event: UInt64
) throws {
    try require(
        record.domain == domain
            && record.recordKind == kind
            && record.subjectID == ownerID
            && record.recordID == event
            && record.flags == routeFlags
            && record.values.count == 8,
        "route record identity")
}

private func decodeTick(_ records: ArraySlice<SM64OracleTraceRecord>) throws -> RouteTick {
    guard records.count == 4 else { try fail("route tick record count") }
    let values = Array(records)
    let script = values[0]
    let object = values[1]
    let collision = values[2]
    let effect = values[3]
    try checkRecord(script, domain: scriptDomain, kind: eventKind, event: scriptEvent)
    try checkRecord(object, domain: objectDomain, kind: stateKind, event: objectEvent)
    try checkRecord(collision, domain: collisionDomain, kind: eventKind, event: collisionEvent)
    try checkRecord(effect, domain: effectDomain, kind: effectKind, event: effectEvent)
    try require(
        Set(values.map(\.simulationTick)).count == 1,
        "route tick alignment")

    let scriptValues = script.values
    let objectValues = object.values
    let collisionValues = collision.values
    let effectValues = effect.values
    let state = RouteState(
        sourceSubject: low(scriptValues[0]),
        sourceOrder: high(scriptValues[0]),
        level: low(scriptValues[1]),
        area: high(scriptValues[1]),
        model: low(scriptValues[2]),
        parameter: high(scriptValues[2]),
        collisionModel: low(scriptValues[3]),
        collisionDistanceBits: high(scriptValues[3]),
        positionXBits: low(objectValues[2]),
        positionYBits: high(objectValues[2]),
        positionZBits: low(objectValues[3]),
        faceYaw: Int32(bitPattern: high(objectValues[3])),
        facePitchBefore: Int32(bitPattern: low(scriptValues[4])),
        facePitchAfter: Int32(bitPattern: high(scriptValues[4])),
        pitchVelocityBeforeBits: low(scriptValues[5]),
        pitchVelocityAfterBits: high(scriptValues[5]),
        distanceToMarioBits: low(scriptValues[6]),
        angleToMario: Int32(bitPattern: high(scriptValues[6])),
        moveAngleYaw: Int32(bitPattern: low(scriptValues[7])),
        marioOnPlatform: (high(scriptValues[7]) & 1) != 0,
        soundPlayed: (high(scriptValues[7]) & 2) != 0,
        flags: routeFlags,
        tick: script.simulationTick
    )
    try require(low(objectValues[0]) == state.sourceSubject, "object source subject")
    try require(high(objectValues[0]) == state.sourceOrder, "object source order")
    try require(objectValues[1] == behaviorID, "semantic behavior identity")
    try require(low(objectValues[4]) == state.model, "object model")
    try require(high(objectValues[4]) == state.parameter, "object parameter")
    try require(low(objectValues[5]) == state.level, "object level")
    try require(high(objectValues[5]) == state.area, "object area")
    try require(low(objectValues[6]) == state.collisionModel, "object collision model")
    try require(high(objectValues[6]) == state.collisionDistanceBits, "object collision distance")
    try require(objectValues[7] == UInt64(routeFlags), "object flags")
    try require(low(collisionValues[0]) == state.sourceSubject, "collision subject")
    try require(high(collisionValues[0]) == state.collisionModel, "collision model")
    try require(low(collisionValues[1]) == state.collisionDistanceBits, "collision distance")
    try require(high(collisionValues[1]) == state.distanceToMarioBits, "collision mario distance")
    try require(low(collisionValues[2]) == (state.marioOnPlatform ? 1 : 0), "collision relation")
    try require(high(collisionValues[2]) == (state.soundPlayed ? 1 : 0), "collision sound")
    try require(low(effectValues[0]) == state.sourceSubject, "effect subject")
    try require(high(effectValues[0]) == (state.soundPlayed ? 1 : 0), "effect sound")
    try require(low(effectValues[1]) == state.pitchVelocityBeforeBits, "effect velocity before")
    try require(high(effectValues[1]) == state.pitchVelocityAfterBits, "effect velocity after")
    try require(low(effectValues[3]) == state.model, "effect model")
    try require(high(effectValues[3]) == state.parameter, "effect parameter")
    try require(low(effectValues[4]) == state.level, "effect level")
    try require(high(effectValues[4]) == state.area, "effect area")
    try require(state.sourceSubject != 0, "source subject")
    try require(state.sourceOrder == 0, "source order")
    try require(state.level == bobLevel && state.area == 1, "Bob area")
    try require(state.model == bobModel, "Bob model")
    try require(state.parameter == bobParameter, "Bob parameter")
    try require(state.collisionModel == bobCollisionModel, "Bob collision model")
    try require(state.collisionDistanceBits == bits(1000), "collision distance default")
    try require(state.positionXBits == bits(-2303), "authored X")
    try require(state.positionYBits == bits(717), "authored Y")
    try require(state.positionZBits == bits(1024), "authored Z")
    try require(state.faceYaw == 0x2000, "authored face yaw")
    try require(state.flags == routeFlags, "route flags")

    /* The real Castle painting entry places Mario away from the platform. The
     * source reducer therefore takes its return-to-zero branch. Keep this
     * reducer independent of the shared SeesawPlatformBehavior type. */
    try require(!state.marioOnPlatform, "unexpected platform relation")
    var expectedPitch = state.facePitchBefore
    var expectedVelocity = state.pitchVelocityBefore
    let startPitch = expectedPitch
    expectedPitch += Int32(expectedVelocity)
    let crossedTarget = (expectedPitch * startPitch < 0)
        && expectedVelocity > -6
        && expectedVelocity < 6
    if expectedPitch == 0 || crossedTarget {
        expectedPitch = 0
        expectedVelocity = 0
    } else {
        var acceleration: Float = expectedPitch >= 0 ? -3 : 3
        if expectedVelocity * acceleration < 0 { acceleration *= 3 }
        expectedVelocity += acceleration
    }
    try require(state.facePitchAfter == expectedPitch, "source pitch reducer")
    try require(state.pitchVelocityAfter == expectedVelocity, "source velocity reducer")
    try require(
        state.soundPlayed == (abs(state.pitchVelocityBefore) > 10),
        "source sound intent")

    return RouteTick(script: script, object: object, collision: collision, effect: effect, state: state)
}

private func selectedRecords(from records: [SM64OracleTraceRecord]) throws -> [SM64OracleTraceRecord] {
    let selected = records.filter {
        $0.subjectID == ownerID && $0.flags == routeFlags
            && (($0.domain == scriptDomain && $0.recordID == scriptEvent)
                || ($0.domain == objectDomain && $0.recordID == objectEvent)
                || ($0.domain == collisionDomain && $0.recordID == collisionEvent)
                || ($0.domain == effectDomain && $0.recordID == effectEvent))
    }
    try require(!selected.isEmpty && selected.count % 4 == 0, "complete route groups")
    return selected
}

private func decodeTicks(_ records: [SM64OracleTraceRecord]) throws -> [RouteTick] {
    var ticks: [RouteTick] = []
    ticks.reserveCapacity(records.count / 4)
    var offset = 0
    while offset < records.count {
        let tick = try decodeTick(records[offset..<(offset + 4)])
        ticks.append(tick)
        offset += 4
    }
    var lastByDomain: [UInt32: (UInt64, UInt32)] = [:]
    for record in records {
        if let last = lastByDomain[record.domain] {
            try require(
                record.simulationTick > last.0
                    || (record.simulationTick == last.0 && record.sequence > last.1),
                "schema sequence ordering")
        }
        lastByDomain[record.domain] = (record.simulationTick, record.sequence)
    }
    return ticks
}

private func normalizedRecords(from ticks: [RouteTick]) throws -> [SM64OracleTraceRecord] {
    var output: [SM64OracleTraceRecord] = []
    output.reserveCapacity(ticks.count * 4)
    for tick in ticks {
        let state = tick.state
        let expected = [
            try SM64OracleTraceRecord(
                simulationTick: tick.script.simulationTick,
                domain: scriptDomain,
                recordKind: eventKind,
                subjectID: ownerID,
                recordID: scriptEvent,
                sequence: tick.script.sequence,
                flags: routeFlags,
                values: state.scriptValues()),
            try SM64OracleTraceRecord(
                simulationTick: tick.object.simulationTick,
                domain: objectDomain,
                recordKind: stateKind,
                subjectID: ownerID,
                recordID: objectEvent,
                sequence: tick.object.sequence,
                flags: routeFlags,
                values: state.objectValues()),
            try SM64OracleTraceRecord(
                simulationTick: tick.collision.simulationTick,
                domain: collisionDomain,
                recordKind: eventKind,
                subjectID: ownerID,
                recordID: collisionEvent,
                sequence: tick.collision.sequence,
                flags: routeFlags,
                values: state.collisionValues()),
            try SM64OracleTraceRecord(
                simulationTick: tick.effect.simulationTick,
                domain: effectDomain,
                recordKind: effectKind,
                subjectID: ownerID,
                recordID: effectEvent,
                sequence: tick.effect.sequence,
                flags: routeFlags,
                values: state.effectValues()),
        ]
        for pair in zip(tick.records, expected) {
            try require(pair.0 == pair.1, "C/Swift normalized route record")
        }
        output.append(contentsOf: expected)
    }
    return output
}

private func writeTrace(cURL: URL, swiftURL: URL) throws {
    let native = try SM64OracleTraceFile.read(from: cURL)
    let selected = try selectedRecords(from: native.records)
    let ticks = try decodeTicks(selected)
    let records = try normalizedRecords(from: ticks)
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: records,
        to: swiftURL)
    print(
        "seesaw_platform_route_swift_capture shard=0x\(String(shardID, radix: 16)) "
            + "records=\(records.count) ticks=\(records.first?.simulationTick ?? 0),"
            + "\(records.last?.simulationTick ?? 0) source=0x\(String(sourceID, radix: 16)) "
            + "owner=0x\(String(ownerID, radix: 16))")
}

private func audit(cURL: URL, swiftURL: URL) throws {
    guard cURL.resolvingSymlinksInPath().standardizedFileURL.path
        != swiftURL.resolvingSymlinksInPath().standardizedFileURL.path else {
        print("seesaw_platform_route_single_artifact_rejected=1")
        try fail("single artifact")
    }
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    let cSelected = try selectedRecords(from: cTrace.records)
    let swiftSelected = try selectedRecords(from: swiftTrace.records)
    _ = try decodeTicks(cSelected)
    _ = try decodeTicks(swiftSelected)
    let blockers: [String] = [
        cTrace.configuration == swiftTrace.configuration ? nil : "header",
        cSelected.count == swiftSelected.count ? nil : "record_count",
        cTrace.records == swiftTrace.records ? nil : "record_bytes",
    ].compactMap { $0 }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "seesaw_platform_route_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cTrace.records.count) swift_records=\(swiftTrace.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) first_divergence=\(firstDivergence)")
    try require(blockers.isEmpty, "exact C/Swift route pair")
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard data.count > 72 + SM64OracleTraceRecord.encodedSize else {
        try fail("tamper input")
    }
    data[data.index(before: data.endIndex)] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("seesaw_platform_route_tamper_rejected=0")
        try fail("tamper accepted")
    } catch {
        print("seesaw_platform_route_tamper_rejected=1")
    }
}

private func partial(input: URL, output: URL) throws {
    let data = try Data(contentsOf: input)
    guard data.count > 72 + SM64OracleTraceRecord.encodedSize else {
        try fail("partial input")
    }
    try data.prefix(data.count - SM64OracleTraceRecord.encodedSize)
        .write(to: output, options: .atomic)
    print("seesaw_platform_route_partial_written=1")
}

private func wrongVariant(input: URL, output: URL) throws {
    let trace = try SM64OracleTraceFile.read(from: input)
    let selected = try selectedRecords(from: trace.records)
    guard let script = selected.first(where: { $0.domain == scriptDomain }) else {
        try fail("wrong variant input")
    }
    var values = script.values
    values[2] = pack(bobModel - 1, bobParameter)
    let replacement = try SM64OracleTraceRecord(
        simulationTick: script.simulationTick,
        domain: script.domain,
        recordKind: script.recordKind,
        subjectID: script.subjectID,
        recordID: script.recordID,
        sequence: script.sequence,
        flags: script.flags,
        values: values)
    var records = trace.records
    guard let index = records.firstIndex(of: script) else { try fail("wrong variant index") }
    records[index] = replacement
    try SM64OracleTraceFile.write(configuration: trace.configuration, records: records, to: output)
    print("seesaw_platform_route_wrong_variant_written=1")
}

@main
struct SM64ModernSeesawPlatformRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else { try fail("mode") }
        switch mode {
        case "write":
            guard arguments.count == 3 else { try fail("write arguments") }
            try writeTrace(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL)
        case "audit":
            guard arguments.count == 3 else { try fail("audit arguments") }
            try audit(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL)
        case "tamper":
            guard arguments.count == 3 else { try fail("tamper arguments") }
            try tamper(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL)
        case "partial":
            guard arguments.count == 3 else { try fail("partial arguments") }
            try partial(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL)
        case "wrong-variant":
            guard arguments.count == 3 else { try fail("wrong variant arguments") }
            try wrongVariant(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL)
        default:
            try fail("unknown mode")
        }
    }
}
