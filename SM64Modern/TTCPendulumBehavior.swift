import Foundation

struct SM64TTCPendulumInitialization: Equatable, Sendable {
    let angleAcceleration: Float
    let angle: Float
}

struct SM64TTCPendulumInput: Equatable, Sendable {
    let speedSetting: Int32
    let angle: Float
    let angleVelocity: Float
    let angleAcceleration: Float
    let accelerationDirection: Float
    let delay: Int32
    let soundTimer: Int32
    /// Result of the random `% 3 != 0` choice when random speed is active.
    let randomAccelerationUses13: Bool
    /// Whether the random delay branch selected an even random value.
    let randomDelayIsEven: Bool
    let randomDelay: Int32
}

struct SM64TTCPendulumOutput: Equatable, Sendable {
    let angle: Float
    let angleVelocity: Float
    let angleAcceleration: Float
    let accelerationDirection: Float
    let delay: Int32
    let soundTimer: Int32
    let faceRoll: Int32
    let playsSwingSound: Bool
}

/// Value counterpart of `bhv_ttc_pendulum_init` and
/// `bhv_ttc_pendulum_update`.
enum SM64TTCPendulumBehavior {
    private static let initialAccelerations: [Float] = [13, 22, 13, 0]

    static func initialize(speedSetting: Int32) -> SM64TTCPendulumInitialization {
        if speedSetting == 3 {
            return SM64TTCPendulumInitialization(angleAcceleration: 0, angle: 6371.5557)
        }
        return SM64TTCPendulumInitialization(
            angleAcceleration: initialAccelerations[Int(speedSetting)],
            angle: 6500
        )
    }

    static func update(_ input: SM64TTCPendulumInput) -> SM64TTCPendulumOutput {
        var angle = input.angle
        var angleVelocity = input.angleVelocity
        var angleAcceleration = input.angleAcceleration
        var accelerationDirection = input.accelerationDirection
        var delay = input.delay
        var soundTimer = input.soundTimer
        var playsSwingSound = false

        if input.speedSetting != 3 {
            if soundTimer != 0 {
                soundTimer -= 1
                if soundTimer == 0 {
                    playsSwingSound = true
                }
            }

            if delay != 0 {
                delay -= 1
            } else {
                if angle * accelerationDirection > 0 {
                    accelerationDirection = -accelerationDirection
                }
                angleVelocity += angleAcceleration * accelerationDirection
                if angleVelocity == 0 {
                    if input.speedSetting == 2 {
                        angleAcceleration = input.randomAccelerationUses13 ? 13 : 42
                        if input.randomDelayIsEven {
                            delay = input.randomDelay
                        }
                    }
                    soundTimer = delay + 15
                }
                angle += angleVelocity
            }
        }

        return SM64TTCPendulumOutput(
            angle: angle,
            angleVelocity: angleVelocity,
            angleAcceleration: angleAcceleration,
            accelerationDirection: accelerationDirection,
            delay: delay,
            soundTimer: soundTimer,
            faceRoll: Int32(angle),
            playsSwingSound: playsSwingSound
        )
    }
}
