import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hFloat(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }

private func hash(_ h: UInt64, _ r: SM64MarioMetalWaterActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue); x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max); x = h32(x, r.actionArgument)
    x = h8(x, r.actionState); x = h16(x, r.animationID)
    x = h32(x, UInt32(bitPattern: r.animationAcceleration))
    x = h16(x, UInt16(bitPattern: r.faceYaw)); x = h16(x, UInt16(bitPattern: r.facePitch))
    x = h16(x, UInt16(bitPattern: r.faceRoll)); x = hFloat(x, r.forwardVelocity)
    x = hFloat(x, r.velocity.x); x = hFloat(x, r.velocity.y); x = hFloat(x, r.velocity.z)
    x = h8(x, r.shouldDropHeldObject ? 1 : 0); x = h8(x, r.shouldStopAtFloor ? 1 : 0)
    x = h8(x, r.shouldStationarySlowDown ? 1 : 0); x = h8(x, r.shouldPlayJumpSound ? 1 : 0)
    x = h8(x, r.shouldPlayLandingSound ? 1 : 0); x = h8(x, r.shouldParticleMistCircle ? 1 : 0)
    x = h8(x, r.shouldPlayStepSound ? 1 : 0); x = h8(x, r.shouldParticleDust ? 1 : 0)
    return h8(x, r.shouldParticleIdleWaterWave ? 1 : 0)
}

private func input(
    _ variant: SM64MarioMetalWaterVariant,
    flags: SM64MarioInputFlags = [], metal: Bool = true,
    drop: Bool = false, soundPlayed: Bool = false, animationEnd: Bool = false,
    soundFrame: Bool = false, actionArg: UInt32 = 0, actionState: UInt8 = 0,
    intendedMagnitude: Float = 18, intendedYaw: Int16 = 0x1800,
    faceYaw: Int16 = 0x0800, facePitch: Int16 = 0x100, faceRoll: Int16 = -0x80,
    forwardVelocity: Float = 8, velocity: SM64ObjectVector3 = .init(x: 0, y: -4, z: 0),
    positionY: Float = 0, waterLevel: Float = 200, buoyancy: Float = 1.5,
    floorNormalY: Float = 1, ground: SM64MarioMetalWaterGroundOutcome = .none,
    air: SM64MarioMetalWaterAirOutcome = .none,
    water: SM64MarioWaterStepOutcome = .none
) -> SM64MarioMetalWaterActionInput {
    SM64MarioMetalWaterActionInput(
        variant: variant, input: flags, metalCap: metal,
        dropObjectRequested: drop, actionSoundPlayed: soundPlayed,
        animationAtEnd: animationEnd, animationPastFrame10Or49: soundFrame,
        actionArgument: actionArg, actionState: actionState,
        intendedMagnitude: intendedMagnitude, intendedYaw: intendedYaw,
        faceYaw: faceYaw, facePitch: facePitch, faceRoll: faceRoll,
        forwardVelocity: forwardVelocity, velocity: velocity, positionY: positionY,
        waterLevel: waterLevel, buoyancy: buoyancy, floorNormalY: floorNormalY,
        groundStep: ground, airStep: air, waterStep: water
    )
}

@main
enum SM64ModernMarioMetalWaterSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let standing = SM64MarioMetalWaterAction.update(input(
            .standing, animationEnd: true, actionState: 2, positionY: 100,
            waterLevel: 200
        ))!
        precondition(standing.animationID == 0xC5 && standing.actionState == 0)
        precondition(standing.shouldStopAtFloor && standing.shouldParticleIdleWaterWave)
        fingerprint = hash(fingerprint, standing)

        let heldDrop = SM64MarioMetalWaterAction.update(input(
            .heldStanding, flags: [.aPressed], drop: true
        ))!
        precondition(heldDrop.action == SM64MarioActionID.metalWaterStanding)
        precondition(heldDrop.shouldDropHeldObject)
        fingerprint = hash(fingerprint, heldDrop)

        let walking = SM64MarioMetalWaterAction.update(input(
            .walking, flags: [.nonzeroAnalog], soundFrame: true,
            forwardVelocity: 12, ground: .none
        ))!
        precondition(walking.animationID == 0x48 && walking.shouldPlayStepSound)
        precondition(walking.forwardVelocity > 12)
        fingerprint = hash(fingerprint, walking)

        let heldFall = SM64MarioMetalWaterAction.update(input(
            .heldWalking, flags: [.nonzeroAnalog], forwardVelocity: 4,
            ground: .leftGround
        ))!
        precondition(heldFall.action == SM64MarioActionID.holdMetalWaterFalling)
        precondition(heldFall.actionArgument == 1 && heldFall.animationID == 0x17)
        fingerprint = hash(fingerprint, heldFall)

        let jump = SM64MarioMetalWaterAction.update(input(
            .jump, flags: [.nonzeroAnalog], forwardVelocity: 10,
            velocity: .init(x: 0, y: -2, z: 0), air: .landed
        ))!
        precondition(jump.action == SM64MarioActionID.metalWaterJumpLand)
        precondition(jump.shouldPlayJumpSound && jump.shouldParticleMistCircle)
        fingerprint = hash(fingerprint, jump)

        let waterJump = SM64MarioMetalWaterAction.update(input(
            .jump, velocity: .init(x: 0, y: 5, z: 0), positionY: 150,
            waterLevel: 200
        ))!
        precondition(waterJump.action == SM64MarioActionID.waterJump)
        precondition(waterJump.actionArgument == 1)
        fingerprint = hash(fingerprint, waterJump)

        let falling = SM64MarioMetalWaterAction.update(input(
            .falling, actionArg: 1, forwardVelocity: 3,
            velocity: .init(x: 0, y: -5, z: 0), water: .hitFloor
        ))!
        precondition(falling.action == SM64MarioActionID.metalWaterFallLand)
        precondition(falling.animationID == 0xA9 && falling.shouldStationarySlowDown)
        fingerprint = hash(fingerprint, falling)

        let land = SM64MarioMetalWaterAction.update(input(
            .fallLand, soundPlayed: true, animationEnd: true
        ))!
        precondition(land.action == SM64MarioActionID.metalWaterStanding)
        precondition(land.shouldPlayLandingSound && !land.shouldParticleMistCircle)
        fingerprint = hash(fingerprint, land)

        precondition(SM64MarioMetalWaterAction.update(input(
            .walking, intendedMagnitude: .infinity
        )) == nil)

        print(String(format: "marioMetalWaterFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario metal-water smoke passed")
    }
}
