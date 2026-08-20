import Foundation

enum SM64StrongWindParticleKind: UInt8, Equatable, Sendable {
    case visible = 0
    case tiny = 1
}

struct SM64StrongWindParticleInput: Equatable, Sendable {
    let kind: SM64StrongWindParticleKind
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let timer: Int32
    let initialRandomX: Float
    let initialRandomY: Float
    let initialRandomZ: Float
    let initialYawJitter: Int32
    let windSpread: UInt8
    let penguinCollisionPosition: SM64ObjectVector3?
}

struct SM64StrongWindParticleOutput: Equatable, Sendable {
    let kind: SM64StrongWindParticleKind
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let opacity: Int32
    let intangible: Bool
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_strong_wind_particle_loop`.
enum SM64StrongWindParticleBehavior {
    static func update(_ input: SM64StrongWindParticleInput) -> SM64StrongWindParticleOutput {
        var position = input.position
        var moveYaw = input.moveYaw
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY
        var opacity: Int32 = 0
        if input.timer == 0 {
            position.x += input.initialRandomX
            position.y += input.initialRandomY
            position.z += input.initialRandomZ
            forwardVelocity = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.movePitch)) * 100
            velocityY = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.movePitch)) * -100
            moveYaw &+= input.initialYawJitter
            opacity = 100
        } else {
            opacity = 100
        }
        position.x += SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw))
        )
        position.z += SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw))
        )
        position.y += velocityY
        let nearPenguin: Bool
        if let penguin = input.penguinCollisionPosition {
            let dx = penguin.x - position.x
            let dz = penguin.z - position.z
            nearPenguin = (dx * dx + dz * dz).squareRoot() < 300
        } else {
            nearPenguin = false
        }
        return SM64StrongWindParticleOutput(
            kind: input.kind,
            position: position,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            opacity: opacity,
            intangible: nearPenguin,
            shouldDelete: input.timer > 15 || nearPenguin
        )
    }
}
