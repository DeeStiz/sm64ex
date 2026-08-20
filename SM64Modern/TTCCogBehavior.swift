import Foundation

struct SM64TTCCogInput: Equatable, Sendable {
    let speedSetting: Int32
    let direction: Int32
    let speed: Float
    let targetSpeed: Float
    let faceYaw: Int16
    let randomTargetSpeed: Float
    let randomApproachReached: Bool
}

struct SM64TTCCogOutput: Equatable, Sendable {
    let speed: Float
    let targetSpeed: Float
    let angleVelocityYaw: Int16
    let faceYaw: Int16
}

/// Value counterpart of `bhv_ttc_cog_init/update`. Random target selection
/// and approach completion are explicit inputs for deterministic replay.
enum SM64TTCCogBehavior {
    private static let normalSpeeds: [Float] = [200, 400]

    static func update(_ input: SM64TTCCogInput) -> SM64TTCCogOutput {
        var speed = input.speed
        var targetSpeed = input.targetSpeed
        switch input.speedSetting {
        case 0, 1:
            speed = normalSpeeds[Int(input.speedSetting)]
        case 2:
            if input.randomApproachReached {
                targetSpeed = input.randomTargetSpeed
            } else {
                speed = approach(speed, target: targetSpeed, delta: 50)
            }
        default:
            break
        }
        let angleVelocity = Int16(truncatingIfNeeded: Int32(speed) * input.direction)
        let faceYaw = Int16(
            bitPattern: UInt16(bitPattern: input.faceYaw)
                &+ UInt16(bitPattern: angleVelocity)
        )
        return SM64TTCCogOutput(
            speed: speed,
            targetSpeed: targetSpeed,
            angleVelocityYaw: angleVelocity,
            faceYaw: faceYaw
        )
    }

    private static func approach(_ value: Float, target: Float, delta: Float) -> Float {
        var step = delta
        if value > target { step = -step }
        let next = value + step
        if (next - target) * step >= 0 { return target }
        return next
    }
}
