import Foundation

struct SM64MarioSlopeDecelerationInput: Equatable, Sendable {
    let coefficient: Float
    let floorClass: SM64MarioFloorClass
    let terrainIsSlide: Bool
    let floorNormalX: Float
    let floorNormalY: Float
    let floorNormalZ: Float
    let floorAngle: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let action: UInt32
}

struct SM64MarioSlopeDecelerationResult: Equatable, Sendable {
    let stopped: Bool
    let forwardVelocity: Float
    let slope: SM64MarioSlopeResult
}

/// Value counterpart of `apply_slope_decel`. The C helper approaches zero,
/// then immediately reapplies `apply_slope_accel`; keeping both operations in
/// one result preserves the velocity/effect ordering for moving actions.
enum SM64MarioSlopeDeceleration {
    static func update(
        _ input: SM64MarioSlopeDecelerationInput
    ) -> SM64MarioSlopeDecelerationResult? {
        guard input.coefficient.isFinite,
              input.forwardVelocity.isFinite else {
            return nil
        }

        let deceleration: Float
        switch input.floorClass {
        case .verySlippery:
            deceleration = input.coefficient * 0.2
        case .slippery:
            deceleration = input.coefficient * 0.7
        case .notSlippery:
            deceleration = input.coefficient * 3.0
        case .defaultClass:
            deceleration = input.coefficient * 2.0
        }

        let forwardVelocity = SM64DeterministicPrimitives.approachFloat(
            current: input.forwardVelocity,
            target: 0,
            increment: deceleration,
            decrement: deceleration
        )
        guard let slope = SM64MarioSlope.update(
            SM64MarioSlopeInput(
                floorClass: input.floorClass,
                terrainIsSlide: input.terrainIsSlide,
                floorNormalX: input.floorNormalX,
                floorNormalY: input.floorNormalY,
                floorNormalZ: input.floorNormalZ,
                floorAngle: input.floorAngle,
                faceYaw: input.faceYaw,
                forwardVelocity: forwardVelocity,
                action: input.action
            )
        ) else {
            return nil
        }

        return SM64MarioSlopeDecelerationResult(
            stopped: forwardVelocity == 0,
            forwardVelocity: forwardVelocity,
            slope: slope
        )
    }
}
