import Foundation

enum SM64CheckerboardPlatformKind: UInt8, Equatable, Sendable {
    case group = 0
    case child = 1
}

struct SM64CheckerboardPlatformInput: Equatable, Sendable {
    let kind: SM64CheckerboardPlatformKind
    let action: Int32
    let timer: Int32
    let waitTime: Int32
    let childParameter: Int32
    let speed: Float
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let moveYaw: Int32
    let movePitch: Int32
    let facePitch: Int32
    let angleVelocityPitch: Int32
    let forwardVelocity: Float
    let velocityY: Float
}

struct SM64CheckerboardPlatformOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let moveYaw: Int32
    let movePitch: Int32
    let facePitch: Int32
    let angleVelocityPitch: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let shouldDelete: Bool
}

/// Value counterpart of the checkerboard group/sub-platform behavior.
enum SM64CheckerboardPlatformBehavior {
    static func update(_ input: SM64CheckerboardPlatformInput)
        -> SM64CheckerboardPlatformOutput
    {
        guard input.kind == .child else {
            return SM64CheckerboardPlatformOutput(
                action: input.action, timer: input.timer,
                positionX: input.positionX, positionY: input.positionY, positionZ: input.positionZ,
                moveYaw: input.moveYaw, movePitch: input.movePitch, facePitch: input.facePitch,
                angleVelocityPitch: input.angleVelocityPitch, forwardVelocity: input.forwardVelocity,
                velocityY: input.velocityY, shouldDelete: true
            )
        }
        var action = input.action
        var timer = input.timer
        var movePitch = input.movePitch
        var facePitch = input.facePitch
        var angleVelocityPitch = input.angleVelocityPitch
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY

        switch input.action {
        case 0:
            action = input.childParameter == 0 ? 1 : 3
        case 1:
            angleVelocityPitch = 0
            forwardVelocity = 0
            velocityY = 10
            if input.timer > input.waitTime { action = 2; timer = 0 }
        case 2:
            velocityY = 0
            angleVelocityPitch = 512
            if input.timer + 1 == 64 { action = 3; timer = 0 }
        case 3:
            angleVelocityPitch = 0
            forwardVelocity = 0
            velocityY = -10
            if input.timer > input.waitTime { action = 4; timer = 0 }
        case 4:
            angleVelocityPitch = -512
            velocityY = 0
            if input.timer + 1 == 64 { action = 1; timer = 0 }
        default:
            break
        }

        movePitch &+= abs(angleVelocityPitch)
        facePitch &+= abs(angleVelocityPitch)
        if movePitch != 0 {
            let sign: Float = angleVelocityPitch >= 0 ? 1 : -1
            forwardVelocity = SM64DeterministicPrimitives.cFloatMultiply(
                sign * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: movePitch)), input.speed
            )
            velocityY = SM64DeterministicPrimitives.cFloatMultiply(
                sign * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: movePitch)), input.speed
            )
        }
        if action == 1 && input.timer + 1 == 64 {
            angleVelocityPitch = 0
            facePitch &= ~0x7FFF
        }
        let velocityX = SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity, SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        )
        let velocityZ = SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity, SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        )
        return SM64CheckerboardPlatformOutput(
            action: action,
            timer: timer,
            positionX: input.positionX + velocityX,
            positionY: input.positionY + velocityY,
            positionZ: input.positionZ + velocityZ,
            moveYaw: input.moveYaw,
            movePitch: movePitch,
            facePitch: facePitch,
            angleVelocityPitch: angleVelocityPitch,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            shouldDelete: false
        )
    }
}
