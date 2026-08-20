import Foundation

struct SM64WhitePuffExplosionInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let gravity: Float
    let dragStrength: Float
    let timer: Int32
    let opacity: Int32
    let initialScale: Float
    let behaviorParam: Int32
}

struct SM64WhitePuffExplosionOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let opacity: Int32
    let scale: Float
    let shouldDelete: Bool
}

enum SM64WhitePuffExplosionBehavior {
    private static func applyDrag(_ value: Float, _ dragStrength: Float) -> Float {
        guard value != 0 else { return 0 }
        let deceleration = value * value * (dragStrength * 0.0001)
        if value > 0 {
            let next = value - deceleration
            return next < 0.001 ? 0 : next
        }
        let next = value + deceleration
        return next > -0.001 ? 0 : next
    }

    static func update(_ input: SM64WhitePuffExplosionInput) -> SM64WhitePuffExplosionOutput {
        var position = input.position
        var velocity = input.velocity
        var opacity = input.opacity
        var scale = input.initialScale
        var shouldDelete = false

        if input.timer == 0 {
            opacity = input.behaviorParam == 2 || input.behaviorParam == 3 ? 254 : opacity
        }

        position.x += velocity.x
        position.y += velocity.y
        position.z += velocity.z
        velocity.y += input.gravity
        velocity.y = min(velocity.y, 100)
        velocity.x = applyDrag(velocity.x, input.dragStrength)
        velocity.z = applyDrag(velocity.z, input.dragStrength)

        if input.timer > 20 { shouldDelete = true }
        if opacity > 0 {
            opacity += input.behaviorParam == 3 ? -13 : -21
            if opacity < 2 { shouldDelete = true }
            if input.behaviorParam == 3 {
                scale = input.initialScale * Float(254 - opacity) / 254
            } else {
                scale = input.initialScale * Float(opacity) / 254
            }
        }

        return SM64WhitePuffExplosionOutput(
            position: position,
            velocity: velocity,
            opacity: opacity,
            scale: scale,
            shouldDelete: shouldDelete
        )
    }
}
