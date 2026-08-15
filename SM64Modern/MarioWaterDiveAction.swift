import Foundation

enum SM64MarioWaterDiveVariant: UInt8, Equatable, Sendable {
    case backwardKnockback = 0
    case forwardKnockback = 1
    case plunge = 2
}

enum SM64MarioWaterDiveIntent: UInt8, Equatable, Sendable {
    case continueAction = 0
    case waterIdle = 1
    case waterDeath = 2
    case waterActionEnd = 3
    case holdWaterActionEnd = 4
    case flutterKick = 5
    case holdFlutterKick = 6
    case metalWaterFalling = 7
}

struct SM64MarioWaterDiveActionInput: Equatable, Sendable {
    let variant: SM64MarioWaterDiveVariant
    let actionArgument: UInt32
    let actionTimer: UInt16
    let actionState: UInt8
    let animationPastEnd: Bool
    let animationIDFrame: Int16
    let health: UInt16
    let forwardVelocity: Float
    let velocityY: Float
    let buoyancy: Float
    let waterStep: SM64MarioWaterStepOutcome
    let nearSurface: Bool
    let heldObject: Bool
    let metalCap: Bool
    let previousActionDiving: Bool
    let previousActionAir: Bool
    let input: SM64MarioInputFlags
    let fallDistance: Float
}

struct SM64MarioWaterDiveActionResult: Equatable, Sendable {
    let variant: SM64MarioWaterDiveVariant
    let intent: SM64MarioWaterDiveIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionTimer: UInt16
    let actionState: UInt8
    let animationID: UInt16
    let forwardVelocity: Float
    let velocityY: Float
    let shouldSetInvincibilityTimer: Bool
    let shouldPlaySplashSound: Bool
    let shouldPlayFallSound: Bool
    let shouldParticleWaterSplash: Bool
    let shouldParticlePlungeBubble: Bool
    let shouldQueueRumble: Bool
    let shouldResetRumble: Bool
    let shouldStationarySlowDown: Bool
}

/// Value counterpart of water knockback and `act_water_plunge`.
/// Water collision/current, animation/audio installation, particles, and
/// camera/warp effects remain explicit owner-thread effects.
enum SM64MarioWaterDiveAction {
    private static let backwardKnockbackAnimation: UInt16 = 0x9E
    private static let forwardKnockbackAnimation: UInt16 = 0xA8
    private static let waterActionEndAnimation: UInt16 = 0xAD
    private static let holdWaterActionEndAnimation: UInt16 = 0xA2
    private static let flutterKickAnimation: UInt16 = 0xAC
    private static let holdFlutterKickAnimation: UInt16 = 0xA1
    private static let generalFallAnimation: UInt16 = 0x56
    private static let fallWithLightObjectAnimation: UInt16 = 0x43

    static func update(
        _ input: SM64MarioWaterDiveActionInput
    ) -> SM64MarioWaterDiveActionResult? {
        guard input.forwardVelocity.isFinite,
              input.velocityY.isFinite,
              input.buoyancy.isFinite,
              input.fallDistance.isFinite else {
            return nil
        }
        switch input.variant {
        case .backwardKnockback, .forwardKnockback:
            return updateKnockback(input)
        case .plunge:
            return updatePlunge(input)
        }
    }

    private static func updateKnockback(
        _ input: SM64MarioWaterDiveActionInput
    ) -> SM64MarioWaterDiveActionResult {
        let dead = input.health < 0x100
        let ended = input.animationPastEnd
        return SM64MarioWaterDiveActionResult(
            variant: input.variant,
            intent: ended ? (dead ? .waterDeath : .waterIdle) : .continueAction,
            action: ended
                ? (dead ? SM64MarioActionID.waterDeath : SM64MarioActionID.waterIdle) : nil,
            actionArgument: 0, actionTimer: input.actionTimer,
            actionState: input.actionState,
            animationID: input.variant == .backwardKnockback
                ? Self.backwardKnockbackAnimation : Self.forwardKnockbackAnimation,
            forwardVelocity: input.forwardVelocity, velocityY: input.velocityY,
            shouldSetInvincibilityTimer: ended && input.actionArgument > 0,
            shouldPlaySplashSound: false, shouldPlayFallSound: false,
            shouldParticleWaterSplash: false, shouldParticlePlungeBubble: false,
            shouldQueueRumble: false, shouldResetRumble: false,
            shouldStationarySlowDown: true
        )
    }

    private static func updatePlunge(
        _ input: SM64MarioWaterDiveActionInput
    ) -> SM64MarioWaterDiveActionResult {
        let actionTimer = input.actionTimer &+ 1
        var actionState = input.actionState
        let stateFlags = (input.heldObject ? 1 : 0)
            | (input.metalCap ? 4 : 0)
            | ((!input.metalCap && (input.previousActionDiving || input.input.contains(.aDown))) ? 2 : 0)
        let endVelocity: Float = input.nearSurface ? 0 : -5
        let velocityY = SM64DeterministicPrimitives.approachFloat(
            current: input.velocityY, target: input.buoyancy,
            increment: 2, decrement: 1
        )
        let splash = actionState == 0
        if splash { actionState = 1 }

        let shouldEnd = input.waterStep == .hitFloor
            || velocityY >= endVelocity || actionTimer > 20
        let transition: (intent: SM64MarioWaterDiveIntent, action: UInt32?, animation: UInt16)
        switch stateFlags {
        case 1:
            transition = (.holdWaterActionEnd, SM64MarioActionID.holdWaterActionEnd,
                          Self.holdWaterActionEndAnimation)
        case 2:
            transition = (.flutterKick, SM64MarioActionID.flutterKick,
                          Self.flutterKickAnimation)
        case 3:
            transition = (.holdFlutterKick, SM64MarioActionID.holdFlutterKick,
                          Self.holdFlutterKickAnimation)
        case 4:
            transition = (.metalWaterFalling, SM64MarioActionID.metalWaterFalling,
                          Self.generalFallAnimation)
        case 5:
            transition = (.metalWaterFalling, SM64MarioActionID.holdMetalWaterFalling,
                          Self.fallWithLightObjectAnimation)
        default:
            transition = (.waterActionEnd, SM64MarioActionID.waterActionEnd,
                          Self.waterActionEndAnimation)
        }
        return SM64MarioWaterDiveActionResult(
            variant: input.variant,
            intent: shouldEnd ? transition.intent : .continueAction,
            action: shouldEnd ? transition.action : nil,
            actionArgument: 0, actionTimer: actionTimer, actionState: actionState,
            animationID: transition.animation,
            forwardVelocity: SM64DeterministicPrimitives.approachFloat(
                current: input.forwardVelocity, target: 0, increment: 1, decrement: 1
            ),
            velocityY: velocityY,
            shouldSetInvincibilityTimer: false,
            shouldPlaySplashSound: splash,
            shouldPlayFallSound: splash && input.fallDistance > 1150,
            shouldParticleWaterSplash: splash,
            shouldParticlePlungeBubble: true,
            shouldQueueRumble: splash && input.previousActionAir,
            shouldResetRumble: shouldEnd,
            shouldStationarySlowDown: true
        )
    }
}
