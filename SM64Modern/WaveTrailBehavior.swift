import Foundation

enum SM64WaveTrailKind: UInt8, Equatable, Sendable {
    case mario = 0
    case object = 1
}

struct SM64WaveTrailInput: Equatable, Sendable {
    let kind: SM64WaveTrailKind
    let position: SM64ObjectVector3
    let waterLevel: Float
    let timer: Int32
    let globalFrame: UInt64
    let animationState: Int32
    let waveTrailSize: Float
    let initialScale: Float
}

struct SM64WaveTrailOutput: Equatable, Sendable {
    let kind: SM64WaveTrailKind
    let position: SM64ObjectVector3
    let animationState: Int32
    let waveTrailSize: Float
    let scaleX: Float
    let scaleZ: Float
    let clearParticleFlag: Bool
    let shouldDelete: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_wave_trail_shrink` and the common wave-trail
/// behavior script used by Mario and object-created trails.
enum SM64WaveTrailBehavior {
    static func update(_ input: SM64WaveTrailInput) -> SM64WaveTrailOutput {
        let animationState: Int32 = input.timer % 2 == 0
            ? min(7, input.animationState + 1)
            : input.animationState
        var size = input.timer == 0 ? input.initialScale : input.waveTrailSize
        if animationState > 3 {
            size = max(0, size - 0.1)
        }
        let alternateFrameDelete = input.timer == 0 && input.globalFrame & 1 != 0
        let finished = input.timer >= 15
        return SM64WaveTrailOutput(
            kind: input.kind,
            position: SM64ObjectVector3(
                x: input.position.x,
                y: input.waterLevel + 5,
                z: input.position.z
            ),
            animationState: animationState,
            waveTrailSize: size,
            scaleX: size,
            scaleZ: size,
            clearParticleFlag: input.kind == .mario && finished,
            shouldDelete: alternateFrameDelete,
            shouldDeactivate: finished
        )
    }
}
