import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }

private func hashBraking(_ h: UInt64, _ r: SM64MarioBrakingActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max); x = h32(x, r.actionArgument)
    x = h16(x, UInt16(bitPattern: r.faceYaw)); x = hf(x, r.forwardVelocity)
    x = hf(x, r.velocity.x); x = hf(x, r.velocity.y); x = hf(x, r.velocity.z)
    x = h8(x, r.slope == nil ? 0 : 1)
    if let slope = r.slope { x = hf(x, slope.forwardVelocity); x = hf(x, slope.velocity.x); x = hf(x, slope.velocity.z) }
    x = h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
    x = h16(x, r.animationID ?? UInt16.max)
    x = h8(x, r.particleDust ? 1 : 0); return h8(x, r.reflectedBonk ? 1 : 0)
}

private func hashDecelerating(_ h: UInt64, _ r: SM64MarioDeceleratingActionResult) -> UInt64 {
    var x = h8(h, r.intent.rawValue)
    x = h32(x, r.action ?? UInt32.max); x = h32(x, r.actionArgument)
    x = h16(x, UInt16(bitPattern: r.faceYaw)); x = hf(x, r.forwardVelocity)
    x = hf(x, r.velocity.x); x = hf(x, r.velocity.y); x = hf(x, r.velocity.z)
    x = h8(x, r.groundStep?.result.rawValue ?? UInt8.max)
    x = h16(x, r.animationID ?? UInt16.max)
    x = h32(x, UInt32(bitPattern: r.animationAcceleration))
    x = h8(x, r.particleDust ? 1 : 0); return h8(x, r.reflectedBonk ? 1 : 0)
}

private func groundInput(
    velocity: SM64ObjectVector3,
    wall: SM64MarioGroundWallProbe? = nil
) -> SM64MarioGroundStepInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: 0, normalY: 1)
    let probes = Array(repeating: SM64MarioGroundQuarterProbe(
        floor: floor, ceilingHeight: 1000, waterLevel: 0, upperWall: wall
    ), count: 4)
    return SM64MarioGroundStepInput(
        position: .zero, velocity: velocity, floor: floor, faceYaw: 0,
        nativeStepScale: 1, ridingShell: false, terrainSoundAddend: 0,
        quarterProbes: probes
    )
}

private func brakingInput(
    input: SM64MarioInputFlags = [],
    floorClass: SM64MarioFloorClass = .defaultClass,
    forwardVelocity: Float = 12,
    wall: SM64MarioGroundWallProbe? = nil
) -> SM64MarioBrakingActionInput {
    SM64MarioBrakingActionInput(
        input: input, terrainIsSlide: false, facingDownhill: false,
        floorClass: floorClass, floorNormalX: 0, floorNormalY: 1,
        floorNormalZ: 0, floorAngle: 0, faceYaw: 0,
        forwardVelocity: forwardVelocity,
        groundStep: groundInput(velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity), wall: wall)
    )
}

private func deceleratingInput(
    input: SM64MarioInputFlags = [],
    floorClass: SM64MarioFloorClass = .defaultClass,
    forwardVelocity: Float = 3,
    stickMagnitude: Float = 0,
    wall: SM64MarioGroundWallProbe? = nil,
    landingJump: SM64MarioLandingJumpInput? = nil
) -> SM64MarioDeceleratingActionInput {
    SM64MarioDeceleratingActionInput(
        input: input, terrainIsSlide: false, facingDownhill: false,
        floorClass: floorClass, faceYaw: 0, forwardVelocity: forwardVelocity,
        stickMagnitude: stickMagnitude, velocityY: 0, landingJump: landingJump,
        groundStep: groundInput(velocity: SM64ObjectVector3(x: 0, y: 0, z: forwardVelocity), wall: wall)
    )
}

