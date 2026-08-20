import Foundation

struct SM64MistParticleSpawnerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
}

struct SM64MistParticleSpawnerOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let spawnPuff1: Bool
    let spawnPuff2: Bool
    let clearParticleFlag: Bool
    let shouldDeactivate: Bool
}

enum SM64MistParticleSpawnerBehavior {
    static func update(_ input: SM64MistParticleSpawnerInput) -> SM64MistParticleSpawnerOutput {
        let active = input.activeParticleFlags & input.particleFlag != 0
        return SM64MistParticleSpawnerOutput(position: input.position, spawnPuff1: input.timer == 0 && active, spawnPuff2: input.timer == 0 && active, clearParticleFlag: active, shouldDeactivate: input.timer >= 1)
    }
}
