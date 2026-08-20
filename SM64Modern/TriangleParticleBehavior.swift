import Foundation

struct SM64TriangleParticleInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let marioPosition: SM64ObjectVector3
    let marioYaw: Int32
    let timer: Int32
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let scale: Float
    let lifetime: Int32
}

struct SM64TriangleParticleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let scale: Float
    let animationState: Int32
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_punch_tiny_triangle_loop`.
enum SM64TriangleParticleBehavior {
    static func update(_ input: SM64TriangleParticleInput) -> SM64TriangleParticleOutput {
        var position = input.position
        var scale = input.scale
        let forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY

        if input.timer == 0 {
            let facingX = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.marioYaw))
            let facingZ = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.marioYaw))
            position = SM64ObjectVector3(
                x: input.marioPosition.x + 100 * facingX,
                y: input.marioPosition.y + 60,
                z: input.marioPosition.z + 100 * facingZ
            )
            scale = 1.28
        }

        let velocityX = forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        let velocityZ = forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        velocityY += input.gravity
        position.x += velocityX
        position.y += velocityY
        position.z += velocityZ

        return SM64TriangleParticleOutput(
            position: position,
            moveYaw: input.moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            scale: scale,
            animationState: 5,
            shouldDeactivate: input.timer > input.lifetime
        )
    }
}
