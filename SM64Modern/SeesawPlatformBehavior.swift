import Foundation

struct SM64SeesawPlatformInitialization: Equatable, Sendable {
    let collisionModelIndex: UInt8
    let collisionDistanceOverride: Float?
}

struct SM64SeesawPlatformInput: Equatable, Sendable {
    let facePitch: Int32
    let pitchVelocity: Float
    let distanceToMario: Float
    let angleToMario: Int16
    let moveAngleYaw: Int16
    let marioIsOnPlatform: Bool
}

struct SM64SeesawPlatformOutput: Equatable, Sendable {
    let facePitch: Int32
    let pitchVelocity: Float
    let playsRockingSound: Bool
}

/// Value counterpart of `bhv_seesaw_platform_init` and
/// `bhv_seesaw_platform_update`.
enum SM64SeesawPlatformBehavior {
    static func initialize(behaviorByte: UInt8) -> SM64SeesawPlatformInitialization {
        SM64SeesawPlatformInitialization(
            collisionModelIndex: behaviorByte,
            collisionDistanceOverride: behaviorByte == 2 ? 2000 : nil
        )
    }

    static func update(_ input: SM64SeesawPlatformInput) -> SM64SeesawPlatformOutput {
        var facePitch = input.facePitch
        var pitchVelocity = input.pitchVelocity
        let playsRockingSound = abs(pitchVelocity) > 10

        if input.marioIsOnPlatform {
            let angleDelta = Int16(
                truncatingIfNeeded: Int32(input.angleToMario) - Int32(input.moveAngleYaw)
            )
            var rotation = input.distanceToMario * SM64CanonicalTrig.coss(angleDelta)
            if pitchVelocity * rotation < 0 {
                rotation *= 0.04
            } else {
                rotation *= 0.02
            }
            pitchVelocity += rotation
            pitchVelocity = min(max(pitchVelocity, -50), 50)
        } else {
            oscillateToward(
                value: &facePitch,
                velocity: &pitchVelocity,
                target: 0,
                velocityCloseToZero: 6,
                acceleration: 3,
                slowdown: 3
            )
        }

        return SM64SeesawPlatformOutput(
            facePitch: facePitch,
            pitchVelocity: pitchVelocity,
            playsRockingSound: playsRockingSound
        )
    }

    @discardableResult
    private static func oscillateToward(
        value: inout Int32,
        velocity: inout Float,
        target: Int32,
        velocityCloseToZero: Float,
        acceleration: Float,
        slowdown: Float
    ) -> Bool {
        let startValue = value
        value = value &+ Int32(velocity)

        let crossedTarget = (value &- target) * (startValue &- target) < 0
            && velocity > -velocityCloseToZero
            && velocity < velocityCloseToZero
        if value == target || crossedTarget {
            value = target
            velocity = 0
            return true
        }

        var adjustedAcceleration = acceleration
        if value >= target {
            adjustedAcceleration = -adjustedAcceleration
        }
        if velocity * adjustedAcceleration < 0 {
            adjustedAcceleration *= slowdown
        }
        velocity += adjustedAcceleration
        return false
    }
}
