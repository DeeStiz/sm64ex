import Foundation

struct SM64WaterSplashSpawnerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
    let waterLevel: Float
}

struct SM64WaterSplashSpawnerOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let animationState: Int32
    let spawnDropletCount: Int32
    let clearParticleFlag: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_water_splash_spawn_droplets` and the ordered
/// repeat/delay tail in `bhvWaterSplash`.
enum SM64WaterSplashSpawnerBehavior {
    static func update(_ input: SM64WaterSplashSpawnerInput) -> SM64WaterSplashSpawnerOutput {
        let inDropletPhase = input.timer < 6
        let active = input.activeParticleFlags & input.particleFlag != 0
        return SM64WaterSplashSpawnerOutput(
            position: SM64ObjectVector3(
                x: input.position.x,
                y: input.timer == 0 ? input.waterLevel : input.position.y,
                z: input.position.z
            ),
            animationState: input.timer < 11 ? input.timer : 10,
            spawnDropletCount: inDropletPhase && active ? 3 : 0,
            clearParticleFlag: input.timer >= 11 && active,
            shouldDeactivate: input.timer >= 11
        )
    }
}
