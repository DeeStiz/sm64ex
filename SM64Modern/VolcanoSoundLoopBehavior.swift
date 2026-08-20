import Foundation

struct SM64VolcanoSoundLoopOutput: Equatable, Sendable {
    let playVolcanoSound: Bool
}

/// Value counterpart of `bhv_volcano_sound_loop`.
enum SM64VolcanoSoundLoopBehavior {
    static func update() -> SM64VolcanoSoundLoopOutput {
        SM64VolcanoSoundLoopOutput(playVolcanoSound: true)
    }
}
