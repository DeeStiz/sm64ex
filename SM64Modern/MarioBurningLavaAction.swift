import Foundation

enum SM64MarioBurningLavaVariant: UInt8, Equatable, Sendable {
    case burningJump = 0
    case burningFall = 1
    case lavaBoost = 2
}

enum SM64MarioBurningLavaIntent: UInt8, Equatable, Sendable {
    case continueAir = 0
    case burningGround = 1
    case lavaBounce = 2
    case lavaBoostLand = 3
    case reflectedWall = 4
    case lavaWallRestart = 5
    case deathWarp = 6
}

enum SM64MarioBurningLavaSound: UInt8, Equatable, Sendable {
    case none = 0
    case terrainJump = 1
    case movingLavaBurn = 2
    case onFire = 3
    case heavyLanding = 4
}

struct SM64MarioBurningLavaActionInput: Equatable, Sendable {
    let variant: SM64MarioBurningLavaVariant
    let input: SM64MarioInputFlags
    let actionArgument: UInt32
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocityY: Float
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let wallAngle: Int16?
    let airStep: SM64MarioCommonAirStepOutcome
    let burnTimer: UInt16
    let health: UInt16
    let hurtCounter: UInt8
    let actionState: UInt8
    let floorIsBurning: Bool
    let metalCap: Bool
    let capOnHead: Bool
    let terrainIsSnow: Bool
    let marioSoundPlayed: Bool
}

struct SM64MarioBurningLavaActionResult: Equatable, Sendable {
    let variant: SM64MarioBurningLavaVariant
    let intent: SM64MarioBurningLavaIntent
    let action: UInt32?
    let actionArgument: UInt32
    let animationID: UInt16
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let burnTimer: UInt16
    let health: UInt16
    let hurtCounter: UInt8
    let actionState: UInt8
    let sound: SM64MarioBurningLavaSound
    let shouldPlayLandingSound: Bool
    let shouldPlayOnFireSound: Bool
    let shouldPlayMovingLavaBurn: Bool
    let shouldQueueRumble: Bool
    let shouldResetRumble: Bool
    let shouldDropHeldObject: Bool
    let shouldParticleFire: Bool
    let shouldSetEyesDead: Bool
    let shouldReflectBonk: Bool
    let shouldTriggerDeathWarp: Bool
}

/// Value counterpart of the burning airborne callers and `act_lava_boost`.
/// Health/timers, lava-control projection, bounce state, and action payloads
/// are pure; collision, audio, particles, camera, and object effects are
/// returned for the owner thread.
enum SM64MarioBurningLavaAction {
    private static let singleJumpAnimation: UInt16 = 0x4D
    private static let fireLavaAnimation: UInt16 = 0x29
    private static let generalFallAnimation: UInt16 = 0x56

    static func update(
        _ input: SM64MarioBurningLavaActionInput
    ) -> SM64MarioBurningLavaActionResult? {
        guard input.forwardVelocity.isFinite,
              input.velocityY.isFinite,
              input.intendedMagnitude.isFinite else {
            return nil
        }

        switch input.variant {
        case .burningJump, .burningFall:
            return updateBurningAir(input)
        case .lavaBoost:
            return updateLavaBoost(input)
        }
    }

    private static func updateBurningAir(
        _ input: SM64MarioBurningLavaActionInput
    ) -> SM64MarioBurningLavaActionResult {
        let burnTimer = input.burnTimer &+ 3
        let decrementedHealth = input.health &- 10
        let health = decrementedHealth < 0x100 ? 0xFF : decrementedHealth
        let landed = input.airStep == .landed
        let animationID: UInt16
        if input.variant == .burningFall {
            animationID = Self.generalFallAnimation
        } else {
            animationID = input.actionArgument == 0
                ? Self.singleJumpAnimation : Self.fireLavaAnimation
        }
        return SM64MarioBurningLavaActionResult(
            variant: input.variant,
            intent: landed ? .burningGround : .continueAir,
            action: landed ? SM64MarioActionID.burningGround : nil,
            actionArgument: 0, animationID: animationID,
            faceYaw: input.faceYaw, forwardVelocity: input.forwardVelocity,
            velocity: velocity(forwardVelocity: input.forwardVelocity,
                               faceYaw: input.faceYaw, velocityY: input.velocityY),
            burnTimer: burnTimer, health: health, hurtCounter: input.hurtCounter,
            actionState: input.actionState,
            sound: input.variant == .burningJump ? .terrainJump : .none,
            shouldPlayLandingSound: landed,
            shouldPlayOnFireSound: false,
            shouldPlayMovingLavaBurn: input.variant == .burningJump,
            shouldQueueRumble: false, shouldResetRumble: true,
            shouldDropHeldObject: false, shouldParticleFire: true,
            shouldSetEyesDead: false, shouldReflectBonk: false,
            shouldTriggerDeathWarp: false
        )
    }

