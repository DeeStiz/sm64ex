import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioBasicAirActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.animationID)
    x = h8(x, r.sound.rawValue)
    x = h8(x, r.shouldQueueRumble ? 1 : 0)
    x = h8(x, r.shouldPlayFlipSounds ? 1 : 0)
    x = h8(x, r.shouldDropHeldObject ? 1 : 0)
    return h8(x, r.common?.intent.rawValue ?? UInt8.max)
}

private func input(
    _ variant: SM64MarioBasicAirVariant,
    actionArgument: UInt32 = 0,
    flags: SM64MarioInputFlags = [],
    velocityY: Float = 10,
    airStep: SM64MarioCommonAirStepOutcome = .none,
    dropRequested: Bool = false,
    heldObjectIsNPC: Bool = false,
    specialTripleJump: Bool = false,
    kickOrDiveAction: UInt32? = nil
) -> SM64MarioBasicAirActionInput {
    SM64MarioBasicAirActionInput(
        variant: variant, actionArgument: actionArgument,
        commonInput: SM64MarioCommonAirActionInput(
            landAction: SM64MarioActionID.jumpLand, animationID: 0,
            input: flags, intendedMagnitude: 0, intendedYaw: 0, faceYaw: 0,
            forwardVelocity: 20, velocityY: velocityY, wallAngle: nil,
            airStep: airStep, fallDamageOrStuck: false,
            horizontalWindActive: false
        ), dropRequested: dropRequested, heldObjectIsNPC: heldObjectIsNPC,
        specialTripleJump: specialTripleJump, kickOrDiveAction: kickOrDiveAction
    )
}

@main
enum SM64ModernMarioBasicAirSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let jump = SM64MarioBasicAirAction.update(input(.jump))!
        precondition(jump.intent == .commonStep && jump.animationID == 0x4D)
        precondition(jump.sound == .terrainJump && jump.common?.intent == .continueAir)
        fingerprint = hash(fingerprint, jump)

        let doubleFall = SM64MarioBasicAirAction.update(input(.doubleJump, velocityY: -1))!
        precondition(doubleFall.animationID == 0x4C && doubleFall.sound == .hoohoo)
        fingerprint = hash(fingerprint, doubleFall)

        let triple = SM64MarioBasicAirAction.update(input(.tripleJump, specialTripleJump: true))!
        precondition(triple.intent == .preempt && triple.action == SM64MarioActionID.flyingTripleJump)
        fingerprint = hash(fingerprint, triple)

        let tripleB = SM64MarioBasicAirAction.update(input(.tripleJump, flags: [.bPressed]))!
        precondition(tripleB.action == SM64MarioActionID.dive)
        fingerprint = hash(fingerprint, tripleB)

        let backflipZ = SM64MarioBasicAirAction.update(input(.backflip, flags: [.zPressed]))!
        precondition(backflipZ.action == SM64MarioActionID.groundPound)
        fingerprint = hash(fingerprint, backflipZ)

        let freefall = SM64MarioBasicAirAction.update(input(.freefall, actionArgument: 1))!
        precondition(freefall.animationID == 0x90 && freefall.sound == .none)
        fingerprint = hash(fingerprint, freefall)

        let holdDrop = SM64MarioBasicAirAction.update(input(.holdJump, dropRequested: true))!
        precondition(holdDrop.action == SM64MarioActionID.freefall && holdDrop.shouldDropHeldObject)
        fingerprint = hash(fingerprint, holdDrop)

        let holdThrow = SM64MarioBasicAirAction.update(input(.holdJump, flags: [.bPressed]))!
        precondition(holdThrow.action == SM64MarioActionID.airThrow)
        precondition(!holdThrow.shouldDropHeldObject)
        fingerprint = hash(fingerprint, holdThrow)

        let tripleLand = SM64MarioBasicAirAction.update(input(
            .tripleJump, airStep: .landed
        ))!
        precondition(tripleLand.action == SM64MarioActionID.tripleJumpLand)
        precondition(tripleLand.shouldQueueRumble && tripleLand.shouldPlayFlipSounds)
        fingerprint = hash(fingerprint, tripleLand)

        let kick = SM64MarioBasicAirAction.update(input(
            .jump, kickOrDiveAction: SM64MarioActionID.dive
        ))!
        precondition(kick.intent == .preempt && kick.action == SM64MarioActionID.dive)
        fingerprint = hash(fingerprint, kick)

        print(String(format: "marioBasicAirFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario basic-air smoke passed")
    }
}
