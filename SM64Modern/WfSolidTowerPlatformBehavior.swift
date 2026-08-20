import Foundation

struct SM64WfSolidTowerPlatformInput: Equatable, Sendable {
    let parentAction: Int32
}

struct SM64WfSolidTowerPlatformOutput: Equatable, Sendable {
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_wf_solid_tower_platform_loop`.
enum SM64WfSolidTowerPlatformBehavior {
    static func update(_ input: SM64WfSolidTowerPlatformInput)
        -> SM64WfSolidTowerPlatformOutput
    {
        SM64WfSolidTowerPlatformOutput(shouldDelete: input.parentAction == 3)
    }
}
