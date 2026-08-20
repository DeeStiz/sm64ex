import Foundation

enum SM64MistParticleKind: UInt8, Equatable, Sendable {
    case puff1 = 0
    case puff2 = 1
}

struct SM64MistParticleInput: Equatable, Sendable {
    let kind: SM64MistParticleKind
    let position: SM64ObjectVector3
    let timer: Int32
    let animationState: Int32
    let initialOffsetX: Float
    let initialOffsetZ: Float
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
}

struct SM64MistParticleOutput: Equatable, Sendable {
    let kind: SM64MistParticleKind
    let position: SM64ObjectVector3
    let scale: Float
    let opacity: Int32
    let animationState: Int32
    let shouldDelete: Bool
    let shouldDeactivate: Bool
}

enum SM64MistParticleBehavior {
    static func update(_ input: SM64MistParticleInput) -> SM64MistParticleOutput {
        var position = input.position
        if input.timer == 0 {
            position.x += input.initialOffsetX
            position.z += input.initialOffsetZ
            if input.kind == .puff1 { position.y += 30 }
        }
        if input.kind == .puff1 {
            position.x += input.forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
            position.y += input.velocityY
            position.z += input.forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            return SM64MistParticleOutput(
                kind: .puff1,
                position: position,
                scale: Float(input.timer) * 0.5 + 0.1,
                opacity: 50,
                animationState: input.animationState,
                shouldDelete: input.timer > 4,
                shouldDeactivate: false
            )
        }
        return SM64MistParticleOutput(
            kind: .puff2,
            position: position,
            scale: 1,
            opacity: 0,
            animationState: input.animationState &+ 1,
            shouldDelete: false,
            shouldDeactivate: input.timer >= 6
        )
    }
}
