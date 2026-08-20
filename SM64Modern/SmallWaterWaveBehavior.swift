import Foundation

struct SM64SmallWaterWaveInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let waterLevel: Float
    let angleX: Int32
    let angleZ: Int32
    let angleVelocityX: Int32
    let angleVelocityZ: Int32
    let timer: Int32
    let interacted: Bool
}

struct SM64SmallWaterWaveOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let scaleX: Float
    let scaleZ: Float
    let angleX: Int32
    let angleZ: Int32
    let timer: Int32
    let shouldDeactivate: Bool
    let shouldDelete: Bool
    let spawnSplash: Bool
}

/// Value counterpart of `bhv_small_water_wave_loop`; the script-only 398
/// subroutine is represented by the owner before this native reducer runs.
enum SM64SmallWaterWaveBehavior {
    static func update(_ input: SM64SmallWaterWaveInput) -> SM64SmallWaterWaveOutput {
        var position = input.position
        position.y += 7
        let scaleX = SM64DeterministicPrimitives.cFloatMultiply(
            SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.angleX)), 0.2
        ) + 1
        let scaleZ = SM64DeterministicPrimitives.cFloatMultiply(
            SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.angleZ)), 0.2
        ) + 1
        let shouldDeactivate = position.y > input.waterLevel
        if shouldDeactivate { position.y += 5 }
        return SM64SmallWaterWaveOutput(
            position: position,
            scaleX: scaleX,
            scaleZ: scaleZ,
            angleX: input.angleX &+ input.angleVelocityX,
            angleZ: input.angleZ &+ input.angleVelocityZ,
            timer: input.timer &+ 1,
            shouldDeactivate: shouldDeactivate || input.timer >= 59,
            shouldDelete: input.interacted,
            spawnSplash: shouldDeactivate
        )
    }
}
