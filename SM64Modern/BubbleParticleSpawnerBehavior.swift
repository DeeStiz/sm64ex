import Foundation

struct SM64BubbleParticleSpawnerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let delay: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
}

struct SM64BubbleParticleSpawnerOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let spawnChild: Bool
    let clearParticleFlag: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of the `bhvBubbleParticleSpawner` script.
enum SM64BubbleParticleSpawnerBehavior {
    static func update(_ input: SM64BubbleParticleSpawnerInput) -> SM64BubbleParticleSpawnerOutput {
        let ready = input.timer >= input.delay
        let active = input.activeParticleFlags & input.particleFlag != 0
        return SM64BubbleParticleSpawnerOutput(
            position: input.position,
            spawnChild: ready && active,
            clearParticleFlag: ready && active,
            shouldDeactivate: ready
        )
    }
}
