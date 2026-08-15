import Foundation

enum SM64MarioAirStepOutcome: UInt8, Equatable, Sendable {
    case none = 0
    case landed = 1
    case hitWall = 2
    case hitLavaWall = 3
}

enum SM64MarioAirKnockbackVariant: UInt8, Equatable, Sendable {
    case backward = 0
    case forward = 1
    case hardBackward = 2
    case hardForward = 3
    case thrownBackward = 4
    case thrownForward = 5
    case softBonk = 6
}

enum SM64MarioAirKnockbackIntent: UInt8, Equatable, Sendable {
    case wallKick = 0
    case continueAir = 1
    case land = 2
    case hardFall = 3
    case hitWall = 4
    case lavaWall = 5
}

struct SM64MarioAirKnockbackActionInput: Equatable, Sendable {
    let variant: SM64MarioAirKnockbackVariant
    let input: SM64MarioInputFlags
    let wallKickTimer: UInt8
    let previousAction: UInt32
    let actionArgument: UInt32
    let hurtCounter: UInt8
    let forwardVelocity: Float
    let velocityY: Float
    let airStep: SM64MarioAirStepOutcome
    let fallDamageOrStuck: Bool
}

struct SM64MarioAirKnockbackActionResult: Equatable, Sendable {
    let variant: SM64MarioAirKnockbackVariant
    let intent: SM64MarioAirKnockbackIntent
    let action: UInt32?
    let actionArgument: UInt32
    let faceYawDelta: Int16
    let animationID: UInt16?
    let airStep: SM64MarioAirStepOutcome
    let forwardVelocity: Float
    let velocityY: Float
    let pitch: Int16?
    let reflectedBonk: Bool
    let shouldQueueRumble: Bool
    let shouldPlayKnockbackSound: Bool
}

/// Value counterpart of `common_air_knockback_step` and its grounded/airborne
/// knockback callers. Air collision is supplied as an immutable step outcome;
/// all action, velocity, wall-reflection, rumble, and animation effects are
/// returned for owner-thread application.
enum SM64MarioAirKnockbackAction {
    static func update(
        _ input: SM64MarioAirKnockbackActionInput
    ) -> SM64MarioAirKnockbackActionResult? {
        guard input.forwardVelocity.isFinite, input.velocityY.isFinite else {
            return nil
        }

        if supportsWallKick(input.variant),
           input.input.contains(.aPressed),
           input.wallKickTimer != 0,
           input.previousAction == SM64MarioActionID.airHitWall {
            return result(
                input: input, intent: .wallKick,
                action: SM64MarioActionID.wallKickAir,
                actionArgument: 0, faceYawDelta: Int16(bitPattern: 0x8000),
                animationID: nil, forwardVelocity: input.forwardVelocity,
                velocityY: input.velocityY, pitch: nil, reflectedBonk: false,
                shouldQueueRumble: false, shouldPlayKnockbackSound: false
            )
        }

        let speed = speed(for: input)
        var forwardVelocity = speed
        var velocityY = input.velocityY
        var animationID: UInt16?
        var pitch: Int16?
        var intent: SM64MarioAirKnockbackIntent
        var action: UInt32?
        var actionArgument: UInt32 = 0
        var reflectedBonk = false
        var shouldQueueRumble = false

        switch input.airStep {
        case .none:
            animationID = animation(for: input.variant)
            intent = .continueAir
            action = nil
            if input.variant == .thrownForward {
                var computedPitch = SM64CanonicalTrig.atan2s(
                    y: forwardVelocity, x: -velocityY
                )
                if computedPitch > 0x1800 { computedPitch = 0x1800 }
                pitch = Int16(truncatingIfNeeded: Int32(computedPitch) + 0x1800)
            }

        case .landed:
            if input.fallDamageOrStuck {
                intent = .hardFall
                action = hardFallAction(for: input)
                actionArgument = 0
            } else {
                intent = .land
                action = landAction(for: input)
                actionArgument = isThrown(input.variant)
                    ? UInt32(input.hurtCounter)
                    : input.actionArgument
            }
            if input.variant == .softBonk {
                shouldQueueRumble = true
            }

        case .hitWall:
            intent = .hitWall
            action = nil
            animationID = 0x02 // MARIO_ANIM_BACKWARD_AIR_KB
            reflectedBonk = true
            if velocityY > 0 { velocityY = 0 }
            forwardVelocity = -speed

        case .hitLavaWall:
            intent = .lavaWall
            action = SM64MarioActionID.lavaBoost
        }

        if isThrown(input.variant) {
            if input.variant == .thrownForward, pitch == nil, input.airStep == .none {
                var computedPitch = SM64CanonicalTrig.atan2s(
                    y: forwardVelocity, x: -velocityY
                )
                if computedPitch > 0x1800 { computedPitch = 0x1800 }
                pitch = Int16(truncatingIfNeeded: Int32(computedPitch) + 0x1800)
            }
            forwardVelocity *= 0.98
        }

        return result(
            input: input, intent: intent, action: action,
            actionArgument: actionArgument, faceYawDelta: 0,
            animationID: animationID, forwardVelocity: forwardVelocity,
            velocityY: velocityY, pitch: pitch,
            reflectedBonk: reflectedBonk,
            shouldQueueRumble: shouldQueueRumble
        )
    }

