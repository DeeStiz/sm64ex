import Foundation

enum SM64TinyStarParticleKind: UInt8, Equatable, Sendable {
    case wall = 0
    case pound = 1
}

struct SM64TinyStarParticleInput: Equatable, Sendable {
    let kind: SM64TinyStarParticleKind
    let position: SM64ObjectVector3
    let marioPosition: SM64ObjectVector3
    let marioYaw: Int32
    let timer: Int32
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let scale: Float
}

struct SM64TinyStarParticleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let scale: Float
    let animationState: Int32
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_wall_tiny_star_particle_loop` and
/// `bhv_pound_tiny_star_particle_loop`.
enum SM64TinyStarParticleBehavior {
    static func update(_ input: SM64TinyStarParticleInput) -> SM64TinyStarParticleOutput {
        var position = input.position
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY
        var scale = input.scale

        if input.timer == 0 {
            scale = 0.28
            switch input.kind {
            case .wall:
                let facingX = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.marioYaw))
                let facingZ = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.marioYaw))
                position = SM64ObjectVector3(
                    x: input.marioPosition.x + 110 * facingX,
                    y: input.marioPosition.y + 30,
                    z: input.marioPosition.z + 110 * facingZ
                )
            case .pound:
                forwardVelocity = 25
                position.y -= 20
                velocityY = 14
            }
        }

        let velocityX = forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        let velocityZ = forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        velocityY += input.gravity
        position.x += velocityX
        position.y += velocityY
        position.z += velocityZ

        return SM64TinyStarParticleOutput(
            position: position,
            moveYaw: input.moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            scale: scale,
            animationState: 4,
            shouldDeactivate: input.timer >= 9
        )
    }
}
