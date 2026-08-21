import Foundation

private let routeFNVOffset: UInt64 = 1_469_598_103_934_665_603
private let routeFNVPrime: UInt64 = 1_099_511_628_211
private let routeShardID: UInt64 = 0x88d0_4246_f94c_e9f8
private let routeInputSeed: UInt64 = 0x6b39_a105_2551_fd60
private let routeSaveSeed: UInt64 = 0x59a2_b6ab_37c5_b109
private let routeFirstRecord: UInt64 = 100
private let routeLastRecord: UInt64 = 118

private func update(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= routeFNVPrime
    }
    return hash
}

private func hashString(_ value: String) -> UInt64 {
    value.utf8.reduce(routeFNVOffset) { hash, byte in
        (hash ^ UInt64(byte)) &* routeFNVPrime
    }
}

private func coverageFingerprint() -> UInt64 {
    var hash = routeFNVOffset
    for recordID in routeFirstRecord...routeLastRecord {
        hash = update(hash, 2)
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

private func configuration() -> SM64OracleTraceConfiguration {
    SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: hashString("sm64-modern-mario-state-route-build-v1"),
        contentFingerprint: hashString(
            "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|mario_state"
        ),
        timebaseFingerprint: timebaseFingerprint(),
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "shard=0x88d04246f94ce9f8"
        ),
        initialSaveFingerprint: hashString(
            "save=empty-us-slot-0;seed=0x59a2b6ab37c5b109"
        ),
        coverageFingerprint: coverageFingerprint()
    )
}

private func stateRecords(
    _ state: SM64MarioState,
    simulationTick: UInt64
) throws -> [SM64OracleTraceRecord] {
    let fields: [(UInt64, [UInt64])] = [
        (100, [UInt64(state.input.rawValue)]),
        (101, [UInt64(state.flags)]),
        (102, [UInt64(state.particleFlags)]),
        (103, [UInt64(state.action)]),
        (104, [UInt64(state.previousAction)]),
        (105, [UInt64(state.actionState)]),
        (106, [UInt64(state.actionTimer)]),
        (107, [UInt64(state.actionArgument)]),
        (108, [UInt64(state.intendedMagnitude.bitPattern)]),
        (109, [UInt64(UInt16(bitPattern: state.intendedYaw))]),
        (110, [
            UInt64(UInt16(truncatingIfNeeded: state.faceAngle.pitch)),
            UInt64(UInt16(truncatingIfNeeded: state.faceAngle.yaw)),
            UInt64(UInt16(truncatingIfNeeded: state.faceAngle.roll)),
        ]),
        (111, [
            UInt64(state.position.x.bitPattern),
            UInt64(state.position.y.bitPattern),
            UInt64(state.position.z.bitPattern),
        ]),
        (112, [
            UInt64(state.velocity.x.bitPattern),
            UInt64(state.velocity.y.bitPattern),
            UInt64(state.velocity.z.bitPattern),
        ]),
        (113, [UInt64(state.forwardVelocity.bitPattern)]),
        (114, [UInt64(UInt16(bitPattern: state.health))]),
        (115, [UInt64(UInt16(bitPattern: state.coinCount))]),
        (116, [UInt64(UInt16(bitPattern: state.starCount))]),
        (117, [UInt64(state.framesSinceA)]),
        (118, [UInt64(state.framesSinceB)]),
    ]
    return try fields.enumerated().map { offset, field in
        try SM64OracleTraceRecord(
            simulationTick: simulationTick,
            domain: 2,
            recordKind: 1,
            recordID: field.0,
            sequence: UInt32(offset),
            values: field.1
        )
    }
}

