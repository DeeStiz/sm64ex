import Foundation

struct SM64BeginningPeachInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let opacity: Int32
    let position: SM64ObjectVector3
    let cameraTargetPosition: SM64ObjectVector3
    let dialogID: Int32
}

struct SM64BeginningPeachOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let opacity: Int32
    let position: SM64ObjectVector3
    let faceAngles: SM64ObjectAngles
    let animationFrame: Int32
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_intro_peach_loop`, with camera-relative
/// placement supplied as an owner-thread value input.
enum SM64BeginningPeachBehavior {
    static func update(_ input: SM64BeginningPeachInput) -> SM64BeginningPeachOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var opacity = input.opacity
        var position = input.position
        var shouldDelete = false
        let faceAngles = SM64ObjectAngles(pitch: 0x400, yaw: 0x7500, roll: -0x3700)
        let animationFrame: Int32 = 100

        switch input.action {
        case 0:
            action = 1
            timer = 0
            opacity = 255
        case 1:
            position = input.cameraTargetPosition
            opacity = 0
            if input.timer > 20 { action = 2; timer = 0 }
        case 2:
            position = input.cameraTargetPosition
            opacity = approach(opacity, target: 255, step: 3)
            if input.timer > 100 && input.dialogID == -1 { action = 3; timer = 0 }
        case 3:
            position = input.cameraTargetPosition
            opacity = approach(opacity, target: 0, step: 8)
            if input.timer > 60 { shouldDelete = true }
        default:
            action = 0
            timer = 0
        }
        return .init(action: action, timer: timer, opacity: opacity, position: position, faceAngles: faceAngles, animationFrame: animationFrame, shouldDelete: shouldDelete)
    }

    private static func approach(_ value: Int32, target: Int32, step: Int32) -> Int32 {
        if value < target { return min(value + step, target) }
        return max(value - step, target)
    }
}
