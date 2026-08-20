import Foundation

/// Inputs for the eight-frame smoke child emitted by Bowser's flame effects.
/// Random values are supplied by the owner bridge so the value layer remains
/// deterministic and testable without depending on a global RNG.
struct SM64BlackSmokeBowserInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let timer: Int32
    let initialMoveYaw: Int32
    let initialForwardVelocity: Float
    let initialVelocityY: Float
    let angleVelocityYaw: Int32
    let animationState: Int32
}

struct SM64BlackSmokeBowserOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let animationState: Int32
    let shouldDeactivate: Bool
}

enum SM64BlackSmokeBowserBehavior {
    static func update(_ input: SM64BlackSmokeBowserInput) -> SM64BlackSmokeBowserOutput {
        var position = input.position
        var moveYaw = input.moveYaw
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY

        if input.timer == 0 {
            moveYaw = input.initialMoveYaw
            forwardVelocity = input.initialForwardVelocity
            velocityY = input.initialVelocityY
        }

        moveYaw &+= input.angleVelocityYaw
        position.x += forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw))
        position.z += forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw))
        position.y += velocityY

        var animationState = input.animationState
        // Source `ANIMATE_TEXTURE(oAnimState, 4)` advances every fourth frame.
        if input.timer % 4 == 0 {
            animationState &+= 1
        }

        return SM64BlackSmokeBowserOutput(
            position: position,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            animationState: animationState,
            // `BEGIN_REPEAT(8)` runs native behavior for timers 0...7.
            shouldDeactivate: input.timer >= 7
        )
    }
}
