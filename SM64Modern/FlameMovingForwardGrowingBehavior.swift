import Foundation

struct SM64FlameMovingForwardGrowingInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let forwardVelocity: Float
    let scaleFactor: Float
    let timer: Int32
    let animationState: Int32
    let initialOffset: SM64ObjectVector3
    let floorHeight: Float
    let initialAnimationState: Int32
    let floorBelowPosition: Bool
}

struct SM64FlameMovingForwardGrowingOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let movePitch: Int32
    let scaleFactor: Float
    let animationState: Int32
    let shouldDelete: Bool
    let spawnBowserFlame: Bool
}

enum SM64FlameMovingForwardGrowingBehavior {
    static func update(_ input: SM64FlameMovingForwardGrowingInput) -> SM64FlameMovingForwardGrowingOutput {
        var position = input.position
        var pitch = input.movePitch
        var animationState = input.animationState
        var scale = input.scaleFactor
        if input.timer == 0 {
            position.x += input.initialOffset.x
            position.z += input.initialOffset.z
            animationState = input.initialAnimationState
        }
        scale += 0.5
        if pitch > 0x800 { pitch -= 0x200 }
        let yaw = Int16(truncatingIfNeeded: input.moveYaw)
        let pitch16 = Int16(truncatingIfNeeded: pitch)
        let pitchCos = SM64CanonicalTrig.coss(pitch16)
        position.x += input.forwardVelocity * SM64CanonicalTrig.sins(yaw) * pitchCos
        position.y += input.forwardVelocity * -SM64CanonicalTrig.sins(pitch16)
        position.z += input.forwardVelocity * SM64CanonicalTrig.coss(yaw) * pitchCos
        let impact = input.floorBelowPosition
        if impact { position.y = input.floorHeight }
        animationState = input.timer % 2 == 0 ? animationState &+ 1 : animationState
        return SM64FlameMovingForwardGrowingOutput(position: position, movePitch: pitch, scaleFactor: scale, animationState: animationState, shouldDelete: scale > 30 || impact, spawnBowserFlame: impact)
    }
}
