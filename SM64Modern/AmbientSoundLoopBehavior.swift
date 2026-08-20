import Foundation

enum SM64AmbientSoundKind: UInt8, Equatable, Sendable {
    case birds = 0
    case sand = 1
}

struct SM64AmbientSoundLoopInput: Equatable, Sendable {
    let kind: SM64AmbientSoundKind
    let behaviorByte: UInt8
    let cameraBehindMario: Bool
}

struct SM64AmbientSoundLoopOutput: Equatable, Sendable {
    let playSound: Bool
    let soundIntent: Int32
}

/// Value counterparts of `bhv_birds_sound_loop` and `bhv_sand_sound_loop`.
enum SM64AmbientSoundLoopBehavior {
    static func update(_ input: SM64AmbientSoundLoopInput) -> SM64AmbientSoundLoopOutput {
        if input.cameraBehindMario {
            return SM64AmbientSoundLoopOutput(playSound: false, soundIntent: -1)
        }
        switch input.kind {
        case .birds:
            guard input.behaviorByte < 3 else {
                return SM64AmbientSoundLoopOutput(playSound: false, soundIntent: -1)
            }
            return SM64AmbientSoundLoopOutput(
                playSound: true,
                soundIntent: Int32(input.behaviorByte)
            )
        case .sand:
            return SM64AmbientSoundLoopOutput(playSound: true, soundIntent: 3)
        }
    }
}
