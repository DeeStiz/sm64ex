import Foundation

enum SM64ShallowWaterParticleKind: UInt8, Equatable, Sendable {
    case wave = 0
    case splash = 1
}

struct SM64ShallowWaterWaveInput: Equatable, Sendable {
    let kind: SM64ShallowWaterParticleKind
    let position: SM64ObjectVector3
    let timer: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
    let waterLevel: Float
}

struct SM64ShallowWaterWaveOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let spawnDropletCount: Int32
    let clearParticleFlag: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of the shallow-water-wave behavior script. The five
/// droplet random draws are supplied by the owner as explicit child inputs.
enum SM64ShallowWaterWaveBehavior {
    static func update(_ input: SM64ShallowWaterWaveInput) -> SM64ShallowWaterWaveOutput {
        let active = input.activeParticleFlags & input.particleFlag != 0
        let spawnCount: Int32 = input.kind == .wave ? 5 : 18
        return SM64ShallowWaterWaveOutput(
            position: input.position,
            spawnDropletCount: input.timer == 0 && active ? spawnCount : 0,
            clearParticleFlag: active,
            shouldDeactivate: input.timer >= 1
        )
    }
}
