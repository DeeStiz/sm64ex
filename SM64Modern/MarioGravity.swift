import Foundation

struct SM64MarioGravityInput: Equatable, Sendable {
    let action: UInt32
    let marioFlags: UInt32
    let input: UInt32
    let angleVelocityY: Int32
    let velocityY: Float
    let unkC4: Float
}

struct SM64MarioGravityResult: Equatable, Sendable {
    let velocityY: Float
    let wingFlutter: Bool
}

/// Value counterpart of `apply_gravity`. Action/flag bits are copied from the
/// owner-thread Mario snapshot; body-state mutation remains in the C caller.
enum SM64MarioGravity {
    private static let marioWingCap: UInt32 = 0x0000_0008
    private static let marioUnknown08: UInt32 = 0x0000_0100
    private static let inputADown: UInt32 = 0x0000_0080
    private static let actionFlagIntangible: UInt32 = 1 << 12
    private static let actionFlagMetalWater: UInt32 = 1 << 14
    private static let actionFlagInvulnerable: UInt32 = 1 << 17
    private static let actionFlagControlJumpHeight: UInt32 = 1 << 25

    private static let actionTwirling: UInt32 = 0x1080_08A4
    private static let actionShotFromCannon: UInt32 = 0x0088_0898
    private static let actionLongJump: UInt32 = 0x0300_0888
    private static let actionSlideKick: UInt32 = 0x0180_08AA
    private static let actionBBHEnterSpin: UInt32 = 0x0000_1535
    private static let actionLavaBoost: UInt32 = 0x0102_08B7
    private static let actionFallAfterStarGrab: UInt32 = 0x0000_1904
    private static let actionGettingBlown: UInt32 = 0x0102_08B8

    static func update(_ input: SM64MarioGravityInput) -> SM64MarioGravityResult? {
        guard input.velocityY.isFinite, input.unkC4.isFinite else { return nil }

        var velocityY = input.velocityY
        var wingFlutter = false
        let action = input.action
        let shouldStrengthen =
            (input.marioFlags & marioUnknown08) != 0
            && (action & (actionFlagIntangible | actionFlagInvulnerable)) == 0
            && (input.input & inputADown) == 0
            && velocityY > 20
            && (action & actionFlagControlJumpHeight) != 0

        if action == actionTwirling && velocityY < 0 {
            var heaviness: Float = 1
            if input.angleVelocityY > 1024 {
                heaviness = 1024 / Float(input.angleVelocityY)
            }
            let terminalVelocity = -75 * heaviness
            velocityY -= 4 * heaviness
            if velocityY < terminalVelocity { velocityY = terminalVelocity }
        } else if action == actionShotFromCannon {
            velocityY -= 1
            if velocityY < -75 { velocityY = -75 }
        } else if action == actionLongJump
                    || action == actionSlideKick
                    || action == actionBBHEnterSpin {
            velocityY -= 2
            if velocityY < -75 { velocityY = -75 }
        } else if action == actionLavaBoost || action == actionFallAfterStarGrab {
            velocityY -= 3.2
            if velocityY < -65 { velocityY = -65 }
        } else if action == actionGettingBlown {
            velocityY -= input.unkC4
            if velocityY < -75 { velocityY = -75 }
        } else if shouldStrengthen {
            velocityY /= 4
        } else if (action & actionFlagMetalWater) != 0 {
            velocityY -= 1.6
            if velocityY < -16 { velocityY = -16 }
        } else if (input.marioFlags & marioWingCap) != 0
                    && velocityY < 0
                    && (input.input & inputADown) != 0 {
            wingFlutter = true
            velocityY -= 2
            if velocityY < -37.5 {
                velocityY += 4
                if velocityY > -37.5 { velocityY = -37.5 }
            }
        } else {
            velocityY -= 4
            if velocityY < -75 { velocityY = -75 }
        }

        return SM64MarioGravityResult(velocityY: velocityY, wingFlutter: wingFlutter)
    }
}
