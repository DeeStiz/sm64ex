import Foundation

/// The action chosen by the `act_walking` decision boundary. A nil action is
/// reserved for the landing-jump helper: that helper still owns the previous
/// action, double-jump timer, steep-floor, and held-object branches.
enum SM64MarioWalkingIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case beginSliding = 1
    case standingAgainstWall = 2
    case braking = 3
    case decelerating = 4
    case jumpFromLanding = 5
    case dive = 6
    case movePunching = 7
    case turningAround = 8
    case crouchSlide = 9
    case freefall = 10
}

struct SM64MarioWalkingActionInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let terrainIsSlide: Bool
    let facingDownhill: Bool
    let actionState: UInt16
    let actionArgument: UInt32
    let faceYaw: Int16
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let forwardVelocity: Float
    let stickMagnitude: Float
    let floorNormalY: Float
    let quicksandDepth: Float
    let floorIsSlow: Bool
    let responsiveCheat: Bool
    let cheatsEnabled: Bool
    /// The collision caller supplies velocity after its slope-acceleration
    /// phase. `update_walking_speed` is still composed here for the forward
    /// speed/yaw state; slope acceleration remains a separate collision seam.
    let groundStep: SM64MarioGroundStepInput
    let walkAnimation: SM64MarioWalkAnimationInput
    let wallResponse: SM64MarioWallResponseInput
    let slope: SM64MarioSlopeInput?
}

struct SM64MarioWalkingActionResult: Equatable, Sendable {
    let intent: SM64MarioWalkingIntent
    let action: UInt32?
    let actionArgument: UInt32
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let actionState: UInt16
    let actionTimer: UInt16
    let animationID: UInt16?
    let animationAcceleration: Int32
    let walkSound: SM64MarioWalkSoundKind
    let wallSound: SM64MarioWallSoundKind
    let groundStep: SM64MarioGroundStepResult?
    let wallResponse: SM64MarioWallResponseResult?
    let particleDust: Bool
    let shouldDropHeldObject: Bool
    let shouldRunLedgeClimbCheck: Bool
    let shouldTiltBodyWalking: Bool
}

/// Value composition of the C `act_walking` body. The collision snapshots and
/// animation/effect inputs are immutable; owner-thread code applies the
/// returned action, transform, particle, and audio intents afterward.
enum SM64MarioWalkingAction {
    private static let downhillFloorNormal: Float = 0.17364818