    private static func speed(
        for input: SM64MarioAirKnockbackActionInput
    ) -> Float {
        switch input.variant {
        case .backward, .hardBackward: return -16
        case .forward, .hardForward: return 16
        case .thrownBackward, .thrownForward, .softBonk: return input.forwardVelocity
        }
    }

    private static func animation(
        for variant: SM64MarioAirKnockbackVariant
    ) -> UInt16 {
        switch variant {
        case .backward, .hardBackward, .thrownBackward: return 0x02
        case .forward, .hardForward, .thrownForward: return 0x2D
        case .softBonk: return 0x56
        }
    }

    private static func landAction(
        for input: SM64MarioAirKnockbackActionInput
    ) -> UInt32 {
        switch input.variant {
        case .backward: return SM64MarioActionID.backwardGroundKnockback
        case .forward: return SM64MarioActionID.forwardGroundKnockback
        case .hardBackward: return SM64MarioActionID.hardBackwardGroundKnockback
        case .hardForward: return SM64MarioActionID.hardForwardGroundKnockback
        case .thrownBackward:
            return input.actionArgument != 0
                ? SM64MarioActionID.hardBackwardGroundKnockback
                : SM64MarioActionID.backwardGroundKnockback
        case .thrownForward:
            return input.actionArgument != 0
                ? SM64MarioActionID.hardForwardGroundKnockback
                : SM64MarioActionID.forwardGroundKnockback
        case .softBonk: return SM64MarioActionID.freefallLand
        }
    }

    private static func hardFallAction(
        for input: SM64MarioAirKnockbackActionInput
    ) -> UInt32 {
        switch input.variant {
        case .backward, .hardBackward, .thrownBackward, .softBonk:
            return SM64MarioActionID.hardBackwardGroundKnockback
        case .forward, .hardForward, .thrownForward:
            return SM64MarioActionID.hardForwardGroundKnockback
        }
    }

    private static func supportsWallKick(
        _ variant: SM64MarioAirKnockbackVariant
    ) -> Bool {
        switch variant {
        case .backward, .forward, .softBonk: return true
        case .hardBackward, .hardForward, .thrownBackward, .thrownForward: return false
        }
    }

    private static func isThrown(
        _ variant: SM64MarioAirKnockbackVariant
    ) -> Bool {
        variant == .thrownBackward || variant == .thrownForward
    }

    private static func result(
        input: SM64MarioAirKnockbackActionInput,
        intent: SM64MarioAirKnockbackIntent,
        action: UInt32?,
        actionArgument: UInt32,
        faceYawDelta: Int16,
        animationID: UInt16?,
        forwardVelocity: Float,
        velocityY: Float,
        pitch: Int16?,
        reflectedBonk: Bool,
        shouldQueueRumble: Bool,
        shouldPlayKnockbackSound: Bool = true
    ) -> SM64MarioAirKnockbackActionResult {
        SM64MarioAirKnockbackActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: actionArgument, faceYawDelta: faceYawDelta,
            animationID: animationID, airStep: input.airStep,
            forwardVelocity: forwardVelocity, velocityY: velocityY,
            pitch: pitch, reflectedBonk: reflectedBonk,
            shouldQueueRumble: shouldQueueRumble,
            shouldPlayKnockbackSound: shouldPlayKnockbackSound
        )
    }
}