    private static func updateLavaBoost(
        _ input: SM64MarioBurningLavaActionInput
    ) -> SM64MarioBurningLavaActionResult {
        var forwardVelocity = input.forwardVelocity
        if !input.input.contains(.nonzeroAnalog) {
            forwardVelocity = SM64DeterministicPrimitives.approachFloat(
                current: forwardVelocity, target: 0, increment: 0.35, decrement: 0.35
            )
        }

        var faceYaw = input.faceYaw
        (faceYaw, forwardVelocity) = lavaControl(
            input: input, faceYaw: faceYaw, forwardVelocity: forwardVelocity
        )
        var velocityY = input.velocityY
        var hurtCounter = input.hurtCounter
        var actionState = input.actionState
        var intent: SM64MarioBurningLavaIntent = .continueAir
        var action: UInt32?
        var actionArgument: UInt32 = 0
        var sound: SM64MarioBurningLavaSound = input.marioSoundPlayed ? .none : .onFire
        var shouldPlayLandingSound = false
        var shouldPlayOnFireSound = !input.marioSoundPlayed
        var shouldQueueRumble = !input.marioSoundPlayed
        var shouldDropHeldObject = false
        var shouldReflectBonk = false

        switch input.airStep {
        case .landed:
            if input.floorIsBurning {
                actionState = 0
                if !input.metalCap {
                    hurtCounter &+= input.capOnHead ? 12 : 18
                }
                velocityY = 84
                sound = .onFire
                shouldPlayOnFireSound = true
                shouldQueueRumble = true
            } else if actionState < 2 && velocityY < 0 {
                intent = .lavaBounce
                velocityY = -velocityY * 0.4
                forwardVelocity *= 0.5
                actionState &+= 1
                sound = .heavyLanding
                shouldPlayLandingSound = true
            } else {
                intent = .lavaBoostLand
                action = SM64MarioActionID.lavaBoostLand
                sound = .heavyLanding
                shouldPlayLandingSound = true
            }
        case .hitWall:
            intent = .reflectedWall
            shouldReflectBonk = true
            if let wallAngle = input.wallAngle {
                faceYaw = Int16(
                    truncatingIfNeeded: Int32(wallAngle) * 2
                        - Int32(faceYaw) + 0x8000
                )
            } else {
                faceYaw = Int16(truncatingIfNeeded: Int32(faceYaw) + 0x8000)
            }
        case .hitLavaWall:
            intent = .lavaWallRestart
            action = SM64MarioActionID.lavaBoost
            actionArgument = 1
            if let wallAngle = input.wallAngle { faceYaw = wallAngle }
            if forwardVelocity < 24 { forwardVelocity = 24 }
            if !input.metalCap {
                hurtCounter &+= input.capOnHead ? 12 : 18
            }
            shouldDropHeldObject = true
            sound = .onFire
            shouldPlayOnFireSound = true
        case .none, .grabbedLedge, .grabbedCeiling:
            break
        }

        let shouldParticleFire = !input.terrainIsSnow && !input.metalCap && velocityY > 0
        let shouldPlayMovingLavaBurn = shouldParticleFire && actionState == 0
        let triggerDeathWarp = input.health < 0x100
        if triggerDeathWarp { intent = .deathWarp }

        return SM64MarioBurningLavaActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: actionArgument, animationID: Self.fireLavaAnimation,
            faceYaw: faceYaw, forwardVelocity: forwardVelocity,
            velocity: velocity(forwardVelocity: forwardVelocity,
                               faceYaw: faceYaw, velocityY: velocityY),
            burnTimer: input.burnTimer, health: input.health,
            hurtCounter: hurtCounter, actionState: actionState, sound: sound,
            shouldPlayLandingSound: shouldPlayLandingSound,
            shouldPlayOnFireSound: shouldPlayOnFireSound,
            shouldPlayMovingLavaBurn: shouldPlayMovingLavaBurn,
            shouldQueueRumble: shouldQueueRumble, shouldResetRumble: true,
            shouldDropHeldObject: shouldDropHeldObject,
            shouldParticleFire: shouldParticleFire, shouldSetEyesDead: true,
            shouldReflectBonk: shouldReflectBonk,
            shouldTriggerDeathWarp: triggerDeathWarp
        )
    }

    private static func lavaControl(
        input: SM64MarioBurningLavaActionInput,
        faceYaw: Int16,
        forwardVelocity: Float
    ) -> (Int16, Float) {
        var faceYaw = faceYaw
        var forwardVelocity = forwardVelocity
        if input.input.contains(.nonzeroAnalog) {
            let delta = Int16(
                truncatingIfNeeded: Int32(input.intendedYaw) - Int32(faceYaw)
            )
            let magnitude = input.intendedMagnitude / 32
            forwardVelocity += SM64CanonicalTrig.coss(delta) * magnitude
            faceYaw = Int16(
                truncatingIfNeeded: Int32(faceYaw)
                    + Int32(SM64CanonicalTrig.sins(delta) * magnitude * 1024)
            )
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
