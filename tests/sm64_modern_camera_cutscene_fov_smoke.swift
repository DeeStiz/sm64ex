import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func hf(_ h: UInt64, _ v: Float) -> UInt64 { h32(h, v.bitPattern) }
private func hi16(_ h: UInt64, _ v: Int16) -> UInt64 { h16(h, UInt16(bitPattern: v)) }

private func hash(_ h: UInt64, _ vector: SM64ObjectVector3) -> UInt64 {
    var x = hf(h, vector.x); x = hf(x, vector.y); return hf(x, vector.z)
}

private func hash(_ h: UInt64, _ result: SM64CameraCutsceneSplineResult) -> UInt64 {
    var x = hash(h, result.point)
    x = hi16(x, result.state.segment); x = hf(x, result.state.progress)
    return h8(x, result.finished ? 1 : 0)
}

private func hash(_ h: UInt64, _ result: SM64CameraCutsceneClockResult) -> UInt64 {
    var x = hi16(h, result.state.cutscene)
    x = hi16(x, result.state.shot); x = hi16(x, result.state.timer)
    x = h8(x, result.stopped ? 1 : 0)
    return h8(x, result.advancedShot ? 1 : 0)
}

private func hash(_ h: UInt64, _ result: SM64CameraFOVResult) -> UInt64 {
    var x = hi16(h, result.state.mode)
    x = hf(x, result.state.fov); x = hf(x, result.state.fovOffset)
    x = hf(x, result.state.shakeAmplitude)
    x = hi16(x, result.state.shakePhase)
    x = hi16(x, result.state.shakeSpeed); x = hi16(x, result.state.decay)
    return hf(x, result.presentedFOV)
}

@main
enum SM64ModernCameraCutsceneFOVSmoke {
    static func main() {
        let points: [SM64CameraCutsceneSplinePoint] = [
            .init(index: 0, speed: 0, point: .init(x: -100, y: -50, z: -200)),
            .init(index: 1, speed: 4, point: .init(x: 0, y: 0, z: 0)),
            .init(index: 2, speed: 2, point: .init(x: 100, y: 50, z: 200)),
            .init(index: 3, speed: 1, point: .init(x: 200, y: 100, z: 400)),
            .init(index: -1, speed: 0, point: .init(x: 300, y: 150, z: 600))
        ]

        var fingerprint = fnvOffset
        let moved = SM64CameraCutscene.movePointAlongSpline(
            points: points,
            state: .init(segment: 0, progress: 0.25)
        )!
        precondition(moved.state.segment == 0 && moved.state.progress == 0.5625
            && !moved.finished && moved.point.x.isFinite)
        fingerprint = hash(fingerprint, moved)

        let finished = SM64CameraCutscene.movePointAlongSpline(
            points: points,
            state: .init(segment: 0, progress: 0)
        )!
        // Equal nonzero speeds advance one whole segment in the fixture, and
        // the fourth point's -1 sentinel wraps the segment back to zero.
        let finishPoints = [
            SM64CameraCutsceneSplinePoint(index: 0, speed: 0, point: .init(x: 0, y: 0, z: 0)),
            SM64CameraCutsceneSplinePoint(index: 1, speed: 1, point: .init(x: 0, y: 0, z: 0)),
            SM64CameraCutsceneSplinePoint(index: 2, speed: 1, point: .init(x: 0, y: 0, z: 0)),
            SM64CameraCutsceneSplinePoint(index: 3, speed: 1, point: .init(x: 0, y: 0, z: 0)),
            SM64CameraCutsceneSplinePoint(index: -1, speed: 0, point: .init(x: 0, y: 0, z: 0))
        ]
        let wrapped = SM64CameraCutscene.movePointAlongSpline(
            points: finishPoints,
            state: .init(segment: 0, progress: 0)
        )!
        precondition(finished.point.x.isFinite && finished.point.y.isFinite
            && finished.point.z.isFinite)
        precondition(wrapped.finished && wrapped.state.segment == 0
            && wrapped.state.progress == 0)
        fingerprint = hash(fingerprint, wrapped)

        precondition(SM64CameraCutscene.eventIsActive(timer: 10, start: 10, end: 10))
        precondition(SM64CameraCutscene.eventIsActive(timer: 11, start: 10, end: -1))
        precondition(!SM64CameraCutscene.eventIsActive(timer: 9, start: 10, end: -1))

        let clock = SM64CameraCutscene.advanceClock(
            state: .init(cutscene: 3, shot: 2, timer: 2),
            shotDuration: 3,
            cutsceneStillActive: true
        )!
        precondition(clock.state == .init(cutscene: 3, shot: 3, timer: 0)
            && clock.advancedShot && !clock.stopped)
        fingerprint = hash(fingerprint, clock)

        let stoppedClock = SM64CameraCutscene.advanceClock(
            state: .init(cutscene: 3, shot: 2, timer: Int16(bitPattern: 0x8000)),
            shotDuration: 30,
            cutsceneStillActive: true
        )!
        precondition(stoppedClock.stopped && stoppedClock.state.timer == 0)
        fingerprint = hash(fingerprint, stoppedClock)

        let base = SM64CameraFOVState(mode: SM64CameraFOVMode.set45.rawValue, fov: 40)
        let set45 = SM64CameraFOV.update(.init(
            state: base, sleeping: false, fixedMode: false, cutsceneActive: false
        ))!
        precondition(set45.state.fov == 45 && set45.presentedFOV == 45)
        fingerprint = hash(fingerprint, set45)

        let shakenState = SM64CameraFOV.requestShake(
            state: set45.state, amplitude: 0x100, decay: 0x30,
            speed: Int16(bitPattern: 0x8000)
        )
        let shaken = SM64CameraFOV.update(.init(
            state: shakenState, sleeping: false, fixedMode: false,
            cutsceneActive: false
        ))!
        precondition(shaken.state.fov == 45 && shaken.state.fovOffset == 1
            && shaken.presentedFOV == 46
            && shaken.state.shakeAmplitude == 208
            && shaken.state.shakePhase == Int16(bitPattern: 0x8000))
        fingerprint = hash(fingerprint, shaken)

        let sleeping = SM64CameraFOV.update(.init(
            state: .init(mode: SM64CameraFOVMode.default.rawValue, fov: 45),
            sleeping: true, fixedMode: false, cutsceneActive: false
        ))!
        precondition(sleeping.state.fov == 44.5)
        fingerprint = hash(fingerprint, sleeping)

        let bbh = SM64CameraFOV.update(.init(
            state: .init(mode: SM64CameraFOVMode.bbh.rawValue, fov: 45),
            sleeping: false, fixedMode: true, cutsceneActive: false
        ))!
        precondition(bbh.state.fov == 47)
        fingerprint = hash(fingerprint, bbh)

        precondition(SM64CameraFOV.update(.init(
            state: .init(mode: 99, fov: 45), sleeping: false,
            fixedMode: false, cutsceneActive: false
        )) == nil)
        print(String(format: "cameraCutsceneFOVFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern camera cutscene/FOV smoke passed")
    }
}
