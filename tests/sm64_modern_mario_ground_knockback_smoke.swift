import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioGroundKnockbackActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.animationID)
    x = h16(x, UInt16(bitPattern: r.animationFrame))
    x = h8(x, r.invincibilityTimer)
    x = h8(x, r.soundFlags.rawValue)
    return h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
}

private func input(
    _ variant: SM64MarioGroundKnockbackVariant,
    actionArgument: UInt32 = 1,
    animationFrame: Int16 = 0,
    animationAtEnd: Bool = false,
    previousAction: UInt32 = 0,
    health: UInt16 = 0x880,
    forwardVelocity: Float = 20,
    positionY: Float = 0,
    floorClass: SM64MarioFloorClass = .defaultClass,
    floorNormalY: Float = 1,
    wall: SM64MarioGroundWallProbe? = nil
) -> SM64MarioGroundKnockbackActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: floorNormalY)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: wall
    ), count: 4)
    return SM64MarioGroundKnockbackActionInput(
        variant: variant, actionArgument: actionArgument,
        animationFrame: animationFrame, animationAtEnd: animationAtEnd,
        previousAction: previousAction, health: health,
        floorClass: floorClass, terrainIsSlide: false,
        floorNormalX: 0, floorNormalY: floorNormalY, floorNormalZ: 0,
        floorAngle: 0, faceYaw: 0, forwardVelocity: forwardVelocity,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor, faceYaw: 0, nativeStepScale: 1,
            ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
        )
    )
}

@main
enum SM64ModernMarioGroundKnockbackSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let hardBack = SM64MarioGroundKnockbackAction.update(
            input(.hardBackward)
        )!
        precondition(hardBack.intent == .continueGround)
        precondition(hardBack.animationID == 0x01 && hardBack.soundFlags == [.heavyLanding, .attacked])
        fingerprint = hash(fingerprint, hardBack)

        let hardForwardDeath = SM64MarioGroundKnockbackAction.update(input(
            .hardForward, animationFrame: 0x15, health: 0xFF
        ))!
        precondition(hardForwardDeath.intent == .deathOnStomach)
        precondition(hardForwardDeath.action == SM64MarioActionID.deathOnStomach)
        fingerprint = hash(fingerprint, hardForwardDeath)

        let forwardAir = SM64MarioGroundKnockbackAction.update(input(
            .backward, positionY: 200
        ))!
        precondition(forwardAir.intent == .forwardAirKnockback)
        precondition(forwardAir.action == SM64MarioActionID.forwardAirKnockback)
        precondition(forwardAir.groundStep?.result == .leftGround)
        fingerprint = hash(fingerprint, forwardAir)

        let idle = SM64MarioGroundKnockbackAction.update(input(
            .softForward, animationAtEnd: true
        ))!
        precondition(idle.intent == .idle && idle.action == SM64MarioActionID.idle)
        precondition(idle.invincibilityTimer == 30 && idle.soundFlags == [.attacked])
        fingerprint = hash(fingerprint, idle)

        let bonk = SM64MarioGroundKnockbackAction.update(input(
            .groundBonk, animationFrame: 0x20
        ))!
        precondition(bonk.soundFlags == [.heavyLanding, .attacked, .landing])
        fingerprint = hash(fingerprint, bonk)

        let backDeath = SM64MarioGroundKnockbackAction.update(input(
            .hardBackward, animationFrame: 0x2B, health: 0xFF
        ))!
        precondition(backDeath.intent == .deathOnBack && backDeath.action == SM64MarioActionID.deathOnBack)
        fingerprint = hash(fingerprint, backDeath)

        let mama = SM64MarioGroundKnockbackAction.update(input(
            .hardBackward, animationFrame: 0x36,
            previousAction: SM64MarioActionID.specialDeathExit
        ))!
        precondition(mama.soundFlags.contains(.mamaMia))
        fingerprint = hash(fingerprint, mama)

        let backwardAir = SM64MarioGroundKnockbackAction.update(input(
            .softBackward, forwardVelocity: -20, positionY: 200
        ))!
        precondition(backwardAir.intent == .backwardAirKnockback)
        fingerprint = hash(fingerprint, backwardAir)

        precondition(SM64MarioGroundKnockbackAction.update(input(.forward, forwardVelocity: .infinity)) == nil)

        print(String(format: "marioGroundKnockbackFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario ground-knockback smoke passed")
    }
}
