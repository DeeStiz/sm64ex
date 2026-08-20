import Foundation

struct SM64FlameFloatingLandingInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let timer: Int32
    let animationState: Int32
    let phase: Int32
    let globalTimer: Int32
    let behaviorParam: Int32
    let scale: Float
    let landed: Bool
    let floorHazard: Bool
}

struct SM64FlameFloatingLandingOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocityY: Float
    let animationState: Int32
    let graphYOffset: Float
    let shouldDelete: Bool
    let spawnBurningOut: Bool
    let spawnBlueGroup: Bool
}

enum SM64FlameFloatingLandingBehavior {
    static func update(_ input: SM64FlameFloatingLandingInput) -> SM64FlameFloatingLandingOutput {
        var position = input.position
        var velocityY = input.velocityY + input.gravity
        position.x += input.forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        position.z += input.forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        position.y += velocityY
        let phase = Int16(truncatingIfNeeded: ((input.phase + input.globalTimer) & 0x3f) << 10)
        position.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw)) * SM64CanonicalTrig.sins(phase) * 4
        position.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw)) * SM64CanonicalTrig.sins(phase) * 4
        let minimumVelocity: Float = input.behaviorParam == 0 ? -8 : (input.behaviorParam == 1 ? -6 : -3)
        velocityY = max(velocityY, minimumVelocity)
        return SM64FlameFloatingLandingOutput(
            position: position,
            velocityY: velocityY,
            animationState: input.timer % 2 == 0 ? input.animationState &+ 1 : input.animationState,
            graphYOffset: input.scale * 14,
            shouldDelete: input.timer > 900 || input.floorHazard || input.landed,
            spawnBurningOut: input.landed && input.behaviorParam == 0,
            spawnBlueGroup: input.landed && input.behaviorParam != 0
        )
    }
}
