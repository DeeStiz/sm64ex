import Foundation

struct SM64PlungeBubbleInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
}

struct SM64PlungeBubbleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let spawnParticleCount: Int32
    let clearParticleFlag: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_water_waves_init` and `bhvPlungeBubble`.
enum SM64PlungeBubbleBehavior {
    static func update(_ input: SM64PlungeBubbleInput) -> SM64PlungeBubbleOutput {
        let active = input.activeParticleFlags & input.particleFlag != 0
        return SM64PlungeBubbleOutput(
            position: input.position,
            spawnParticleCount: active ? 3 : 0,
            clearParticleFlag: active,
            shouldDeactivate: true
        )
    }
}
