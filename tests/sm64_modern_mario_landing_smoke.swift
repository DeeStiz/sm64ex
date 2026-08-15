import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioLandingActionResult) -> UInt64 {
    var x = h8(h, r.variant.rawValue)
    x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, r.actionTimer)
    x = h8(x, r.doubleJumpTimer)
    x = h16(x, r.animationID ?? UInt16.max)
    x = h8(x, r.particleDust ? 1 : 0)
    x = h8(x, r.shouldPlayLandingSound ? 1 : 0)
    x = h8(x, r.shouldClearAPressed ? 1 : 0)
    x = h8(x, r.shouldDropHeldObject ? 1 : 0)
    x = h8(x, r.shouldFlipSideFlipYaw ? 1 : 0)
    return h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
}

private func input(
    _ variant: SM64MarioLandingVariant,
    flags: SM64MarioInputFlags = [],
    actionTimer: UInt16 = 0,
    doubleJumpTimer: UInt8 = 5,
    quicksandDepth: Float = 0,
    heldObjectPresent: Bool = false,
    dropInteraction: Bool = false,
    floorIsSteep: Bool = false,
    floorNormalY: Float = 1,
    floorClass: SM64MarioFloorClass = .defaultClass,
    terrainIsSlide: Bool = false,
    facingDownhill: Bool = false,
    floorIsQuicksand: Bool = false,
    longJumpIsSlow: Bool = false,
    wingCap: Bool = false,
    squishTimer: UInt8 = 0,
    previousAction: UInt32 = 0,
    forwardVelocity: Float = 10,
    faceYaw: Int16 = 0,
    wall: SM64MarioGroundWallProbe? = nil,
    positionY: Float = 0
) -> SM64MarioLandingActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: floorNormalY)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: wall
    ), count: 4)
    return SM64MarioLandingActionInput(
        variant: variant, input: flags, actionTimer: actionTimer,
        doubleJumpTimer: doubleJumpTimer, quicksandDepth: quicksandDepth,
        heldObjectPresent: heldObjectPresent, dropInteraction: dropInteraction,
        floorIsSteep: floorIsSteep, floorNormalY: floorNormalY,
        floorClass: floorClass, terrainIsSlide: terrainIsSlide,
        facingDownhill: facingDownhill, floorIsQuicksand: floorIsQuicksand,
        longJumpIsSlow: longJumpIsSlow, wingCap: wingCap,
        squishTimer: squishTimer, previousAction: previousAction,
        forwardVelocity: forwardVelocity, faceYaw: faceYaw,
        floorNormalX: 0, floorNormalZ: 0, floorAngle: 0,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor, faceYaw: Int32(faceYaw), nativeStepScale: 1,
            ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
        )
    )
}

@main
enum SM64ModernMarioLandingSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let normal = SM64MarioLandingAction.update(input(.jump))!
        precondition(normal.intent == .continueGround && normal.actionTimer == 1)
        precondition(normal.animationID == 0x4E && normal.shouldPlayLandingSound)
        fingerprint = hash(fingerprint, normal)

        let slide = SM64MarioLandingAction.update(input(
            .jump, flags: [.aboveSlide], terrainIsSlide: true
        ))!
        precondition(slide.intent == .beginSliding && slide.action == SM64MarioActionID.beginSliding)
        fingerprint = hash(fingerprint, slide)

        let firstPerson = SM64MarioLandingAction.update(input(
            .jump, flags: [.firstPerson]
        ))!
        precondition(firstPerson.intent == .firstPersonEnd && firstPerson.action == SM64MarioActionID.jumpLandStop)
        fingerprint = hash(fingerprint, firstPerson)

        let ended = SM64MarioLandingAction.update(input(.jump, actionTimer: 3))!
        precondition(ended.intent == .animationEnd && ended.actionTimer == 4)
        fingerprint = hash(fingerprint, ended)

        let steep = SM64MarioLandingAction.update(input(
            .jump, flags: [.aPressed], floorIsSteep: true
        ))!
        precondition(steep.intent == .aPressed && steep.action == SM64MarioActionID.steepJump)
        precondition(steep.shouldDropHeldObject)
        fingerprint = hash(fingerprint, steep)

        let quicksand = SM64MarioLandingAction.update(input(
            .jump, flags: [.aPressed], quicksandDepth: 12,
            heldObjectPresent: true
        ))!
        precondition(quicksand.action == SM64MarioActionID.holdQuicksandJumpLand)
        fingerprint = hash(fingerprint, quicksand)

        let double = SM64MarioLandingAction.update(input(.jump, flags: [.aPressed]))!
        precondition(double.action == SM64MarioActionID.doubleJump)
        fingerprint = hash(fingerprint, double)

        let offFloor = SM64MarioLandingAction.update(input(.freefall, flags: [.offFloor]))!
        precondition(offFloor.intent == .offFloor && offFloor.action == SM64MarioActionID.freefall)
        fingerprint = hash(fingerprint, offFloor)

        let heldDrop = SM64MarioLandingAction.update(input(
            .holdJump, heldObjectPresent: true, dropInteraction: true
        ))!
        precondition(heldDrop.intent == .dropHeldObject && heldDrop.shouldDropHeldObject)
        fingerprint = hash(fingerprint, heldDrop)

        let longJump = SM64MarioLandingAction.update(input(
            .longJump, flags: [.aPressed], longJumpIsSlow: true
        ))!
        precondition(longJump.shouldClearAPressed && longJump.intent == .continueGround)
        precondition(longJump.animationID == 0x12)
        fingerprint = hash(fingerprint, longJump)

        let triple = SM64MarioLandingAction.update(input(
            .doubleJump, flags: [.aPressed], forwardVelocity: 24
        ))!
        precondition(triple.action == SM64MarioActionID.tripleJump)
        fingerprint = hash(fingerprint, triple)

        let sideFlip = SM64MarioLandingAction.update(input(
            .sideFlip, forwardVelocity: 20,
            wall: SM64MarioGroundWallProbe(surfaceID: 2, normalX: 0, normalZ: 1)
        ))!
        precondition(sideFlip.intent == .continueGround && !sideFlip.shouldFlipSideFlipYaw)
        fingerprint = hash(fingerprint, sideFlip)

        let quicksandDepth = SM64MarioLandingAction.update(input(
            .jump, actionTimer: 1, floorIsQuicksand: true
        ))!
        precondition(quicksandDepth.quicksandDepth > 0)
        fingerprint = hash(fingerprint, quicksandDepth)

        precondition(SM64MarioLandingAction.update(input(.jump, forwardVelocity: .infinity)) == nil)

        print(String(format: "marioLandingFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario landing smoke passed")
    }
}
