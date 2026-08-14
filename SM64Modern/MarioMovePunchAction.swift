import Foundation

enum SM64MarioMovePunchIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case beginSliding = 1
    case jumpKick = 2
    case freefall = 3
}

struct SM64MarioMovePunchActionInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let terrainIsSlide: Bool
    let facingDownhill: Bool
    let actionState: UInt16
    let actionArgument: UInt32
    let animationFrame: Int16
    let animationAtEnd: Bool
    let animationPastEnd: Bool
    let floorClass: SM64MarioFloorClass
    let floorNormalX: Float
    let floorNormalY: Float
    let floorNormalZ: Float
    let floorAngle: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let groundStep: SM64MarioGroundStepInput
}

struct SM64MarioMovePunchActionResult: Equatable, Sendable {
    let intent: SM64MarioMovePunchIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionState: UInt16
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let punch: SM64MarioPunchSequenceResult?
    let slope: SM64MarioSlopeResult?
    let groundStep: SM64MarioGroundStepResult?
    let particleDust: Bool
    let shouldDropHeldObject: Bool
}

/// Value counterpart of `act_move_punching`. Animation/object interaction is
/// represented as a punch result and effect intents; owner-thread code applies
/// action transitions, body flags, and object grabs after this boundary.
enum SM64MarioMovePunchAction {
    static func update(
        _ input: SM64MarioMovePunchActionInput
    ) -> SM64MarioMovePunchActionResult? {
        guard input.forwardVelocity.isFinite,
              input.floorNormalX.isFinite,
              input.floorNormalY.isFinite,
              input.floorNormalZ.isFinite,
              input.groundStep.velocity.x.isFinite,
              input.groundStep.velocity.y.isFinite,
              input.groundStep.velocity.z.isFinite else {
            return nil
        }

        if input.input.contains(.aboveSlide),
           input.terrainIsSlide || input.forwardVelocity <= -1 || input.facingDownhill {
            return transition(
                intent: .beginSliding,
                action: SM64MarioActionID.beginSliding,
                actionArgument: 0,
                actionState: 0,
                faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity,
                velocity: input.groundStep.velocity,
                punch: nil,
                slope: nil,
                groundStep: nil,
                particleDust: false
            )
        }

        if input.actionState == 0 && input.input.contains(.aDown) {
            var velocity = input.groundStep.velocity
            velocity.y = 20
            return transition(
                intent: .jumpKick,
                action: SM64MarioActionID.jumpKick,
                actionArgument: 0,
                actionState: 0,
                faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity,
                velocity: velocity,
                punch: nil,
                slope: nil,
                groundStep: nil,
                particleDust: false
            )
        }

        guard let punch = SM64MarioPunchSequence.update(
            SM64MarioPunchSequenceInput(
                movingAction: true,
                actionArgument: input.actionArgument,
                animationFrame: input.animationFrame,
                animationAtEnd: input.animationAtEnd,
                animationPastEnd: input.animationPastEnd,
                bPressed: input.input.contains(.bPressed)
            )
        ) else {
            return nil
        }

        let slope: SM64MarioSlopeResult?
        let forwardVelocity: Float
        if input.forwardVelocity >= 0 {
            guard let deceleration = SM64MarioSlopeDeceleration.update(
                SM64MarioSlopeDecelerationInput(
                    coefficient: 0.5,
                    floorClass: input.floorClass,
                    terrainIsSlide: input.terrainIsSlide,
                    floorNormalX: input.floorNormalX,
                    floorNormalY: input.floorNormalY,
                    floorNormalZ: input.floorNormalZ,
                    floorAngle: input.floorAngle,
                    faceYaw: input.faceYaw,
                    forwardVelocity: input.forwardVelocity,
                    action: SM64MarioActionID.movePunching
                )
            ) else {
                return nil
            }
            slope = deceleration.slope
            forwardVelocity = deceleration.forwardVelocity
        } else {
            var adjustedVelocity = input.forwardVelocity + 8
            if adjustedVelocity >= 0 {
                adjustedVelocity = 0
            }
            guard let accelerated = SM64MarioSlope.update(
                SM64MarioSlopeInput(
                    floorClass: input.floorClass,
                    terrainIsSlide: input.terrainIsSlide,
                    floorNormalX: input.floorNormalX,
                    floorNormalY: input.floorNormalY,
                    floorNormalZ: input.floorNormalZ,
                    floorAngle: input.floorAngle,
                    faceYaw: input.faceYaw,
                    forwardVelocity: adjustedVelocity,
                    action: SM64MarioActionID.movePunching
                )
            ) else {
                return nil
            }
            slope = accelerated
            forwardVelocity = accelerated.forwardVelocity
        }

        let stepInput = SM64MarioGroundStepInput(
            position: input.groundStep.position,
            velocity: slope?.velocity ?? input.groundStep.velocity,
            floor: input.groundStep.floor,
            faceYaw: Int32(slope?.slideYaw ?? input.faceYaw),
            nativeStepScale: input.groundStep.nativeStepScale,
            ridingShell: input.groundStep.ridingShell,
            terrainSoundAddend: input.groundStep.terrainSoundAddend,
            quarterProbes: input.groundStep.quarterProbes
        )
        guard let groundStep = SM64MarioGroundStep.update(stepInput) else {
            return nil
        }

        let transitionAction = punch.transitionAction
        switch groundStep.result {
        case .leftGround:
            return SM64MarioMovePunchActionResult(
                intent: .freefall,
                action: SM64MarioActionID.freefall,
                actionArgument: 0,
                actionState: 0,
                faceYaw: slope?.slideYaw ?? input.faceYaw,
                forwardVelocity: forwardVelocity,
                velocity: stepInput.velocity,
                punch: punch,
                slope: slope,
                groundStep: groundStep,
                particleDust: false,
                shouldDropHeldObject: false
            )

        case .none, .hitWall, .hitWallContinueQuarterSteps:
            return SM64MarioMovePunchActionResult(
                intent: .continueGround,
                action: transitionAction,
                actionArgument: punch.actionArgument,
                actionState: transitionAction == nil ? 1 : 0,
                faceYaw: slope?.slideYaw ?? input.faceYaw,
                forwardVelocity: forwardVelocity,
                velocity: stepInput.velocity,
                punch: punch,
                slope: slope,
                groundStep: groundStep,
                particleDust: groundStep.result == .none,
                shouldDropHeldObject: false
            )
        }
    }

    private static func transition(
        intent: SM64MarioMovePunchIntent,
        action: UInt32,
        actionArgument: UInt32,
        actionState: UInt16,
        faceYaw: Int16,
        forwardVelocity: Float,
        velocity: SM64ObjectVector3,
        punch: SM64MarioPunchSequenceResult?,
        slope: SM64MarioSlopeResult?,
        groundStep: SM64MarioGroundStepResult?,
        particleDust: Bool
    ) -> SM64MarioMovePunchActionResult {
        SM64MarioMovePunchActionResult(
            intent: intent,
            action: action,
            actionArgument: actionArgument,
            actionState: actionState,
            faceYaw: faceYaw,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            punch: punch,
            slope: slope,
            groundStep: groundStep,
            particleDust: particleDust,
            shouldDropHeldObject: false
        )
    }
}
