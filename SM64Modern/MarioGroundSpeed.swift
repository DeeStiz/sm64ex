import Foundation

struct SM64MarioGroundSpeedInput: Equatable, Sendable {
    let intendedMagnitude: Float
    let forwardVelocity: Float
    let quicksandDepth: Float
    let floorNormalY: Float
    let intendedYaw: Int32
    let faceYaw: Int32
    let floorIsSlow: Bool
    let responsiveCheat: Bool
    let cheatsEnabled: Bool
}

struct SM64MarioGroundSpeedResult: Equatable, Sendable {
    let forwardVelocity: Float
    let faceYaw: Int16
}

/// Value counterpart of the migrated `update_walking_speed` callback. It is
/// intentionally independent of the object graph; the caller supplies the
/// floor normal/type and cheat switches as scalar snapshots.
enum SM64MarioGroundSpeed {
    static func update(_ input: SM64MarioGroundSpeedInput) -> SM64MarioGroundSpeedResult? {
        guard input.intendedMagnitude.isFinite,
              input.forwardVelocity.isFinite,
              input.quicksandDepth.isFinite,
              input.floorNormalY.isFinite else {
            return nil
        }

        let maxTargetSpeed: Float = input.floorIsSlow ? 24 : 32
        var targetSpeed = input.intendedMagnitude < maxTargetSpeed
            ? input.intendedMagnitude
            : maxTargetSpeed
        if input.quicksandDepth > 10 {
            targetSpeed = Float(
                Double(targetSpeed) * (6.25 / Double(input.quicksandDepth))
            )
        }

        var forwardVelocity = input.forwardVelocity
        if forwardVelocity <= 0 {
            forwardVelocity += 1.1
        } else if forwardVelocity <= targetSpeed {
            forwardVelocity += 1.1 - forwardVelocity / 43
        } else if input.floorNormalY >= 0.95 {
            forwardVelocity -= 1
        }
        if forwardVelocity > 48 { forwardVelocity = 48 }

        let intendedYaw = Int32(Int16(truncatingIfNeeded: input.intendedYaw))
        let faceYaw = Int32(Int16(truncatingIfNeeded: input.faceYaw))
        let nextFaceYaw: Int32
        if input.responsiveCheat && input.cheatsEnabled {
            nextFaceYaw = intendedYaw
        } else {
            let delta = Int32(Int16(truncatingIfNeeded: intendedYaw - faceYaw))
            nextFaceYaw = intendedYaw - approachS32(
                delta,
                target: 0,
                increment: 0x800,
                decrement: 0x800
            )
        }

        return SM64MarioGroundSpeedResult(
            forwardVelocity: forwardVelocity,
            faceYaw: Int16(truncatingIfNeeded: nextFaceYaw)
        )
    }

    private static func approachS32(
        _ current: Int32,
        target: Int32,
        increment: Int32,
        decrement: Int32
    ) -> Int32 {
        if current < target {
            let next = current + increment
            return next > target ? target : next
        }
        let next = current - decrement
        return next < target ? target : next
    }
}
