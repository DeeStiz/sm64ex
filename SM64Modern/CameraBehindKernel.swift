import Foundation

struct SM64CameraBehindInput: Equatable, Sendable {
    let distance: Float
    let pitch: Int16
    let yaw: Int16
    let marioFacePitch: Int16
    let marioYaw: Int16
    let marioModeActive: Bool
    let waterOrMetalAction: Bool
    let cButtonsPressed: UInt16
    let sideButtonYaw: Int16
    let behindMarioSoundTimer: Int16
}

struct SM64CameraBehindResult: Equatable, Sendable {
    let distance: Float
    let pitch: Int16
    let yaw: Int16
    let maxDistance: Float
    let focusYOffset: Float
    let sideButtonYaw: Int16
    let behindMarioSoundTimer: Int16
    let yawSpeed: Int16
    let pitchIncrement: Int16
    let goalPitch: Int16
    let goalYawOffset: Int16
    let playedSideSound: Bool
}

/// Value counterpart of `update_behind_mario_camera`. It keeps world bounds,
/// camera collision, sound playback, and render mutation at the owner-thread
/// boundary while preserving the high-fanout control ordering.
enum SM64CameraBehindKernel {
    static func update(_ input: SM64CameraBehindInput) -> SM64CameraBehindResult? {
        guard input.distance.isFinite, input.distance >= 0 else { return nil }
        var distance = input.distance
        let maxDistance: Float = input.marioModeActive ? 350 : 800
        let focusYOffset: Float = input.marioModeActive ? 120 : 125
        var goalPitch = Int16(truncatingIfNeeded: -Int32(input.marioFacePitch))
        var goalYawOffset: Int16 = 0
        var yawSpeed: Int16
        var pitchIncrement: Int16 = input.waterOrMetalAction ? 32 : 128
        var sideButtonYaw = input.sideButtonYaw
        var behindMarioSoundTimer = input.behindMarioSoundTimer
        var playedSideSound = false

        if distance > maxDistance { distance = maxDistance }
        let absolutePitch = abs(Int32(input.pitch))
        yawSpeed = Int16(clamping: 32 - absolutePitch / 0x200)
        yawSpeed = min(max(yawSpeed, 1), 32)

        if sideButtonYaw != 0 {
            sideButtonYaw = SM64CameraPrimitives.cameraApproachS16Symmetric(
                current: sideButtonYaw, target: 0, increment: 1
            ).value
            yawSpeed = 8
        }
        if behindMarioSoundTimer != 0 {
            goalPitch = 0
            behindMarioSoundTimer = SM64CameraPrimitives.cameraApproachS16Symmetric(
                current: behindMarioSoundTimer, target: 0, increment: 1
            ).value
            pitchIncrement = 0x800
        }

        // C input is consumed in C-left, C-right, C-down, C-up order. The
        // input normalizer keeps opposing directions mutually exclusive.
        if input.cButtonsPressed & SM64CameraPrimitives.leftCButtons != 0 {
            if distance < maxDistance {
                distance = SM64CameraPrimitives.cameraApproachF32Symmetric(
                    current: distance, target: maxDistance, increment: 5
                ).value
            }
            goalYawOffset = -0x3FF8
            sideButtonYaw = 30
            yawSpeed = 2
            playedSideSound = true
        }
        if input.cButtonsPressed & SM64CameraPrimitives.rightCButtons != 0 {
            if distance < maxDistance {
                distance = SM64CameraPrimitives.cameraApproachF32Symmetric(
                    current: distance, target: maxDistance, increment: 5
                ).value
            }
            goalYawOffset = 0x3FF8
            sideButtonYaw = 30
            yawSpeed = 2
            playedSideSound = true
        }
        if input.cButtonsPressed & SM64CameraPrimitives.downCButtons != 0 {
            if distance < maxDistance {
                distance = SM64CameraPrimitives.cameraApproachF32Symmetric(
                    current: distance, target: maxDistance, increment: 5
                ).value
            }
            goalPitch = -0x3000
            behindMarioSoundTimer = 30
            pitchIncrement = 0x800
            playedSideSound = true
        }
        if input.cButtonsPressed & SM64CameraPrimitives.upCButtons != 0 {
            if distance < maxDistance {
                distance = SM64CameraPrimitives.cameraApproachF32Symmetric(
                    current: distance, target: maxDistance, increment: 5
                ).value
            }
            goalPitch = 0x3000
            behindMarioSoundTimer = 30
            pitchIncrement = 0x800
            playedSideSound = true
        }

        let targetYaw = input.marioYaw &+ goalYawOffset
        let yawResult = SM64CameraPrimitives.approachS16Asymptotic(
            current: input.yaw, target: targetYaw, divisor: yawSpeed
        )
        let pitchResult = SM64CameraPrimitives.cameraApproachS16Symmetric(
            current: input.pitch, target: goalPitch, increment: pitchIncrement
        )
        if distance < 300 { distance = 300 }
        return SM64CameraBehindResult(
            distance: distance,
            pitch: pitchResult.value,
            yaw: yawResult.value,
            maxDistance: maxDistance,
            focusYOffset: focusYOffset,
            sideButtonYaw: sideButtonYaw,
            behindMarioSoundTimer: behindMarioSoundTimer,
            yawSpeed: yawSpeed,
            pitchIncrement: pitchIncrement,
            goalPitch: goalPitch,
            goalYawOffset: goalYawOffset,
            playedSideSound: playedSideSound
        )
    }
}
