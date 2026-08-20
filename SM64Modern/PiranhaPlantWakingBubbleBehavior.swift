import Foundation

struct SM64PiranhaPlantWakingBubbleInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let timer: Int32
    let initialMoveYaw: Int32
    let initialForwardVelocity: Float
    let initialVelocityY: Float
}

struct SM64PiranhaPlantWakingBubbleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let timer: Int32
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_piranha_plant_waking_bubbles_loop`.
enum SM64PiranhaPlantWakingBubbleBehavior {
    static func update(_ input: SM64PiranhaPlantWakingBubbleInput) -> SM64PiranhaPlantWakingBubbleOutput {
        var moveYaw = input.moveYaw
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY
        if input.timer == 0 {
            velocityY = input.initialVelocityY
            forwardVelocity = input.initialForwardVelocity
            moveYaw = input.initialMoveYaw
        }
        var position = input.position
        position.x += SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw))
        )
        position.z += SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw))
        )
        position.y += velocityY
        return SM64PiranhaPlantWakingBubbleOutput(
            position: position,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            timer: input.timer &+ 1,
            shouldDeactivate: input.timer >= 9
        )
    }
}
