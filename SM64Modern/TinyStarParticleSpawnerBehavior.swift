import Foundation

enum SM64TinyStarParticleSpawnerKind: UInt8, Equatable, Sendable {
    case vertical = 0
    case horizontal = 1
}

struct SM64TinyStarParticleSeed: Equatable, Sendable {
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
}

struct SM64TinyStarParticleSpawnerInput: Equatable, Sendable {
    let kind: SM64TinyStarParticleSpawnerKind
    let position: SM64ObjectVector3
    let timer: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
    let seeds: [SM64TinyStarParticleSeed]
}

struct SM64TinyStarParticleSpawnerOutput: Equatable, Sendable {
    let seeds: [SM64TinyStarParticleSeed]
    let clearParticleFlag: Bool
    let shouldSpawnChildren: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of the vertical/horizontal tiny-star particle spawners.
enum SM64TinyStarParticleSpawnerBehavior {
    static func update(_ input: SM64TinyStarParticleSpawnerInput) -> SM64TinyStarParticleSpawnerOutput {
        let firstTick = input.timer == 0
        return SM64TinyStarParticleSpawnerOutput(
            seeds: firstTick ? input.seeds : [],
            clearParticleFlag: firstTick && (input.activeParticleFlags & input.particleFlag != 0),
            shouldSpawnChildren: firstTick,
            shouldDeactivate: input.timer >= 1
        )
    }
}
