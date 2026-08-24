import Foundation

struct SM64CameraAngles: Equatable, Sendable {
    let distance: Float
    let pitch: Int16
    let yaw: Int16
}

struct SM64CameraPitchClampResult: Equatable, Sendable {
    let position: SM64ObjectVector3
    let pitch: Int16
    let yaw: Int16
    let distance: Float
    let outOfRange: UInt8
}

/// Pure camera math and state kernels extracted from `camera.c`. Camera
/// ownership, collision queries, audio, HUD, and render-layer mutation remain
/// outside this value boundary.
enum SM64CameraPrimitives {
    static let cButtonMask: UInt16 = 0x000F
    static let leftCButtons: UInt16 = 0x0002
    static let rightCButtons: UInt16 = 0x0001
    static let upCButtons: UInt16 = 0x0008
    static let downCButtons: UInt16 = 0x0004

    static func findCButtonsPressed(
        currentState: UInt16,
        buttonsPressed: UInt16,
        buttonsDown: UInt16
    ) -> UInt16 {
        let pressed = buttonsPressed & Self.cButtonMask
        let down = buttonsDown & Self.cButtonMask
        var state = currentState
        if pressed & Self.leftCButtons != 0 {
            state |= Self.leftCButtons
            state &= ~Self.rightCButtons
        }
        if down & Self.leftCButtons == 0 { state &= ~Self.leftCButtons }
        if pressed & Self.rightCButtons != 0 {
            state |= Self.rightCButtons
            state &= ~Self.leftCButtons
        }
        if down & Self.rightCButtons == 0 { state &= ~Self.rightCButtons }
        if pressed & Self.upCButtons != 0 {
            state |= Self.upCButtons
            state &= ~Self.downCButtons
        }
        if down & Self.upCButtons == 0 { state &= ~Self.upCButtons }
        if pressed & Self.downCButtons != 0 {
            state |= Self.downCButtons
            state &= ~Self.upCButtons
        }
        if down & Self.downCButtons == 0 { state &= ~Self.downCButtons }
        return state
    }

    static func approachF32Asymptotic(
        current: Float, target: Float, multiplier: Float
    ) -> (value: Float, moving: Bool) {
        let multiplier = min(multiplier, 1)
        let value = current + (target - current) * multiplier
        return (value, value != target)
    }

    static func approachS16Asymptotic(
        current: Int16, target: Int16, divisor: Int16
    ) -> (value: Int16, moving: Bool) {
        guard divisor != 0 else { return (target, false) }
        let current32 = Int32(current)
        let target32 = Int32(target)
        let value = Int16(truncatingIfNeeded: current32 - target32
            - (current32 - target32) / Int32(divisor) + target32)
        return (value, value != target)
    }

    static func cameraApproachS16Symmetric(
        current: Int16, target: Int16, increment: Int16
    ) -> (value: Int16, moving: Bool) {
        let step = abs(Int32(increment))
        var distance = Int32(target) - Int32(current)
        if distance > 0 {
            distance -= step
            let value = distance >= 0 ? Int32(target) - distance : Int32(target)
            let result = Int16(truncatingIfNeeded: value)
            return (result, result != target)
        }
        distance += step
        let value = distance <= 0 ? Int32(target) - distance : Int32(target)
        let result = Int16(truncatingIfNeeded: value)
        return (result, result != target)
    }

    static func cameraApproachF32Symmetric(
        current: Float, target: Float, increment: Float
    ) -> (value: Float, moving: Bool) {
        let step = abs(increment)
        var distance = target - current
        if distance > 0 {
            distance -= step
            let value = distance > 0 ? target - distance : target
            return (value, value != target)
        }
        distance += step
        let value = distance < 0 ? target - distance : target
        return (value, value != target)
    }

