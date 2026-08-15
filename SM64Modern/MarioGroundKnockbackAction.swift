import Foundation

enum SM64MarioGroundKnockbackVariant: UInt8, Equatable, Hashable, Sendable {
    case hardBackward = 0
    case hardForward = 1
    case backward = 2
    case forward = 3
    case softBackward = 4
    case softForward = 5
    case groundBonk = 6
}

enum SM64MarioGroundKnockbackIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case forwardAirKnockback = 1
    case backwardAirKnockback = 2
    case standingDeath = 3
    case idle = 4
    case deathOnBack = 5
    case deathOnStomach = 6
}

/// Bitmask of sound/effect requests emitted by the common ground-knockback
/// body. The owner thread applies the requests through its normal sound flags.
struct SM64MarioGroundKnockbackSound: OptionSet, Equatable, Sendable {
    let rawValue: UInt8

    static let heavyLanding = Self(rawValue: 1 << 0)
    static let attacked = Self(rawValue: 1 << 1)
    static let ooof = Self(rawValue: 1 << 2)
    static let landing = Self(rawValue: 1 << 3)
    static let mamaMia = Self(rawValue: 1 << 4)
}

struct SM64MarioGroundKnockbackActionInput: Equatable, Sendable {
    let variant: SM64MarioGroundKnockbackVariant
    let actionArgument: UInt32
    let animationFrame: Int16
    let animationAtEnd: Bool
    let previousAction: UInt32
    let health: UInt16
    let floorClass: SM64MarioFloorClass
    let terrainIsSlide: Bool
    let floorNormalX: Float
    let floorNormalY: Float
    let floorNormalZ: Float
    let floorAngle: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let groundStep: SM64MarioGroundStepInput
}

struct SM64MarioGroundKnockbackActionResult: Equatable, Sendable {
    let variant: SM64MarioGroundKnockbackVariant
    let intent: SM64MarioGroundKnockbackIntent
    let action: UInt32?
    let actionArgument: UInt32
    let animationID: UInt16
    let animationFrame: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let groundStep: SM64MarioGroundStepResult?
    let invincibilityTimer: UInt8
    let soundFlags: SM64MarioGroundKnockbackSound
}

/// Value counterpart of `common_ground_knockback_action` and the seven
/// grounded knockback actions. Animation, sound flags, invincibility, and
/// action transitions are returned as effects for the owner thread.
enum SM64MarioGroundKnockbackAction {
    private static let animationByVariant: [SM64MarioGroundKnockbackVariant: UInt16] = [
        .hardBackward: 0x01, // MARIO_ANIM_FALL_OVER_BACKWARDS
        .hardForward: 0x2C, // MARIO_ANIM_LAND_ON_STOMACH
        .backward: 0x7B, // MARIO_ANIM_BACKWARD_KB
        .forward: 0x7C, // MARIO_ANIM_FORWARD_KB
        .softBackward: 0x74, // MARIO_ANIM_SOFT_BACK_KB
        .softForward: 0x75, // MARIO_ANIM_SOFT_FRONT_KB
        .groundBonk: 0x8A // MARIO_ANIM_GROUND_BONK
    ]

    private static let thresholdByVariant: [SM64MarioGroundKnockbackVariant: Int16] = [
        .hardBackward: 0x2B,
        .hardForward: 0x15,
        .backward: 0x16,
        .forward: 0x14,
        .softBackward: 0x64,
        .softForward: 0x64,
        .groundBonk: 0x20
    ]

    private static let heavyLandingVariants: Set<SM64MarioGroundKnockbackVariant> = [
        .hardBackward, .hardForward, .backward, .forward, .groundBonk
    ]

