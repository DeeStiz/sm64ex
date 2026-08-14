import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioShellGroundActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, UInt16(bitPattern: r.faceYaw))
    x = h16(x, r.animationID ?? UInt16.max)
    x = h8(x, r.particleVerticalStar ? 1 : 0)
    x = h8(x, r.shouldStopRiding ? 1 : 0)
    x = h8(x, r.shouldTiltBody ? 1 : 0)
    x = h8(x, r.shouldResetRumble ? 1 : 0)
    x = h8(x, r.sound?.rawValue ?? UInt8.max)
    x = h32(x, r.soundAddend)
    return h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
}

private func input(
    flags: SM64MarioInputFlags = [],
    actionArgument: UInt32 = 1,
    intendedMagnitude: Float = 20,
    intendedYaw: Int16 = 0,
    faceYaw: Int16 = 0,
    forwardVelocity: Float = 4,
    floorIsSlow: Bool = false,
    floorIsBurning: Bool = false,
    terrainSoundAddend: UInt32 = 3,
    positionY: Float = 0,
    wall: SM64MarioGroundWallProbe? = nil
) -> SM64MarioShellGroundActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: wall
    ), count: 4)
    return SM64MarioShellGroundActionInput(
        input: flags, actionArgument: actionArgument,
        intendedMagnitude: intendedMagnitude, intendedYaw: intendedYaw,
        faceYaw: faceYaw, forwardVelocity: forwardVelocity,
        floorNormalY: 1, floorIsSlow: floorIsSlow,
        floorIsBurning: floorIsBurning, terrainSoundAddend: terrainSoundAddend,
        metalCap: false,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor, faceYaw: Int32(faceYaw), nativeStepScale: 1,
            ridingShell: true, terrainSoundAddend: terrainSoundAddend,
            quarterProbes: probes
        ), slope: nil
    )
}

@main
enum SM64ModernMarioShellGroundSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let jump = SM64MarioShellGroundAction.update(input(flags: [.aPressed]))!
        precondition(jump.intent == .shellJump && jump.action == SM64MarioActionID.ridingShellJump)
        fingerprint = hash(fingerprint, jump)

        let slide = SM64MarioShellGroundAction.update(input(flags: [.zPressed], forwardVelocity: 10))!
        precondition(slide.intent == .crouchSlide && slide.action == SM64MarioActionID.crouchSlide)
        precondition(slide.forwardVelocity == 24 && slide.shouldStopRiding)
        fingerprint = hash(fingerprint, slide)

        let start = SM64MarioShellGroundAction.update(input(actionArgument: 0))!
        precondition(start.intent == .continueGround && start.animationID == 0x6D)
        precondition(start.groundStep?.result == SM64MarioGroundStepOutcome.none)
        fingerprint = hash(fingerprint, start)

        let lava = SM64MarioShellGroundAction.update(input(floorIsBurning: true))!
        precondition(lava.animationID == 0x47 && lava.sound == .lava)
        fingerprint = hash(fingerprint, lava)

        let fall = SM64MarioShellGroundAction.update(input(positionY: 200))!
        precondition(fall.intent == .shellFall && fall.action == SM64MarioActionID.ridingShellFall)
        fingerprint = hash(fingerprint, fall)

        let wall = SM64MarioShellGroundAction.update(input(
            wall: SM64MarioGroundWallProbe(surfaceID: 2, normalX: 0, normalZ: 1)
        ))!
        precondition(wall.intent == .backwardGroundKnockback && wall.shouldStopRiding)
        precondition(wall.particleVerticalStar && wall.sound == .bonk)
        fingerprint = hash(fingerprint, wall)

        let slow = SM64MarioShellGroundAction.update(input(intendedMagnitude: 10, floorIsSlow: true))!
        precondition(slow.forwardVelocity <= 48)
        fingerprint = hash(fingerprint, slow)

        precondition(SM64MarioShellGroundAction.update(input(intendedMagnitude: .infinity)) == nil)

        print(String(format: "marioShellGroundFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario shell-ground smoke passed")
    }
}
