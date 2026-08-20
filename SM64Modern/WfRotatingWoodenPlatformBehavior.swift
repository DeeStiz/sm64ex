import Foundation

struct SM64WfRotatingWoodenPlatformInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let faceYaw: Int32
}

struct SM64WfRotatingWoodenPlatformOutput: Equatable, Sendable {
    let action: Int32
    let faceYaw: Int32
    let angleVelocityYaw: Int32
    let playedSound: Bool
}

/// Value counterpart of `bhv_wf_rotating_wooden_platform_loop`.
enum SM64WfRotatingWoodenPlatformBehavior {
    static func update(_ input: SM64WfRotatingWoodenPlatformInput)
        -> SM64WfRotatingWoodenPlatformOutput
    {
        var action = input.action
        var angleVelocityYaw: Int32 = 0
        var playedSound = false
        if input.action == 0 {
            if input.timer > 60 { action = 1 }
        } else {
            angleVelocityYaw = 0x100
            if input.timer > 126 { action = 0 }
            playedSound = true
        }
        return SM64WfRotatingWoodenPlatformOutput(
            action: action,
            faceYaw: input.faceYaw &+ angleVelocityYaw,
            angleVelocityYaw: angleVelocityYaw,
            playedSound: playedSound
        )
    }
}
