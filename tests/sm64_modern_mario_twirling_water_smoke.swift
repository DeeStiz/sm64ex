import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioTwirlingWaterActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.animationID)
    x = h16(x, UInt16(bitPattern: r.twirlYaw))
    x = h16(x, UInt16(bitPattern: r.angleVelocityY))
    x = h16(x, UInt16(bitPattern: r.faceYaw))
    x = h8(x, r.shouldPlayTwirlSound ? 1 : 0)
    x = h8(x, r.shouldSetLedgeAnimation ? 1 : 0)
    x = h8(x, r.shouldSetDefaultCamera ? 1 : 0)
    x = h8(x, r.shouldDropHeldObject ? 1 : 0)
    x = h8(x, r.shouldReflectBonk ? 1 : 0)
    return h8(x, r.shouldPlayLavaBoost ? 1 : 0)
}

private func input(
    _ variant: SM64MarioTwirlingWaterVariant,
    flags: SM64MarioInputFlags = [],
    actionArgument: UInt32 = 0,
    twirlYaw: Int16 = 0,
    angleVelocityY: Int16 = 0,
    faceYaw: Int16 = 0,
    forwardVelocity: Float = 20,
    velocityY: Float = 10,
    intendedMagnitude: Float = 0,
    intendedYaw: Int16 = 0,
    wallAngle: Int16? = nil,
    airStep: SM64MarioCommonAirStepOutcome = .none,
    animationPastEnd: Bool = false,
    dropObjectRequested: Bool = false
) -> SM64MarioTwirlingWaterActionInput {
    SM64MarioTwirlingWaterActionInput(
        variant: variant, input: flags, actionArgument: actionArgument,
        twirlYaw: twirlYaw, angleVelocityY: angleVelocityY,
        faceYaw: faceYaw, forwardVelocity: forwardVelocity, velocityY: velocityY,
        intendedMagnitude: intendedMagnitude, intendedYaw: intendedYaw,
        wallAngle: wallAngle, airStep: airStep,
        animationPastEnd: animationPastEnd, dropObjectRequested: dropObjectRequested
    )
}

@main
enum SM64ModernMarioTwirlingWaterSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let twirl = SM64MarioTwirlingWaterAction.update(input(.twirling))!
        precondition(twirl.animationID == 0x95 && twirl.angleVelocityY == 0x200)
        precondition(twirl.twirlYaw == 0x200 && twirl.intent == .continueAir)
        fingerprint = hash(fingerprint, twirl)

        let fastTwirl = SM64MarioTwirlingWaterAction.update(input(
            .twirling, flags: [.aDown], actionArgument: 1,
            twirlYaw: 0x1000, angleVelocityY: 0x7FFF,
            airStep: .hitWall
        ))!
        precondition(fastTwirl.animationID == 0x94 && fastTwirl.actionArgument == 1)
        precondition(fastTwirl.shouldReflectBonk && fastTwirl.shouldPlayTwirlSound)
        fingerprint = hash(fingerprint, fastTwirl)

        let twirlLand = SM64MarioTwirlingWaterAction.update(input(
            .twirling, airStep: .landed
        ))!
        precondition(twirlLand.intent == .twirlLand && twirlLand.action == SM64MarioActionID.twirlLand)
        fingerprint = hash(fingerprint, twirlLand)

        let waterLand = SM64MarioTwirlingWaterAction.update(input(
            .waterJump, forwardVelocity: 8, airStep: .landed
        ))!
        precondition(waterLand.forwardVelocity == 15)
        precondition(waterLand.intent == .waterJumpLand && waterLand.action == SM64MarioActionID.jumpLand)
        precondition(waterLand.animationID == 0x4D && waterLand.shouldSetDefaultCamera)
        fingerprint = hash(fingerprint, waterLand)

        let ledge = SM64MarioTwirlingWaterAction.update(input(
            .waterJump, airStep: .grabbedLedge
        ))!
        precondition(ledge.intent == .ledgeGrab && ledge.action == SM64MarioActionID.ledgeGrab)
        precondition(ledge.animationID == 0x33 && ledge.shouldSetLedgeAnimation)
        fingerprint = hash(fingerprint, ledge)

        let holdWall = SM64MarioTwirlingWaterAction.update(input(
            .holdWaterJump, forwardVelocity: 4, airStep: .hitWall
        ))!
        precondition(holdWall.forwardVelocity == 15 && holdWall.animationID == 0x41)
        fingerprint = hash(fingerprint, holdWall)

        let holdDrop = SM64MarioTwirlingWaterAction.update(input(
            .holdWaterJump, dropObjectRequested: true
        ))!
        precondition(holdDrop.intent == .dropHeldObject && holdDrop.action == SM64MarioActionID.freefall)
        precondition(holdDrop.shouldDropHeldObject)
        fingerprint = hash(fingerprint, holdDrop)

        let lava = SM64MarioTwirlingWaterAction.update(input(
            .waterJump, airStep: .hitLavaWall
        ))!
        precondition(lava.intent == .lavaBoost && lava.action == SM64MarioActionID.lavaBoost)
        precondition(lava.shouldPlayLavaBoost)
        fingerprint = hash(fingerprint, lava)

        precondition(SM64MarioTwirlingWaterAction.update(input(
            .twirling, forwardVelocity: .infinity
        )) == nil)

        print(String(format: "marioTwirlingWaterFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario twirling-water smoke passed")
    }
}
