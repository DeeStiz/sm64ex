import Foundation

enum SM64MarioTwirlingWaterVariant: UInt8, Equatable, Sendable {
    case twirling = 0
    case waterJump = 1
    case holdWaterJump = 2
}

enum SM64MarioTwirlingWaterIntent: UInt8, Equatable, Sendable {
    case continueAir = 0
    case twirlLand = 1
    case waterJumpLand = 2
    case holdWaterJumpLand = 3
    case lowSpeedWallStop = 4
    case reflectedWall = 5
    case ledgeGrab = 6
    case lavaBoost = 7
    case dropHeldObject = 8
}

struct SM64MarioTwirlingWaterActionInput: Equatable, Sendable {
    let variant: SM64MarioTwirlingWaterVariant
    let input: SM64MarioInputFlags
    let actionArgument: UInt32
    let twirlYaw: Int16
    let angleVelocityY: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocityY: Float
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let wallAngle: Int16?
    let airStep: SM64MarioCommonAirStepOutcome
    let animationPastEnd: Bool
    let dropObjectRequested: Bool
}

struct SM64MarioTwirlingWaterActionResult: Equatable, Sendable {
    let variant: SM64MarioTwirlingWaterVariant
    let intent: SM64MarioTwirlingWaterIntent
    let action: UInt32?
    let actionArgument: UInt32
    let animationID: UInt16
    let twirlYaw: Int16
    let angleVelocityY: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let shouldPlayTwirlSound: Bool
    let shouldSetLedgeAnimation: Bool
    let shouldSetDefaultCamera: Bool
    let shouldDropHeldObject: Bool
    let shouldReflectBonk: Bool
    let shouldPlayLavaBoost: Bool
}

/// Value counterpart of `act_twirling`, `act_water_jump`, and
/// `act_hold_water_jump`. Collision, camera, audio, animation installation,
/// and object mutation remain owner-thread effects; this boundary owns the
/// scalar branch order and action payloads.
enum SM64MarioTwirlingWaterAction {
    private static let idleOnLedgeAnimation: UInt16 = 0x33
    private static let singleJumpAnimation: UInt16 = 0x4D
    private static let holdJumpAnimation: UInt16 = 0x41
    private static let twirlAnimation: UInt16 = 0x94
    private static let startTwirlAnimation: UInt16 = 0x95

    static func update(
        _ input: SM64MarioTwirlingWaterActionInput
    ) -> SM64MarioTwirlingWaterActionResult? {
        guard input.forwardVelocity.isFinite,
              input.velocityY.isFinite,
              input.intendedMagnitude.isFinite else {
            return nil
        }

        switch input.variant {
        case .twirling:
            return updateTwirling(input)
        case .waterJump, .holdWaterJump:
            return updateWaterJump(input)
        }
    }

