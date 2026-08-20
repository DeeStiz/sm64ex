import Foundation

struct SM64ActivatedBackAndForthPlatformInitialization: Equatable, Sendable {
    let maxOffset: Float
    let vertical: Bool
    let flipRotation: Int32
    let startYaw: Int32
}

struct SM64ActivatedBackAndForthPlatformInput: Equatable, Sendable {
    let offset: Float
    let platformVelocity: Float
    let countdown: Int32
    let marioOnPlatform: Bool
    let distanceToMario: Float
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let homeX: Float
    let homeY: Float
    let homeZ: Float
    let moveYaw: Int32
    let faceYaw: Int32
    let maxOffset: Float
    let vertical: Bool
    let flipRotation: Int32
}

struct SM64ActivatedBackAndForthPlatformOutput: Equatable, Sendable {
    let offset: Float
    let platformVelocity: Float
    let countdown: Int32
    let velocityY: Float
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let faceYaw: Int32
}

/// Value counterpart of `bhv_activated_back_and_forth_platform_init/update`.
enum SM64ActivatedBackAndForthPlatformBehavior {
    static func initialize(behaviorByte: UInt8, faceYaw: Int32)
        -> SM64ActivatedBackAndForthPlatformInitialization
    {
        let platformType = Int(behaviorByte & 0x03)
        let distanceUnits = Float(behaviorByte & 0x7F)
        let maxOffset = distanceUnits * 50 - (platformType == 2 ? 12 : 0)
        return SM64ActivatedBackAndForthPlatformInitialization(
            maxOffset: maxOffset,
            vertical: behaviorByte & 0x80 != 0,
            flipRotation: platformType == 0 ? 0x8000 : 0,
            startYaw: faceYaw
        )
    }

    static func update(_ input: SM64ActivatedBackAndForthPlatformInput)
        -> SM64ActivatedBackAndForthPlatformOutput
    {
        let velocityY: Float = input.marioOnPlatform ? -6 : 6
        var offset = input.offset
        var platformVelocity = input.platformVelocity
        var countdown = input.countdown
        var faceYaw = input.faceYaw
        if platformVelocity != 0 {
            if countdown != 0 {
                countdown -= 1
            } else {
                offset += platformVelocity
                let clamped = offset <= 0 || offset >= input.maxOffset
                if offset <= 0 { offset = 0 }
                if offset >= input.maxOffset { offset = input.maxOffset }
                if clamped || (platformVelocity > 0 && input.distanceToMario > 3000) {
                    countdown = 20
                    if velocityY < 0 || platformVelocity > 0 { platformVelocity = -platformVelocity }
                    else { platformVelocity = 0 }
                    faceYaw &+= input.flipRotation
                }
            }
        } else {
            if velocityY < 0 { platformVelocity = 10 }
            countdown = 20
        }
        var positionX = input.positionX
        var positionY = input.positionY
        var positionZ = input.positionZ
        if input.vertical {
            positionY = input.homeY + offset
        } else {
            positionY += velocityY
            positionY = min(max(positionY, input.homeY - 20), input.homeY)
            let distance = -offset
            positionX = input.homeX + SM64DeterministicPrimitives.cFloatMultiply(
                distance, SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
            )
            positionZ = input.homeZ + SM64DeterministicPrimitives.cFloatMultiply(
                distance, SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            )
        }
        return SM64ActivatedBackAndForthPlatformOutput(
            offset: offset, platformVelocity: platformVelocity, countdown: countdown,
            velocityY: velocityY, positionX: positionX, positionY: positionY,
            positionZ: positionZ, faceYaw: faceYaw
        )
    }
}
