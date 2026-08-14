import Foundation

struct SM64MarioDeceleratingSpeedInput: Equatable, Sendable {
    let forwardVelocity: Float
    let faceYaw: Int16
    let velocityY: Float
}

struct SM64MarioDeceleratingSpeedResult: Equatable, Sendable {
    let stopped: Bool
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let shouldUpdateMovingSand: Bool
    let shouldUpdateWindyGround: Bool
}

/// Value counterpart of `update_decelerating_speed` and its
/// `mario_set_forward_vel` call.
enum SM64MarioDeceleratingSpeed {
    static func update(
        _ input: SM64MarioDeceleratingSpeedInput
    ) -> SM64MarioDeceleratingSpeedResult? {
        guard input.forwardVelocity.isFinite, input.velocityY.isFinite else {
            return nil
        }
        let forwardVelocity = SM64DeterministicPrimitives.approachFloat(
            current: input.forwardVelocity,
            target: 0,
            increment: 1,
            decrement: 1
        )
        let x = SM64CanonicalTrig.sins(input.faceYaw) * forwardVelocity
        let z = SM64CanonicalTrig.coss(input.faceYaw) * forwardVelocity
        return SM64MarioDeceleratingSpeedResult(
            stopped: forwardVelocity == 0,
            forwardVelocity: forwardVelocity,
            velocity: SM64ObjectVector3(x: x, y: input.velocityY, z: z),
            shouldUpdateMovingSand: true,
            shouldUpdateWindyGround: true
        )
    }
}
