import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioAirKnockbackActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, UInt16(bitPattern: r.faceYawDelta))
    x = h16(x, r.animationID ?? UInt16.max)
    x = h8(x, r.airStep.rawValue)
    x = h16(x, UInt16(bitPattern: r.pitch ?? Int16.min))
    x = h8(x, r.reflectedBonk ? 1 : 0)
    x = h8(x, r.shouldQueueRumble ? 1 : 0)
    return h8(x, r.shouldPlayKnockbackSound ? 1 : 0)
}

private func input(
    _ variant: SM64MarioAirKnockbackVariant,
    flags: SM64MarioInputFlags = [],
    wallKickTimer: UInt8 = 0,
    previousAction: UInt32 = 0,
    actionArgument: UInt32 = 1,
    hurtCounter: UInt8 = 7,
    forwardVelocity: Float = 20,
    velocityY: Float = -10,
    airStep: SM64MarioAirStepOutcome = .none,
    fallDamageOrStuck: Bool = false
) -> SM64MarioAirKnockbackActionInput {
    SM64MarioAirKnockbackActionInput(
        variant: variant, input: flags, wallKickTimer: wallKickTimer,
        previousAction: previousAction, actionArgument: actionArgument,
        hurtCounter: hurtCounter, forwardVelocity: forwardVelocity,
        velocityY: velocityY, airStep: airStep,
        fallDamageOrStuck: fallDamageOrStuck
    )
}

@main
enum SM64ModernMarioAirKnockbackSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let backward = SM64MarioAirKnockbackAction.update(input(.backward))!
        precondition(backward.intent == .continueAir && backward.animationID == 0x02)
        precondition(backward.forwardVelocity == -16 && backward.shouldPlayKnockbackSound)
        fingerprint = hash(fingerprint, backward)

        let forwardLand = SM64MarioAirKnockbackAction.update(input(
            .forward, airStep: .landed
        ))!
        precondition(forwardLand.intent == .land && forwardLand.action == SM64MarioActionID.forwardGroundKnockback)
        fingerprint = hash(fingerprint, forwardLand)

        let hardFall = SM64MarioAirKnockbackAction.update(input(
            .hardBackward, airStep: .landed, fallDamageOrStuck: true
        ))!
        precondition(hardFall.intent == .hardFall && hardFall.action == SM64MarioActionID.hardBackwardGroundKnockback)
        fingerprint = hash(fingerprint, hardFall)

        let wall = SM64MarioAirKnockbackAction.update(input(
            .forward, velocityY: 5, airStep: .hitWall
        ))!
        precondition(wall.intent == .hitWall && wall.reflectedBonk)
        precondition(wall.forwardVelocity == -16 && wall.velocityY == 0)
        fingerprint = hash(fingerprint, wall)

        let lava = SM64MarioAirKnockbackAction.update(input(
            .backward, airStep: .hitLavaWall
        ))!
        precondition(lava.intent == .lavaWall && lava.action == SM64MarioActionID.lavaBoost)
        fingerprint = hash(fingerprint, lava)

        let kick = SM64MarioAirKnockbackAction.update(input(
            .backward, flags: [.aPressed], wallKickTimer: 1,
            previousAction: SM64MarioActionID.airHitWall
        ))!
        precondition(kick.intent == .wallKick && kick.action == SM64MarioActionID.wallKickAir)
        precondition(kick.faceYawDelta == Int16.min)
        precondition(!kick.shouldPlayKnockbackSound)
        fingerprint = hash(fingerprint, kick)

        let thrownBack = SM64MarioAirKnockbackAction.update(input(
            .thrownBackward, actionArgument: 0, hurtCounter: 9,
            forwardVelocity: 30, airStep: .landed
        ))!
        precondition(thrownBack.action == SM64MarioActionID.backwardGroundKnockback)
        precondition(thrownBack.actionArgument == 9 && abs(thrownBack.forwardVelocity - 29.4) < 0.001)
        fingerprint = hash(fingerprint, thrownBack)

        let thrownForward = SM64MarioAirKnockbackAction.update(input(
            .thrownForward, actionArgument: 1, forwardVelocity: 20,
            velocityY: -20
        ))!
        precondition(thrownForward.intent == .continueAir && thrownForward.pitch != nil)
        precondition(abs(thrownForward.forwardVelocity - 19.6) < 0.001)
        fingerprint = hash(fingerprint, thrownForward)

        let soft = SM64MarioAirKnockbackAction.update(input(
            .softBonk, airStep: .landed
        ))!
        precondition(soft.intent == .land && soft.action == SM64MarioActionID.freefallLand)
        precondition(soft.shouldQueueRumble)
        fingerprint = hash(fingerprint, soft)

        precondition(SM64MarioAirKnockbackAction.update(input(.forward, forwardVelocity: .infinity)) == nil)

        print(String(format: "marioAirKnockbackFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario air-knockback smoke passed")
    }
}
