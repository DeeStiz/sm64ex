import Foundation

struct SM64MrBlizzardSnowballInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
    let gravity: Float
    let moveYaw: Int32
    let forwardVelocity: Float
    let parentHolding: Bool
    let parentThrowing: Bool
    let parentYaw: Int32
    let distanceToMario: Float
    let onGround: Bool
    let enteredWater: Bool
}

struct SM64MrBlizzardSnowballOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
    let moveYaw: Int32
    let forwardVelocity: Float
    let shouldDelete: Bool
    let spawnWhiteParticles: Bool
    let playSandSound: Bool
    let hitboxRadius: Float
    let hitboxHeight: Float
}

/// Value counterpart of `bhv_mr_blizzard_snowball`.
enum SM64MrBlizzardSnowballBehavior {
    static func update(_ input: SM64MrBlizzardSnowballInput) -> SM64MrBlizzardSnowballOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var velocityY = input.velocityY
        var yaw = input.moveYaw
        var forward = input.forwardVelocity
        var delete = false
        if action == 0 {
            if input.parentHolding { action = 1 }
            position.y += velocityY
            velocityY += input.gravity
        } else if action == 1 {
            if !input.parentHolding {
                if input.parentThrowing {
                    let distance = min(input.distanceToMario, 800)
                    yaw = input.parentYaw &+ 4000 &- Int32(distance * 4)
                    forward = 40
                    velocityY = -20 + distance * 0.075
                }
                action = 2
                timer = 0
            }
        } else if action == 2 {
            if input.onGround || input.enteredWater {
                delete = true
            } else {
                let angle = Int16(truncatingIfNeeded: yaw)
                position.x += SM64CanonicalTrig.sins(angle) * forward
                position.z += SM64CanonicalTrig.coss(angle) * forward
                position.y += velocityY
                velocityY += input.gravity
            }
        }
        return .init(action: action, timer: timer, position: position, velocityY: velocityY, moveYaw: yaw, forwardVelocity: forward, shouldDelete: delete, spawnWhiteParticles: delete, playSandSound: delete, hitboxRadius: 30, hitboxHeight: 30)
    }
}
