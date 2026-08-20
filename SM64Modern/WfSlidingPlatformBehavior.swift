import Foundation

struct SM64WfSlidingPlatformInitialization: Equatable, Sendable {
    let positionX: Float
    let homeX: Float
    let faceYaw: Int32
    let speed: Float
    let timer: Int32
}

struct SM64WfSlidingPlatformPosition: Equatable, Sendable {
    let x: Float
    let y: Float
    let z: Float

    static let zero = SM64WfSlidingPlatformPosition(x: 0, y: 0, z: 0)
}

struct SM64WfSlidingPlatformInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let homeX: Float
    let forwardVelocity: Float
    let faceYaw: Int32
    let moveYaw: Int32
    let speed: Float
}

struct SM64WfSlidingPlatformOutput: Equatable, Sendable {
    let action: Int32
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let forwardVelocity: Float
    let faceYaw: Int32
    let moveYaw: Int32
    let velocityX: Float
    let velocityZ: Float
}

/// Value counterpart of `bhv_wf_sliding_platform_init/loop`. The random
/// initial timer is supplied by the owner/replay rather than consumed here.
enum SM64WfSlidingPlatformBehavior {
    static func initialize(
        position: SM64WfSlidingPlatformPosition,
        faceYaw: Int32,
        moveYaw: Int32,
        behaviorByte: UInt8,
        initialTimer: Int32
    ) -> SM64WfSlidingPlatformInitialization {
        let speed: Float
        switch behaviorByte {
        case 1: speed = 10
        case 2: speed = 15
        case 3: speed = 20
        default: speed = 0
        }
        _ = moveYaw
        return SM64WfSlidingPlatformInitialization(
            positionX: position.x + 2,
            homeX: position.x + 2,
            faceYaw: faceYaw &- 0x4000,
            speed: speed,
            timer: initialTimer
        )
    }

    static func update(_ input: SM64WfSlidingPlatformInput)
        -> SM64WfSlidingPlatformOutput
    {
        var action = input.action
        var positionX = input.positionX
        var forwardVelocity = input.forwardVelocity
        var moveYaw = input.moveYaw
        let threshold = input.speed == 0 ? Float.greatestFiniteMagnitude : 500 / input.speed

        switch input.action {
        case 0:
            if Float(input.timer) >= 101 {
                action = 1
                forwardVelocity = input.speed
            }
        case 1:
            if Float(input.timer) >= threshold {
                forwardVelocity = 0
                positionX = input.homeX + 510
            }
            if input.timer == 60 {
                action = 2
                forwardVelocity = input.speed
                moveYaw &-= 0x8000
            }
        case 2:
            if Float(input.timer) >= threshold {
                forwardVelocity = 0
                positionX = input.homeX
            }
            if input.timer == 90 {
                action = 1
                forwardVelocity = input.speed
                moveYaw &-= 0x8000
            }
        default:
            break
        }

        let velocityX = SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw))
        )
        let velocityZ = SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw))
        )
        return SM64WfSlidingPlatformOutput(
            action: action,
            positionX: positionX + velocityX,
            positionY: input.positionY,
            positionZ: input.positionZ + velocityZ,
            forwardVelocity: forwardVelocity,
            faceYaw: input.faceYaw,
            moveYaw: moveYaw,
            velocityX: velocityX,
            velocityZ: velocityZ
        )
    }
}
