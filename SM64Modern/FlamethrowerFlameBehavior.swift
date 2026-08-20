import Foundation

struct SM64FlamethrowerFlameInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocityY: Float
    let moveYaw: Int32
    let forwardVelocity: Float
    let gravity: Float
    let timer: Int32
    let animationState: Int32
    let behaviorParam: Int32
    let parentLifetime: Int32
    let floorHeight: Float
    let initialOffset: SM64ObjectVector3
    let initialAnimationState: Int32
}

struct SM64FlamethrowerFlameOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocityY: Float
    let scale: Float
    let animationState: Int32
    let interactionStatus: Int32
    let shouldDelete: Bool
}

enum SM64FlamethrowerFlameBehavior {
    static func update(_ input: SM64FlamethrowerFlameInput) -> SM64FlamethrowerFlameOutput {
        var position = input.position
        var velocityY = input.velocityY
        var animationState = input.animationState
        if input.timer == 0 {
            position.x += input.initialOffset.x
            position.y += input.initialOffset.y
            position.z += input.initialOffset.z
            animationState = input.initialAnimationState
        }
        let scale = input.behaviorParam == 2
            ? Float(input.timer) * (input.forwardVelocity - 6) / 100 + 2
            : Float(input.timer) * (input.forwardVelocity - 20) / 100 + 1
        if input.behaviorParam == 3 {
            velocityY = -28
            if position.y - 25 * scale < input.floorHeight {
                velocityY = 0
                position.y = input.floorHeight + 25 * scale
            }
        }
        if input.behaviorParam == 4 {
            position.y += input.forwardVelocity
        } else {
            position.x += input.forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            position.z += input.forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
            velocityY += input.gravity
            position.y += velocityY
        }
        animationState &+= 1
        return SM64FlamethrowerFlameOutput(
            position: position,
            velocityY: velocityY,
            scale: scale,
            animationState: animationState,
            interactionStatus: 0,
            shouldDelete: input.timer > input.parentLifetime
        )
    }
}
