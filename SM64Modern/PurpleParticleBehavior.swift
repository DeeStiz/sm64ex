import Foundation

struct SM64PurpleParticleInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let randomForwardUnit: Float
    let randomVerticalUnit: Float
}

struct SM64PurpleParticleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhvPurpleParticle` and `bhv_piranha_particle_loop`.
enum SM64PurpleParticleBehavior {
    static func update(_ input: SM64PurpleParticleInput) -> SM64PurpleParticleOutput {
        let forwardVelocity = input.timer == 0 ? 20 + 20 * input.randomForwardUnit : input.forwardVelocity
        let velocityY = input.timer == 0 ? 20 + 20 * input.randomVerticalUnit : input.velocityY
        let velocityX = forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        let velocityZ = forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        return SM64PurpleParticleOutput(
            position: SM64ObjectVector3(
                x: input.position.x + velocityX,
                y: input.position.y + velocityY,
                z: input.position.z + velocityZ
            ),
            moveYaw: input.timer == 0 ? input.moveYaw : input.moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            shouldDeactivate: input.timer >= 9
        )
    }
}
