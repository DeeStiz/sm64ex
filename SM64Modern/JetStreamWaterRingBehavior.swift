import Foundation

struct SM64JetStreamWaterRingInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let opacity: Int32
    let averageScale: Float
    let position: SM64ObjectVector3
    let faceYaw: Int32
    let marioNear: Bool
    let crossedRingPlane: Bool
}

struct SM64JetStreamWaterRingOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let opacity: Int32
    let averageScale: Float
    let position: SM64ObjectVector3
    let faceYaw: Int32
    let scale: Float
    let shouldDelete: Bool
    let collected: Bool
}

/// Value counterpart of the Jet Stream water-ring loop.
enum SM64JetStreamWaterRingBehavior {
    static func update(_ input: SM64JetStreamWaterRingInput) -> SM64JetStreamWaterRingOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var opacity = input.opacity
        var averageScale = input.averageScale
        var position = input.position
        var faceYaw = input.faceYaw
        var shouldDelete = false
        var collected = false
        var scale: Float

        if input.action == 0 {
            averageScale = min(Float(input.timer) / 225 * 3 + 0.5, 3.5)
            scale = averageScale
            if input.timer >= 226 {
                opacity -= 2
                if opacity < 3 { shouldDelete = true }
            }
            if input.marioNear && input.crossedRingPlane {
                action = 1
                timer = 0
                collected = true
            }
            position.y += 10
            faceYaw &+= 0x100
        } else {
            averageScale = Float(input.timer) * 0.2 + input.averageScale
            scale = averageScale
            opacity -= 10
            if input.timer >= 21 { shouldDelete = true }
        }
        return .init(action: action, timer: timer, opacity: max(opacity, 0), averageScale: averageScale, position: position, faceYaw: faceYaw, scale: scale, shouldDelete: shouldDelete, collected: collected)
    }
}
