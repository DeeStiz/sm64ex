import Foundation

struct SM64WfTowerPlatformGroupInput: Equatable, Sendable {
    let action: Int32
    let marioY: Float
    let homeY: Float
}

struct SM64WfTowerPlatformGroupOutput: Equatable, Sendable {
    let action: Int32
    let spawnChildren: Bool
}

/// Value counterpart of `bhv_tower_platform_group_loop`.
enum SM64WfTowerPlatformGroupBehavior {
    static func update(_ input: SM64WfTowerPlatformGroupInput)
        -> SM64WfTowerPlatformGroupOutput
    {
        var action = input.action
        var spawnChildren = false
        switch input.action {
        case 0:
            if input.marioY > input.homeY - 1000 { action = 1 }
        case 1:
            action = 2
            spawnChildren = true
        case 2:
            if input.marioY < input.homeY - 1000 { action = 3 }
        case 3:
            action = 0
        default:
            action = 0
        }
        return SM64WfTowerPlatformGroupOutput(action: action, spawnChildren: spawnChildren)
    }
}
