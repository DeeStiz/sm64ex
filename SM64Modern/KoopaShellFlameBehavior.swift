import Foundation

struct SM64KoopaShellFlameInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let scale: Float
    let timer: Int32
    let animationState: Int32
    let initialOffset: SM64ObjectVector3
    let initialYaw: Int32
    let initialVelocityY: Float
    let initialAnimationState: Int32
    let floorBelowPosition: Bool
}

struct SM64KoopaShellFlameOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let velocityY: Float
    let scale: Float
    let animationState: Int32
    let shouldDelete: Bool
}

enum SM64KoopaShellFlameBehavior {
    static func update(_ input: SM64KoopaShellFlameInput) -> SM64KoopaShellFlameOutput {
        var position = input.position
        var moveYaw = input.moveYaw
        var velocityY = input.velocityY
        var animationState = input.animationState
        var scale = input.scale
        if input.timer == 0 {
            position.x += input.initialOffset.x
            position.y += input.initialOffset.y
            position.z += input.initialOffset.z
            moveYaw = input.initialYaw
            velocityY = input.initialVelocityY
            animationState = input.initialAnimationState
        }
        position.x += input.forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw))
        position.z += input.forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw))
        velocityY += input.gravity
        position.y += velocityY
        scale -= 0.3
        animationState = input.timer % 2 == 0 ? animationState &+ 1 : animationState
        return SM64KoopaShellFlameOutput(position: position, moveYaw: moveYaw, velocityY: velocityY, scale: scale, animationState: animationState, shouldDelete: input.floorBelowPosition || input.timer > 10)
    }
}
