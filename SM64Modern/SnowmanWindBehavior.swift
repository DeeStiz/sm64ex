import Foundation

struct SM64SnowmanWindInput: Equatable, Sendable {
    let subAction: Int32
    let timer: Int32
    let originalYaw: Int32
    let moveYaw: Int32
    let angleToMario: Int32
    let distanceToMario: Float
    let marioY: Float
    let homeY: Float
    let canActivateText: Bool
    let dialogComplete: Bool
}

struct SM64SnowmanWindOutput: Equatable, Sendable {
    let subAction: Int32
    let timer: Int32
    let moveYaw: Int32
    let dialogID: Int32
    let spawnStrongWindParticles: Bool
    let particleCount: Int32
    let playWindSound: Bool
}

/// Value counterpart of `bhv_sl_snowman_wind_loop`.
enum SM64SnowmanWindBehavior {
    static func update(_ input: SM64SnowmanWindInput) -> SM64SnowmanWindOutput {
        var subAction = input.subAction
        var yaw = input.moveYaw
        var particles = false
        if subAction == 0 {
            if input.canActivateText { subAction = 1 }
        } else if subAction == 1 {
            if input.dialogComplete { subAction = 2 }
        } else if input.distanceToMario < 1_500 && abs(input.marioY - input.homeY) < 500 {
            let delta = Int16(truncatingIfNeeded: input.angleToMario &- input.originalYaw)
            if delta > 0 {
                yaw = delta < 0x1500 ? input.angleToMario : input.originalYaw &+ 0x1500
            } else {
                yaw = delta > -0x1500 ? input.angleToMario : input.originalYaw &- 0x1500
            }
            particles = true
        }
        return .init(subAction: subAction, timer: input.timer &+ 1, moveYaw: yaw, dialogID: 153, spawnStrongWindParticles: particles, particleCount: particles ? 12 : 0, playWindSound: particles)
    }
}
