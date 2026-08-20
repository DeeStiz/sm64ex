import Foundation

struct SM64SquarishPathMovingInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let behaviorByte: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let velocityY: Float
    let gravity: Float
}

struct SM64SquarishPathMovingOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let collisionModelRequested: Bool
}

/// Value counterpart of `bhv_squarish_path_moving_loop`.
///
/// The legacy loop selects the first leg from the behavior byte, holds each
/// cardinal yaw for 61 callbacks (`oTimer > 60`), then advances using the
/// standard forward-velocity/gravity helper. Collision submission is reported
/// as an owner effect instead of reaching into the C collision registry.
enum SM64SquarishPathMovingBehavior {
    static func update(_ input: SM64SquarishPathMovingInput)
        -> SM64SquarishPathMovingOutput
    {
        var action = input.action
        var timer = input.timer
        var moveYaw = input.moveYaw

        switch input.action {
        case 0:
            action = (input.behaviorByte & 3) + 1
            timer = 0
        case 1:
            moveYaw = 0
            if input.timer > 60 { action = 2; timer = 0 }
        case 2:
            moveYaw = 0x4000
            if input.timer > 60 { action = 3; timer = 0 }
        case 3:
            moveYaw = 0x8000
            if input.timer > 60 { action = 4; timer = 0 }
        case 4:
            moveYaw = 0xC000
            if input.timer > 60 { action = 1; timer = 0 }
        default:
            break
        }

        var position = input.position
        let forwardVelocity: Float = 10
        let velocityY = input.velocityY + input.gravity
        position.x += forwardVelocity * SM64CanonicalTrig.sins(
            Int16(truncatingIfNeeded: moveYaw)
        )
        position.y += velocityY
        position.z += forwardVelocity * SM64CanonicalTrig.coss(
            Int16(truncatingIfNeeded: moveYaw)
        )

        if action == input.action { timer = input.timer &+ 1 }

        return .init(
            action: action,
            timer: timer,
            position: position,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            collisionModelRequested: true
        )
    }
}
