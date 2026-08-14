import Foundation

enum SM64MarioBrakingIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case brakingStop = 1
    case movePunching = 2
    case freefall = 3
    case walking = 4
    case jump = 5
    case beginSliding = 6
    case backwardGroundKnockback = 7
}

struct SM64MarioBrakingActionInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let terrainIsSlide: Bool
    let facingDownhill: Bool
    let floorClass: SM64MarioFloorClass
    let floorNormalX: Float
    let floorNormalY: Float
    let floorNormalZ: Float
    let floorAngle: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let groundStep: SM64MarioGroundStepInput
}

struct SM64MarioBrakingActionResult: Equatable, Sendable {
    let intent: SM64MarioBrakingIntent
    let action: UInt32?
    let actionArgument: UInt32
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let slope: SM64MarioSlopeResult?
    let groundStep: SM64MarioGroundStepResult?
    let animationID: UInt16?
    let particleDust: Bool
    let reflectedBonk: Bool
}

/// Value counterpart of `act_braking`. Common exits and slide-bonk action
/// selection are returned as intents; terrain/audio delivery remains outside
/// the deterministic action boundary.
enum SM64MarioBrakingAction {
    private static let skidAnimation: UInt16 = 0x0F
    private static let downhillFloorNormal: Float = 0.17364818

    static func update(
        _ input: SM64MarioBrakingActionInput
    ) -> SM64MarioBrakingActionResult? {
        guard input.forwardVelocity.isFinite,
              input.floorNormalX.isFinite,
              input.floorNormalY.isFinite,
              input.floorNormalZ.isFinite,
              input.groundStep.velocity.x.isFinite,
              input.groundStep.velocity.y.isFinite,
              input.groundStep.velocity.z.isFinite else {
            return nil
        }

        if !input.input.contains(.firstPerson),
           input.input.intersection([.nonzeroAnalog, .aPressed, .offFloor, .aboveSlide]).isEmpty == false {
            if input.input.contains(.aPressed) {
                return early(.jump, action: SM64MarioActionID.jump, input: input)
            }
            if input.input.contains(.offFloor) {
                return early(.freefall, action: SM64MarioActionID.freefall, input: input)
            }
            if input.input.contains(.nonzeroAnalog) {
                return early(.walking, action: SM64MarioActionID.walking, input: input)
            }
            return early(.beginSliding, action: SM64MarioActionID.beginSliding, input: input)
        }

        guard let deceleration = SM64MarioSlopeDeceleration.update(
            SM64MarioSlopeDecelerationInput(
                coefficient: 2,
                floorClass: input.floorClass,
                terrainIsSlide: input.terrainIsSlide,
                floorNormalX: input.floorNormalX,
                floorNormalY: input.floorNormalY,
                floorNormalZ: input.floorNormalZ,
                floorAngle: input.floorAngle,
                faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity,
                action: SM64MarioActionID.braking
            )
        ) else {
            return nil
        }

        if deceleration.stopped {
            return result(
                intent: .brakingStop,
                action: SM64MarioActionID.brakingStop,
                input: input,
                forwardVelocity: deceleration.slope.forwardVelocity,
                velocity: deceleration.slope.velocity,
                slope: deceleration.slope,
                groundStep: nil,
                animationID: nil,
                particleDust: false,
                reflectedBonk: false
            )
        }

        if input.input.contains(.bPressed) {
            return result(
                intent: .movePunching,
                action: SM64MarioActionID.movePunching,
                input: input,
                forwardVelocity: deceleration.slope.forwardVelocity,
                velocity: deceleration.slope.velocity,
                slope: deceleration.slope,
                groundStep: nil,
                animationID: nil,
                particleDust: false,
                reflectedBonk: false
            )
        }

        let stepInput = SM64MarioGroundStepInput(
            position: input.groundStep.position,
            velocity: deceleration.slope.velocity,
            floor: input.groundStep.floor,
            faceYaw: Int32(deceleration.slope.slideYaw),
            nativeStepScale: input.groundStep.nativeStepScale,
            ridingShell: input.groundStep.ridingShell,
            terrainSoundAddend: input.groundStep.terrainSoundAddend,
            quarterProbes: input.groundStep.quarterProbes
        )
        guard let groundStep = SM64MarioGroundStep.update(stepInput) else {
            return nil
        }

        switch groundStep.result {
        case .leftGround:
            return result(
                intent: .freefall,
                action: SM64MarioActionID.freefall,
                input: input,
                forwardVelocity: deceleration.slope.forwardVelocity,
                velocity: stepInput.velocity,
                slope: deceleration.slope,
                groundStep: groundStep,
                animationID: nil,
                particleDust: false,
                reflectedBonk: false
            )

        case .none:
            return result(
                intent: .continueGround,
                action: nil,
                input: input,
                forwardVelocity: deceleration.slope.forwardVelocity,
                velocity: stepInput.velocity,
                slope: deceleration.slope,
                groundStep: groundStep,
                animationID: skidAnimation,
                particleDust: true,
                reflectedBonk: false
            )

        case .hitWall, .hitWallContinueQuarterSteps:
            if deceleration.slope.forwardVelocity > 16 {
                return result(
                    intent: .backwardGroundKnockback,
                    action: SM64MarioActionID.backwardGroundKnockback,
                    input: input,
                    forwardVelocity: deceleration.slope.forwardVelocity,
                    velocity: stepInput.velocity,
                    slope: deceleration.slope,
                    groundStep: groundStep,
                    animationID: nil,
                    particleDust: false,
                    reflectedBonk: true
                )
            }
            let stoppedVelocity = SM64ObjectVector3(
                x: 0,
                y: stepInput.velocity.y,
                z: 0
            )
            return result(
                intent: .brakingStop,
                action: SM64MarioActionID.brakingStop,
                input: input,
                forwardVelocity: 0,
                velocity: stoppedVelocity,
                slope: deceleration.slope,
                groundStep: groundStep,
                animationID: nil,
                particleDust: false,
                reflectedBonk: false
            )
        }
    }

    private static func early(
        _ intent: SM64MarioBrakingIntent,
        action: UInt32,
        input: SM64MarioBrakingActionInput
    ) -> SM64MarioBrakingActionResult {
        result(
            intent: intent,
            action: action,
            input: input,
            forwardVelocity: input.forwardVelocity,
            velocity: input.groundStep.velocity,
            slope: nil,
            groundStep: nil,
            animationID: nil,
            particleDust: false,
            reflectedBonk: false
        )
    }

    private static func result(
        intent: SM64MarioBrakingIntent,
        action: UInt32?,
        input: SM64MarioBrakingActionInput,
        forwardVelocity: Float,
        velocity: SM64ObjectVector3,
        slope: SM64MarioSlopeResult?,
        groundStep: SM64MarioGroundStepResult?,
        animationID: UInt16?,
        particleDust: Bool,
        reflectedBonk: Bool
    ) -> SM64MarioBrakingActionResult {
        SM64MarioBrakingActionResult(
            intent: intent,
            action: action,
            actionArgument: 0,
            faceYaw: slope?.slideYaw ?? input.faceYaw,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            slope: slope,
            groundStep: groundStep,
            animationID: animationID,
            particleDust: particleDust,
            reflectedBonk: reflectedBonk
        )
    }
}