    static func calculateAngles(
        from: SM64ObjectVector3, to: SM64ObjectVector3
    ) -> SM64CameraAngles? {
        guard finite(from), finite(to) else { return nil }
        let x = to.x - from.x
        let y = to.y - from.y
        let z = to.z - from.z
        let horizontal = (x * x + z * z).squareRoot()
        let distance = (x * x + y * y + z * z).squareRoot()
        return SM64CameraAngles(
            distance: distance,
            pitch: SM64CanonicalTrig.atan2s(y: horizontal, x: y),
            yaw: SM64CanonicalTrig.atan2s(y: z, x: x)
        )
    }

    /// Value counterpart of `vec3f_set_dist_and_angle`. Keep this separate
    /// from `focusOnMario`: the legacy camera first quantizes the current
    /// position to s16 pitch/yaw, then reconstructs the point before applying
    /// floor/ceiling and camera-height rules.
    static func setDistanceAndAngle(
        from: SM64ObjectVector3,
        distance: Float,
        pitch: Int16,
        yaw: Int16
    ) -> SM64ObjectVector3? {
        guard finite(from), distance.isFinite, distance >= 0 else { return nil }
        let cosinePitch = SM64CanonicalTrig.coss(pitch)
        return SM64ObjectVector3(
            x: from.x + distance * cosinePitch * SM64CanonicalTrig.sins(yaw),
            y: from.y + distance * SM64CanonicalTrig.sins(pitch),
            z: from.z + distance * cosinePitch * SM64CanonicalTrig.coss(yaw)
        )
    }

    /// Value counterpart of the camera's source-authored `offset_rotated`
    /// initialization helper. The source intentionally flips the Z axis in
    /// the pitch rotation to match the N64 camera coordinate convention.
    static func offsetRotated(
        from: SM64ObjectVector3,
        offset: SM64ObjectVector3,
        pitch: Int16,
        yaw: Int16
    ) -> SM64ObjectVector3? {
        guard finite(from), finite(offset) else { return nil }
        let pitchZ = -(
            offset.z * SM64CanonicalTrig.coss(pitch)
                - offset.y * SM64CanonicalTrig.sins(pitch)
        )
        let pitchY = offset.z * SM64CanonicalTrig.sins(pitch)
            + offset.y * SM64CanonicalTrig.coss(pitch)
        let position = SM64ObjectVector3(
            x: from.x + pitchZ * SM64CanonicalTrig.sins(yaw)
                + offset.x * SM64CanonicalTrig.coss(yaw),
            y: from.y + pitchY,
            z: from.z + pitchZ * SM64CanonicalTrig.coss(yaw)
                - offset.x * SM64CanonicalTrig.sins(yaw)
        )
        return finite(position) ? position : nil
    }

    static func rotateInXZ(
        _ vector: SM64ObjectVector3, yaw: Int16
    ) -> SM64ObjectVector3? {
        guard finite(vector) else { return nil }
        let sine = SM64CanonicalTrig.sins(yaw)
        let cosine = SM64CanonicalTrig.coss(yaw)
        return SM64ObjectVector3(
            x: vector.z * sine + vector.x * cosine,
            y: vector.y,
            z: vector.z * cosine - vector.x * sine
        )
    }

    static func clampPitch(
        from: SM64ObjectVector3,
        to: SM64ObjectVector3,
        maxPitch: Int16,
        minPitch: Int16
    ) -> SM64CameraPitchClampResult? {
        guard let angles = calculateAngles(from: from, to: to) else { return nil }
        var pitch = angles.pitch
        var outOfRange: UInt8 = 0
        if pitch > maxPitch { pitch = maxPitch; outOfRange &+= 1 }
        if pitch < minPitch { pitch = minPitch; outOfRange &+= 1 }
        let cosinePitch = SM64CanonicalTrig.coss(pitch)
        let position = SM64ObjectVector3(
            x: from.x + angles.distance * cosinePitch * SM64CanonicalTrig.sins(angles.yaw),
            y: from.y + angles.distance * SM64CanonicalTrig.sins(pitch),
            z: from.z + angles.distance * cosinePitch * SM64CanonicalTrig.coss(angles.yaw)
        )
        return SM64CameraPitchClampResult(
            position: position, pitch: pitch, yaw: angles.yaw,
            distance: angles.distance, outOfRange: outOfRange
        )
    }

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
