import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioWaterDiveActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.actionTimer)
    x = h8(x, r.actionState)
    x = h16(x, r.animationID)
    x = h8(x, r.shouldSetInvincibilityTimer ? 1 : 0)
    x = h8(x, r.shouldPlaySplashSound ? 1 : 0)
    x = h8(x, r.shouldPlayFallSound ? 1 : 0)
    x = h8(x, r.shouldParticleWaterSplash ? 1 : 0)
    x = h8(x, r.shouldParticlePlungeBubble ? 1 : 0)
    x = h8(x, r.shouldQueueRumble ? 1 : 0)
    x = h8(x, r.shouldResetRumble ? 1 : 0)
    return h8(x, r.shouldStationarySlowDown ? 1 : 0)
}

private func input(
    _ variant: SM64MarioWaterDiveVariant,
    actionArgument: UInt32 = 0,
    actionTimer: UInt16 = 0,
    actionState: UInt8 = 0,
    animationPastEnd: Bool = false,
    animationIDFrame: Int16 = 0,
    health: UInt16 = 0x880,
    forwardVelocity: Float = 4,
    velocityY: Float = -10,
    buoyancy: Float = 1.25,
    waterStep: SM64MarioWaterStepOutcome = .none,
    nearSurface: Bool = false,
    heldObject: Bool = false,
    metalCap: Bool = false,
    previousActionDiving: Bool = false,
    previousActionAir: Bool = false,
    flags: SM64MarioInputFlags = [],
    fallDistance: Float = 0
) -> SM64MarioWaterDiveActionInput {
    SM64MarioWaterDiveActionInput(
        variant: variant, actionArgument: actionArgument, actionTimer: actionTimer,
        actionState: actionState, animationPastEnd: animationPastEnd,
        animationIDFrame: animationIDFrame, health: health,
        forwardVelocity: forwardVelocity, velocityY: velocityY, buoyancy: buoyancy,
        waterStep: waterStep, nearSurface: nearSurface, heldObject: heldObject,
        metalCap: metalCap, previousActionDiving: previousActionDiving,
        previousActionAir: previousActionAir, input: flags, fallDistance: fallDistance
    )
}

@main
enum SM64ModernMarioWaterDiveSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let kb = SM64MarioWaterDiveAction.update(input(
            .backwardKnockback, actionArgument: 1
        ))!
        precondition(kb.animationID == 0x9E && kb.shouldStationarySlowDown)
        fingerprint = hash(fingerprint, kb)

        let kbEnd = SM64MarioWaterDiveAction.update(input(
            .forwardKnockback, actionArgument: 1, animationPastEnd: true
        ))!
        precondition(kbEnd.action == SM64MarioActionID.waterIdle)
        precondition(kbEnd.shouldSetInvincibilityTimer && kbEnd.animationID == 0xA8)
        fingerprint = hash(fingerprint, kbEnd)

        let kbDeath = SM64MarioWaterDiveAction.update(input(
            .forwardKnockback, animationPastEnd: true, health: 0xFF
        ))!
        precondition(kbDeath.intent == .waterDeath && kbDeath.action == SM64MarioActionID.waterDeath)
        fingerprint = hash(fingerprint, kbDeath)

        let plunge = SM64MarioWaterDiveAction.update(input(
            .plunge, previousActionAir: true, fallDistance: 1200
        ))!
        precondition(plunge.actionState == 1 && plunge.shouldPlaySplashSound)
        precondition(plunge.shouldPlayFallSound && plunge.shouldParticlePlungeBubble)
        precondition(plunge.shouldQueueRumble)
        fingerprint = hash(fingerprint, plunge)

        let holdEnd = SM64MarioWaterDiveAction.update(input(
            .plunge, actionState: 1, velocityY: 1, waterStep: .hitFloor,
            nearSurface: true, heldObject: true
        ))!
        precondition(holdEnd.intent == .holdWaterActionEnd && holdEnd.action == SM64MarioActionID.holdWaterActionEnd)
        precondition(holdEnd.animationID == 0xA2 && holdEnd.shouldResetRumble)
        fingerprint = hash(fingerprint, holdEnd)

        let flutter = SM64MarioWaterDiveAction.update(input(
            .plunge, actionState: 1, velocityY: -10, buoyancy: -10,
            waterStep: .hitFloor, previousActionDiving: true
        ))!
        precondition(flutter.intent == .flutterKick && flutter.action == SM64MarioActionID.flutterKick)
        fingerprint = hash(fingerprint, flutter)

        let metal = SM64MarioWaterDiveAction.update(input(
            .plunge, actionState: 1, velocityY: -10, buoyancy: -18,
            waterStep: .hitFloor, metalCap: true
        ))!
        precondition(metal.intent == .metalWaterFalling && metal.action == SM64MarioActionID.metalWaterFalling)
        precondition(metal.animationID == 0x56)
        fingerprint = hash(fingerprint, metal)

        let timeout = SM64MarioWaterDiveAction.update(input(
            .plunge, actionTimer: 20, actionState: 1, velocityY: -10,
            buoyancy: -2
        ))!
        precondition(timeout.action == SM64MarioActionID.waterActionEnd)
        fingerprint = hash(fingerprint, timeout)

        precondition(SM64MarioWaterDiveAction.update(input(
            .plunge, forwardVelocity: .infinity
        )) == nil)

        print(String(format: "marioWaterDiveFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario water-dive smoke passed")
    }
}