    static func update(_ input: SM64MarioWalkingActionInput) -> SM64MarioWalkingActionResult? {
        guard input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.stickMagnitude.isFinite,
              input.floorNormalY.isFinite,
              input.quicksandDepth.isFinite else {
            return nil
        }

        let drop = true // act_walking always starts with mario_drop_held_object.
        let initialSlope: SM64MarioSlopeResult?
        if let slopeInput = input.slope {
            guard let slope = SM64MarioSlope.update(slopeInput) else { return nil }
            initialSlope = slope
        } else {
            initialSlope = nil
        }
        let facingDownhill = initialSlope?.facingDownhill ?? input.facingDownhill

        if input.input.contains(.aboveSlide),
           input.terrainIsSlide || input.forwardVelocity <= -1 || facingDownhill {
            return transition(
                intent: .beginSliding,
                action: SM64MarioActionID.beginSliding,
                argument: 0,
                faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity,
                velocity: input.groundStep.velocity,
                drop: drop
            )
        }

        if input.input.contains(.firstPerson) {
            return beginBraking(input, drop: drop)
        }

        if input.input.contains(.aPressed) {
            // `set_jump_from_landing` is intentionally its own next seam. It
            // depends on previous action, double-jump timer, caps, quicksand,
            // and steep-floor state that this boundary does not own yet.
            return transition(
                intent: .jumpFromLanding,
                action: nil,
                argument: 0,
                faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity,
                velocity: input.groundStep.velocity,
                drop: drop
            )
        }

        if input.input.contains(.bPressed) {
            if input.forwardVelocity >= 29 && input.stickMagnitude > 48 {
                var velocity = input.groundStep.velocity
                velocity.y = 20
                return transition(
                    intent: .dive,
                    action: SM64MarioActionID.dive,
                    argument: 1,
                    faceYaw: input.faceYaw,
                    forwardVelocity: input.forwardVelocity,
                    velocity: velocity,
                    drop: drop
                )
            }
            return transition(
                intent: .movePunching,
                action: SM64MarioActionID.movePunching,
                argument: 0,
                faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity,
                velocity: input.groundStep.velocity,
                drop: drop
            )
        }

        if input.input.contains(.unknown5) {
            return beginBraking(input, drop: drop)
        }

        if analogStickHeldBack(intendedYaw: input.intendedYaw, faceYaw: input.faceYaw),
           input.forwardVelocity >= 16 {
            return transition(
                intent: .turningAround,
                action: SM64MarioActionID.turningAround,
                argument: 0,
                faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity,
                velocity: input.groundStep.velocity,
                drop: drop
            )
        }

        if input.input.contains(.zPressed) {
            return transition(
                intent: .crouchSlide,
                action: SM64MarioActionID.crouchSlide,
                argument: 0,
                faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity,
                velocity: input.groundStep.velocity,
                drop: drop
            )
        }

        guard let speed = SM64MarioGroundSpeed.update(
            SM64MarioGroundSpeedInput(
                intendedMagnitude: input.intendedMagnitude,
                forwardVelocity: input.forwardVelocity,
                quicksandDepth: input.quicksandDepth,
                floorNormalY: input.floorNormalY,
                intendedYaw: Int32(input.intendedYaw),
                faceYaw: Int32(input.faceYaw),
                floorIsSlow: input.floorIsSlow,
                responsiveCheat: input.responsiveCheat,
                cheatsEnabled: input.cheatsEnabled
            )
        ) else {
            return nil
        }

        let appliedSlope: SM64MarioSlopeResult?
        if let slopeInput = input.slope {
            let updatedSlopeInput = SM64MarioSlopeInput(
                floorClass: slopeInput.floorClass,
                terrainIsSlide: slopeInput.terrainIsSlide,
                floorNormalX: slopeInput.floorNormalX,
                floorNormalY: slopeInput.floorNormalY,
                floorNormalZ: slopeInput.floorNormalZ,
                floorAngle: slopeInput.floorAngle,
                faceYaw: speed.faceYaw,
                forwardVelocity: speed.forwardVelocity,
                action: slopeInput.action
            )
            guard let slope = SM64MarioSlope.update(updatedSlopeInput) else { return nil }
            appliedSlope = slope
        } else {
            appliedSlope = nil
        }
        let finalForwardVelocity = appliedSlope?.forwardVelocity ?? speed.forwardVelocity
        let finalFaceYaw = appliedSlope?.slideYaw ?? speed.faceYaw
        let groundVelocity = appliedSlope?.velocity ?? input.groundStep.velocity

        let stepInput = SM64MarioGroundStepInput(
            position: input.groundStep.position,
            velocity: groundVelocity,
            floor: input.groundStep.floor,
            faceYaw: Int32(finalFaceYaw),
            nativeStepScale: input.groundStep.nativeStepScale,
            ridingShell: input.groundStep.ridingShell,
            terrainSoundAddend: input.groundStep.terrainSoundAddend,
            quarterProbes: input.groundStep.quarterProbes
        )
        guard let groundStep = SM64MarioGroundStep.update(stepInput) else { return nil }

        switch groundStep.result {
        case .leftGround:
            return SM64MarioWalkingActionResult(
                intent: .freefall,
                action: SM64MarioActionID.freefall,
                actionArgument: 0,
                faceYaw: finalFaceYaw,
                forwardVelocity: finalForwardVelocity,
                velocity: stepInput.velocity,
                actionState: 0,
                actionTimer: 0,
                animationID: SM64MarioWalkingAnimationID.generalFall,
                animationAcceleration: 0,
                walkSound: .none,
                wallSound: .none,
                groundStep: groundStep,
                wallResponse: nil,
                particleDust: false,
                shouldDropHeldObject: drop,
                shouldRunLedgeClimbCheck: true,
                shouldTiltBodyWalking: true
            )

        case .none:
            let walkInput = SM64MarioWalkAnimationInput(
                intendedMagnitude: input.intendedMagnitude,
                forwardVelocity: finalForwardVelocity,
                quicksandDepth: input.quicksandDepth,
                actionTimer: input.walkAnimation.actionTimer,
                animationPastFrame23: input.walkAnimation.animationPastFrame23,
                animationPastFrame1: input.walkAnimation.animationPastFrame1,
                animationPastFrame2: input.walkAnimation.animationPastFrame2,
                metalCap: input.walkAnimation.metalCap,
                walkingPitch: input.walkAnimation.walkingPitch,
                runningPitch: input.walkAnimation.runningPitch
            )
            guard let walk = SM64MarioWalkAnimation.update(walkInput) else { return nil }
            return SM64MarioWalkingActionResult(
                intent: .continueGround,
                action: nil,
                actionArgument: 0,
                faceYaw: finalFaceYaw,
                forwardVelocity: finalForwardVelocity,
                velocity: stepInput.velocity,
                actionState: 0,
                actionTimer: walk.actionTimer,
                animationID: walk.animationID,
                animationAcceleration: walk.animationAcceleration,
                walkSound: walk.sound,
                wallSound: .none,
                groundStep: groundStep,
                wallResponse: nil,
                particleDust: input.intendedMagnitude - finalForwardVelocity > 16,
                shouldDropHeldObject: drop,
                shouldRunLedgeClimbCheck: true,
                shouldTiltBodyWalking: true
            )

        case .hitWall, .hitWallContinueQuarterSteps:
            let wallInput = SM64MarioWallResponseInput(
                startPosition: input.wallResponse.startPosition,
                position: groundStep.position,
                velocity: stepInput.velocity,
                forwardVelocity: finalForwardVelocity,
                faceYaw: Int32(finalFaceYaw),
                animationFrame: input.wallResponse.animationFrame,
                animationPastFrame1: input.wallResponse.animationPastFrame1,
                animationPastFrame2: input.wallResponse.animationPastFrame2,
                terrainSoundAddend: groundStep.terrainSoundAddend,
                floorSlopePitch: input.wallResponse.floorSlopePitch,
                wall: input.wallResponse.wall
            )
            guard let wall = SM64MarioWallResponse.update(wallInput) else { return nil }
            return SM64MarioWalkingActionResult(
                intent: .continueGround,
                action: nil,
                actionArgument: wall.actionArgument,
                faceYaw: finalFaceYaw,
                forwardVelocity: wall.forwardVelocity,
                velocity: wall.velocity,
                actionState: wall.actionState,
                actionTimer: 0,
                animationID: wall.animationID,
                animationAcceleration: wall.animationAcceleration,
                walkSound: .none,
                wallSound: wall.sound,
                groundStep: groundStep,
                wallResponse: wall,
                particleDust: wall.particleDust,
                shouldDropHeldObject: drop,
                shouldRunLedgeClimbCheck: true,
                shouldTiltBodyWalking: true
            )
        }
    }

