import Foundation

struct SM64CameraCutsceneSplinePoint: Equatable, Sendable {
    let index: Int8
    let speed: UInt8
    let point: SM64ObjectVector3
}

struct SM64CameraCutsceneSplineState: Equatable, Sendable {
    let segment: Int16
    let progress: Float
}

struct SM64CameraCutsceneSplineResult: Equatable, Sendable {
    let point: SM64ObjectVector3
    let state: SM64CameraCutsceneSplineState
    let finished: Bool
}

struct SM64CameraCutsceneClockState: Equatable, Sendable {
    let cutscene: Int16
    let shot: Int16
    let timer: Int16
}

struct SM64CameraCutsceneClockResult: Equatable, Sendable {
    let state: SM64CameraCutsceneClockState
    let stopped: Bool
    let advancedShot: Bool
}

/// Value-only cutscene timing and spline kernels.  The owner thread supplies
/// the selected shot and installs the returned camera vectors; this boundary
/// never calls a C camera-event function or touches a mutable object pointer.
enum SM64CameraCutscene {
    static let cutsceneStop: Int16 = Int16(bitPattern: 0x8000)
    static let cutsceneLoop: Int16 = 0x7FFF

    static func movePointAlongSpline(
        points: [SM64CameraCutsceneSplinePoint],
        state: SM64CameraCutsceneSplineState
    ) -> SM64CameraCutsceneSplineResult? {
        guard points.count >= 4, state.progress.isFinite,
              state.progress >= 0 else { return nil }

        var segment = Int(state.segment)
        var progress = state.progress
        if segment < 0 {
            segment = 0
            progress = 0
        }
        guard segment + 2 < points.count else { return nil }
        if points[segment].index == -1
            || points[segment + 1].index == -1
            || points[segment + 2].index == -1 {
            return SM64CameraCutsceneSplineResult(
                point: points[segment].point,
                state: SM64CameraCutsceneSplineState(
                    segment: Int16(truncatingIfNeeded: segment), progress: progress
                ),
                finished: true
            )
        }

        let point = evaluateCubicSpline(
            progress,
            points[segment].point,
            points[segment + 1].point,
            points[segment + 2].point,
            points[segment + 3].point
        )
        let firstSpeed = points[segment + 1].speed == 0
            ? Float(0)
            : Float(1) / Float(points[segment + 1].speed)
        let secondSpeed = points[segment + 2].speed == 0
            ? Float(0)
            : Float(1) / Float(points[segment + 2].speed)
        let progressChange = (secondSpeed - firstSpeed) * progress + firstSpeed
        progress += progressChange

        var finished = false
        if progress >= 1 {
            segment += 1
            guard segment + 3 < points.count else { return nil }
            if points[segment + 3].index == -1 {
                segment = 0
                finished = true
            }
            progress -= 1
        }
        return SM64CameraCutsceneSplineResult(
            point: point,
            state: SM64CameraCutsceneSplineState(
                segment: Int16(truncatingIfNeeded: segment), progress: progress
            ),
            finished: finished
        )
    }

    static func eventIsActive(timer: Int16, start: Int16, end: Int16) -> Bool {
        timer >= start && (end == -1 || timer <= end)
    }

    static func advanceClock(
        state: SM64CameraCutsceneClockState,
        shotDuration: Int16,
        cutsceneStillActive: Bool
    ) -> SM64CameraCutsceneClockResult? {
        guard shotDuration >= 0 else { return nil }
        var next = state
        var advancedShot = false
        let timerBits = UInt16(bitPattern: state.timer)
        if cutsceneStillActive && shotDuration != 0
            && timerBits & UInt16(bitPattern: Self.cutsceneStop) == 0 {
            if state.timer < 0x3FFF {
                next = SM64CameraCutsceneClockState(
                    cutscene: state.cutscene,
                    shot: state.shot,
                    timer: state.timer &+ 1
                )
            }
            if next.timer == shotDuration {
                next = SM64CameraCutsceneClockState(
                    cutscene: state.cutscene,
                    shot: state.shot &+ 1,
                    timer: 0
                )
                advancedShot = true
            }
        } else {
            next = SM64CameraCutsceneClockState(
                cutscene: state.cutscene, shot: 0, timer: 0
            )
        }
        return SM64CameraCutsceneClockResult(
            state: next,
            stopped: !cutsceneStillActive || shotDuration == 0
                || timerBits & UInt16(bitPattern: Self.cutsceneStop) != 0,
            advancedShot: advancedShot
        )
    }

    private static func evaluateCubicSpline(
        _ progress: Float,
        _ a0: SM64ObjectVector3,
        _ a1: SM64ObjectVector3,
        _ a2: SM64ObjectVector3,
        _ a3: SM64ObjectVector3
    ) -> SM64ObjectVector3 {
        let u = min(progress, 1)
        let oneMinusU = 1 - u
        let b0 = oneMinusU * oneMinusU * oneMinusU / 6
        let b1 = u * u * u / 2 - u * u + 0.6666667
        let b2 = -u * u * u / 2 + u * u / 2 + u / 2 + 0.16666667
        let b3 = u * u * u / 6
        return SM64ObjectVector3(
            x: b0 * a0.x + b1 * a1.x + b2 * a2.x + b3 * a3.x,
            y: b0 * a0.y + b1 * a1.y + b2 * a2.y + b3 * a3.y,
            z: b0 * a0.z + b1 * a1.z + b2 * a2.z + b3 * a3.z
        )
    }
}
