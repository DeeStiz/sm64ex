import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioDiveAirActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h8(x, r.airStep.rawValue)
    x = h16(x, r.animationID)
    x = h16(x, UInt16(bitPattern: r.faceYaw))
    x = h16(x, UInt16(bitPattern: r.facePitch))
    x = h16(x, UInt16(bitPattern: r.graphicsPitch))
    x = h8(x, r.actionState)
    x = h8(x, r.actionTimer)
    x = h8(x, r.shouldQueueRumble ? 1 : 0)
    x = h8(x, r.particleMistCircle ? 1 : 0)
    x = h8(x, r.particleVerticalStar ? 1 : 0)
    x = h8(x, r.shouldDropHeldObject ? 1 : 0)
    x = h8(x, r.shouldThrowHeldObject ? 1 : 0)
    x = h8(x, r.shouldPlayLandingSound ? 1 : 0)
    return h8(x, r.shouldPlaySpinSound ? 1 : 0)
}

private func input(
    _ variant: SM64MarioDiveAirVariant,
    facePitch: Int16 = 0,
    forwardVelocity: Float = 20,
    velocityY: Float = -10,
    wallAngle: Int16? = nil,
    airStep: SM64MarioCommonAirStepOutcome = .none,
    actionState: UInt8 = 1,
    actionTimer: UInt8 = 0,
    animationFrame: Int16 = 0,
    animationReturnValue: Int16 = 0,
    animationPastEnd: Bool = false,
    fallDamageOrStuck: Bool = false,
    shouldGetStuckInGround: Bool = false,
    heldObjectPresent: Bool = false,
    objectGrabTransitionAction: UInt32? = nil
) -> SM64MarioDiveAirActionInput {
    SM64MarioDiveAirActionInput(
        variant: variant, actionArgument: 0, input: [],
        intendedMagnitude: 0, intendedYaw: 0, faceYaw: 0,
        facePitch: facePitch, forwardVelocity: forwardVelocity,
        velocityY: velocityY, wallAngle: wallAngle, airStep: airStep,
        actionState: actionState, actionTimer: actionTimer,
        animationFrame: animationFrame, animationReturnValue: animationReturnValue,
        animationPastEnd: animationPastEnd, fallDamageOrStuck: fallDamageOrStuck,
        shouldGetStuckInGround: shouldGetStuckInGround,
        heldObjectPresent: heldObjectPresent,
        objectGrabTransitionAction: objectGrabTransitionAction,
        horizontalWindActive: false
    )
}

@main
enum SM64ModernMarioDiveAirSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let dive = SM64MarioDiveAirAction.update(input(.dive))!
        precondition(dive.intent == .continueAir && dive.animationID == 0x88)
        precondition(dive.facePitch == -0x200 && dive.graphicsPitch == 0x200)
        fingerprint = hash(fingerprint, dive)

        let slide = SM64MarioDiveAirAction.update(input(
            .dive, airStep: .landed
        ))!
        precondition(slide.intent == .diveSlide && slide.action == SM64MarioActionID.diveSlide)
        precondition(slide.facePitch == 0 && slide.shouldPlayLandingSound)
        fingerprint = hash(fingerprint, slide)

        let stuck = SM64MarioDiveAirAction.update(input(
            .dive, facePitch: -0x2AAA, airStep: .landed,
            shouldGetStuckInGround: true
        ))!
        precondition(stuck.intent == .headStuck && stuck.action == SM64MarioActionID.headStuckInGround)
        precondition(stuck.shouldQueueRumble && stuck.particleMistCircle && stuck.shouldDropHeldObject)
        fingerprint = hash(fingerprint, stuck)

        let wall = SM64MarioDiveAirAction.update(input(
            .dive, velocityY: 5, airStep: .hitWall
        ))!
        precondition(wall.action == SM64MarioActionID.backwardAirKnockback)
        precondition(wall.forwardVelocity < 0 && wall.velocityY == 0)
        precondition(wall.particleVerticalStar && wall.shouldDropHeldObject)
        fingerprint = hash(fingerprint, wall)

        let throwFrame = SM64MarioDiveAirAction.update(input(
            .airThrow, actionTimer: 3
        ))!
        precondition(throwFrame.actionTimer == 4 && throwFrame.shouldThrowHeldObject)
        precondition(throwFrame.animationID == 0x52)
        fingerprint = hash(fingerprint, throwFrame)

        let throwLand = SM64MarioDiveAirAction.update(input(
            .airThrow, airStep: .landed
        ))!
        precondition(throwLand.intent == .airThrowLand && throwLand.action == SM64MarioActionID.airThrowLand)
        fingerprint = hash(fingerprint, throwLand)

        let forward = SM64MarioDiveAirAction.update(input(
            .forwardRollout, actionState: 0, animationReturnValue: 4
        ))!
        precondition(forward.actionState == 1 && forward.velocityY == 30)
        precondition(forward.animationID == 0x6F && forward.shouldPlaySpinSound)
        fingerprint = hash(fingerprint, forward)

        let backward = SM64MarioDiveAirAction.update(input(
            .backwardRollout, actionState: 1, animationReturnValue: 2,
            animationPastEnd: true
        ))!
        precondition(backward.actionState == 2 && backward.animationID == 0x70)
        fingerprint = hash(fingerprint, backward)

        let rolloutLand = SM64MarioDiveAirAction.update(input(
            .forwardRollout, airStep: .landed
        ))!
        precondition(rolloutLand.action == SM64MarioActionID.freefallLandStop)
        fingerprint = hash(fingerprint, rolloutLand)

        precondition(SM64MarioDiveAirAction.update(input(.dive, forwardVelocity: .infinity)) == nil)

        print(String(format: "marioDiveAirFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario dive-air smoke passed")
    }
}
