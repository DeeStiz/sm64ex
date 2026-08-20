import Foundation

struct SM64UnlockDoorStarInput: Equatable, Sendable {
    let state: Int32
    let timer: Int32
    let moveYaw: Int32
    let yawVelocity: Int32
    let positionY: Float
    let scale: Float
}

struct SM64UnlockDoorStarOutput: Equatable, Sendable {
    let state: Int32
    let timer: Int32
    let moveYaw: Int32
    let yawVelocity: Int32
    let positionY: Float
    let scale: Float
    let hidden: Bool
    let spawnParticles: Bool
    let shouldDelete: Bool
    let playMenuSound: Bool
}

/// Value counterpart of `bhv_unlock_door_star_init/loop`.
enum SM64UnlockDoorStarBehavior {
    static func update(_ input: SM64UnlockDoorStarInput) -> SM64UnlockDoorStarOutput {
        var state = input.state
        var timer = input.timer
        var yaw = input.moveYaw
        var yawVelocity = input.yawVelocity
        var positionY = input.positionY
        var scale = input.scale
        var hidden = state >= 2
        var particles = false
        var shouldDelete = false
        var menuSound = false
        if yawVelocity < 0x2400 { yawVelocity = min(yawVelocity &+ 0x60, 0x2400) }
        switch state {
        case 0:
            positionY += 3.4
            yaw &+= yawVelocity
            scale = Float(timer) / 50 + 0.5
            timer &+= 1
            if timer == 30 { timer = 0; state = 1 }
        case 1:
            yaw &+= yawVelocity
            timer &+= 1
            if timer == 30 { menuSound = true; hidden = true; timer = 0; state = 2 }
        case 2:
            hidden = true
            particles = true
            if timer == 20 { timer = 0; state = 3 } else { timer &+= 1 }
        case 3:
            hidden = true
            if timer == 50 { shouldDelete = true }
            timer &+= 1
        default:
            hidden = true
        }
        return .init(state: state, timer: timer, moveYaw: yaw, yawVelocity: yawVelocity, positionY: positionY, scale: scale, hidden: hidden, spawnParticles: particles, shouldDelete: shouldDelete, playMenuSound: menuSound)
    }
}
