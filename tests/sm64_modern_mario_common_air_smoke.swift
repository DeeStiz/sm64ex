import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioCommonAirActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h8(x, r.airStep.rawValue)
    x = h16(x, r.animationID)
    x = h16(x, UInt16(bitPattern: r.faceYaw))
    x = h8(x, r.shouldQueueRumble ? 1 : 0)
    x = h8(x, r.particleVerticalStar ? 1 : 0)
    x = h8(x, r.shouldReflectBonk ? 1 : 0)
    x = h8(x, r.shouldDropHeldObject ? 1 : 0)
    return h8(x, r.shouldPlayLavaBoost ? 1 : 0)
}

private func input(
    landAction: UInt32 = SM64MarioActionID.jumpLand,
    animationID: UInt16 = 0x4D,
    flags: SM64MarioInputFlags = [],
    intendedMagnitude: Float = 0,
    intendedYaw: Int16 = 0,
    faceYaw: Int16 = 0,
    forwardVelocity: Float = 20,
    velocityY: Float = -10,
    wallAngle: Int16? = nil,
    airStep: SM64MarioCommonAirStepOutcome = .none,
    fallDamageOrStuck: Bool = false,
    horizontalWindActive: Bool = false
) -> SM64MarioCommonAirActionInput {
    SM64MarioCommonAirActionInput(
        landAction: landAction, animationID: animationID, input: flags,
        intendedMagnitude: intendedMagnitude, intendedYaw: intendedYaw,
        faceYaw: faceYaw, forwardVelocity: forwardVelocity,
        velocityY: velocityY, wallAngle: wallAngle, airStep: airStep,
        fallDamageOrStuck: fallDamageOrStuck,
        horizontalWindActive: horizontalWindActive
    )
}

@main
enum SM64ModernMarioCommonAirSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let continuing = SM64MarioCommonAirAction.update(input())!
        precondition(continuing.intent == .continueAir && continuing.animationID == 0x4D)
        precondition(abs(continuing.forwardVelocity - 19.65) < 0.0001)
        fingerprint = hash(fingerprint, continuing)

        let landed = SM64MarioCommonAirAction.update(input(airStep: .landed))!
        precondition(landed.intent == .land && landed.action == SM64MarioActionID.jumpLand)
        fingerprint = hash(fingerprint, landed)

        let hard = SM64MarioCommonAirAction.update(input(
            airStep: .landed, fallDamageOrStuck: true
        ))!
        precondition(hard.intent == .hardFall)
        precondition(hard.action == SM64MarioActionID.hardBackwardGroundKnockback)
        fingerprint = hash(fingerprint, hard)

        let lowWall = SM64MarioCommonAirAction.update(input(
            forwardVelocity: 10, airStep: .hitWall
        ))!
        precondition(lowWall.intent == .lowSpeedWallStop && lowWall.forwardVelocity == 0)
        fingerprint = hash(fingerprint, lowWall)

        let soft = SM64MarioCommonAirAction.update(input(
            forwardVelocity: 20, velocityY: 5, airStep: .hitWall
        ))!
        precondition(soft.intent == .softBonk && soft.action == SM64MarioActionID.softBonk)
        precondition(soft.forwardVelocity == -8 && soft.velocity.y == 0)
        precondition(soft.shouldQueueRumble && soft.shouldReflectBonk)
        fingerprint = hash(fingerprint, soft)

        let hardWall = SM64MarioCommonAirAction.update(input(
            forwardVelocity: 40, airStep: .hitWall
        ))!
        precondition(hardWall.intent == .backwardAirKnockback)
        precondition(hardWall.particleVerticalStar)
        fingerprint = hash(fingerprint, hardWall)

        let retainedWall = SM64MarioCommonAirAction.update(input(
            faceYaw: 0x1000, forwardVelocity: 20, wallAngle: 0,
            airStep: .hitWall
        ))!
        precondition(retainedWall.intent == .airHitWall)
        precondition(retainedWall.action == SM64MarioActionID.airHitWall)
        precondition(retainedWall.faceYaw == Int16(bitPattern: 0x7000))
        fingerprint = hash(fingerprint, retainedWall)

        let ledge = SM64MarioCommonAirAction.update(input(
            airStep: .grabbedLedge
        ))!
        precondition(ledge.intent == .ledgeGrab && ledge.action == SM64MarioActionID.ledgeGrab)
        precondition(ledge.animationID == 0x33 && ledge.shouldDropHeldObject)
        fingerprint = hash(fingerprint, ledge)

        let ceiling = SM64MarioCommonAirAction.update(input(
            airStep: .grabbedCeiling
        ))!
        precondition(ceiling.intent == .hanging && ceiling.action == SM64MarioActionID.startHanging)
        fingerprint = hash(fingerprint, ceiling)

        let lava = SM64MarioCommonAirAction.update(input(
            airStep: .hitLavaWall
        ))!
        precondition(lava.intent == .lavaWall && lava.shouldPlayLavaBoost)
        fingerprint = hash(fingerprint, lava)

        precondition(SM64MarioCommonAirAction.update(input(forwardVelocity: .infinity)) == nil)

        print(String(format: "marioCommonAirFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario common-air smoke passed")
    }
}