    static func update(
        _ input: SM64MarioGroundKnockbackActionInput
    ) -> SM64MarioGroundKnockbackActionResult? {
        guard input.animationFrame >= -1,
              input.forwardVelocity.isFinite,
              input.floorNormalX.isFinite,
              input.floorNormalY.isFinite,
              input.floorNormalZ.isFinite,
              input.groundStep.position.x.isFinite,
              input.groundStep.position.y.isFinite,
              input.groundStep.position.z.isFinite,
              input.groundStep.velocity.x.isFinite,
              input.groundStep.velocity.y.isFinite,
              input.groundStep.velocity.z.isFinite else {
            return nil
        }

        let animationID = Self.animationByVariant[input.variant]!
        let threshold = Self.thresholdByVariant[input.variant]!
        var soundFlags: SM64MarioGroundKnockbackSound = []
        if Self.heavyLandingVariants.contains(input.variant) {
            soundFlags.insert(.heavyLanding)
        }
        soundFlags.insert(input.actionArgument > 0 ? .attacked : .ooof)

        guard let slope = SM64MarioSlope.update(
            SM64MarioSlopeInput(
                floorClass: input.floorClass,
                terrainIsSlide: input.terrainIsSlide,
                floorNormalX: input.floorNormalX,
                floorNormalY: input.floorNormalY,
                floorNormalZ: input.floorNormalZ,
                floorAngle: input.floorAngle,
                faceYaw: input.faceYaw,
                forwardVelocity: input.forwardVelocity,
                action: action(for: input.variant)
            )
        ) else {
            return nil
        }

        var forwardVelocity = slope.forwardVelocity
        if !slope.floorIsSlope {
            forwardVelocity *= 0.9
            if forwardVelocity * forwardVelocity < 1 {
                forwardVelocity = 0
            }
        }

        let velocity = SM64ObjectVector3(
            x: SM64CanonicalTrig.sins(input.faceYaw) * forwardVelocity,
            y: slope.velocity.y,
            z: SM64CanonicalTrig.coss(input.faceYaw) * forwardVelocity
        )
        guard let groundStep = SM64MarioGroundStep.update(
            SM64MarioGroundStepInput(
                position: input.groundStep.position,
                velocity: velocity,
                floor: input.groundStep.floor,
                faceYaw: Int32(input.faceYaw),
                nativeStepScale: input.groundStep.nativeStepScale,
                ridingShell: input.groundStep.ridingShell,
                terrainSoundAddend: input.groundStep.terrainSoundAddend,
                quarterProbes: input.groundStep.quarterProbes
            )
        ) else {
            return nil
        }

        var result = SM64MarioGroundKnockbackActionResult(
            variant: input.variant,
            intent: .continueGround,
            action: nil,
            actionArgument: 0,
            animationID: animationID,
            animationFrame: input.animationFrame,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            groundStep: groundStep,
            invincibilityTimer: 0,
            soundFlags: soundFlags
        )

        if groundStep.result == .leftGround {
            let forward = forwardVelocity >= 0
            result = result.with(
                intent: forward ? .forwardAirKnockback : .backwardAirKnockback,
                action: forward
                    ? SM64MarioActionID.forwardAirKnockback
                    : SM64MarioActionID.backwardAirKnockback,
                actionArgument: input.actionArgument
            )
        } else if input.animationAtEnd {
            result = result.with(
                intent: input.health < 0x100 ? .standingDeath : .idle,
                action: input.health < 0x100
                    ? SM64MarioActionID.standingDeath
                    : SM64MarioActionID.idle,
                actionArgument: 0,
                invincibilityTimer: input.health >= 0x100 && input.actionArgument > 0 ? 30 : 0
            )
        }

        if input.variant == .hardBackward,
           input.animationFrame == threshold,
           input.health < 0x100 {
            result = result.with(
                intent: .deathOnBack,
                action: SM64MarioActionID.deathOnBack,
                actionArgument: 0
            )
        } else if input.variant == .hardForward,
                  input.animationFrame == threshold,
                  input.health < 0x100 {
            result = result.with(
                intent: .deathOnStomach,
                action: SM64MarioActionID.deathOnStomach,
                actionArgument: 0
            )
        }

        if input.variant == .hardBackward,
           input.animationFrame == 0x36,
           input.previousAction == SM64MarioActionID.specialDeathExit {
            var sounds = result.soundFlags
            sounds.insert(.mamaMia)
            result = result.with(soundFlags: sounds)
        }
        if input.variant == .hardBackward, input.animationFrame == 0x45 {
            var sounds = result.soundFlags
            sounds.insert(.landing)
            result = result.with(soundFlags: sounds)
        }
        if input.variant == .groundBonk, input.animationFrame == threshold {
            var sounds = result.soundFlags
            sounds.insert(.landing)
            result = result.with(soundFlags: sounds)
        }

        return result
    }

    private static func action(for variant: SM64MarioGroundKnockbackVariant) -> UInt32 {
        switch variant {
        case .hardBackward: return SM64MarioActionID.hardBackwardGroundKnockback
        case .hardForward: return SM64MarioActionID.hardForwardGroundKnockback
        case .backward: return SM64MarioActionID.backwardGroundKnockback
        case .forward: return SM64MarioActionID.forwardGroundKnockback
        case .softBackward: return SM64MarioActionID.softBackwardGroundKnockback
        case .softForward: return SM64MarioActionID.softForwardGroundKnockback
        case .groundBonk: return SM64MarioActionID.groundBonk
        }
    }
}

private extension SM64MarioGroundKnockbackActionResult {
    func with(soundFlags: SM64MarioGroundKnockbackSound) -> Self {
        Self(
            variant: variant,
            intent: intent,
            action: action,
            actionArgument: actionArgument,
            animationID: animationID,
            animationFrame: animationFrame,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            groundStep: groundStep,
            invincibilityTimer: invincibilityTimer,
            soundFlags: soundFlags
        )
    }

    func with(
        intent: SM64MarioGroundKnockbackIntent,
        action: UInt32?,
        actionArgument: UInt32,
        invincibilityTimer: UInt8? = nil,
        soundFlags: SM64MarioGroundKnockbackSound? = nil
    ) -> Self {
        Self(
            variant: variant,
            intent: intent,
            action: action,
            actionArgument: actionArgument,
            animationID: animationID,
            animationFrame: animationFrame,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            groundStep: groundStep,
            invincibilityTimer: invincibilityTimer ?? self.invincibilityTimer,
            soundFlags: soundFlags ?? self.soundFlags
        )
    }
}
