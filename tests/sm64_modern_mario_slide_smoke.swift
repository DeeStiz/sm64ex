import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }

private func hash(_ h: UInt64, _ r: SM64MarioSlideActionResult) -> UInt64 {
    var x = h8(h, r.body.rawValue); x = h8(x, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max); x = h32(x, r.actionArgument); x = h16(x, r.actionTimer)
    x = h16(x, UInt16(bitPattern: r.faceYaw)); x = h16(x, UInt16(bitPattern: r.slideYaw))
    x = hf(x, r.forwardVelocity); x = hf(x, r.slideVelocityX); x = hf(x, r.slideVelocityZ)
    x = hf(x, r.velocity.x); x = hf(x, r.velocity.y); x = hf(x, r.velocity.z)
    if let slide = r.sliding {
        x = h8(x, 1); x = h8(x, slide.stopped ? 1 : 0)
        x = h16(x, UInt16(bitPattern: slide.faceYaw)); x = h16(x, UInt16(bitPattern: slide.slideYaw))
        x = hf(x, slide.forwardVelocity); x = hf(x, slide.slideVelocityX); x = hf(x, slide.slideVelocityZ)
    } else { x = h8(x, 0) }
    x = h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
    x = h16(x, r.animationID ?? UInt16.max)
    x = h8(x, r.particleDust ? 1 : 0); x = h8(x, r.verticalStar ? 1 : 0)
    x = h8(x, r.reflectedBonk ? 1 : 0); x = h8(x, r.shouldAlignWithFloor ? 1 : 0)
    x = h8(x, r.shouldTiltBody ? 1 : 0); return h8(x, r.highSpeedHoohoo ? 1 : 0)
}

private func input(
    body: SM64MarioSlideBody = .butt,
    actionTimer: UInt16 = 0,
    flags: SM64MarioInputFlags = [],
    floorClass: SM64MarioFloorClass = .defaultClass,
    floorIsSlippery: Bool = false,
    forwardVelocity: Float = 10,
    positionY: Float = 0,
    wall: SM64MarioGroundWallProbe? = nil
) -> SM64MarioSlideActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: wall
    ), count: 4)
    return SM64MarioSlideActionInput(
        body: body, input: flags, actionTimer: actionTimer,
        floorClass: floorClass, floorIsSlope: false, floorIsSlippery: floorIsSlippery,
        floorNormalX: 0, floorNormalY: 1, floorNormalZ: 0,
        intendedYaw: 0, intendedMagnitude: 0, faceYaw: 0, slideYaw: 0,
        forwardVelocity: forwardVelocity, slideVelocityX: 0, slideVelocityZ: forwardVelocity,
        groundStep: SM64MarioGroundStepInput(
            position: SM64ObjectVector3(x: 0, y: positionY, z: 0),
            velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity),
            floor: floor, faceYaw: 0, nativeStepScale: 1,
            ridingShell: false, terrainSoundAddend: 0, quarterProbes: probes
        ), wall: wall
    )
}

@main
enum SM64ModernMarioSlideSmoke {
    static func main() {
        var fingerprint = fnvOffset
        let butt = SM64MarioSlideAction.update(input())!
        precondition(butt.intent == .continueGround && butt.actionTimer == 1)
        precondition(butt.animationID == 0x91 && butt.particleDust)
        fingerprint = hash(fingerprint, butt)

        let jump = SM64MarioSlideAction.update(input(actionTimer: 5, flags: [.aPressed]))!
        precondition(jump.intent == .jump && jump.action == SM64MarioActionID.jump)
        fingerprint = hash(fingerprint, jump)

        let rollout = SM64MarioSlideAction.update(input(
            body: .stomach, actionTimer: 5, flags: [.bPressed], forwardVelocity: -10
        ))!
        precondition(rollout.intent == .rollout && rollout.action == SM64MarioActionID.backwardRollout)
        fingerprint = hash(fingerprint, rollout)

        let stop = SM64MarioSlideAction.update(input(forwardVelocity: 2))!
        precondition(stop.intent == .stopped && stop.action == SM64MarioActionID.buttSlideStop)
        fingerprint = hash(fingerprint, stop)

        let bonk = SM64MarioSlideAction.update(input(
            forwardVelocity: 20,
            wall: SM64MarioGroundWallProbe(surfaceID: 2, normalX: 0, normalZ: 1)
        ))!
        precondition(bonk.intent == .groundBonk && bonk.reflectedBonk && bonk.verticalStar)
        fingerprint = hash(fingerprint, bonk)

        let air = SM64MarioSlideAction.update(input(forwardVelocity: 20, positionY: 200))!
        precondition(air.intent == .freefall && air.action == SM64MarioActionID.buttSlideAir)
        fingerprint = hash(fingerprint, air)

        let slipperyWall = SM64MarioSlideAction.update(input(
            floorClass: .verySlippery, floorIsSlippery: true, forwardVelocity: 10,
            wall: SM64MarioGroundWallProbe(surfaceID: 3, normalX: 0, normalZ: 1)
        ))!
        precondition(slipperyWall.intent == .continueGround && slipperyWall.shouldAlignWithFloor)
        fingerprint = hash(fingerprint, slipperyWall)

        print(String(format: "marioSlideFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario slide smoke passed")
    }
}
