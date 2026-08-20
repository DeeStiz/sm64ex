import Foundation

struct SM64AmbientSoundsInput: Equatable, Sendable {
    let cameraBehindMario: Bool
}

struct SM64AmbientSoundsOutput: Equatable, Sendable {
    let playCastleOutdoorsAmbient: Bool
}

/// Value counterpart of `bhv_ambient_sounds_init`.
enum SM64AmbientSoundsBehavior {
    static func update(_ input: SM64AmbientSoundsInput) -> SM64AmbientSoundsOutput {
        SM64AmbientSoundsOutput(playCastleOutdoorsAmbient: !input.cameraBehindMario)
    }
}
