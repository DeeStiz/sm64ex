import Foundation

enum SM64CameraFOVMode: Int16, Equatable, Sendable {
    case set45 = 1
    case `default` = 2
    case approach45 = 4
    case set30 = 5
    case approach20 = 6
    case bbh = 7
    case approach80 = 9
    case approach30 = 10
    case approach60 = 11
    case zoom30 = 12
    case set29 = 13
}

struct SM64CameraFOVState: Equatable, Sendable {
    let mode: Int16
    let fov: Float
    let fovOffset: Float
    let shakeAmplitude: Float
    let shakePhase: Int16
    let shakeSpeed: Int16
    let decay: Int16

    init(
        mode: Int16 = SM64CameraFOVMode.default.rawValue,
        fov: Float = 45,
        fovOffset: Float = 0,
        shakeAmplitude: Float = 0,
        shakePhase: Int16 = 0,
        shakeSpeed: Int16 = 0,
        decay: Int16 = 0
    ) {
        self.mode = mode
        self.fov = fov
        self.fovOffset = fovOffset
        self.shakeAmplitude = shakeAmplitude
        self.shakePhase = shakePhase
        self.shakeSpeed = shakeSpeed
        self.decay = decay
    }
}

struct SM64CameraFOVInput: Equatable, Sendable {
    let state: SM64CameraFOVState
    let sleeping: Bool
    let fixedMode: Bool
    let cutsceneActive: Bool
}

struct SM64CameraFOVResult: Equatable, Sendable {
    let state: SM64CameraFOVState
    let presentedFOV: Float
}

/// C-compatible FOV function selection and shake decay.  The result carries
/// both the unshaken FOV state and the frame's presented value; render code is
/// responsible for applying the latter to its perspective descriptor.
enum SM64CameraFOV {
    static func requestShake(
        state: SM64CameraFOVState,
        amplitude: Int16,
        decay: Int16,
        speed: Int16
    ) -> SM64CameraFOVState {
        guard amplitude > 0, Float(amplitude) > state.shakeAmplitude else {
            return state
        }
        return SM64CameraFOVState(
            mode: state.mode, fov: state.fov, fovOffset: state.fovOffset,
            shakeAmplitude: Float(amplitude), shakePhase: state.shakePhase,
            shakeSpeed: speed, decay: decay
        )
    }

    static func update(_ input: SM64CameraFOVInput) -> SM64CameraFOVResult? {
        guard input.state.fov.isFinite, input.state.fovOffset.isFinite,
              input.state.shakeAmplitude.isFinite,
              input.state.shakeAmplitude >= 0,
              input.state.decay >= 0 else { return nil }
        guard let mode = SM64CameraFOVMode(rawValue: input.state.mode) else {
            return nil
        }
        var fov = input.state.fov
        switch mode {
        case .set45:
            fov = 45
        case .default:
            let target: Float = input.sleeping ? 30 : 45
            fov = approachSymmetric(fov, target, (target - fov) / 30)
        case .approach45:
            fov = approachAsymmetric(fov, 45, 2)
        case .set30:
            fov = 30
        case .approach20:
            fov = approachSymmetric(fov, 20, 0.3)
        case .bbh:
            let target: Float = input.fixedMode && !input.cutsceneActive ? 60 : 45
            fov = approachAsymmetric(fov, target, 2)
        case .approach80:
            fov = approachSymmetric(fov, 80, 3.5)
        case .approach30:
            fov = approachSymmetric(fov, 30, 1)
        case .approach60:
            fov = approachSymmetric(fov, 60, 1)
        case .zoom30:
            fov = approachSymmetric(fov, 30, (30 - fov) / 60)
        case .set29:
            fov = 29
        }

        var fovOffset = input.state.fovOffset
        var phase = input.state.shakePhase
        var amplitude = input.state.shakeAmplitude
        if amplitude != 0 {
            fovOffset = SM64CanonicalTrig.coss(phase) * amplitude / 0x100
            phase = phase &+ input.state.shakeSpeed
            amplitude = approachSymmetric(
                amplitude, 0, Float(abs(Int32(input.state.decay)))
            )
            if amplitude == 0 { phase = 0 }
        } else {
            phase = 0
        }
        guard fov.isFinite, fovOffset.isFinite, amplitude.isFinite else {
            return nil
        }
        let state = SM64CameraFOVState(
            mode: input.state.mode, fov: fov, fovOffset: fovOffset,
            shakeAmplitude: amplitude, shakePhase: phase,
            shakeSpeed: input.state.shakeSpeed, decay: input.state.decay
        )
        return SM64CameraFOVResult(state: state, presentedFOV: fov + fovOffset)
    }

    private static func approachSymmetric(
        _ current: Float, _ target: Float, _ increment: Float
    ) -> Float {
        guard increment.isFinite else { return current }
        let step = abs(increment)
        var distance = target - current
        if distance > 0 {
            distance -= step
            return distance > 0 ? target - distance : target
        }
        distance += step
        return distance < 0 ? target - distance : target
    }

    private static func approachAsymmetric(
        _ current: Float, _ target: Float, _ increment: Float
    ) -> Float {
        if current < target { return min(current + increment, target) }
        return max(current - increment, target)
    }
}
