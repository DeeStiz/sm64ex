import Foundation

struct SM64FlameBouncingInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let timer: Int32
    let animationState: Int32
    let initialScale: Float
    let distanceToBowser: Float
    let bowserExists: Bool
    let bowserHeldState: Int32
    let floorHazard: Bool
}

struct SM64FlameBouncingOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let forwardVelocity: Float
    let velocityY: Float
    let scale: Float
    let animationState: Int32
    let interactionStatus: Int32
    let shouldDelete: Bool
}

enum SM64FlameBouncingBehavior {
    static func update(_ input: SM64FlameBouncingInput) -> SM64FlameBouncingOutput {
        var position = input.position
        var velocityY = input.velocityY
        if input.timer == 0 {
            velocityY = 30
        }
        let forwardVelocity: Float = 15
        position.x += forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        position.z += forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        velocityY += input.gravity
        position.y += velocityY
        let animationState = input.timer % 2 == 0 ? input.animationState &+ 1 : input.animationState
        let bowserDelete = input.bowserExists && input.bowserHeldState == 0 && input.distanceToBowser < 300
        return SM64FlameBouncingOutput(
            position: position,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            scale: input.initialScale,
            animationState: animationState,
            interactionStatus: 0,
            shouldDelete: input.timer > 300 || input.floorHazard || bowserDelete
        )
    }
}
