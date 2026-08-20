import Foundation

/// Inputs sampled at the owner-thread boundary for `bhvSushiShark`.
///
/// The legacy callback keeps the orbit angle in `oSushiSharkUnkF4`, moves the
/// shark around its home point relative to the local water surface, and emits
/// a wave-trail request while Mario and the shark are in the water band.
struct SM64SushiSharkInput: Equatable, Sendable {
    let timer: Int32
    let homePosition: SM64ObjectVector3
    let orbitAngle: Int32
    let waterLevel: Float
    let marioY: Float
}

struct SM64SushiSharkOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let orbitAngle: Int32
    let spawnWaveTrail: Bool
    let playWaterSound: Bool
    let clearInteractionStatus: Bool
}

/// Value counterpart of `bhv_sushi_shark_loop`.
enum SM64SushiSharkBehavior {
    static func update(_ input: SM64SushiSharkInput) -> SM64SushiSharkOutput {
        let angle = Int16(truncatingIfNeeded: input.orbitAngle)
        let sine = SM64CanonicalTrig.sins(angle)
        let cosine = SM64CanonicalTrig.coss(angle)
        let position = SM64ObjectVector3(
            x: input.homePosition.x + SM64DeterministicPrimitives.cFloatMultiply(sine, 1_700),
            y: input.waterLevel + input.homePosition.y
                + SM64DeterministicPrimitives.cFloatMultiply(sine, 200),
            z: input.homePosition.z + SM64DeterministicPrimitives.cFloatMultiply(cosine, 1_700)
        )
        let sharkInWaterBand = position.y - input.waterLevel > -200
        let marioInWaterBand = input.marioY - input.waterLevel > -500
        return SM64SushiSharkOutput(
            position: position,
            moveYaw: input.orbitAngle &+ 0x4000,
            orbitAngle: input.orbitAngle &+ 0x80,
            spawnWaveTrail: marioInWaterBand && sharkInWaterBand,
            playWaterSound: (input.timer & 0xF) == 0,
            clearInteractionStatus: true
        )
    }
}
