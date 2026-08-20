import Foundation

struct SM64TriangleParticleSpawnerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
    let seeds: [SM64TinyStarParticleSeed]
}

struct SM64TriangleParticleSpawnerOutput: Equatable, Sendable {
    let seeds: [SM64TinyStarParticleSeed]
    let clearParticleFlag: Bool
    let shouldSpawnChildren: Bool
    let shouldDeactivate: Bool
}

enum SM64TriangleParticleSpawnerBehavior {
    static func update(_ input: SM64TriangleParticleSpawnerInput) -> SM64TriangleParticleSpawnerOutput {
        let firstTick = input.timer == 0
        return .init(seeds: firstTick ? input.seeds : [], clearParticleFlag: firstTick && (input.activeParticleFlags & input.particleFlag != 0), shouldSpawnChildren: firstTick, shouldDeactivate: input.timer >= 1)
    }
}
