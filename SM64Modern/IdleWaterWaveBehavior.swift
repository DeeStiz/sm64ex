import Foundation

struct SM64IdleWaterWaveInput: Equatable, Sendable {
    let animationState: Int32
    let globalTimer: UInt64
    let marioPosition: SM64ObjectVector3
    let marioWaterLevel: Float
    let marioParticleFlags: UInt32
    let idleParticleFlag: UInt32

    init(
        animationState: Int32,
        globalTimer: UInt64,
        marioPosition: SM64ObjectVector3 = .zero,
        marioWaterLevel: Float = 0,
        marioParticleFlags: UInt32 = 0,
        idleParticleFlag: UInt32 = 0x80
    ) {
        self.animationState = animationState
        self.globalTimer = globalTimer
        self.marioPosition = marioPosition
        self.marioWaterLevel = marioWaterLevel
        self.marioParticleFlags = marioParticleFlags
        self.idleParticleFlag = idleParticleFlag
    }
}

struct SM64IdleWaterWaveOutput: Equatable, Sendable {
    let animationState: Int32
    let position: SM64ObjectVector3
    let deactivate: Bool
    let clearMarioFlag: Bool
}

/// Value counterparts of `bhv_idle_water_wave_loop` and
/// `bhv_object_water_wave_loop`.
enum SM64IdleWaterWaveBehavior {
    static func update(_ input: SM64IdleWaterWaveInput) -> SM64IdleWaterWaveOutput {
        updateObject(input)
    }

    static func updateIdle(_ input: SM64IdleWaterWaveInput) -> SM64IdleWaterWaveOutput {
        SM64IdleWaterWaveOutput(
            animationState: input.animationState &+ 1,
            position: SM64ObjectVector3(
                x: input.marioPosition.x,
                y: input.marioWaterLevel + 5,
                z: input.marioPosition.z
            ),
            deactivate: input.marioParticleFlags & input.idleParticleFlag == 0,
            clearMarioFlag: input.marioParticleFlags & input.idleParticleFlag == 0
        )
    }

    static func updateObject(_ input: SM64IdleWaterWaveInput) -> SM64IdleWaterWaveOutput {
        SM64IdleWaterWaveOutput(
            animationState: input.animationState &+ 1,
            position: input.marioPosition,
            deactivate: input.globalTimer % 16 == 0,
            clearMarioFlag: false
        )
    }
}
