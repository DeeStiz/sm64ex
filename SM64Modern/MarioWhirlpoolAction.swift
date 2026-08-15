import Foundation

enum SM64MarioWhirlpoolIntent: UInt8, Equatable, Sendable {
    case continueAction = 0
    case deathWarp = 1
}

struct SM64MarioWhirlpoolActionInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let whirlpoolPosition: SM64ObjectVector3
    let whirlpoolOffsetY: Float
    let velocityY: Float
    let faceYaw: Int16
    let actionTimer: UInt16
}

struct SM64MarioWhirlpoolActionResult: Equatable, Sendable {
    let intent: SM64MarioWhirlpoolIntent
    let position: SM64ObjectVector3
    let whirlpoolOffsetY: Float
    let velocityY: Float
    let faceYaw: Int16
    let actionTimer: UInt16
    let animationID: UInt16
    let shouldSyncGraphics: Bool
    let shouldResetRumble: Bool
    let shouldTriggerDeathWarp: Bool
}

/// Value counterpart of `act_caught_in_whirlpool`.
///
/// The object lookup, warp dispatch, animation installation, graphics-object
/// synchronization, and rumble implementation remain explicit owner-thread
/// effects. This value step preserves the orbit radius, vertical offset,
/// angular velocity, and death-warp timer contract.
enum SM64MarioWhirlpoolAction {
    private static let fallAnimation: UInt16 = 0x56

    static func update(
        _ input: SM64MarioWhirlpoolActionInput
    ) -> SM64MarioWhirlpoolActionResult? {
        guard input.position.x.isFinite, input.position.y.isFinite,
              input.position.z.isFinite,
              input.whirlpoolPosition.x.isFinite,
              input.whirlpoolPosition.y.isFinite,
              input.whirlpoolPosition.z.isFinite,
              input.whirlpoolOffsetY.isFinite,
              input.velocityY.isFinite else {
            return nil
        }

        let deltaX = input.position.x - input.whirlpoolPosition.x
        let deltaZ = input.position.z - input.whirlpoolPosition.z
        let distance = (deltaX * deltaX + deltaZ * deltaZ).squareRoot()

        var whirlpoolOffsetY = input.whirlpoolOffsetY + input.velocityY
        var actionTimer = input.actionTimer
        var shouldTriggerDeathWarp = false
        if whirlpoolOffsetY < 0 {
            whirlpoolOffsetY = 0
            if distance < 16.1 {
                shouldTriggerDeathWarp = actionTimer == 16
                actionTimer &+= 1
            }
        }

        let newDistance: Float
        let angleChange: Int16
        if distance <= 28 {
            newDistance = 16
            angleChange = 0x1800
        } else if distance < 256 {
            newDistance = distance - (12 - distance / 32)
            let rawAngle = Int32(0x1C00) - Int32(distance * 20)
            angleChange = Int16(truncatingIfNeeded: rawAngle)
        } else {
            newDistance = distance - 4
            angleChange = 0x0800
        }

        let velocityY = -640 / (newDistance + 16)
        var orbitX = deltaX
        var orbitZ = deltaZ
        if distance < 1 {
            orbitX = newDistance * SM64CanonicalTrig.sins(input.faceYaw)
            orbitZ = newDistance * SM64CanonicalTrig.coss(input.faceYaw)
        } else {
            orbitX *= newDistance / distance
            orbitZ *= newDistance / distance
        }

        let sinAngleChange = SM64CanonicalTrig.sins(angleChange)
        let cosAngleChange = SM64CanonicalTrig.coss(angleChange)
        let position = SM64ObjectVector3(
            x: input.whirlpoolPosition.x
                + orbitX * cosAngleChange + orbitZ * sinAngleChange,
            y: input.whirlpoolPosition.y + whirlpoolOffsetY,
            z: input.whirlpoolPosition.z
                - orbitX * sinAngleChange + orbitZ * cosAngleChange
        )
        let faceYaw = SM64CanonicalTrig.atan2s(y: orbitZ, x: orbitX)
            &+ Int16(bitPattern: 0x8000)

        return SM64MarioWhirlpoolActionResult(
            intent: shouldTriggerDeathWarp ? .deathWarp : .continueAction,
            position: position,
            whirlpoolOffsetY: whirlpoolOffsetY,
            velocityY: velocityY,
            faceYaw: faceYaw,
            actionTimer: actionTimer,
            animationID: Self.fallAnimation,
            shouldSyncGraphics: true,
            shouldResetRumble: true,
            shouldTriggerDeathWarp: shouldTriggerDeathWarp
        )
    }
}