    private static func updateTwirling(
        _ input: SM64MarioTwirlingWaterActionInput
    ) -> SM64MarioTwirlingWaterActionResult {
        let angleVelocityY = Int16(
            truncatingIfNeeded: SM64DeterministicPrimitives.approachS32(
                current: Int32(input.angleVelocityY),
                target: input.input.contains(.aDown) ? 0x2000 : 0x1800,
                increment: 0x200,
                decrement: 0x200
            )
        )
        let startTwirlYaw = input.twirlYaw
        let twirlYaw = Int16(
            truncatingIfNeeded: Int32(input.twirlYaw) + Int32(angleVelocityY)
        )
        let actionArgument: UInt32 = input.animationPastEnd ? 1 : input.actionArgument
        let (faceYaw, forwardVelocity) = updateLavaControl(input)
        var intent: SM64MarioTwirlingWaterIntent = .continueAir
        var action: UInt32?
        var shouldReflectBonk = false
        var shouldPlayLavaBoost = false

        switch input.airStep {
        case .landed:
            intent = .twirlLand
            action = SM64MarioActionID.twirlLand
        case .hitWall:
            intent = .reflectedWall
            shouldReflectBonk = true
        case .hitLavaWall:
            intent = .lavaBoost
            action = SM64MarioActionID.lavaBoost
            shouldPlayLavaBoost = true
        case .none, .grabbedLedge, .grabbedCeiling:
            break
        }

        return SM64MarioTwirlingWaterActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: actionArgument,
            animationID: input.actionArgument == 0
                ? Self.startTwirlAnimation : Self.twirlAnimation,
            twirlYaw: twirlYaw, angleVelocityY: angleVelocityY,
            faceYaw: faceYaw, forwardVelocity: forwardVelocity,
            velocity: velocity(forwardVelocity: forwardVelocity, faceYaw: faceYaw,
                               velocityY: input.velocityY),
            shouldPlayTwirlSound: startTwirlYaw > twirlYaw,
            shouldSetLedgeAnimation: false,
            shouldSetDefaultCamera: false,
            shouldDropHeldObject: false,
            shouldReflectBonk: shouldReflectBonk,
            shouldPlayLavaBoost: shouldPlayLavaBoost
        )
    }

    private static func updateWaterJump(
        _ input: SM64MarioTwirlingWaterActionInput
    ) -> SM64MarioTwirlingWaterActionResult {
        if input.variant == .holdWaterJump && input.dropObjectRequested {
            return SM64MarioTwirlingWaterActionResult(
                variant: input.variant, intent: .dropHeldObject,
                action: SM64MarioActionID.freefall, actionArgument: 0,
                animationID: Self.holdJumpAnimation,
                twirlYaw: input.twirlYaw, angleVelocityY: input.angleVelocityY,
                faceYaw: input.faceYaw, forwardVelocity: input.forwardVelocity,
                velocity: SM64ObjectVector3(x: 0, y: input.velocityY, z: 0),
                shouldPlayTwirlSound: false, shouldSetLedgeAnimation: false,
                shouldSetDefaultCamera: false, shouldDropHeldObject: true,
                shouldReflectBonk: false, shouldPlayLavaBoost: false
            )
        }

        var forwardVelocity = input.forwardVelocity
        if forwardVelocity < 15 { forwardVelocity = 15 }
        var intent: SM64MarioTwirlingWaterIntent = .continueAir
        var action: UInt32?
        var animationID = input.variant == .holdWaterJump
            ? Self.holdJumpAnimation : Self.singleJumpAnimation
        var shouldSetLedgeAnimation = false
        var shouldSetDefaultCamera = false
        var shouldPlayLavaBoost = false

        switch input.airStep {
        case .landed:
            intent = input.variant == .holdWaterJump
                ? .holdWaterJumpLand : .waterJumpLand
            action = input.variant == .holdWaterJump
                ? SM64MarioActionID.holdJumpLand : SM64MarioActionID.jumpLand
            shouldSetDefaultCamera = true
        case .hitWall:
            // Both water-jump callers force the minimum speed after a wall.
            forwardVelocity = 15
        case .grabbedLedge:
            if input.variant == .waterJump {
                intent = .ledgeGrab
                action = SM64MarioActionID.ledgeGrab
                animationID = Self.idleOnLedgeAnimation
                shouldSetLedgeAnimation = true
                shouldSetDefaultCamera = true
            }
        case .hitLavaWall:
            intent = .lavaBoost
            action = SM64MarioActionID.lavaBoost
            shouldPlayLavaBoost = true
        case .none, .grabbedCeiling:
            break
        }

        return SM64MarioTwirlingWaterActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: 0, animationID: animationID,
            twirlYaw: input.twirlYaw, angleVelocityY: input.angleVelocityY,
            faceYaw: input.faceYaw, forwardVelocity: forwardVelocity,
            velocity: velocity(forwardVelocity: forwardVelocity,
                               faceYaw: input.faceYaw, velocityY: input.velocityY),
            shouldPlayTwirlSound: false,
            shouldSetLedgeAnimation: shouldSetLedgeAnimation,
            shouldSetDefaultCamera: shouldSetDefaultCamera,
            shouldDropHeldObject: false, shouldReflectBonk: false,
            shouldPlayLavaBoost: shouldPlayLavaBoost
        )
    }

    private static func updateLavaControl(
        _ input: SM64MarioTwirlingWaterActionInput
    ) -> (faceYaw: Int16, forwardVelocity: Float) {
        var faceYaw = input.faceYaw
        var forwardVelocity = input.forwardVelocity
        if input.input.contains(.nonzeroAnalog) {
            let intendedDYaw = Int16(
                truncatingIfNeeded: Int32(input.intendedYaw) - Int32(faceYaw)
            )
            let intendedMagnitude = input.intendedMagnitude / 32
            forwardVelocity += SM64CanonicalTrig.coss(intendedDYaw) * intendedMagnitude
            let yawDelta = Int32(
                SM64CanonicalTrig.sins(intendedDYaw) * intendedMagnitude * 1024
            )
            faceYaw = Int16(truncatingIfNeeded: Int32(faceYaw) + yawDelta)
            if forwardVelocity < 0 {
                faceYaw = Int16(truncatingIfNeeded: Int32(faceYaw) + 0x8000)
                forwardVelocity *= -1
            }
            if forwardVelocity > 32 { forwardVelocity -= 2 }
        }
        return (faceYaw, forwardVelocity)
    }

    private static func velocity(
        forwardVelocity: Float, faceYaw: Int16, velocityY: Float
    ) -> SM64ObjectVector3 {
        SM64ObjectVector3(
            x: forwardVelocity * SM64CanonicalTrig.sins(faceYaw),
            y: velocityY,
            z: forwardVelocity * SM64CanonicalTrig.coss(faceYaw)
        )
    }
}
