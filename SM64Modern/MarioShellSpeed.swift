import Foundation

struct SM64MarioShellSpeedInput: Equatable, Sendable {
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let floorIsSlow: Bool
    let floorNormalY: Float
    let floorClass: SM64MarioFloorClass
    let terrainIsSlide: Bool
    let floorNormalX: Float
    let floorNormalZ: Float
    let floorAngle: Int16
    let action: UInt32
}

struct SM64MarioShellSpeedResult: Equatable, Sendable {
    let forwardVelocity: Float
    let faceYaw: Int16
    let slope: SM64MarioSlopeResult
}

/// Value counterpart of `update_shell_speed`; floor pseudo-surface creation
/// and moving-sand/wind delivery stay in the C owner-thread wrapper.
enum SM64MarioShellSpeed {
    static func update(_ input: SM64MarioShellSpeedInput) -> SM64MarioShellSpeedResult? {
        guard input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.floorNormalY.isFinite,
              input.floorNormalX.isFinite,
              input.floorNormalZ.isFinite else { return nil }

        let maxTargetSpeed: Float = input.floorIsSlow ? 48 : 64
        var targetSpeed = min(input.intendedMagnitude * 2, maxTargetSpeed)
        if targetSpeed < 24 { targetSpeed = 24 }

        var forwardVelocity = input.forwardVelocity
        if forwardVelocity <= 0 {
            forwardVelocity += 1.1
        } else if forwardVelocity <= targetSpeed {
            forwardVelocity += 1.1 - forwardVelocity / 58
        } else if input.floorNormalY >= 0.95 {
            forwardVelocity -= 1
        }
        if forwardVelocity > 64 { forwardVelocity = 64 }

        let delta = Int32(Int16(truncatingIfNeeded: Int32(input.intendedYaw) - Int32(input.faceYaw)))
        let adjustedDelta = SM64DeterministicPrimitives.approachS32(
            current: delta, target: 0, increment: 0x800, decrement: 0x800
        )
        let faceYaw = Int16(
            truncatingIfNeeded: Int32(input.intendedYaw) - adjustedDelta
        )
        guard let slope = SM64MarioSlope.update(
            SM64MarioSlopeInput(
                floorClass: input.floorClass,
                terrainIsSlide: input.terrainIsSlide,
                floorNormalX: input.floorNormalX,
                floorNormalY: input.floorNormalY,
                floorNormalZ: input.floorNormalZ,
                floorAngle: input.floorAngle,
                faceYaw: faceYaw,
                forwardVelocity: forwardVelocity,
                action: input.action
            )
        ) else { return nil }
        return SM64MarioShellSpeedResult(
            forwardVelocity: slope.forwardVelocity,
            faceYaw: faceYaw,
            slope: slope
        )
    }
}
