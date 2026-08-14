import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU8(_ initial: UInt64, _ value: UInt8) -> UInt64 {
    var hash = initial; hash ^= UInt64(value); hash &*= fnvPrime; return hash
}

private func hashU16(_ initial: UInt64, _ value: UInt16) -> UInt64 {
    var hash = initial
    for byte in 0..<2 { hash ^= UInt64((value >> UInt16(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 { hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashFloat(_ initial: UInt64, _ value: Float) -> UInt64 {
    hashU32(initial, value.bitPattern)
}

private func hashResult(_ initial: UInt64, _ result: SM64MarioWalkingActionResult) -> UInt64 {
    var hash = hashU8(initial, result.intent.rawValue)
    hash = hashU32(hash, result.action ?? UInt32.max)
    hash = hashU32(hash, result.actionArgument)
    hash = hashU16(hash, UInt16(bitPattern: result.faceYaw))
    hash = hashFloat(hash, result.forwardVelocity)
    hash = hashFloat(hash, result.velocity.x)
    hash = hashFloat(hash, result.velocity.y)
    hash = hashFloat(hash, result.velocity.z)
    hash = hashU16(hash, result.actionState)
    hash = hashU16(hash, result.actionTimer)
    hash = hashU16(hash, result.animationID ?? UInt16.max)
    hash = hashU32(hash, UInt32(bitPattern: result.animationAcceleration))
    hash = hashU8(hash, result.walkSound.rawValue)
    hash = hashU8(hash, result.wallSound.rawValue)
    hash = hashU8(hash, result.particleDust ? 1 : 0)
    hash = hashU8(hash, result.shouldDropHeldObject ? 1 : 0)
    hash = hashU8(hash, result.shouldRunLedgeClimbCheck ? 1 : 0)
    return hashU8(hash, result.shouldTiltBodyWalking ? 1 : 0)
}

private func baseInput(
    flags: SM64MarioInputFlags = [],
    terrainIsSlide: Bool = false,
    facingDownhill: Bool = false,
    actionState: UInt16 = 0,
    actionArgument: UInt32 = 0,
    faceYaw: Int16 = 0,
    intendedMagnitude: Float = 20,
    intendedYaw: Int16 = 0,
    forwardVelocity: Float = 12,
    stickMagnitude: Float = 0,
    floorNormalY: Float = 1,
    groundPosition: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
    groundVelocity: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 6),
    groundFloorHeight: Float = 0,
    quarterFloors: [SM64MarioGroundFloorProbe?]? = nil,
    wall: SM64MarioWallResponseProbe? = nil
) -> SM64MarioWalkingActionInput {
    let floor = SM64MarioGroundFloorProbe(surfaceID: 1, height: groundFloorHeight, normalY: 1)
    let probes = (quarterFloors ?? Array(repeating: floor, count: 4)).map {
        SM64MarioGroundQuarterProbe(
            floor: $0,
            ceilingHeight: 1000,
            waterLevel: 0,
            upperWall: nil
        )
    }
    return SM64MarioWalkingActionInput(
        input: flags,
        terrainIsSlide: terrainIsSlide,
        facingDownhill: facingDownhill,
        actionState: actionState,
        actionArgument: actionArgument,
        faceYaw: faceYaw,
        intendedMagnitude: intendedMagnitude,
        intendedYaw: intendedYaw,
        forwardVelocity: forwardVelocity,
        stickMagnitude: stickMagnitude,
        floorNormalY: floorNormalY,
        quicksandDepth: 0,
        floorIsSlow: false,
        responsiveCheat: false,
        cheatsEnabled: false,
        groundStep: SM64MarioGroundStepInput(
            position: groundPosition,
            velocity: groundVelocity,
            floor: floor,
            faceYaw: Int32(faceYaw),
            nativeStepScale: 1,
            ridingShell: false,
            terrainSoundAddend: 0x50000,
            quarterProbes: probes
        ),
        walkAnimation: SM64MarioWalkAnimationInput(
            intendedMagnitude: intendedMagnitude,
            forwardVelocity: forwardVelocity,
            quicksandDepth: 0,
            actionTimer: 0,
            animationPastFrame23: false,
            animationPastFrame1: false,
            animationPastFrame2: false,
            metalCap: false,
            walkingPitch: 0,
            runningPitch: 0x2000
        ),
        wallResponse: SM64MarioWallResponseInput(
            startPosition: groundPosition,
            position: groundPosition,
            velocity: groundVelocity,
            forwardVelocity: forwardVelocity,
            faceYaw: Int32(faceYaw),
            animationFrame: 10,
            animationPastFrame1: false,
            animationPastFrame2: false,
            terrainSoundAddend: 0x50000,
            floorSlopePitch: 0x1234,
            wall: wall
        )
    )
}

@main
enum SM64ModernMarioWalkingActionSmoke {
    static func main() {
        var fingerprint = fnvOffset

        let sliding = SM64MarioWalkingAction.update(baseInput(
            flags: [.aboveSlide], terrainIsSlide: true
        ))!
        precondition(sliding.intent == .beginSliding && sliding.action == SM64MarioActionID.beginSliding)
        fingerprint = hashResult(fingerprint, sliding)

        let wallBrake = SM64MarioWalkingAction.update(baseInput(
            flags: [.firstPerson], actionState: 1, actionArgument: 0xBEEF
        ))!
        precondition(wallBrake.intent == .standingAgainstWall && wallBrake.faceYaw == Int16(bitPattern: 0xBEEF))
        fingerprint = hashResult(fingerprint, wallBrake)

        let brake = SM64MarioWalkingAction.update(baseInput(flags: [.firstPerson], forwardVelocity: 20))!
        precondition(brake.intent == .braking && brake.action == SM64MarioActionID.braking)
        fingerprint = hashResult(fingerprint, brake)

        let decel = SM64MarioWalkingAction.update(baseInput(
            flags: [.firstPerson], forwardVelocity: 10
        ))!
        precondition(decel.intent == .decelerating && decel.action == SM64MarioActionID.decelerating)
        fingerprint = hashResult(fingerprint, decel)

        let jump = SM64MarioWalkingAction.update(baseInput(flags: [.aPressed]))!
        precondition(jump.intent == .jumpFromLanding && jump.action == nil)
        fingerprint = hashResult(fingerprint, jump)

        let dive = SM64MarioWalkingAction.update(baseInput(
            flags: [.bPressed], forwardVelocity: 30, stickMagnitude: 49
        ))!
        precondition(dive.intent == .dive && dive.action == SM64MarioActionID.dive && dive.velocity.y == 20)
        fingerprint = hashResult(fingerprint, dive)

        let punch = SM64MarioWalkingAction.update(baseInput(flags: [.bPressed]))!
        precondition(punch.intent == .movePunching && punch.action == SM64MarioActionID.movePunching)
        fingerprint = hashResult(fingerprint, punch)

        let turn = SM64MarioWalkingAction.update(baseInput(
            flags: [.nonzeroAnalog], intendedYaw: 0x6000, forwardVelocity: 20
        ))!
        precondition(turn.intent == .turningAround && turn.action == SM64MarioActionID.turningAround)
        fingerprint = hashResult(fingerprint, turn)

        let crouch = SM64MarioWalkingAction.update(baseInput(flags: [.zPressed]))!
        precondition(crouch.intent == .crouchSlide && crouch.action == SM64MarioActionID.crouchSlide)
        fingerprint = hashResult(fingerprint, crouch)

        let none = SM64MarioWalkingAction.update(baseInput(
            intendedMagnitude: 20, forwardVelocity: 4
        ))!
        precondition(none.intent == SM64MarioWalkingIntent.continueGround
            && none.groundStep?.result == SM64MarioGroundStepOutcome.none)
        fingerprint = hashResult(fingerprint, none)

        let leftGround = SM64MarioWalkingAction.update(baseInput(
            groundPosition: SM64ObjectVector3(x: 0, y: 200, z: 0),
            groundFloorHeight: 200,
            quarterFloors: Array(repeating: SM64MarioGroundFloorProbe(surfaceID: 2, height: 0, normalY: 1), count: 4)
        ))!
        precondition(leftGround.intent == .freefall && leftGround.animationID == SM64MarioWalkingAnimationID.generalFall)
        fingerprint = hashResult(fingerprint, leftGround)

        let hitWall = SM64MarioWalkingAction.update(baseInput(
            forwardVelocity: 20,
            quarterFloors: Array(repeating: SM64MarioGroundFloorProbe(surfaceID: 3, height: 0, normalY: 1), count: 4),
            wall: SM64MarioWallResponseProbe(normalX: -1, normalZ: 1)
        ).withWallOnAllQuarters())!
        precondition(hitWall.intent == SM64MarioWalkingIntent.continueGround
            && hitWall.wallResponse?.actionState == 1)
        fingerprint = hashResult(fingerprint, hitWall)

        precondition(SM64MarioWalkingAction.update(baseInput(intendedMagnitude: .infinity)) == nil)
        print(String(format: "marioWalkingActionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern Mario walking-action smoke passed")
    }
}

private extension SM64MarioWalkingActionInput {
    func withWallOnAllQuarters() -> SM64MarioWalkingActionInput {
        let wall = SM64MarioGroundWallProbe(surfaceID: 9, normalX: 0, normalZ: 1)
        let probes = groundStep.quarterProbes.map {
            SM64MarioGroundQuarterProbe(
                floor: $0.floor,
                ceilingHeight: $0.ceilingHeight,
                waterLevel: $0.waterLevel,
                upperWall: wall
            )
        }
        return SM64MarioWalkingActionInput(
            input: input,
            terrainIsSlide: terrainIsSlide,
            facingDownhill: facingDownhill,
            actionState: actionState,
            actionArgument: actionArgument,
            faceYaw: faceYaw,
            intendedMagnitude: intendedMagnitude,
            intendedYaw: intendedYaw,
            forwardVelocity: forwardVelocity,
            stickMagnitude: stickMagnitude,
            floorNormalY: floorNormalY,
            quicksandDepth: quicksandDepth,
            floorIsSlow: floorIsSlow,
            responsiveCheat: responsiveCheat,
            cheatsEnabled: cheatsEnabled,
            groundStep: SM64MarioGroundStepInput(
                position: groundStep.position,
                velocity: groundStep.velocity,
                floor: groundStep.floor,
                faceYaw: groundStep.faceYaw,
                nativeStepScale: groundStep.nativeStepScale,
                ridingShell: groundStep.ridingShell,
                terrainSoundAddend: groundStep.terrainSoundAddend,
                quarterProbes: probes
            ),
            walkAnimation: walkAnimation,
            wallResponse: wallResponse
        )
    }
}