private func sourceBackedStates() throws -> [SM64MarioState] {
    let floor = SM64Surface(
        id: 7,
        vertex1: SM64SurfaceVec3s(x: -8_000, y: 0, z: -8_000),
        vertex2: SM64SurfaceVec3s(x: -8_000, y: 0, z: 8_000),
        vertex3: SM64SurfaceVec3s(x: 8_000, y: 0, z: -8_000),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: 0
    )
    let world = try SM64SurfaceCollisionWorld(staticSurfaces: [floor])
    let floorResult = world.findFloor(x: -1_328, y: 281, z: 4_664)
    let marioID = SM64ObjectID(slot: 0, generation: 1)
    var state = SM64MarioState.initialized(
        save: SM64MarioSaveState(totalStars: 0),
        spawn: SM64MarioSpawnInput(
            position: SM64ObjectVector3(x: -1_328, y: 281, z: 4_664),
            faceAngle: SM64ObjectAngles(pitch: 0, yaw: Int32(bitPattern: 0x8000), roll: 0),
            waterLevel: -11_000
        ),
        floor: floorResult,
        marioObjectID: marioID
    )

    var normalizer = SM64ControllerInputNormalizer()
    let firstController = normalizer.update(
        SM64ControllerRawSample(buttons: 0x8000),
        advanceLegacyDomain: true
    )
    let firstInput = SM64MarioInputCore.update(
        controller: firstController,
        squishTimer: 0,
        previousFramesSinceA: .max,
        previousFramesSinceB: .max,
        faceYaw: Int16(bitPattern: 0x8000),
        cameraYaw: 0
    )
    state.input = firstInput.input
    state.intendedMagnitude = firstInput.intendedMagnitude
    state.intendedYaw = firstInput.intendedYaw
    state.framesSinceA = firstInput.framesSinceA
    state.framesSinceB = firstInput.framesSinceB
    _ = state.setAction(SM64MarioActionID.jump)
    state.velocity.y -= 4
    state.position.y += state.velocity.y
    var second = state

    let secondController = normalizer.update(
        SM64ControllerRawSample(buttons: 0x8000),
        advanceLegacyDomain: true
    )
    let secondInput = SM64MarioInputCore.update(
        controller: secondController,
        squishTimer: 0,
        previousFramesSinceA: state.framesSinceA,
        previousFramesSinceB: state.framesSinceB,
        faceYaw: state.faceAngle.yaw == 0 ? 0 : Int16(truncatingIfNeeded: state.faceAngle.yaw),
        cameraYaw: 0
    )
    second.input = secondInput.input
    second.intendedMagnitude = secondInput.intendedMagnitude
    second.intendedYaw = secondInput.intendedYaw
    second.framesSinceA = secondInput.framesSinceA
    second.framesSinceB = secondInput.framesSinceB
    second.velocity.y -= 4
    second.position.y += second.velocity.y
    return [state, second]
}

private func writeTrace(to url: URL) throws {
    let states = try sourceBackedStates()
    let records = try states.enumerated().flatMap { index, state in
        try stateRecords(state, simulationTick: UInt64(index + 2))
    }
    try SM64OracleTraceFile.write(
        configuration: configuration(), records: records, to: url
    )
    print(
        "swift_mario_state_route_recorded path=\(url.path) records=\(records.count) "
            + "ticks=2,3 coverage=0x\(String(coverageFingerprint(), radix: 16))"
    )
}

private func validOrdering(_ records: [SM64OracleTraceRecord]) -> Bool {
    guard !records.isEmpty else { return false }
    var lastTick: UInt64?
    var lastSequence: UInt32 = 0
    for record in records {
        if let lastTick {
            if record.simulationTick < lastTick { return false }
            if record.simulationTick == lastTick
                && record.sequence != lastSequence &+ 1 { return false }
            if record.simulationTick > lastTick && record.sequence != 0 { return false }
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
    if cTrace.records.count != swiftTrace.records.count { blockers.append("record_count") }
    if cTrace.records != swiftTrace.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "mario_state_pairing_audit admitted=0 c_records=\(cTrace.records.count) "
            + "swift_records=\(swiftTrace.records.count) blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence)"
    )
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard !data.isEmpty else { throw SM64OracleTraceCodecError.truncated }
    data[data.index(before: data.endIndex)] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("mario_state_pairing_tamper_rejected=0")
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("mario_state_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernMarioStateRouteSwiftSmoke {
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
