import Foundation

struct SM64WhitePuffSmoke2Input: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let timer: Int32
    let animationState: Int32
    let initialOffsetX: Float
    let initialOffsetZ: Float
}

struct SM64WhitePuffSmoke2Output: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocityY: Float
    let animationState: Int32
    let shouldDeactivate: Bool
}

enum SM64WhitePuffSmoke2Behavior {
    static func update(_ input: SM64WhitePuffSmoke2Input) -> SM64WhitePuffSmoke2Output {
        var position = input.position
        if input.timer == 0 {
            // `obj_translate_xz_random(o, 40.0f)` is replay-injected here.
            position.x += input.initialOffsetX
            position.z += input.initialOffsetZ
        }
        var velocityY = input.velocityY
        position.x += input.forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        position.z += input.forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        velocityY += input.gravity
        position.y += velocityY
        return SM64WhitePuffSmoke2Output(
            position: position,
            velocityY: velocityY,
            animationState: input.animationState &+ 1,
            // `BEGIN_REPEAT(7)` runs on timers 0...6, then DEACTIVATE().
            shouldDeactivate: input.timer >= 6
        )
    }
}
