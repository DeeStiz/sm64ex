import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ r: SM64MarioCrawlingActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max)
    x = h32(x, r.actionArgument)
    x = h16(x, UInt16(bitPattern: r.faceYaw))
    x = h32(x, UInt32(bitPattern: r.animationAcceleration))
    x = h16(x, r.animationID ?? UInt16.max)
    x = h8(x, r.shouldAlignWithFloor ? 1 : 0)
    x = h8(x, r.shouldPlayStepSound ? 1 : 0)
    return h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
}

private func input(
    flags: SM64MarioInputFlags = [.zDown],
    terrainIsSlide: Bool = false,
    facingDownhill: Bool = false,
    intendedMagnitude: Float = 20,
    intendedYaw: Int16 = 0,
    faceYaw: Int16 = 0,
    forwardVelocity: Float = 4,
    stickMagnitude: Float = 0,
    positionY: Float = 0,
    wall: SM64MarioGroundWallProbe? = nil
) -> SM64MarioCrawlingActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: wall
    ), count: 4)
    return SM64MarioCrawlingActionInput(
        input: flags, terrainIsSlide: terrainIsSlide, facingDownhill: facingDownhill,
        intendedMagnitude: intendedMagnitude, intendedYaw: intendedYaw,
        faceYaw: faceYaw, forwardVelocity: forwardVelocity,
        stickMagnitude: stickMagnitude, quicksandDepth: 0,
        floorNormalY: 1, floorIsSlow: false, responsiveCheat: false,
        cheatsEnabled: false,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor, faceYaw: Int32(faceYaw), nativeStepScale: 1,
            ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
        )
    )
}

@main
enum SM64ModernMarioCrawlingSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let slide = SM64MarioCrawlingAction.update(input(flags: [.zDown, .aboveSlide], terrainIsSlide: true))!
        precondition(slide.intent == .beginSliding && slide.action == SM64MarioActionID.beginSliding)
        fingerprint = hash(fingerprint, slide)

        let firstPerson = SM64MarioCrawlingAction.update(input(flags: [.zDown, .firstPerson]))!
        precondition(firstPerson.intent == .stopCrawling && firstPerson.action == SM64MarioActionID.stopCrawling)
        fingerprint = hash(fingerprint, firstPerson)

        let jump = SM64MarioCrawlingAction.update(input(flags: [.zDown, .aPressed]))!
        precondition(jump.intent == .jump && jump.action == SM64MarioActionID.jump)
        fingerprint = hash(fingerprint, jump)

        let dive = SM64MarioCrawlingAction.update(input(
            flags: [.zDown, .bPressed], forwardVelocity: 30, stickMagnitude: 60
        ))!
        precondition(dive.intent == .dive && dive.action == SM64MarioActionID.dive && dive.velocity.y == 20)
        fingerprint = hash(fingerprint, dive)

        let punch = SM64MarioCrawlingAction.update(input(flags: [.zDown, .bPressed], forwardVelocity: 10))!
        precondition(punch.intent == .movePunching && punch.action == SM64MarioActionID.movePunching)
        fingerprint = hash(fingerprint, punch)

        let unknown = SM64MarioCrawlingAction.update(input(flags: [.zDown, .unknown5]))!
        precondition(unknown.intent == .stopCrawling)
        fingerprint = hash(fingerprint, unknown)

        let released = SM64MarioCrawlingAction.update(input(flags: []))!
        precondition(released.intent == .stopCrawling)
        fingerprint = hash(fingerprint, released)

        let ground = SM64MarioCrawlingAction.update(input())!
        precondition(ground.intent == .continueGround && ground.animationID == 0x99)
        precondition(ground.shouldAlignWithFloor && ground.shouldPlayStepSound)
        fingerprint = hash(fingerprint, ground)

        let wall = SM64MarioCrawlingAction.update(input(
            forwardVelocity: 20,
            wall: SM64MarioGroundWallProbe(surfaceID: 2, normalX: 0, normalZ: 1)
        ))!
        precondition(wall.intent == .continueGround && wall.forwardVelocity == 10)
        precondition(wall.shouldAlignWithFloor && wall.groundStep?.result == .hitWall)
        fingerprint = hash(fingerprint, wall)

        let air = SM64MarioCrawlingAction.update(input(positionY: 200))!
        precondition(air.intent == .freefall && air.action == SM64MarioActionID.freefall)
        fingerprint = hash(fingerprint, air)

        precondition(SM64MarioCrawlingAction.update(input(intendedMagnitude: .infinity)) == nil)

        print(String(format: "marioCrawlingFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario crawling smoke passed")
    }
}
