import Foundation

struct SM64LllRotatingFireBarInput: Equatable, Sendable {
    let action: Int32
    let distanceToMario: Float
    let behaviorByte: UInt8
    let moveYaw: Int32
}

struct SM64LllRotatingFireBarOutput: Equatable, Sendable {
    let action: Int32
    let moveYaw: Int32
    let angleVelocityYaw: Int32
    let spawnFlames: Bool
    let flameCount: Int32
}

/// Value counterpart of `bhv_lll_rotating_block_fire_bars_loop`.
enum SM64LllRotatingFireBarBehavior {
    static func update(_ input: SM64LllRotatingFireBarInput)
        -> SM64LllRotatingFireBarOutput
    {
        var action = input.action
        var moveYaw = input.moveYaw
        var angleVelocityYaw: Int32 = 0
        var spawnFlames = false
        var flameCount: Int32 = 0
        switch input.action {
        case 0:
            if input.distanceToMario < 3000 { action = 1 }
        case 1:
            action = 2
            spawnFlames = true
            flameCount = input.behaviorByte == 0 ? 8 : 6
        case 2:
            angleVelocityYaw = -0x100
            moveYaw &-= 0x100
            if input.distanceToMario > 3200 { action = 3 }
        case 3:
            action = 0
        default:
            action = 0
        }
        return SM64LllRotatingFireBarOutput(
            action: action,
            moveYaw: moveYaw,
            angleVelocityYaw: angleVelocityYaw,
            spawnFlames: spawnFlames,
            flameCount: flameCount
        )
    }
}
