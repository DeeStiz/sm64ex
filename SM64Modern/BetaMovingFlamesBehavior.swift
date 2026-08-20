import Foundation

struct SM64BetaMovingFlamesInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movingFlameTimer: Int32
    let animationState: Int32
}

struct SM64BetaMovingFlamesOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let forwardVelocity: Float
    let movingFlameTimer: Int32
    let animationState: Int32
    let scale: Float
}

enum SM64BetaMovingFlamesBehavior {
    static func update(_ input: SM64BetaMovingFlamesInput) -> SM64BetaMovingFlamesOutput {
        let phase = Int16(truncatingIfNeeded: input.movingFlameTimer)
        let forwardVelocity = SM64CanonicalTrig.sins(phase) * 70
        var position = input.position
        position.x += forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        position.z += forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        return SM64BetaMovingFlamesOutput(position: position, forwardVelocity: forwardVelocity, movingFlameTimer: input.movingFlameTimer &+ 0x800, animationState: input.animationState &+ 1, scale: 5)
    }
}

struct SM64BetaMovingFlamesSpawnInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let action: Int32
}

struct SM64BetaMovingFlamesSpawnOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let action: Int32
    let spawnChild: Bool
}

enum SM64BetaMovingFlamesSpawnBehavior {
    static func update(_ input: SM64BetaMovingFlamesSpawnInput) -> SM64BetaMovingFlamesSpawnOutput {
        let spawn = input.action >= 0 && input.action <= 7
        let nextAction = input.action < 9 ? input.action + 1 : input.action
        return SM64BetaMovingFlamesSpawnOutput(position: input.position, action: nextAction, spawnChild: spawn)
    }
}
