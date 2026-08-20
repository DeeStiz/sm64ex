import Foundation

struct SM64WaterfallSoundLoopOutput: Equatable, Sendable {
    let playWaterfallSound: Bool
}

/// Value counterpart of `bhv_waterfall_sound_loop`.
enum SM64WaterfallSoundLoopBehavior {
    static func update() -> SM64WaterfallSoundLoopOutput {
        SM64WaterfallSoundLoopOutput(playWaterfallSound: true)
    }
}
