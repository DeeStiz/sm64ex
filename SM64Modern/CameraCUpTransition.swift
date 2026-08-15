import Foundation

struct SM64CameraTransitionPoint: Equatable, Sendable {
    let focus: SM64ObjectVector3
    let position: SM64ObjectVector3
    let distance: Float
    let pitch: Int16
    let yaw: Int16
}

struct SM64CameraCUpTransitionInput: Equatable, Sendable {
    let start: SM64CameraTransitionPoint
    let end: SM64CameraTransitionPoint
    let frame: Int16
    let max: Int16
    let marioPosition: SM64ObjectVector3
}

struct SM64CameraCUpTransitionResult: Equatable, Sendable {
    let focus: SM64ObjectVector3
    let position: SM64ObjectVector3
    let distance: Float
    let pitch: Int16
    let yaw: Int16
    let nextFrame: Int16
    let finished: Bool
    let headPitch: Int16
    let headYaw: Int16
}

/// Value counterpart of the C move_into_c_up routine. Transition points are
/// the Mario-relative values stored by set_camera_mode; the returned camera
/// vectors are world-space values ready for owner-thread installation.
enum SM64CameraCUpTransition {
    static func update(
        _ input: SM64CameraCUpTransitionInput
    ) -> SM64CameraCUpTransitionResult? {
        guard input.max > 0, input.frame >= 0, input.frame <= input.max,
              input.start.distance.isFinite, input.end.distance.isFinite,
              finite(input.start.focus), finite(input.start.position),
              finite(input.end.focus), finite(input.end.position),
              finite(input.marioPosition) else { return nil }
        let factor = Float(input.frame) / Float(input.max)
        let distance = input.start.distance
            + (input.end.distance - input.start.distance) * factor
        let focusRelative = lerp(input.start.focus, input.end.focus, factor)
        let focus = SM64ObjectVector3(
            x: focusRelative.x + input.marioPosition.x,
            y: focusRelative.y + input.marioPosition.y,
            z: focusRelative.z + input.marioPosition.z
        )
        let pitch = interpolateAngle(
            start: input.start.pitch, end: input.end.pitch,
            frame: input.frame, max: input.max
        )
        let yaw = interpolateAngle(
            start: input.start.yaw, end: input.end.yaw,
            frame: input.frame, max: input.max
        )
        guard let position = setDistanceAndAngle(
            from: focus, distance: distance, pitch: pitch, yaw: yaw
        ) else { return nil }
        let nextFrame = input.frame &+ 1
        return SM64CameraCUpTransitionResult(
            focus: focus, position: position, distance: distance,
            pitch: pitch, yaw: yaw, nextFrame: nextFrame,
            finished: nextFrame == input.max, headPitch: 0, headYaw: 0
        )
    }

    private static func interpolateAngle(
        start: Int16, end: Int16, frame: Int16, max: Int16
    ) -> Int16 {
        let delta = Int64(end) - Int64(start)
        let value = Int64(start) + delta * Int64(frame) / Int64(max)
        return Int16(truncatingIfNeeded: value)
    }

    private static func lerp(
        _ start: SM64ObjectVector3, _ end: SM64ObjectVector3, _ factor: Float
    ) -> SM64ObjectVector3 {
        SM64ObjectVector3(
            x: start.x + (end.x - start.x) * factor,
            y: start.y + (end.y - start.y) * factor,
            z: start.z + (end.z - start.z) * factor
        )
    }

    private static func setDistanceAndAngle(
        from: SM64ObjectVector3, distance: Float, pitch: Int16, yaw: Int16
    ) -> SM64ObjectVector3? {
        guard distance.isFinite, distance >= 0 else { return nil }
        let cosinePitch = SM64CanonicalTrig.coss(pitch)
        return SM64ObjectVector3(
            x: from.x + distance * cosinePitch * SM64CanonicalTrig.sins(yaw),
            y: from.y + distance * SM64CanonicalTrig.sins(pitch),
            z: from.z + distance * cosinePitch * SM64CanonicalTrig.coss(yaw)
        )
    }

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
