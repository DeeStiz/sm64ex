import Foundation

struct SM64SoundSpawnerInput: Equatable, Sendable {
    let timer: Int32
    let soundID: Int32
}

struct SM64SoundSpawnerOutput: Equatable, Sendable {
    let timer: Int32
    let soundID: Int32
    let playSound: Bool
    let shouldDelete: Bool
}

enum SM64SoundSpawnerBehavior {
    static func update(_ input: SM64SoundSpawnerInput) -> SM64SoundSpawnerOutput {
        .init(timer: input.timer &+ 1, soundID: input.soundID,
              playSound: input.timer == 3, shouldDelete: input.timer == 33)
    }
}
