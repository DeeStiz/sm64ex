import Foundation

enum SM64DustSmokeKind: UInt8, Equatable, Sendable {
    case smoke = 0
    case bobombFuse = 1
}

struct SM64DustSmokeInput: Equatable, Sendable {
    let kind: SM64DustSmokeKind
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let timer: Int32
    let smokeTimer: Int32
    let animationState: Int32
    let delayed: Bool
    let scale: Float
}

struct SM64DustSmokeOutput: Equatable, Sendable {
    let kind: SM64DustSmokeKind
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let smokeTimer: Int32
    let animationState: Int32
    let delayed: Bool
    let scale: Float
    let shouldDelete: Bool
}

enum SM64DustSmokeBehavior {
    static func update(_ input: SM64DustSmokeInput) -> SM64DustSmokeOutput {
        if input.delayed {
            return SM64DustSmokeOutput(
                kind: input.kind,
                position: input.position,
                velocity: input.velocity,
                smokeTimer: input.smokeTimer,
                animationState: input.animationState,
                delayed: false,
                scale: input.scale,
                shouldDelete: false
            )
        }

        var position = input.position
        if input.kind == .smoke {
            // `OBJ_FLAG_MOVE_XZ_USING_FVEL` runs after the native dust loop.
            position.x += input.forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            position.z += input.forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        }
        position.x += input.velocity.x
        position.y += input.velocity.y
        position.z += input.velocity.z

        return SM64DustSmokeOutput(
            kind: input.kind,
            position: position,
            velocity: input.velocity,
            smokeTimer: input.smokeTimer &+ 1,
            animationState: input.animationState &+ 1,
            delayed: false,
            scale: input.scale,
            // `bhv_dust_smoke_loop` marks when oSmokeTimer == 10.
            shouldDelete: input.smokeTimer == 10
        )
    }
}
