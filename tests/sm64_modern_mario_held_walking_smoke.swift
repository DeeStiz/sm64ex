import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioHeldWalkingActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, UInt16(bitPattern: r.faceYaw))
    x = h16(x, r.actionTimer)
    x = h16(x, r.animation?.animationID ?? UInt16.max)
    x = h32(x, UInt32(bitPattern: r.animation?.acceleration ?? 0))
    x = h8(x, r.particleDust ? 1 : 0)
    x = h8(x, r.reflectedBonk ? 1 : 0)
    x = h8(x, r.shouldDropHeldObject ? 1 : 0)
    x = h8(x, r.shouldPlayStepSound ? 1 : 0)
    return h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
}

private func input(
    _ variant: SM64MarioHeldWalkingVariant,
    flags: SM64MarioInputFlags = [],
    drop: Bool = false,
    jumpingBox: Bool = false,
    intendedMagnitude: Float = 20,
    faceYaw: Int16 = 0,
    forwardVelocity: Float = 4,
    actionTimer: UInt16 = 0,
    floorClass: SM64MarioFloorClass = .defaultClass,
    positionY: Float = 0,
    wall: SM64MarioGroundWallProbe? = nil
) -> SM64MarioHeldWalkingActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: wall
    ), count: 4)
    return SM64MarioHeldWalkingActionInput(
        variant: variant, input: flags, terrainIsSlide: false, facingDownhill: false,
        dropInteraction: drop, jumpingBox: jumpingBox,
        intendedMagnitude: intendedMagnitude, intendedYaw: 0, faceYaw: faceYaw,
        forwardVelocity: forwardVelocity, quicksandDepth: 0, floorNormalY: 1,
        floorIsSlow: false, floorClass: floorClass, responsiveCheat: false,
        cheatsEnabled: false, actionTimer: actionTimer,
        animationPastFrame1: false, animationPastFrame2: false,
        velocityY: 0,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor, faceYaw: Int32(faceYaw), nativeStepScale: 1,
            ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
        )
    )
}

@main
enum SM64ModernMarioHeldWalkingSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let box = SM64MarioHeldWalkingAction.update(input(.light, jumpingBox: true))!
        precondition(box.intent == .crazyBoxBounce && box.action == SM64MarioActionID.crazyBoxBounce)
        fingerprint = hash(fingerprint, box)

        let drop = SM64MarioHeldWalkingAction.update(input(.light, drop: true))!
        precondition(drop.intent == .walking && drop.action == SM64MarioActionID.walking && drop.shouldDropHeldObject)
        fingerprint = hash(fingerprint, drop)

        let slide = SM64MarioHeldWalkingAction.update(input(.light, flags: [.aboveSlide], forwardVelocity: -2))!
        precondition(slide.intent == .beginSliding && slide.action == SM64MarioActionID.holdBeginSliding)
        fingerprint = hash(fingerprint, slide)

        let throwLight = SM64MarioHeldWalkingAction.update(input(.light, flags: [.bPressed]))!
        precondition(throwLight.intent == .throwing && throwLight.action == SM64MarioActionID.throwing)
        fingerprint = hash(fingerprint, throwLight)

        let jump = SM64MarioHeldWalkingAction.update(input(.light, flags: [.aPressed]))!
        precondition(jump.intent == .jump && jump.action == SM64MarioActionID.holdJump)
        fingerprint = hash(fingerprint, jump)

        let decel = SM64MarioHeldWalkingAction.update(input(.light, flags: [.unknown5]))!
        precondition(decel.intent == .decelerating && decel.action == SM64MarioActionID.holdDecelerating)
        fingerprint = hash(fingerprint, decel)

        let crouch = SM64MarioHeldWalkingAction.update(input(.light, flags: [.zPressed]))!
        precondition(crouch.intent == .crouchSlide && crouch.shouldDropHeldObject)
        fingerprint = hash(fingerprint, crouch)

        let lightGround = SM64MarioHeldWalkingAction.update(input(.light))!
        precondition(lightGround.intent == .continueGround && lightGround.animation?.animationID == 0x16)
        precondition(lightGround.animation?.actionTimer == 1 && lightGround.groundStep?.result == SM64MarioGroundStepOutcome.none)
        fingerprint = hash(fingerprint, lightGround)

        let heavyThrow = SM64MarioHeldWalkingAction.update(input(.heavy, flags: [.bPressed]))!
        precondition(heavyThrow.intent == .heavyThrow && heavyThrow.action == SM64MarioActionID.heavyThrow)
        fingerprint = hash(fingerprint, heavyThrow)

        let heavySlide = SM64MarioHeldWalkingAction.update(input(.heavy, flags: [.aboveSlide], forwardVelocity: -2))!
        precondition(heavySlide.intent == .beginSliding && heavySlide.shouldDropHeldObject)
        fingerprint = hash(fingerprint, heavySlide)

        let heavyIdle = SM64MarioHeldWalkingAction.update(input(.heavy, flags: [.unknown5]))!
        precondition(heavyIdle.intent == .holdHeavyIdle && heavyIdle.action == SM64MarioActionID.holdHeavyIdle)
        fingerprint = hash(fingerprint, heavyIdle)

        let heavyGround = SM64MarioHeldWalkingAction.update(input(.heavy))!
        precondition(heavyGround.animation?.animationID == 0xBB && heavyGround.groundStep?.result == SM64MarioGroundStepOutcome.none)
        fingerprint = hash(fingerprint, heavyGround)

        let heldDrop = SM64MarioHeldWalkingAction.update(input(.decelerating, drop: true))!
        precondition(heldDrop.intent == .walking && heldDrop.shouldDropHeldObject)
        fingerprint = hash(fingerprint, heldDrop)

        let heldAnalog = SM64MarioHeldWalkingAction.update(input(.decelerating, flags: [.nonzeroAnalog]))!
        precondition(heldAnalog.intent == .holdWalking && heldAnalog.action == SM64MarioActionID.holdWalking)
        fingerprint = hash(fingerprint, heldAnalog)

        let heldStopped = SM64MarioHeldWalkingAction.update(input(.decelerating, forwardVelocity: 0))!
        precondition(heldStopped.intent == .holdIdle && heldStopped.action == SM64MarioActionID.holdIdle)
        fingerprint = hash(fingerprint, heldStopped)

        let heldGround = SM64MarioHeldWalkingAction.update(input(.decelerating))!
        precondition(heldGround.intent == .continueGround && heldGround.animation?.animationID == 0x16)
        fingerprint = hash(fingerprint, heldGround)

        let heldReflect = SM64MarioHeldWalkingAction.update(input(
            .decelerating, forwardVelocity: 4, floorClass: .verySlippery,
            wall: SM64MarioGroundWallProbe(surfaceID: 2, normalX: 0, normalZ: 1)
        ))!
        precondition(heldReflect.reflectedBonk && heldReflect.particleDust)

        precondition(SM64MarioHeldWalkingAction.update(input(.light, intendedMagnitude: .infinity)) == nil)

        print(String(format: "marioHeldWalkingFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario held-walking smoke passed")
    }
}
