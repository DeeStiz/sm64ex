import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }

private func hash(_ h: UInt64, _ r: SM64MarioTurningActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue); x = h32(x, r.action ?? UInt32.max); x = h32(x, r.actionArgument)
    x = h16(x, UInt16(bitPattern: r.faceYaw)); x = hf(x, r.forwardVelocity)
    x = hf(x, r.velocity.x); x = hf(x, r.velocity.y); x = hf(x, r.velocity.z)
    x = h8(x, r.slope == nil ? 0 : 1)
    if let slope = r.slope { x = hf(x, slope.forwardVelocity); x = hf(x, slope.velocity.x); x = hf(x, slope.velocity.z) }
    x = h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
    x = h16(x, r.animationID ?? UInt16.max); x = h8(x, r.particleDust ? 1 : 0)
    return h8(x, r.terrainSound ? 1 : 0)
}

private func input(
    flags: SM64MarioInputFlags = [],
    floorClass: SM64MarioFloorClass = .defaultClass,
    faceYaw: Int16 = Int16(bitPattern: 0x8000),
    intendedYaw: Int16 = 0,
    forwardVelocity: Float = 20,
    animationAtEnd: Bool = false,
    positionY: Float = 0
) -> SM64MarioTurningActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: nil
    ), count: 4)
    return SM64MarioTurningActionInput(
        input: flags, terrainIsSlide: false, facingDownhill: false,
        floorClass: floorClass, floorNormalX: 0, floorNormalY: 1, floorNormalZ: 0,
        floorAngle: 0, faceYaw: faceYaw, intendedYaw: intendedYaw,
        forwardVelocity: forwardVelocity, animationAtEnd: animationAtEnd,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor, faceYaw: Int32(faceYaw), nativeStepScale: 1,
            ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
        )
    )
}

@main
enum SM64ModernMarioTurningSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let slide = SM64MarioTurningAction.update(input(flags: [.aboveSlide]))!
        precondition(slide.intent == .beginSliding && slide.action == SM64MarioActionID.beginSliding)
        fingerprint = hash(fingerprint, slide)

        let sideFlip = SM64MarioTurningAction.update(input(flags: [.aPressed]))!
        precondition(sideFlip.intent == .sideFlip && sideFlip.action == SM64MarioActionID.sideFlip)
        fingerprint = hash(fingerprint, sideFlip)

        let braking = SM64MarioTurningAction.update(input(flags: [.unknown5]))!
        precondition(braking.intent == .braking && braking.action == SM64MarioActionID.braking)
        fingerprint = hash(fingerprint, braking)

        let walking = SM64MarioTurningAction.update(input(faceYaw: 0, intendedYaw: 0))!
        precondition(walking.intent == .walking && walking.action == SM64MarioActionID.walking)
        fingerprint = hash(fingerprint, walking)

        let part2 = SM64MarioTurningAction.update(input(forwardVelocity: 20))!
        precondition(part2.intent == .continueGround && part2.forwardVelocity == 16)
        precondition(part2.animationID == 0xBD && part2.particleDust)
        fingerprint = hash(fingerprint, part2)

        let part1 = SM64MarioTurningAction.update(input(forwardVelocity: 24))!
        precondition(part1.forwardVelocity == 20 && part1.animationID == 0xBC)
        fingerprint = hash(fingerprint, part1)

        let finish = SM64MarioTurningAction.update(input(forwardVelocity: 4))!
        precondition(finish.intent == .finishTurningAround && finish.action == SM64MarioActionID.finishTurningAround)
        precondition(finish.forwardVelocity == 8 && finish.faceYaw == 0)
        fingerprint = hash(fingerprint, finish)

        let walkAfterTurn = SM64MarioTurningAction.update(input(
            forwardVelocity: 16, animationAtEnd: true
        ))!
        precondition(walkAfterTurn.intent == .walking && walkAfterTurn.action == SM64MarioActionID.walking)
        precondition(walkAfterTurn.forwardVelocity == -12 && walkAfterTurn.faceYaw == 0)
        fingerprint = hash(fingerprint, walkAfterTurn)

        let airborne = SM64MarioTurningAction.update(input(
            forwardVelocity: 20, positionY: 200
        ))!
        precondition(airborne.intent == .freefall && airborne.action == SM64MarioActionID.freefall)
        fingerprint = hash(fingerprint, airborne)

        print(String(format: "marioTurningFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario turning smoke passed")
    }
}
