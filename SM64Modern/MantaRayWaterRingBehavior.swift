import Foundation

struct SM64MantaRayWaterRingInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let opacity: Int32
    let averageScale: Float
    let marioNear: Bool
    let crossedRingPlane: Bool
}

struct SM64MantaRayWaterRingOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let opacity: Int32
    let averageScale: Float
    let scale: Float
    let shouldDelete: Bool
    let collected: Bool
}

/// Value counterpart of `bhv_manta_ray_water_ring_loop`.
enum SM64MantaRayWaterRingBehavior {
    static func update(_ input: SM64MantaRayWaterRingInput) -> SM64MantaRayWaterRingOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var opacity = input.opacity
        var averageScale = input.averageScale
        var shouldDelete = false
        var collected = false
        if input.action == 0 {
            averageScale = min(Float(input.timer) / 50 * 1.3 + 0.1, 1.3)
            if input.timer >= 151 {
                opacity -= 2
                if opacity < 3 { shouldDelete = true }
            }
            if input.marioNear && input.crossedRingPlane {
                action = 1
                timer = 0
                collected = true
            }
        } else {
            averageScale = Float(input.timer) * 0.2 + input.averageScale
            opacity -= 10
            if input.timer >= 21 { shouldDelete = true }
        }
        return .init(action: action, timer: timer, opacity: max(opacity, 0), averageScale: averageScale, scale: averageScale, shouldDelete: shouldDelete, collected: collected)
    }
}
