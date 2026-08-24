import Foundation

private let routeFNVOffset: UInt64 = 1_469_598_103_934_665_603
private let routeFNVPrime: UInt64 = 1_099_511_628_211
private let routeShardID: UInt64 = 0x4eb1_9b71_d76b_e0d4
private let routeInputSeed: UInt64 = 0xb572_8a6c_95a2_0bac
private let routeSaveSeed: UInt64 = 0x06d7_c939_379a_2dd5
private let routeFirstRecord: UInt64 = 300
private let routeLastRecord: UInt64 = 306
private let routeJumpInitialVelocity: Float = 42
private let routeGravity: Float = 4

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

private func routeShardHex() -> String {
    String(routeShardID, radix: 16)
}

private func coverageFingerprint() -> UInt64 {
    var hash = routeFNVOffset
    for recordID in routeFirstRecord...routeLastRecord {
        hash = update(hash, 5)
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
        buildFingerprint: hashString("sm64-modern-camera-state-route-build-v1"),
        contentFingerprint: hashString(
            "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|camera_state"
        ),
        timebaseFingerprint: timebaseFingerprint(),
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "shard=0x\(routeShardHex())"
        ),
        initialSaveFingerprint: hashString(
            "save=empty-us-slot-0;seed=0x06d7c939379a2dd5"
        ),
        coverageFingerprint: coverageFingerprint()
    )
}

private func sourceBackedFrames() throws -> [(SM64CameraModeState, SM64CameraFocusPlacement)] {
    // Castle Grounds' authored first spawn. The C route receives the A button
    // on its first owner tick, entering ACT_JUMP before the camera update.
    // Reproduce only that source-defined vertical state transition here; the
    // camera artifact remains independent of the C trace and does not copy
    // fixture values.
    let spawn = SM64ObjectVector3(x: -1_328, y: 260, z: 4_664)
    let floorHeight = spawn.y
    // `init_camera` starts Castle Grounds behind Mario with this
    // source-authored offset and the route's face yaw. The C camera then
    // quantizes its current position to s16 pitch/yaw and reconstructs it
    // before applying the mode's floor-height rules on every tick.
    guard var cameraPosition = SM64CameraPrimitives.offsetRotated(
        from: spawn,
        offset: SM64ObjectVector3(x: 0, y: 125, z: 400),
        pitch: 0,
        yaw: -0x8000
    ) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    cameraPosition.y = floorHeight + 125
    var timebase = try SM64LegacyTimebase(
        simulationRateNumerator: 60,
        simulationRateDenominator: 1,
        legacyRateNumerator: 30,
        legacyRateDenominator: 1,
        maxCatchUpSteps: 2
    )
    timebase.setLifecycleActive(true)
    let nativeStepScale = timebase.nativeStepScale
    var mario = spawn
    var velocityY = routeJumpInitialVelocity
    var smoothMovement = false
    var state = SM64CameraModeState(
        mode: SM64CameraMode.freeRoam.rawValue,
        defaultMode: SM64CameraMode.freeRoam.rawValue
    )
    var frames: [(SM64CameraModeState, SM64CameraFocusPlacement)] = []
    for _ in 0..<2 {
        mario.y += velocityY * nativeStepScale
        velocityY -= routeGravity
        let heightInput = SM64CameraHeightInput(
            marioY: mario.y,
            floorHeight: floorHeight,
            waterHeight: nil,
            isMetalWater: false,
            isOnPole: false,
            poleObjectY: nil,
            poleObjectHitboxHeight: nil
        )
        guard let offsets = SM64CameraGeometry.calculateHeightOffsets(heightInput) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        guard let angles = SM64CameraPrimitives.calculateAngles(
            from: mario, to: cameraPosition
        ) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        // With no wall obstruction in the native Castle Grounds snapshot,
        // `update_default_camera` asymptotically approaches zoomDist - 100
        // before reconstructing the camera point. This is the source of the
        // otherwise surprising 14-unit Z change from the initial offset.
        let approachedDistance = SM64CameraPrimitives.approachF32Asymptotic(
            current: angles.distance,
            target: 700,
            multiplier: 0.05
        ).value
        guard let reconstructed = SM64CameraPrimitives.setDistanceAndAngle(
            from: mario,
            distance: approachedDistance,
            pitch: angles.pitch,
            yaw: angles.yaw
        ) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        // Castle Grounds has a flat floor at 260 and no ceiling in this
        // snapshot. Free-roam adds its source-defined 100-unit camera lift;
        // the first frame has smooth movement disabled by init_camera, and
        // update_lakitu enables it for the following frame.
        let cameraFloorHeight = floorHeight + 125
        let cameraGoalHeight = cameraFloorHeight + 100
        let cameraHeight = smoothMovement
            ? SM64CameraPrimitives.cameraApproachF32Symmetric(
                current: cameraPosition.y,
                target: cameraGoalHeight,
                increment: 20
            ).value
            : cameraGoalHeight
        cameraPosition = SM64ObjectVector3(
            x: reconstructed.x,
            y: cameraHeight,
            z: reconstructed.z
        )
        let focus = SM64ObjectVector3(
            x: mario.x,
            y: mario.y + 125 + offsets.focus,
            z: mario.z
        )
        let placement = SM64CameraFocusPlacement(
            focus: focus, position: cameraPosition
        )
        frames.append((state, placement))
        state.transitionFrame &+= 1
        smoothMovement = true
    }
    return frames
}

