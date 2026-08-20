import Foundation

enum SM64EndCutsceneActorRole: UInt8, Equatable, Sendable { case peach = 0; case toad = 1 }

struct SM64EndCutsceneActorInput: Equatable, Sendable {
    let role: SM64EndCutsceneActorRole
    let animationIndex: Int32
    let positionX: Float
    let nearAnimationEnd: Bool
}

struct SM64EndCutsceneActorOutput: Equatable, Sendable {
    let role: SM64EndCutsceneActorRole
    let animationIndex: Int32
    let advanced: Bool
}

/// Value counterpart of `bhv_end_peach_loop` and `bhv_end_toad_loop`.
enum SM64EndCutsceneActorBehavior {
    static func update(_ input: SM64EndCutsceneActorInput) -> SM64EndCutsceneActorOutput {
        var animation = input.animationIndex
        var advanced = false
        if input.nearAnimationEnd {
            switch input.role {
            case .peach:
                if animation < 3 || animation == 6 || animation == 7 {
                    animation += 1
                    advanced = true
                }
            case .toad:
                if animation == 0 || animation == 2 {
                    animation += 1
                    advanced = true
                }
            }
        }
        return .init(role: input.role, animationIndex: animation, advanced: advanced)
    }
}
