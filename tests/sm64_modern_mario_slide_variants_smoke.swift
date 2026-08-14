import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioSlideVariantResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.actionTimer)
    x = h16(x, r.animationID ?? UInt16.max)
    x = h8(x, r.particleDust ? 1 : 0)
    x = h8(x, r.verticalStar ? 1 : 0)
    x = h8(x, r.reflectedBonk ? 1 : 0)
    x = h8(x, r.shouldAlignWithFloor ? 1 : 0)
    x = h8(x, r.shouldTiltBody ? 1 : 0)
    x = h8(x, r.highSpeedHoohoo ? 1 : 0)
    x = h8(x, r.queueRumble ? 1 : 0)
    x = h8(x, r.shouldPlayLandingSound ? 1 : 0)
    x = h8(x, r.shouldGrabObject ? 1 : 0)
    x = h8(x, r.grabPositionLightObject ? 1 : 0)
    return h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
}

private func input(
    _ variant: SM64MarioSlideVariant,
    flags: SM64MarioInputFlags = [],
    timer: UInt16 = 0,
    forward: Float = 20,
    positionY: Float = 0,
    slippery: Bool = false,
    wall: SM64MarioGroundWallProbe? = nil,
    drop: Bool = false,
    animationAtEnd: Bool = false,
    grabbable: Bool = false,
    landingSoundAlreadyPlayed: Bool = false
) -> SM64MarioSlideVariantInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: wall
    ), count: 4)
    let body: SM64MarioSlideBody = variant == .holdButt ? .butt : .stomach
    let slide = SM64MarioSlideActionInput(
        body: body, input: flags, actionTimer: timer,
        floorClass: slippery ? .verySlippery : .defaultClass,
        floorIsSlope: false, floorIsSlippery: slippery,
        floorNormalX: 0, floorNormalY: 1, floorNormalZ: 0,
        intendedYaw: 0, intendedMagnitude: 0, faceYaw: 0, slideYaw: 0,
        forwardVelocity: forward, slideVelocityX: 0, slideVelocityZ: forward,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forward),
            floor: floor, faceYaw: 0, nativeStepScale: 1,
            ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
        ), wall: wall
    )
    return SM64MarioSlideVariantInput(
        variant: variant, slide: slide, dropInteraction: drop,
        animationAtEnd: animationAtEnd, interactObjectGrabbable: grabbable,
        landingSoundAlreadyPlayed: landingSoundAlreadyPlayed
    )
}

@main
enum SM64ModernMarioSlideVariantsSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let holdDrop = SM64MarioSlideVariants.update(input(.holdButt, drop: true))!
        precondition(holdDrop.intent == .dropToButtSlide && holdDrop.action == SM64MarioActionID.buttSlide)
        precondition(holdDrop.shouldTiltBody)
        fingerprint = hash(fingerprint, holdDrop)

        let holdJump = SM64MarioSlideVariants.update(input(.holdButt, flags: [.aPressed], timer: 5))!
        precondition(holdJump.intent == .jump && holdJump.action == SM64MarioActionID.holdJump)
        fingerprint = hash(fingerprint, holdJump)

        let holdStomach = SM64MarioSlideVariants.update(input(.holdStomach, drop: true))!
        precondition(holdStomach.intent == .dropToStomachSlide && holdStomach.action == SM64MarioActionID.stomachSlide)
        fingerprint = hash(fingerprint, holdStomach)

        let crouchLong = SM64MarioSlideVariants.update(input(.crouch, flags: [.aPressed], forward: 12))!
        precondition(crouchLong.intent == .longJump && crouchLong.action == SM64MarioActionID.longJump)
        fingerprint = hash(fingerprint, crouchLong)

        let crouchPunch = SM64MarioSlideVariants.update(input(.crouch, flags: [.bPressed], forward: 4))!
        precondition(crouchPunch.intent == .movePunching && crouchPunch.actionArgument == 9)
        fingerprint = hash(fingerprint, crouchPunch)

        let kickWall = SM64MarioSlideVariants.update(input(
            .slideKick, forward: 20,
            wall: SM64MarioGroundWallProbe(surfaceID: 2, normalX: 0, normalZ: 1)
        ))!
        precondition(kickWall.intent == .backwardGroundKnockback && kickWall.verticalStar && kickWall.reflectedBonk)
        fingerprint = hash(fingerprint, kickWall)

        let diveRoll = SM64MarioSlideVariants.update(input(.dive, flags: [.bPressed], forward: 8))!
        precondition(diveRoll.intent == .rollout && diveRoll.action == SM64MarioActionID.forwardRollout)
        fingerprint = hash(fingerprint, diveRoll)

        let diveGrab = SM64MarioSlideVariants.update(input(
            .dive, forward: 12, grabbable: true, landingSoundAlreadyPlayed: false
        ))!
        precondition(diveGrab.intent == .grabbedObject && diveGrab.shouldGrabObject && diveGrab.grabPositionLightObject)
        precondition(diveGrab.shouldPlayLandingSound)
        fingerprint = hash(fingerprint, diveGrab)

        let diveGround = SM64MarioSlideVariants.update(input(.dive, forward: 20))!
        precondition(diveGround.intent == .continueGround && diveGround.animationID == 0x88)
        fingerprint = hash(fingerprint, diveGround)

        print(String(format: "marioSlideVariantsFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario slide variants smoke passed")
    }
}
