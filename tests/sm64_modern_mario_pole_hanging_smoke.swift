import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x=h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x=h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i*8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x=h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i*8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }
private func hash(_ h: UInt64, _ r: SM64MarioPoleHangingActionResult) -> UInt64 {
    var x=h8(h,r.variant.rawValue); x=h8(x,r.intent.rawValue); x=h32(x,r.action ?? UInt32.max)
    x=h32(x,r.actionArgument); x=h16(x,r.actionTimer); x=h16(x,r.animationID)
    x=h32(x,UInt32(bitPattern:r.animationAcceleration)); x=h16(x,UInt16(bitPattern:r.faceYaw))
    x=hf(x,r.polePosition); x=h16(x,UInt16(bitPattern:r.poleYawVelocity)); x=hf(x,r.forwardVelocity)
    x=hf(x,r.velocity.x); x=hf(x,r.velocity.y); x=hf(x,r.velocity.z)
    x=h8(x,r.shouldQueueRumble ? 1:0); x=h16(x,r.rumbleDistance); x=h8(x,r.shouldResetRumble ? 1:0)
    x=h8(x,r.shouldPlayWhoa ? 1:0); x=h8(x,r.shouldPlayClimbingSound ? 1:0)
    x=h8(x,r.shouldPlayHangingStep ? 1:0); x=h8(x,r.shouldAddTreeLeafParticles ? 1:0)
    return h8(x,r.shouldSyncGraphics ? 1:0)
}

private func input(
    _ variant: SM64MarioPoleHangingVariant,
    flags: SM64MarioInputFlags = [], health: UInt16 = 0x880,
    marioSoundPlayed: Bool = false, stickX: Float = 0, stickY: Float = 0,
    cameraYaw: Int16 = 0x2000, faceYaw: Int16 = 0x1000,
    polePosition: Float = 20, poleTop: Float = 100, poleYawVelocity: Int16 = 0x100,
    actionArgument: UInt32 = 0, actionTimer: UInt16 = 0, animationAtEnd: Bool = false,
    animationFrame: Int16 = 0, poleIsGiant: Bool = false,
    polePlacement: SM64MarioPolePlacement = .none, ceilingHangable: Bool = true,
    hangStep: SM64MarioHangStep = .none, intendedYaw: Int16 = 0x1800,
    ceilNormalY: Float = 1, forwardVelocity: Float = 0,
    velocity: SM64ObjectVector3 = .zero
) -> SM64MarioPoleHangingActionInput {
    SM64MarioPoleHangingActionInput(
        variant: variant, input: flags, health: health, marioSoundPlayed: marioSoundPlayed,
        stickX: stickX, stickY: stickY, cameraYaw: cameraYaw, faceYaw: faceYaw,
        polePosition: polePosition, poleTop: poleTop, poleYawVelocity: poleYawVelocity,
        actionArgument: actionArgument, actionTimer: actionTimer, animationAtEnd: animationAtEnd,
        animationFrame: animationFrame, poleIsGiant: poleIsGiant, polePlacement: polePlacement,
        ceilingHangable: ceilingHangable, hangStep: hangStep, intendedYaw: intendedYaw,
        ceilNormalY: ceilNormalY, forwardVelocity: forwardVelocity, velocity: velocity
    )
}

@main
enum SM64ModernMarioPoleHangingSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let pole = SM64MarioPoleHangingAction.update(input(
            .holdingPole, stickX: 2, stickY: -20, polePosition: 40,
            poleYawVelocity: 0x100
        ))!
        precondition(pole.animationID == 0x0D && pole.shouldPlayClimbingSound)
        precondition(pole.poleYawVelocity > 0x100 && pole.shouldResetRumble)
        fingerprint = hash(fingerprint, pole)

        let climb = SM64MarioPoleHangingAction.update(input(
            .climbingPole, stickY: 16, polePosition: 40
        ))!
        precondition(climb.animationID == 0x05 && climb.animationAcceleration > 0)
        precondition(climb.shouldAddTreeLeafParticles)
        fingerprint = hash(fingerprint, climb)

        let grab = SM64MarioPoleHangingAction.update(input(
            .grabPoleSlow, animationAtEnd: true
        ))!
        precondition(grab.action == SM64MarioActionID.holdingPole && grab.shouldPlayWhoa)
        fingerprint = hash(fingerprint, grab)

        let top = SM64MarioPoleHangingAction.update(input(
            .topOfPoleTransition, animationAtEnd: true
        ))!
        precondition(top.action == SM64MarioActionID.topOfPole && top.animationID == 0x0B)
        fingerprint = hash(fingerprint, top)

        let start = SM64MarioPoleHangingAction.update(input(
            .startHanging, flags: [.nonzeroAnalog, .aDown], actionTimer: 30
        ))!
        precondition(start.action == SM64MarioActionID.hanging && start.actionTimer == 0)
        fingerprint = hash(fingerprint, start)

        let hanging = SM64MarioPoleHangingAction.update(input(
            .hanging, flags: [.nonzeroAnalog, .aDown], actionArgument: 1
        ))!
        precondition(hanging.action == SM64MarioActionID.hangMoving)
        fingerprint = hash(fingerprint, hanging)

        let moving = SM64MarioPoleHangingAction.update(input(
            .hangMoving, flags: [.aDown], faceYaw: 0x1000, actionArgument: 0,
            animationFrame: 12, forwardVelocity: 2
        ))!
        precondition(moving.shouldPlayHangingStep && moving.shouldQueueRumble)
        precondition(moving.forwardVelocity == 3)
        fingerprint = hash(fingerprint, moving)

        let left = SM64MarioPoleHangingAction.update(input(
            .hangMoving, flags: [.aDown], hangStep: .leftCeiling
        ))!
        precondition(left.action == SM64MarioActionID.freefall)
        fingerprint = hash(fingerprint, left)

        precondition(SM64MarioPoleHangingAction.update(input(
            .holdingPole, stickX: .infinity
        )) == nil)

        print(String(format: "marioPoleHangingFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario pole/hanging smoke passed")
    }
}
