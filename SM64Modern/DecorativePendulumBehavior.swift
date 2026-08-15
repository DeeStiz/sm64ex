import Foundation

struct SM64DecorativePendulumInitialization: Equatable, Sendable {
    let angleVelocityRoll: Int32
    let initializesRoom: Bool
}

struct SM64DecorativePendulumInput: Equatable, Sendable {
    let faceRoll: Int32
    let angleVelocityRoll: Int32
}

struct SM64DecorativePendulumOutput: Equatable, Sendable {
    let faceRoll: Int32
    let angleVelocityRoll: Int32
    let playsClockSound: Bool
}

/// Value counterpart of `bhv_decorative_pendulum_init` and
/// `bhv_decorative_pendulum_loop`.
enum SM64DecorativePendulumBehavior {
    static func initialize() -> SM64DecorativePendulumInitialization {
        SM64DecorativePendulumInitialization(angleVelocityRoll: 0x100, initializesRoom: true)
    }

    static func update(_ input: SM64DecorativePendulumInput) -> SM64DecorativePendulumOutput {
        var angleVelocityRoll = input.angleVelocityRoll
        if input.faceRoll > 0 {
            angleVelocityRoll &-= 0x08
        } else {
            angleVelocityRoll &+= 0x08
        }
        let faceRoll = input.faceRoll &+ angleVelocityRoll
        return SM64DecorativePendulumOutput(
            faceRoll: faceRoll,
            angleVelocityRoll: angleVelocityRoll,
            playsClockSound: angleVelocityRoll == 0x10 || angleVelocityRoll == -0x10
        )
    }
}
