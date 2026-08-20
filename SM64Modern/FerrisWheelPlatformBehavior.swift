import Foundation

struct SM64FerrisWheelVector3: Equatable, Sendable {
    let x: Float
    let y: Float
    let z: Float
}

struct SM64FerrisWheelPlatformInput: Equatable, Sendable {
    let parentPosition: SM64FerrisWheelVector3
    let parentRoll: Int16
    let parentMoveYaw: Int16
    let platformIndex: Int32
    let previousPosition: SM64FerrisWheelVector3
}

struct SM64FerrisWheelPlatformOutput: Equatable, Sendable {
    let position: SM64FerrisWheelVector3
    let velocity: SM64FerrisWheelVector3
}

/// Value counterpart of `bhv_ferris_wheel_platform_update`.
enum SM64FerrisWheelPlatformBehavior {
    static func update(_ input: SM64FerrisWheelPlatformInput)
        -> SM64FerrisWheelPlatformOutput
    {
        let offsetAngle = Int16(
            truncatingIfNeeded: Int32(input.parentRoll)
                &+ input.platformIndex &* 0x4000
        )
        let offsetXZ = SM64DeterministicPrimitives.cFloatMultiply(
            400,
            SM64CanonicalTrig.coss(offsetAngle)
        )
        let parentYaw = input.parentMoveYaw
        let position = SM64FerrisWheelVector3(
            x: input.parentPosition.x
                + SM64DeterministicPrimitives.cFloatMultiply(offsetXZ, SM64CanonicalTrig.sins(parentYaw))
                + SM64DeterministicPrimitives.cFloatMultiply(300, SM64CanonicalTrig.coss(parentYaw)),
            y: input.parentPosition.y
                + SM64DeterministicPrimitives.cFloatMultiply(400, SM64CanonicalTrig.sins(offsetAngle)),
            z: input.parentPosition.z
                + SM64DeterministicPrimitives.cFloatMultiply(offsetXZ, SM64CanonicalTrig.coss(parentYaw))
                + SM64DeterministicPrimitives.cFloatMultiply(300, SM64CanonicalTrig.sins(parentYaw))
        )
        return SM64FerrisWheelPlatformOutput(
            position: position,
            velocity: SM64FerrisWheelVector3(
                x: position.x - input.previousPosition.x,
                y: position.y - input.previousPosition.y,
                z: position.z - input.previousPosition.z
            )
        )
    }
}
