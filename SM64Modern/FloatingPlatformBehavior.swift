import Foundation

enum SM64FloatingPlatformVariant: UInt8, Equatable, Sendable {
    case wdwSquare = 0
    case wdwRectangular = 1
    case jrb = 2
}

struct SM64FloatingPlatformInput: Equatable, Sendable {
    let marioOnPlatform: Bool
    let objectPosition: SM64ObjectVector3
    let marioPosition: SM64ObjectVector3
    let moveYaw: Int32
    let floorHeight: Float
    let waterLevel: Float
    let platformOffset: Float
    let floatY: Float
    let velocityY: Float
    let oscillationTimer: Int32
    let facePitch: Int32
    let faceRoll: Int32
}

struct SM64FloatingPlatformOutput: Equatable, Sendable {
    let action: Int32
    let usingFloor: Bool
    let homeY: Float
    let positionY: Float
    let facePitch: Int32
    let faceRoll: Int32
    let floatY: Float
    let velocityY: Float
    let oscillationTimer: Int32
}

/// Value counterpart of `bhv_floating_platform_loop`.
enum SM64FloatingPlatformBehavior {
    static func update(_ input: SM64FloatingPlatformInput) -> SM64FloatingPlatformOutput {
        let usingFloor = input.waterLevel <= input.floorHeight + input.platformOffset
        let homeY = usingFloor
            ? input.floorHeight + input.platformOffset
            : input.waterLevel + input.platformOffset
        var facePitch = input.facePitch
        var faceRoll = input.faceRoll
        var floatY = input.floatY
        var velocityY = input.velocityY
        var positionY = homeY
        var oscillationTimer = input.oscillationTimer

        if !usingFloor {
            let yaw = Int16(truncatingIfNeeded: -input.moveYaw)
            let dx = input.marioPosition.x - input.objectPosition.x
            let dz = input.marioPosition.z - input.objectPosition.z
            let localRoll = SM64DeterministicPrimitives.cFloatMultiply(dx, SM64CanonicalTrig.coss(yaw))
                + SM64DeterministicPrimitives.cFloatMultiply(dz, SM64CanonicalTrig.sins(yaw))
            let localPitch = SM64DeterministicPrimitives.cFloatMultiply(dz, SM64CanonicalTrig.coss(yaw))
                - SM64DeterministicPrimitives.cFloatMultiply(dx, SM64CanonicalTrig.sins(yaw))
            let sp6 = Int32(Int16(truncatingIfNeeded: Int32(localRoll)))
            let sp4 = Int32(Int16(truncatingIfNeeded: Int32(localPitch)))

            if input.marioOnPlatform {
                facePitch = sp4 &* 2
                faceRoll = -sp6 &* 2
                velocityY = max(velocityY - 1, 0)
                floatY = min(floatY + velocityY, 90)
            } else {
                facePitch /= 2
                faceRoll /= 2
                floatY = max(floatY - 5, 0)
                velocityY = 10
            }

            positionY = homeY - input.platformOffset - floatY
                + SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: oscillationTimer &* 0x800)) * 10
            oscillationTimer = oscillationTimer == 31 ? 0 : oscillationTimer &+ 1
        }

        return SM64FloatingPlatformOutput(
            action: usingFloor ? 1 : 0,
            usingFloor: usingFloor,
            homeY: homeY,
            positionY: positionY,
            facePitch: facePitch,
            faceRoll: faceRoll,
            floatY: floatY,
            velocityY: velocityY,
            oscillationTimer: oscillationTimer
        )
    }
}