private func cameraRecords(
    _ frame: (SM64CameraModeState, SM64CameraFocusPlacement),
    simulationTick: UInt64
) throws -> [SM64OracleTraceRecord] {
    let state = frame.0
    let placement = frame.1
    let fields: [(UInt64, [UInt64])] = [
        (300, [UInt64(UInt16(bitPattern: state.mode))]),
        (301, [UInt64(UInt16(bitPattern: state.defaultMode))]),
        (302, [0]),
        (303, [0]),
        (304, [0]),
        (305, [
            UInt64(placement.focus.x.bitPattern),
            UInt64(placement.focus.y.bitPattern),
            UInt64(placement.focus.z.bitPattern),
        ]),
        (306, [
            UInt64(placement.position.x.bitPattern),
            UInt64(placement.position.y.bitPattern),
            UInt64(placement.position.z.bitPattern),
        ]),
    ]
    return try fields.enumerated().map { offset, field in
        try SM64OracleTraceRecord(
            simulationTick: simulationTick,
            domain: 5,
            recordKind: 1,
            recordID: field.0,
            sequence: UInt32(offset),
            values: field.1
        )
    }
}

private func writeTrace(to url: URL) throws {
    let frames = try sourceBackedFrames()
    let records = try frames.enumerated().flatMap { index, frame in
        try cameraRecords(frame, simulationTick: UInt64(index + 2))
    }
    try SM64OracleTraceFile.write(
        configuration: configuration(), records: records, to: url
    )
    let first = frames[0].1
    print(
        "swift_camera_state_route_recorded shard=0x\(routeShardHex()) path=\(url.path) records=\(records.count) "
            + "ticks=2,3 coverage=0x\(String(coverageFingerprint(), radix: 16)) "
            + "source_focus=(\(first.focus.x),\(first.focus.y),\(first.focus.z))"
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

private func describeFloatVector(_ values: [UInt64]) -> String {
    values.map { value in
        let bits = UInt32(truncatingIfNeeded: value)
        return "0x\(String(bits, radix: 16, uppercase: false))=\(Float(bitPattern: bits))"
    }.joined(separator: ",")
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
    let focusRecordIndex = 5
    let positionRecordIndex = 6
    let focusMatched = cTrace.records.count > focusRecordIndex
        && swiftTrace.records.count > focusRecordIndex
        && cTrace.records[focusRecordIndex] == swiftTrace.records[focusRecordIndex]
    if cTrace.records.count > positionRecordIndex,
       swiftTrace.records.count > positionRecordIndex {
        print(
            "camera_position_pairing matched=\(cTrace.records[positionRecordIndex] == swiftTrace.records[positionRecordIndex] ? 1 : 0) "
                + "c=(\(describeFloatVector(Array(cTrace.records[positionRecordIndex].values.prefix(3))))) "
                + "swift=(\(describeFloatVector(Array(swiftTrace.records[positionRecordIndex].values.prefix(3)))))"
        )
    }
    if cTrace.records.count > focusRecordIndex,
       swiftTrace.records.count > focusRecordIndex {
        print(
            "camera_focus_pairing matched=\(focusMatched ? 1 : 0) "
                + "c=(\(describeFloatVector(Array(cTrace.records[focusRecordIndex].values.prefix(3))))) "
                + "swift=(\(describeFloatVector(Array(swiftTrace.records[focusRecordIndex].values.prefix(3)))))"
        )
    }
    print(
        "camera_state_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
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
        print("camera_state_pairing_tamper_rejected=0")
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("camera_state_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernCameraStateRouteSwiftSmoke {
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
