import Foundation

enum SM64MarioFinishTurningIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case beginSliding = 1
    case sideFlip = 2
    case walking = 3
    case freefall = 4
}

struct SM64MarioFinishTurningActionInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let intendedMagnitude: Float
    let quicksandDepth: Float
    let floorNormalY: Float
    let floorIsSlow: Bool
    let responsiveCheat: Bool
    let cheatsEnabled: Bool
    let intendedYaw: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let animationAtEnd: Bool
    let groundStep: SM64MarioGroundStepInput
    let slope: SM64MarioSlopeInput?
}

struct SM64MarioFinishTurningActionResult: Equatable, Sendable {
    let intent: SM64MarioFinishTurningIntent
    let action: UInt32?
    let actionArgument: UInt32
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let animationID: UInt16?
    let groundStep: SM64MarioGroundStepResult?
    let slope: SM64MarioSlopeResult?
    let graphicsYawDelta: Int16
}

/// Value counterpart of `act_finish_turning_around`. The walking-speed and
/// optional slope snapshots are composed before the four-quarter step; the
/// graphics-facing 180-degree adjustment is returned as an owner-thread intent.
enum SM64MarioFinishTurningAction {
    private static let turningPart2: UInt16 = 0xBD

    static func update(
        _ input: SM64MarioFinishTurningActionInput
    ) -> SM64MarioFinishTurningActionResult? {
        guard input.intendedMagnitude.isFinite,
              input.quicksandDepth.isFinite,
              input.floorNormalY.isFinite,
              input.forwardVelocity.isFinite,
              input.groundStep.velocity.x.isFinite,
              input.groundStep.velocity.y.isFinite,
              input.groundStep.velocity.z.isFinite else {
            return nil
        }

        if input.input.contains(.aboveSlide) {
            return early(.beginSliding, action: SM64MarioActionID.beginSliding, input: input)
        }
        if input.input.contains(.aPressed) {
            return early(.sideFlip, action: SM64MarioActionID.sideFlip, input: input)
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
        if let slope = input.slope {
            guard let updated = SM64MarioSlope.update(
                SM64MarioSlopeInput(
                    floorClass: slope.floorClass,
                    terrainIsSlide: slope.terrainIsSlide,
                    floorNormalX: slope.floorNormalX,
                    floorNormalY: slope.floorNormalY,
                    floorNormalZ: slope.floorNormalZ,
                    floorAngle: slope.floorAngle,
                    faceYaw: speed.faceYaw,
                    forwardVelocity: speed.forwardVelocity,
                    action: SM64MarioActionID.finishTurningAround
                )
            ) else {
                return nil
            }
            appliedSlope = updated
        } else {
            appliedSlope = nil
        }

        let finalForwardVelocity = appliedSlope?.forwardVelocity ?? speed.forwardVelocity
        let finalFaceYaw = appliedSlope?.slideYaw ?? speed.faceYaw
        let stepInput = SM64MarioGroundStepInput(
            position: input.groundStep.position,
            velocity: appliedSlope?.velocity ?? input.groundStep.velocity,
            floor: input.groundStep.floor,
            faceYaw: Int32(finalFaceYaw),
            nativeStepScale: input.groundStep.nativeStepScale,
            ridingShell: input.groundStep.ridingShell,
            terrainSoundAddend: input.groundStep.terrainSoundAddend,
            quarterProbes: input.groundStep.quarterProbes
        )
        guard let groundStep = SM64MarioGroundStep.update(stepInput) else {
            return nil
        }

        let leftGround = groundStep.result == .leftGround
        let action: UInt32?
        let intent: SM64MarioFinishTurningIntent
        if input.animationAtEnd {
            action = SM64MarioActionID.walking
            intent = .walking
        } else if leftGround {
            action = SM64MarioActionID.freefall
            intent = .freefall
        } else {
            action = nil
            intent = .continueGround
        }
        return SM64MarioFinishTurningActionResult(
            intent: intent,
            action: action,
            actionArgument: 0,
            faceYaw: finalFaceYaw,
            forwardVelocity: finalForwardVelocity,
            velocity: stepInput.velocity,
            animationID: turningPart2,
            groundStep: groundStep,
            slope: appliedSlope,
            graphicsYawDelta: Int16(bitPattern: 0x8000)
        )
    }

    private static func early(
        _ intent: SM64MarioFinishTurningIntent,
        action: UInt32,
        input: SM64MarioFinishTurningActionInput
    ) -> SM64MarioFinishTurningActionResult {
        SM64MarioFinishTurningActionResult(
            intent: intent,
            action: action,
            actionArgument: 0,
            faceYaw: input.faceYaw,
            forwardVelocity: input.forwardVelocity,
            velocity: input.groundStep.velocity,
            animationID: nil,
            groundStep: nil,
            slope: nil,
            graphicsYawDelta: 0
        )
    }
}
