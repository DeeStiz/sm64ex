import Foundation

struct SM64MistCircParticleSeed: Equatable, Sendable {
    let randomScaleUnit: Float
    let randomYaw: Int32
    let randomForwardUnit: Float
}

struct SM64MistCircParticleSpawnerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
    let seeds: [SM64MistCircParticleSeed]
}

struct SM64MistCircParticleChild: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let scale: Float
    let gravity: Float
    let dragStrength: Float
    let behaviorParam: Int32
}

struct SM64MistCircParticleSpawnerOutput: Equatable, Sendable {
    let children: [SM64MistCircParticleChild]
    let clearParticleFlag: Bool
    let shouldSpawnChildren: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_pound_white_puffs_init` plus `D_8032F3CC`.
enum SM64MistCircParticleSpawnerBehavior {
    static func update(_ input: SM64MistCircParticleSpawnerInput) -> SM64MistCircParticleSpawnerOutput {
        let firstTick = input.timer == 0
        guard firstTick else {
            return .init(children: [], clearParticleFlag: false, shouldSpawnChildren: false, shouldDeactivate: true)
        }
        let seeds = Array(input.seeds.prefix(20))
        let children = seeds.map { seed in
            let forwardVelocity = seed.randomForwardUnit * 5 + 10
            return SM64MistCircParticleChild(
                position: .init(x: input.position.x, y: input.position.y + 20, z: input.position.z),
                velocity: .init(
                    x: forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: seed.randomYaw)),
                    y: 0,
                    z: forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: seed.randomYaw))
                ),
                scale: seed.randomScaleUnit * 0.15 + 3,
                gravity: 0,
                dragStrength: 30,
                behaviorParam: 3
            )
        }
        return .init(
            children: children,
            clearParticleFlag: (input.activeParticleFlags & input.particleFlag) != 0,
            shouldSpawnChildren: true,
            shouldDeactivate: false
        )
    }
}
