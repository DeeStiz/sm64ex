import Foundation

struct SM64HorizontalGrindelInput: Equatable, Sendable {
    let onGround: Bool
    let wasOnGround: Bool
    let lateralDistanceHome: Float
    let timer: Int32
    let moveYaw: Int32
    let targetYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
}

struct SM64HorizontalGrindelOutput: Equatable, Sendable {
    let onGround: Bool
    let timer: Int32
    let moveYaw: Int32
    let targetYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let faceYaw: Int32
    let impactSound: Bool
    let jumpSound: Bool
    let shake: Bool
}

enum SM64HorizontalGrindelBehavior {
    private static func approach(_ current: Int32, _ target: Int32, _ increment: Int32) -> (Int32, Bool) {
        let delta = Int16(truncatingIfNeeded: target &- current)
        if delta > increment { return (current &+ increment, false) }
        if delta < -increment { return (current &- increment, false) }
        return (target, true)
    }

    static func update(_ input: SM64HorizontalGrindelInput) -> SM64HorizontalGrindelOutput {
        var timer = input.timer
        var targetYaw = input.targetYaw
        var moveYaw = input.moveYaw
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY
        var gravity = input.gravity
        var impact = false
        var jump = false
        var shake = false
        var wasOnGround = input.wasOnGround

        if input.onGround {
            if !wasOnGround {
                impact = true; shake = true; wasOnGround = true; timer = 0; forwardVelocity = 0
            }
            let (nextYaw, aligned) = approach(moveYaw, targetYaw, 0x400)
            moveYaw = nextYaw
            if aligned {
                if timer > 60 {
                    if input.lateralDistanceHome > 300 {
                        targetYaw = Int32(Int16(truncatingIfNeeded: targetYaw &+ 0x8000)); timer = 0
                    } else {
                        jump = true; forwardVelocity = 11; velocityY = 70; gravity = -4; timer = 0; wasOnGround = false
                    }
                }
            } else { timer = 0 }
        } else {
            wasOnGround = false
            if velocityY < 0 { gravity = -16 }
            timer &+= 1
        }
        return .init(onGround: wasOnGround, timer: timer, moveYaw: moveYaw, targetYaw: targetYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, faceYaw: moveYaw &+ 0x4000, impactSound: impact, jumpSound: jump, shake: shake)
    }
}
