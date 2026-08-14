import Foundation

enum SM64MarioTurningIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case beginSliding = 1
    case sideFlip = 2
    case braking = 3
    case walking = 4
    case finishTurningAround = 5
    case freefall = 6
}

struct SM64MarioTurningActionInput: Equatable, Sendable {
    let input: SM64MarioInputFlags
    let terrainIsSlide: Bool
    let facingDownhill: Bool
    let floorClass: SM64MarioFloorClass
    let floorNormalX: Float
    let floorNormalY: Float
    let floorNormalZ: Float
    let floorAngle: Int16
    let faceYaw: Int16
    let intendedYaw: Int16
    let forwardVelocity: Float
    let animationAtEnd: Bool
    let groundStep: SM64MarioGroundStepInput
}

struct SM64MarioTurningActionResult: Equatable, Sendable {
    let intent: SM64MarioTurningIntent
    let action: UInt32?
    let actionArgument: UInt32
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let slope: SM64MarioSlopeResult?
    let groundStep: SM64MarioGroundStepResult?
    let animationID: UInt16?
    let particleDust: Bool
    let terrainSound: Bool
}

/// Value counterpart of `act_turning_around`. The later finish-turning body
/// consumes the same immutable state but owns walking-speed/camera-facing
/// effects separately.
enum SM64MarioTurningAction {
    private static let turningPart1: UInt16 = 0xBC
    private static let turningPart2: UInt16 = 0xBD

    static func update(
        _ input: SM64MarioTurningActionInput
    ) -> SM64MarioTurningActionResult? {
        guard input.forwardVelocity.isFinite,
              input.floorNormalX.isFinite,
              input.floorNormalY.isFinite,
              input.floorNormalZ.isFinite,
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
        if input.input.contains(.unknown5) {
            return early(.braking, action: SM64MarioActionID.braking, input: input)
        }
        if !analogStickHeldBack(intendedYaw: input.intendedYaw, faceYaw: input.faceYaw) {
            return early(.walking, action: SM64MarioActionID.walking, input: input)
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
                action: SM64MarioActionID.turningAround
            )
        ) else {
            return nil
        }

        if deceleration.stopped {
            let velocity = SM64ObjectVector3(
                x: SM64CanonicalTrig.sins(input.intendedYaw) * 8,
                y: input.groundStep.velocity.y,
                z: SM64CanonicalTrig.coss(input.intendedYaw) * 8
            )
            return result(
                intent: .finishTurningAround,
                action: SM64MarioActionID.finishTurningAround,
                input: input,
                faceYaw: input.intendedYaw,
                forwardVelocity: 8,
                velocity: velocity,
                slope: deceleration.slope,
                groundStep: nil,
                animationID: nil,
                particleDust: false,
                terrainSound: false
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

        if groundStep.result == .leftGround {
            return result(
                intent: .freefall,
                action: SM64MarioActionID.freefall,
                input: input,
                faceYaw: input.faceYaw,
                forwardVelocity: deceleration.slope.forwardVelocity,
                velocity: stepInput.velocity,
                slope: deceleration.slope,
                groundStep: groundStep,
                animationID: nil,
                particleDust: false,
                terrainSound: true
            )
        }

        if deceleration.slope.forwardVelocity >= 18 {
            return result(
                intent: .continueGround,
                action: nil,
                input: input,
                faceYaw: input.faceYaw,
                forwardVelocity: deceleration.slope.forwardVelocity,
                velocity: stepInput.velocity,
                slope: deceleration.slope,
                groundStep: groundStep,
                animationID: turningPart1,
                particleDust: groundStep.result == .none,
                terrainSound: true
            )
        }

        if input.animationAtEnd {
            let nextForwardVelocity = deceleration.slope.forwardVelocity > 0
                ? -deceleration.slope.forwardVelocity
                : 8
            let velocity = SM64ObjectVector3(
                x: SM64CanonicalTrig.sins(input.intendedYaw) * nextForwardVelocity,
                y: stepInput.velocity.y,
                z: SM64CanonicalTrig.coss(input.intendedYaw) * nextForwardVelocity
            )
            return result(
                intent: .walking,
                action: SM64MarioActionID.walking,
                input: input,
                faceYaw: input.intendedYaw,
                forwardVelocity: nextForwardVelocity,
                velocity: velocity,
                slope: deceleration.slope,
                groundStep: groundStep,
                animationID: turningPart2,
                particleDust: groundStep.result == .none,
                terrainSound: true
            )
        }

        return result(
            intent: .continueGround,
            action: nil,
            input: input,
            faceYaw: input.faceYaw,
            forwardVelocity: deceleration.slope.forwardVelocity,
            velocity: stepInput.velocity,
            slope: deceleration.slope,
            groundStep: groundStep,
            animationID: turningPart2,
            particleDust: groundStep.result == .none,
            terrainSound: true
        )
    }

    private static func analogStickHeldBack(intendedYaw: Int16, faceYaw: Int16) -> Bool {
        let delta = Int32(Int16(truncatingIfNeeded: Int32(intendedYaw) - Int32(faceYaw)))
        return delta < -0x471C || delta > 0x471C
    }

    private static func early(
        _ intent: SM64MarioTurningIntent,
        action: UInt32,
        input: SM64MarioTurningActionInput
    ) -> SM64MarioTurningActionResult {
        result(
            intent: intent,
            action: action,
            input: input,
            faceYaw: input.faceYaw,
            forwardVelocity: input.forwardVelocity,
            velocity: input.groundStep.velocity,
            slope: nil,
            groundStep: nil,
            animationID: nil,
            particleDust: false,
            terrainSound: false
        )
    }

    private static func result(
        intent: SM64MarioTurningIntent,
        action: UInt32?,
        input: SM64MarioTurningActionInput,
        faceYaw: Int16,
        forwardVelocity: Float,
        velocity: SM64ObjectVector3,
        slope: SM64MarioSlopeResult?,
        groundStep: SM64MarioGroundStepResult?,
        animationID: UInt16?,
        particleDust: Bool,
        terrainSound: Bool
    ) -> SM64MarioTurningActionResult {
        SM64MarioTurningActionResult(
            intent: intent,
            action: action,
            actionArgument: 0,
            faceYaw: faceYaw,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            slope: slope,
            groundStep: groundStep,
            animationID: animationID,
            particleDust: particleDust,
            terrainSound: terrainSound
        )
    }
}
