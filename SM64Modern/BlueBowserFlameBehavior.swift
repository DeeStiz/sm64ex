import Foundation

struct SM64BlueBowserFlameInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let scale: Float
    let timer: Int32
    let animationState: Int32
    let behaviorParam: Int32
    let phase: Int32
    let globalTimer: Int32
    let initialOffset: SM64ObjectVector3
    let initialAnimationState: Int32
}

struct SM64BlueBowserFlameOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocityY: Float
    let scale: Float
    let animationState: Int32
    let spawnCount: Int32
    let childScale: Float
    let shouldDelete: Bool
}

enum SM64BlueBowserFlameBehavior {
    static func update(_ input: SM64BlueBowserFlameInput) -> SM64BlueBowserFlameOutput {
        var position = input.position
        var velocityY = input.velocityY
        var scale = input.scale
        var animationState = input.animationState
        if input.timer == 0 { position.x += input.initialOffset.x; position.y += input.initialOffset.y; position.z += input.initialOffset.z; animationState = input.initialAnimationState }
        scale = min(16, scale + 0.5)
        position.x += input.forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        position.z += input.forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        velocityY += input.gravity
        position.y += velocityY
        let spawn = input.timer > 20
        return SM64BlueBowserFlameOutput(position: position, velocityY: velocityY, scale: scale, animationState: input.timer % 2 == 0 ? animationState &+ 1 : animationState, spawnCount: spawn ? (input.behaviorParam == 0 ? 3 : 2) : 0, childScale: input.behaviorParam == 0 ? 5 : 8, shouldDelete: spawn)
    }
}
