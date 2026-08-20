import Foundation

struct SM64VolcanoFlamesInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let timer: Int32
    let animationState: Int32
    let landedOrWaterSurface: Bool
}

struct SM64VolcanoFlamesOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocityY: Float
    let animationState: Int32
    let shouldDelete: Bool
}

enum SM64VolcanoFlamesBehavior {
    static func update(_ input: SM64VolcanoFlamesInput) -> SM64VolcanoFlamesOutput {
        var position = input.position
        let velocityY = input.velocityY + input.gravity
        position.x += input.forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        position.z += input.forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        position.y += velocityY
        return SM64VolcanoFlamesOutput(
            position: position,
            velocityY: velocityY,
            animationState: input.animationState &+ 1,
            shouldDelete: input.landedOrWaterSurface
        )
    }
}
