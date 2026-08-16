import Foundation

struct SM64KingBobombHomeArcInput: Equatable, Sendable {
    let currentPosition: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let initialVelocityY: Float
    let gravity: Float
}

struct SM64KingBobombHomeArcStart: Equatable, Sendable {
    let moveYaw: Int16
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let flightFrames: Int32
}

struct SM64KingBobombHomeArcStepInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int16
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let nativeStepScale: Float
}

struct SM64KingBobombHomeArcStep: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
}

/// Value counterpart of the two King Bob-omb home-return helpers:
/// `arc_to_goal_pos` and `cur_obj_move_using_fvel_and_gravity`. The helper is
/// deliberately independent from the collision world because the C source
/// uses this movement path after the floor/wall prepass and does not apply a
/// terminal velocity or floor clamp in the same function.
enum SM64KingBobombHomeMovement {
    static func start(_ input: SM64KingBobombHomeArcInput) -> SM64KingBobombHomeArcStart? {
        guard finite(input.currentPosition),
              finite(input.homePosition),
              input.initialVelocityY.isFinite,
              input.gravity.isFinite,
              input.gravity != 0 else {
            return nil
        }
        let deltaX = input.homePosition.x - input.currentPosition.x
        let deltaZ = input.homePosition.z - input.currentPosition.z
        let planarDistance = (deltaX * deltaX + deltaZ * deltaZ).squareRoot()
        let flightFrames = (-2 / input.gravity) * input.initialVelocityY - 1
        guard flightFrames.isFinite, flightFrames > 0 else { return nil }
        return SM64KingBobombHomeArcStart(
            moveYaw: SM64CanonicalTrig.atan2s(y: deltaZ, x: deltaX),
            forwardVelocity: planarDistance / flightFrames,
            velocityY: input.initialVelocityY,
            gravity: input.gravity,
            flightFrames: Int32(flightFrames.rounded(.towardZero))
        )
    }

    static func step(_ input: SM64KingBobombHomeArcStepInput) -> SM64KingBobombHomeArcStep? {
        guard finite(input.position),
              input.forwardVelocity.isFinite,
              input.velocityY.isFinite,
              input.gravity.isFinite,
              input.nativeStepScale.isFinite,
              input.nativeStepScale >= 0 else {
            return nil
        }
        let velocity = SM64ObjectVector3(
            x: SM64CanonicalTrig.sins(input.moveYaw) * input.forwardVelocity,
            y: input.velocityY + input.gravity * input.nativeStepScale,
            z: SM64CanonicalTrig.coss(input.moveYaw) * input.forwardVelocity
        )
        return SM64KingBobombHomeArcStep(
            position: SM64ObjectVector3(
                x: input.position.x + velocity.x * input.nativeStepScale,
                y: input.position.y + velocity.y * input.nativeStepScale,
                z: input.position.z + velocity.z * input.nativeStepScale
            ),
            velocity: velocity
        )
    }

    private static func finite(_ value: SM64ObjectVector3) -> Bool {
        value.x.isFinite && value.y.isFinite && value.z.isFinite
    }
}
