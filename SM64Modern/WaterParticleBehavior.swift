import Foundation

enum SM64WaterParticleKind: UInt8, Equatable, Sendable {
    case small = 0
    case snow = 1
    case bubbles = 2
}

struct SM64WaterParticleInput: Equatable, Sendable {
    let kind: SM64WaterParticleKind
    let position: SM64ObjectVector3
    let angleX: Int32
    let angleZ: Int32
    let angleVelocityX: Int32
    let angleVelocityZ: Int32
    let timer: Int32
    let waterLevel: Float
    let randomStepX: Float
    let randomStepZ: Float
}

struct SM64WaterParticleOutput: Equatable, Sendable {
    let kind: SM64WaterParticleKind
    let position: SM64ObjectVector3
    let scaleX: Float
    let scaleY: Float
    let angleX: Int32
    let angleZ: Int32
    let timer: Int32
    let spawnObjectSplash: Bool
    let shouldDelete: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_particle_loop` and `bhv_small_bubbles_loop`.
enum SM64WaterParticleBehavior {
    static func update(_ input: SM64WaterParticleInput) -> SM64WaterParticleOutput {
        var position = input.position
        position.y += 5
        position.x += input.randomStepX
        position.z += input.randomStepZ
        let scaleX = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.angleX)) * 0.5 + 2
        let scaleY = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.angleZ)) * 0.5 + 2
        let nextTimer = input.timer &+ 1
        let crossesWater = input.kind != .bubbles && input.timer > 0 && position.y > input.waterLevel
        let lifetime: Int32 = input.kind == .snow ? 30 : 70
        return SM64WaterParticleOutput(
            kind: input.kind,
            position: position,
            scaleX: scaleX,
            scaleY: scaleY,
            angleX: input.angleX &+ input.angleVelocityX,
            angleZ: input.angleZ &+ input.angleVelocityZ,
            timer: nextTimer,
            spawnObjectSplash: crossesWater,
            shouldDelete: crossesWater,
            shouldDeactivate: input.timer >= lifetime - 1
        )
    }
}
