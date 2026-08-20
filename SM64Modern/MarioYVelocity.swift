import Foundation

struct SM64MarioYVelocityInput: Equatable, Sendable {
    let initialVelocityY: Float
    let forwardVelocity: Float
    let multiplier: Float
    let squishTimer: Bool
    let quicksandDepth: Float
}

struct SM64MarioYVelocityResult: Equatable, Sendable {
    let velocityY: Float
    let halfSpeedApplied: Bool
}

/// Value counterpart of `set_mario_y_vel_based_on_fspeed`; C retains the
/// legacy additive-Y trampoline call and Mario state mutation.
enum SM64MarioYVelocity {
    static func update(_ input: SM64MarioYVelocityInput) -> SM64MarioYVelocityResult? {
        guard input.initialVelocityY.isFinite,
              input.forwardVelocity.isFinite,
              input.multiplier.isFinite,
              input.quicksandDepth.isFinite else { return nil }
        var velocityY = input.initialVelocityY + input.forwardVelocity * input.multiplier
        let halfSpeedApplied = input.squishTimer || input.quicksandDepth > 1
        if halfSpeedApplied { velocityY *= 0.5 }
        return SM64MarioYVelocityResult(
            velocityY: velocityY,
            halfSpeedApplied: halfSpeedApplied
        )
    }
}
