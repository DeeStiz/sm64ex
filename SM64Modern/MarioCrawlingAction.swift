import Foundation

enum SM64MarioCrawlingIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case beginSliding = 1
    case stopCrawling = 2
    case jump = 3
    case dive = 4
    case movePunching = 5
    case freefall = 6
}

struct SM64MarioCrawlingActionInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let terrainIsSlide: Bool
    let facingDownhill: Bool
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let stickMagnitude: Float
    let quicksandDepth: Float
    let floorNormalY: Float
    let floorIsSlow: Bool
    let responsiveCheat: Bool
    let cheatsEnabled: Bool
    let groundStep: SM64MarioGroundStepInput
}

struct SM64MarioCrawlingActionResult: Equatable, Sendable {
    let intent: SM64MarioCrawlingIntent
    let action: UInt32?
    let actionArgument: UInt32
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let groundStep: SM64MarioGroundStepResult?
    let animationID: UInt16?
    let animationAcceleration: Int32
    let shouldAlignWithFloor: Bool
    let shouldPlayStepSound: Bool
    let shouldDropHeldObject: Bool
}

/// Value counterpart of `act_crawling`. The intentionally missing C `break`
/// after a wall clamp is preserved by applying the clamp and then retaining
/// the floor-alignment intent exactly like the `GROUND_STEP_NONE` fallthrough.
enum SM64MarioCrawlingAction {
    private static let crawlingAnimation: UInt16 = 0x99

    static func update(
        _ input: SM64MarioCrawlingActionInput
    ) -> SM64MarioCrawlingActionResult? {
        guard input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.stickMagnitude.isFinite,
              input.quicksandDepth.isFinite,
              input.floorNormalY.isFinite,
              input.groundStep.position.x.isFinite,
              input.groundStep.position.y.isFinite,
              input.groundStep.position.z.isFinite else {
            return nil
        }

        if input.input.contains(.aboveSlide),
           input.terrainIsSlide || input.forwardVelocity <= -1 || input.facingDownhill {
            return transition(
                input, intent: .beginSliding, action: SM64MarioActionID.beginSliding
            )
        }
        if input.input.contains(.firstPerson) {
            return transition(
                input, intent: .stopCrawling, action: SM64MarioActionID.stopCrawling
            )
        }
        if input.input.contains(.aPressed) {
            return transition(
                input, intent: .jump, action: SM64MarioActionID.jump
            )
        }
        if input.input.contains(.bPressed) {
            if input.forwardVelocity >= 29 && input.stickMagnitude > 48 {
                var velocity = input.groundStep.velocity
                velocity.y = 20
                return transition(
                    input, intent: .dive, action: SM64MarioActionID.dive,
                    velocity: velocity, actionArgument: 1
                )
            }
            return transition(
                input, intent: .movePunching, action: SM64MarioActionID.movePunching
            )
        }
        if input.input.contains(.unknown5) || !input.input.contains(.zDown) {
            return transition(
                input, intent: .stopCrawling, action: SM64MarioActionID.stopCrawling
            )
        }

        let crawlMagnitude = input.intendedMagnitude * 0.1
        guard let speed = SM64MarioGroundSpeed.update(
            SM64MarioGroundSpeedInput(
                intendedMagnitude: crawlMagnitude,
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

        let forwardVelocity = speed.forwardVelocity
        let faceYaw = speed.faceYaw
        var velocity = SM64ObjectVector3(
            x: SM64CanonicalTrig.sins(faceYaw) * forwardVelocity,
            y: input.groundStep.velocity.y,
            z: SM64CanonicalTrig.coss(faceYaw) * forwardVelocity
        )
        let animationAcceleration = Int32(input.intendedMagnitude * 0.2 * 0x10000)
        guard let groundStep = SM64MarioGroundStep.update(
            SM64MarioGroundStepInput(
                position: input.groundStep.position,
                velocity: velocity,
                floor: input.groundStep.floor,
                faceYaw: Int32(faceYaw),
                nativeStepScale: input.groundStep.nativeStepScale,
                ridingShell: input.groundStep.ridingShell,
                terrainSoundAddend: input.groundStep.terrainSoundAddend,
                quarterProbes: input.groundStep.quarterProbes
            )
        ) else {
            return nil
        }

        switch groundStep.result {
        case .leftGround:
            return SM64MarioCrawlingActionResult(
                intent: .freefall, action: SM64MarioActionID.freefall,
                actionArgument: 0, faceYaw: faceYaw,
                forwardVelocity: forwardVelocity, velocity: velocity,
                groundStep: groundStep, animationID: nil,
                animationAcceleration: animationAcceleration,
                shouldAlignWithFloor: false, shouldPlayStepSound: true,
                shouldDropHeldObject: false
            )

        case .hitWall, .hitWallContinueQuarterSteps:
            if forwardVelocity > 10 {
                let clampedForward = Float(10)
                velocity = SM64ObjectVector3(
                    x: SM64CanonicalTrig.sins(faceYaw) * clampedForward,
                    y: velocity.y,
                    z: SM64CanonicalTrig.coss(faceYaw) * clampedForward
                )
                return SM64MarioCrawlingActionResult(
                    intent: .continueGround, action: nil, actionArgument: 0,
                    faceYaw: faceYaw, forwardVelocity: clampedForward,
                    velocity: velocity, groundStep: groundStep,
                    animationID: Self.crawlingAnimation,
                    animationAcceleration: animationAcceleration,
                    shouldAlignWithFloor: true, shouldPlayStepSound: true,
                    shouldDropHeldObject: false
                )
            }
            fallthrough

        case .none:
            return SM64MarioCrawlingActionResult(
                intent: .continueGround, action: nil, actionArgument: 0,
                faceYaw: faceYaw, forwardVelocity: forwardVelocity,
                velocity: velocity, groundStep: groundStep,
                animationID: Self.crawlingAnimation,
                animationAcceleration: animationAcceleration,
                shouldAlignWithFloor: true, shouldPlayStepSound: true,
                shouldDropHeldObject: false
            )
        }
    }

    private static func transition(
        _ input: SM64MarioCrawlingActionInput,
        intent: SM64MarioCrawlingIntent,
        action: UInt32,
        velocity: SM64ObjectVector3? = nil,
        actionArgument: UInt32 = 0
    ) -> SM64MarioCrawlingActionResult {
        SM64MarioCrawlingActionResult(
            intent: intent, action: action, actionArgument: actionArgument,
            faceYaw: input.faceYaw, forwardVelocity: input.forwardVelocity,
            velocity: velocity ?? input.groundStep.velocity,
            groundStep: nil, animationID: nil, animationAcceleration: 0,
            shouldAlignWithFloor: false, shouldPlayStepSound: false,
            shouldDropHeldObject: false
        )
    }
}