    private static func beginBraking(
        _ input: SM64MarioWalkingActionInput,
        drop: Bool
    ) -> SM64MarioWalkingActionResult {
        if input.actionState == 1 {
            return transition(
                intent: .standingAgainstWall,
                action: SM64MarioActionID.standingAgainstWall,
                argument: 0,
                faceYaw: Int16(truncatingIfNeeded: input.actionArgument),
                forwardVelocity: input.forwardVelocity,
                velocity: input.groundStep.velocity,
                drop: drop
            )
        }
        let fastEnough = input.forwardVelocity >= 16
        let action: UInt32 = fastEnough && input.floorNormalY >= downhillFloorNormal
            ? SM64MarioActionID.braking
            : SM64MarioActionID.decelerating
        return transition(
            intent: fastEnough && input.floorNormalY >= downhillFloorNormal ? .braking : .decelerating,
            action: action,
            argument: 0,
            faceYaw: input.faceYaw,
            forwardVelocity: input.forwardVelocity,
            velocity: input.groundStep.velocity,
            drop: drop
        )
    }

    private static func analogStickHeldBack(intendedYaw: Int16, faceYaw: Int16) -> Bool {
        let delta = Int32(Int16(truncatingIfNeeded: Int32(intendedYaw) - Int32(faceYaw)))
        return delta < -0x471C || delta > 0x471C
    }

    private static func transition(
        intent: SM64MarioWalkingIntent,
        action: UInt32?,
        argument: UInt32,
        faceYaw: Int16,
        forwardVelocity: Float,
        velocity: SM64ObjectVector3,
        drop: Bool
    ) -> SM64MarioWalkingActionResult {
        SM64MarioWalkingActionResult(
            intent: intent,
            action: action,
            actionArgument: argument,
            faceYaw: faceYaw,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            actionState: 0,
            actionTimer: 0,
            animationID: nil,
            animationAcceleration: 0,
            walkSound: .none,
            wallSound: .none,
            groundStep: nil,
            wallResponse: nil,
            particleDust: false,
            shouldDropHeldObject: drop,
            shouldRunLedgeClimbCheck: false,
            shouldTiltBodyWalking: false
        )
    }
}

enum SM64MarioWalkingAnimationID {
    static let generalFall: UInt16 = 0x56
}