@main
enum SM64ModernMarioBrakingDeceleratingSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let braking = SM64MarioBrakingAction.update(brakingInput())!
        precondition(braking.intent == .continueGround && braking.forwardVelocity == 8)
        precondition(braking.animationID == 0x0F && braking.particleDust)
        fingerprint = hashBraking(fingerprint, braking)

        let brakingStop = SM64MarioBrakingAction.update(brakingInput(forwardVelocity: 3))!
        precondition(brakingStop.intent == .brakingStop && brakingStop.action == SM64MarioActionID.brakingStop)
        fingerprint = hashBraking(fingerprint, brakingStop)

        let brakingPunch = SM64MarioBrakingAction.update(brakingInput(input: [.bPressed]))!
        precondition(brakingPunch.intent == .movePunching && brakingPunch.action == SM64MarioActionID.movePunching)
        fingerprint = hashBraking(fingerprint, brakingPunch)

        let brakingBonk = SM64MarioBrakingAction.update(brakingInput(
            forwardVelocity: 24,
            wall: SM64MarioGroundWallProbe(surfaceID: 2, normalX: 0, normalZ: 1)
        ))!
        precondition(brakingBonk.intent == .backwardGroundKnockback && brakingBonk.reflectedBonk)
        fingerprint = hashBraking(fingerprint, brakingBonk)

        let decelerating = SM64MarioDeceleratingAction.update(deceleratingInput())!
        precondition(decelerating.intent == .continueGround && decelerating.forwardVelocity == 2)
        precondition(decelerating.animationID == 0x48 && decelerating.animationAcceleration == 0x8000)
        fingerprint = hashDecelerating(fingerprint, decelerating)

        let idle = SM64MarioDeceleratingAction.update(deceleratingInput(forwardVelocity: 1))!
        precondition(idle.intent == .idle && idle.action == SM64MarioActionID.idle)
        fingerprint = hashDecelerating(fingerprint, idle)

        let slippery = SM64MarioDeceleratingAction.update(deceleratingInput(
            floorClass: .verySlippery
        ))!
        precondition(slippery.animationID == 0xC3 && slippery.particleDust)
        fingerprint = hashDecelerating(fingerprint, slippery)

        let dive = SM64MarioDeceleratingAction.update(deceleratingInput(
            input: [.bPressed], forwardVelocity: 30, stickMagnitude: 49
        ))!
        precondition(dive.intent == .dive && dive.action == SM64MarioActionID.dive && dive.velocity.y == 20)
        fingerprint = hashDecelerating(fingerprint, dive)

        let jump = SM64MarioDeceleratingAction.update(deceleratingInput(
            input: [.aPressed], landingJump: SM64MarioLandingJumpInput(
                quicksandDepth: 0, heldObjectPresent: false, floorIsSteep: false,
                doubleJumpTimer: 0, squishTimer: 0, previousAction: SM64MarioActionID.idle,
                wingCap: false, forwardVelocity: 3
            )
        ))!
        precondition(jump.intent == .jump && jump.action == SM64MarioActionID.jump)
        fingerprint = hashDecelerating(fingerprint, jump)

        let wall = SM64MarioDeceleratingAction.update(deceleratingInput(
            forwardVelocity: 3,
            wall: SM64MarioGroundWallProbe(surfaceID: 3, normalX: 0, normalZ: 1)
        ))!
        precondition(wall.groundStep?.result == .hitWall && wall.forwardVelocity == 0)
        fingerprint = hashDecelerating(fingerprint, wall)

        let slipperyWall = SM64MarioDeceleratingAction.update(deceleratingInput(
            floorClass: .verySlippery, forwardVelocity: 3,
            wall: SM64MarioGroundWallProbe(surfaceID: 4, normalX: 0, normalZ: 1)
        ))!
        precondition(slipperyWall.reflectedBonk && slipperyWall.forwardVelocity == -2)
        fingerprint = hashDecelerating(fingerprint, slipperyWall)

        print(String(format: "marioBrakingDeceleratingFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario braking/decelerating smoke passed")
    }
}
