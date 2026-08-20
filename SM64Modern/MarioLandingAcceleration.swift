import Foundation

struct SM64MarioLandingAccelerationInput: Equatable, Sendable {
    let frictionFactor: Float
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

struct SM64MarioLandingAccelerationResult: Equatable, Sendable {
    let stopped: Bool
    let forwardVelocity: Float
    let slope: SM64MarioSlopeResult
}

/// Value counterpart of `apply_landing_accel`; collision and terrain effects
/// remain in the C owner-thread wrapper.
enum SM64MarioLandingAcceleration {
    static func update(
        _ input: SM64MarioLandingAccelerationInput
    ) -> SM64MarioLandingAccelerationResult? {
        guard input.frictionFactor.isFinite,
              input.forwardVelocity.isFinite,
              input.floorNormalX.isFinite,
              input.floorNormalY.isFinite,
              input.floorNormalZ.isFinite else { return nil }
        guard let slope = SM64MarioSlope.update(
            SM64MarioSlopeInput(
                floorClass: input.floorClass,
                terrainIsSlide: input.terrainIsSlide,
                floorNormalX: input.floorNormalX,
                floorNormalY: input.floorNormalY,
                floorNormalZ: input.floorNormalZ,
                floorAngle: input.floorAngle,
                faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity,
                action: input.action
            )
        ) else { return nil }

        var forwardVelocity = slope.forwardVelocity
        var stopped = false
        var resultSlope = slope
        if !slope.floorIsSlope {
            forwardVelocity = SM64DeterministicPrimitives.cFloatMultiply(
                forwardVelocity, input.frictionFactor
            )
            if SM64DeterministicPrimitives.cFloatMultiply(
                forwardVelocity, forwardVelocity
            ) < 1 {
                forwardVelocity = 0
                stopped = true
            }
            guard let frictionSlope = SM64MarioSlope.update(
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
            ) else { return nil }
            resultSlope = frictionSlope
        }
        return SM64MarioLandingAccelerationResult(
            stopped: stopped,
            forwardVelocity: resultSlope.forwardVelocity,
            slope: resultSlope
        )
    }
}
