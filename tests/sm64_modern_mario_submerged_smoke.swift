import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioSubmergedActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.actionTimer)
    x = h8(x, r.actionState)
    x = h16(x, r.animationID)
    x = h32(x, UInt32(bitPattern: r.animationAcceleration))
    x = h8(x, r.eyeState.rawValue)
    x = h8(x, r.shouldDropHeldObject ? 1 : 0)
    x = h8(x, r.shouldSetMetalShock ? 1 : 0)
    x = h8(x, r.shouldSetInvincibilityTimer ? 1 : 0)
    x = h8(x, r.shouldPlayWaterStep ? 1 : 0)
    x = h8(x, r.shouldPlayDrowningSound ? 1 : 0)
    x = h8(x, r.shouldPlayShockSound ? 1 : 0)
    x = h8(x, r.shouldSetCameraShake ? 1 : 0)
    return h8(x, r.shouldTriggerDeathWarp ? 1 : 0)
}

private func input(
    _ variant: SM64MarioSubmergedVariant,
    flags: SM64MarioInputFlags = [],
    actionArgument: UInt32 = 0,
    actionTimer: UInt16 = 0,
    actionState: UInt8 = 0,
    animationReturnValue: Int16 = 1,
    animationFrame: Int16 = 0,
    animationPastEnd: Bool = false,
    facePitch: Int16 = 0,
    metalCap: Bool = false,
    dropObjectRequested: Bool = false,
    health: UInt16 = 0x880
) -> SM64MarioSubmergedActionInput {
    SM64MarioSubmergedActionInput(
        variant: variant, input: flags, actionArgument: actionArgument,
        actionTimer: actionTimer, actionState: actionState,
        animationReturnValue: animationReturnValue, animationFrame: animationFrame,
        animationPastEnd: animationPastEnd, facePitch: facePitch,
        metalCap: metalCap, dropObjectRequested: dropObjectRequested, health: health
    )
}

@main
enum SM64ModernMarioSubmergedSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let idle = SM64MarioSubmergedAction.update(input(
            .waterIdle, facePitch: -0x2000
        ))!
        precondition(idle.animationID == 0xB2 && idle.animationAcceleration == 0x30000)
        fingerprint = hash(fingerprint, idle)

        let idleB = SM64MarioSubmergedAction.update(input(
            .waterIdle, flags: [.bPressed]
        ))!
        precondition(idleB.intent == .waterPunch && idleB.action == SM64MarioActionID.waterPunch)
        fingerprint = hash(fingerprint, idleB)

        let holdDrop = SM64MarioSubmergedAction.update(input(
            .holdWaterIdle, dropObjectRequested: true
        ))!
        precondition(holdDrop.action == SM64MarioActionID.waterIdle && holdDrop.shouldDropHeldObject)
        fingerprint = hash(fingerprint, holdDrop)

        let metal = SM64MarioSubmergedAction.update(input(
            .waterIdle, metalCap: true
        ))!
        precondition(metal.intent == .metalWaterFall && metal.action == SM64MarioActionID.metalWaterFalling)
        precondition(metal.actionArgument == 1)
        fingerprint = hash(fingerprint, metal)

        let endIdle = SM64MarioSubmergedAction.update(input(
            .waterActionEnd, animationPastEnd: true
        ))!
        precondition(endIdle.intent == .waterIdle && endIdle.action == SM64MarioActionID.waterIdle)
        fingerprint = hash(fingerprint, endIdle)

        let holdEnd = SM64MarioSubmergedAction.update(input(
            .holdWaterActionEnd, actionArgument: 1
        ))!
        precondition(holdEnd.animationID == 0xA3)
        fingerprint = hash(fingerprint, holdEnd)

        let drownStart = SM64MarioSubmergedAction.update(input(
            .drowning, animationPastEnd: true
        ))!
        precondition(drownStart.actionState == 1 && drownStart.animationID == 0xA6)
        precondition(drownStart.eyeState == .dead && drownStart.shouldPlayDrowningSound)
        fingerprint = hash(fingerprint, drownStart)

        let drownWarp = SM64MarioSubmergedAction.update(input(
            .drowning, actionState: 1, animationFrame: 30
        ))!
        precondition(drownWarp.intent == .deathWarp && drownWarp.shouldTriggerDeathWarp)
        fingerprint = hash(fingerprint, drownWarp)

        let death = SM64MarioSubmergedAction.update(input(
            .waterDeath, animationFrame: 35
        ))!
        precondition(death.intent == .deathWarp && death.animationID == 0xA7)
        fingerprint = hash(fingerprint, death)

        let shock = SM64MarioSubmergedAction.update(input(
            .waterShocked, actionTimer: 5, animationReturnValue: 0,
            health: 0x880
        ))!
        precondition(shock.actionTimer == 6 && shock.action == SM64MarioActionID.waterIdle)
        precondition(shock.shouldSetMetalShock && shock.shouldSetInvincibilityTimer)
        fingerprint = hash(fingerprint, shock)

        let shockDeath = SM64MarioSubmergedAction.update(input(
            .waterShocked, actionTimer: 5, animationReturnValue: 0,
            health: 0xFF
        ))!
        precondition(shockDeath.action == SM64MarioActionID.waterDeath)
        fingerprint = hash(fingerprint, shockDeath)

        print(String(format: "marioSubmergedFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario submerged smoke passed")
    }
}
