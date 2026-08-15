import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioWaterInteractionActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.actionTimer)
    x = h8(x, r.actionState)
    x = h16(x, r.animationID)
    x = h8(x, r.shouldThrowHeldObject ? 1 : 0)
    x = h8(x, r.shouldQueueRumble ? 1 : 0)
    x = h8(x, r.shouldGrabUsedObject ? 1 : 0)
    x = h8(x, r.shouldSetGrabPosition ? 1 : 0)
    x = h8(x, r.shouldDropHeldObject ? 1 : 0)
    x = h8(x, r.shouldStopRidingShell ? 1 : 0)
    x = h8(x, r.shouldStopShellMusic ? 1 : 0)
    return h8(x, r.shouldPlaySwimmingNoise ? 1 : 0)
}

private func input(
    _ variant: SM64MarioWaterInteractionVariant,
    flags: SM64MarioInputFlags = [],
    actionTimer: UInt16 = 0,
    actionState: UInt8 = 0,
    animationPastEnd: Bool = false,
    waterGrabFound: Bool = false,
    heldObjectIsShell: Bool = false,
    dropObjectRequested: Bool = false,
    forwardVelocity: Float = 6
) -> SM64MarioWaterInteractionActionInput {
    SM64MarioWaterInteractionActionInput(
        variant: variant, input: flags, actionTimer: actionTimer,
        actionState: actionState, animationPastEnd: animationPastEnd,
        waterGrabFound: waterGrabFound, heldObjectIsShell: heldObjectIsShell,
        dropObjectRequested: dropObjectRequested, forwardVelocity: forwardVelocity
    )
}

@main
enum SM64ModernMarioWaterInteractionSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let throwFrame = SM64MarioWaterInteractionAction.update(input(
            .waterThrow, actionTimer: 5
        ))!
        precondition(throwFrame.actionTimer == 6 && throwFrame.animationID == 0xB1)
        precondition(throwFrame.shouldThrowHeldObject && throwFrame.shouldQueueRumble)
        fingerprint = hash(fingerprint, throwFrame)

        let throwEnd = SM64MarioWaterInteractionAction.update(input(
            .waterThrow, animationPastEnd: true
        ))!
        precondition(throwEnd.intent == .waterIdle && throwEnd.action == SM64MarioActionID.waterIdle)
        fingerprint = hash(fingerprint, throwEnd)

        let grab = SM64MarioWaterInteractionAction.update(input(
            .waterPunch, actionState: 0, animationPastEnd: true, waterGrabFound: true
        ))!
        precondition(grab.actionState == 2 && grab.shouldGrabUsedObject && grab.shouldSetGrabPosition)
        precondition(grab.animationID == 0xB0)
        fingerprint = hash(fingerprint, grab)

        let grabEnd = SM64MarioWaterInteractionAction.update(input(
            .waterPunch, actionState: 1, animationPastEnd: true
        ))!
        precondition(grabEnd.action == SM64MarioActionID.waterActionEnd)
        fingerprint = hash(fingerprint, grabEnd)

        let shell = SM64MarioWaterInteractionAction.update(input(
            .waterPunch, actionState: 2, animationPastEnd: true, heldObjectIsShell: true
        ))!
        precondition(shell.action == SM64MarioActionID.waterShellSwimming)
        fingerprint = hash(fingerprint, shell)

        let holdEnd = SM64MarioWaterInteractionAction.update(input(
            .waterPunch, actionState: 2, animationPastEnd: true
        ))!
        precondition(holdEnd.action == SM64MarioActionID.holdWaterActionEnd)
        precondition(holdEnd.actionArgument == 1)
        fingerprint = hash(fingerprint, holdEnd)

        let shellStep = SM64MarioWaterInteractionAction.update(input(
            .waterShellSwimming, actionTimer: 10, forwardVelocity: 28
        ))!
        precondition(shellStep.actionTimer == 11 && shellStep.animationID == 0xA1)
        precondition(shellStep.forwardVelocity == 30 && shellStep.shouldPlaySwimmingNoise)
        fingerprint = hash(fingerprint, shellStep)

        let shellStop = SM64MarioWaterInteractionAction.update(input(
            .waterShellSwimming, actionTimer: 240
        ))!
        precondition(shellStop.action == SM64MarioActionID.flutterKick)
        precondition(shellStop.shouldStopRidingShell && shellStop.shouldStopShellMusic)
        fingerprint = hash(fingerprint, shellStop)

        let shellDrop = SM64MarioWaterInteractionAction.update(input(
            .waterShellSwimming, dropObjectRequested: true
        ))!
        precondition(shellDrop.action == SM64MarioActionID.waterIdle && shellDrop.shouldDropHeldObject)
        fingerprint = hash(fingerprint, shellDrop)

        let shellThrow = SM64MarioWaterInteractionAction.update(input(
            .waterShellSwimming, flags: [.bPressed]
        ))!
        precondition(shellThrow.action == SM64MarioActionID.waterThrow)
        fingerprint = hash(fingerprint, shellThrow)

        precondition(SM64MarioWaterInteractionAction.update(input(
            .waterPunch, forwardVelocity: .infinity
        )) == nil)

        print(String(format: "marioWaterInteractionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario water-interaction smoke passed")
    }
}
