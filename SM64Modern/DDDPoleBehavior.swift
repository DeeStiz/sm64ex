import Foundation

struct SM64DDDPoleInput: Equatable, Sendable {
    let timer: Int32
    let offset: Float
    let velocity: Float
    let maxOffset: Float
    let saveUnlocked: Bool
}

struct SM64DDDPoleOutput: Equatable, Sendable {
    let timer: Int32
    let offset: Float
    let velocity: Float
    let hitboxDownOffset: Float
    let shouldDelete: Bool
    let bounced: Bool
}

/// Value counterpart of `bhv_ddd_pole_init` and `bhv_ddd_pole_update`.
enum SM64DDDPoleBehavior {
    static func update(_ input: SM64DDDPoleInput) -> SM64DDDPoleOutput {
        guard input.saveUnlocked else {
            return .init(timer: input.timer, offset: input.offset, velocity: input.velocity, hitboxDownOffset: 100, shouldDelete: true, bounced: false)
        }
        var timer = input.timer &+ 1
        var offset = input.offset
        var velocity = input.velocity
        var bounced = false
        if input.timer > 20 {
            offset += velocity
            if offset < 0 {
                offset = 0
                velocity = -velocity
                timer = 0
                bounced = true
            } else if offset > input.maxOffset {
                offset = input.maxOffset
                velocity = -velocity
                timer = 0
                bounced = true
            }
        }
        return .init(timer: timer, offset: offset, velocity: velocity, hitboxDownOffset: 100, shouldDelete: false, bounced: bounced)
    }
}
