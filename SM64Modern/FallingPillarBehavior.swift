import Foundation

enum SM64FallingPillarAction: UInt8, Equatable, Sendable {
    case idle = 0
    case turning = 1
    case falling = 2
}

struct SM64FallingPillarOutput: Equatable, Sendable {
    let action: SM64FallingPillarAction
    let position: SM64ObjectVector3
    let faceAngles: SM64ObjectAngles
    let velocity: SM64ObjectVector3
    let pitchAcceleration: Float
    let spawnHitboxes: Bool
    let deactivated: Bool
}

enum SM64FallingPillarBehavior {
    static func update(
        action: SM64FallingPillarAction,
        position: SM64ObjectVector3,
        distanceToMario: Float,
        angleToMario: Int32,
        marioPosition: SM64ObjectVector3,
        marioYaw: Int32,
        moveYaw: Int32,
        faceAngles: SM64ObjectAngles,
        angleVelocity: SM64ObjectAngles,
        pitchAcceleration: Float,
        timer: Int32
    ) -> SM64FallingPillarOutput {
        var nextAction = action
        var nextPosition = position
        var nextMoveYaw = moveYaw
        var nextFace = faceAngles
        var nextVelocity = SM64ObjectVector3.zero
        var nextPitchAcceleration = pitchAcceleration
        var spawnHitboxes = false
        var deactivated = false

        switch action {
        case .idle:
            if distanceToMario <= 1_300 {
                nextMoveYaw = angleToMario
                nextVelocity.x = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: nextMoveYaw))
                nextVelocity.z = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: nextMoveYaw))
                nextAction = .turning
                spawnHitboxes = true
            }
        case .turning:
            nextVelocity.x = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: nextMoveYaw))
            nextVelocity.z = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: nextMoveYaw))
            nextPosition.x += nextVelocity.x
            nextPosition.z += nextVelocity.z
            let targetYaw = marioYaw &+ 0x8000
            nextFace.yaw = approachAngle(current: nextFace.yaw, target: targetYaw, increment: 0x400)
            if timer > 10 { nextAction = .falling }
        case .falling:
            nextVelocity.x = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: nextMoveYaw))
            nextVelocity.z = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: nextMoveYaw))
            nextPosition.x += nextVelocity.x
            nextPosition.z += nextVelocity.z
            nextPitchAcceleration += 4
            let nextPitchVelocity = angleVelocity.pitch + Int32(nextPitchAcceleration)
            nextFace.pitch += nextPitchVelocity
            if nextFace.pitch > 0x3900 {
                nextPosition.x = marioPosition.x + SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: nextFace.yaw)) * 500
                nextPosition.z = marioPosition.z + SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: nextFace.yaw)) * 500
                deactivated = true
            }
        }

        return .init(
            action: nextAction,
            position: nextPosition,
            faceAngles: nextFace,
            velocity: nextVelocity,
            pitchAcceleration: nextPitchAcceleration,
            spawnHitboxes: spawnHitboxes,
            deactivated: deactivated
        )
    }

    private static func approachAngle(current: Int32, target: Int32, increment: Int32) -> Int32 {
        let delta = Int16(truncatingIfNeeded: target &- current)
        if delta > Int16(increment) { return current &+ increment }
        if delta < -Int16(increment) { return current &- increment }
        return target
    }
}
