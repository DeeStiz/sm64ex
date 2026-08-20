import Foundation

struct SM64BreathParticleSpawnerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
}

struct SM64BreathParticleSpawnerOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let spawnMist: Bool
    let clearParticleFlag: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_water_mist_spawn_loop` and the breath spawner
/// behavior script.
enum SM64BreathParticleSpawnerBehavior {
    static func update(_ input: SM64BreathParticleSpawnerInput) -> SM64BreathParticleSpawnerOutput {
        let active = input.activeParticleFlags & input.particleFlag != 0
        let activePhase = input.timer < 8
        return SM64BreathParticleSpawnerOutput(
            position: input.position,
            spawnMist: active && activePhase,
            clearParticleFlag: active,
            shouldDeactivate: input.timer >= 7
        )
    }
}
