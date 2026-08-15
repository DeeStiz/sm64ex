import Foundation

/// The action IDs and transition flags needed by `set_mario_action`. Keeping
/// these as fixed-width values makes the Swift dispatcher independent of the
/// C enum declaration order and preserves the US ROM action wire values.
enum SM64MarioActionID {
    static let idle: UInt32 = 0x0C400201
    static let walking: UInt32 = 0x04000440
    static let holdWalking: UInt32 = 0x00000442
    static let beginSliding: UInt32 = 0x00000050
    static let holdBeginSliding: UInt32 = 0x00000051
    static let buttSlide: UInt32 = 0x00840452
    static let stomachSlide: UInt32 = 0x008C0453
    static let holdButtSlide: UInt32 = 0x00840454
    static let holdStomachSlide: UInt32 = 0x008C0455
    static let inQuicksand: UInt32 = 0x0002020D
    static let startCrouching: UInt32 = 0x0C008221
    static let crouching: UInt32 = 0x0C008220
    static let stopCrouching: UInt32 = 0x0C008222
    static let startCrawling: UInt32 = 0x0C008223
    static let stopCrawling: UInt32 = 0x0C008224
    static let crawling: UInt32 = 0x04008448
    static let holdIdle: UInt32 = 0x08000207
    static let holdHeavyIdle: UInt32 = 0x08000208
    static let shockwaveBounce: UInt32 = 0x00020226
    static let firstPerson: UInt32 = 0x0C000227
    static let freefall: UInt32 = 0x0100088C
    static let airHitWall: UInt32 = 0x000008A7
    static let softBonk: UInt32 = 0x010208B6
    static let hardForwardAirKnockback: UInt32 = 0x010208B2
    static let hardBackwardAirKnockback: UInt32 = 0x010208B3
    static let thrownForward: UInt32 = 0x010208BD
    static let thrownBackward: UInt32 = 0x010208BE
    static let jumpLand: UInt32 = 0x04000470
    static let freefallLand: UInt32 = 0x04000471
    static let doubleJumpLand: UInt32 = 0x04000472
    static let sideFlipLand: UInt32 = 0x04000473
    static let holdJumpLand: UInt32 = 0x00000474
    static let holdFreefallLand: UInt32 = 0x00000475
    static let sideFlipLandStop: UInt32 = 0x0C000233
    static let jumpLandStop: UInt32 = 0x0C000230
    static let doubleJumpLandStop: UInt32 = 0x0C000231
    static let freefallLandStop: UInt32 = 0x0C000232
    static let holdJumpLandStop: UInt32 = 0x08000234
    static let holdFreefallLandStop: UInt32 = 0x08000235
    static let tripleJumpLandStop: UInt32 = 0x0800023A
    static let longJumpLandStop: UInt32 = 0x0800023B
    static let backflipLandStop: UInt32 = 0x0800022F
    static let tripleJumpLand: UInt32 = 0x04000478
    static let longJumpLand: UInt32 = 0x00000479
    static let backflipLand: UInt32 = 0x0400047A
    static let quicksandJumpLand: UInt32 = 0x00000476
    static let holdQuicksandJumpLand: UInt32 = 0x00000477
    static let softBackwardGroundKnockback: UInt32 = 0x00020464
    static let softForwardGroundKnockback: UInt32 = 0x00020465
    static let hardBackwardGroundKnockback: UInt32 = 0x00020460
    static let hardForwardGroundKnockback: UInt32 = 0x00020461
    static let forwardGroundKnockback: UInt32 = 0x00020463
    static let standingAgainstWall: UInt32 = 0x0C400209
    static let braking: UInt32 = 0x04000445
    static let decelerating: UInt32 = 0x0400044A
    static let holdDecelerating: UInt32 = 0x0000044B
    static let finishTurningAround: UInt32 = 0x00000444
    static let brakingStop: UInt32 = 0x0C00023D
    static let backwardGroundKnockback: UInt32 = 0x00020462
    static let groundBonk: UInt32 = 0x00020466
    static let deathExitLand: UInt32 = 0x00020467
    static let forwardAirKnockback: UInt32 = 0x010208B1
    static let backwardAirKnockback: UInt32 = 0x010208B0
    static let standingDeath: UInt32 = 0x00021311
    static let deathOnStomach: UInt32 = 0x00021315
    static let deathOnBack: UInt32 = 0x00021316
    static let ridingShellGround: UInt32 = 0x20810446
    static let ridingShellJump: UInt32 = 0x0281089A
    static let ridingShellFall: UInt32 = 0x0081089B
    static let punching: UInt32 = 0x00800380
    static let movePunching: UInt32 = 0x00800457
    static let crouchSlide: UInt32 = 0x04808459
    static let buttSlideStop: UInt32 = 0x0C00023E
    static let buttSlideAir: UInt32 = 0x0300088E
    static let holdButtSlideStop: UInt32 = 0x0800043F
    static let holdButtSlideAir: UInt32 = 0x010008A2
    static let stomachSlideStop: UInt32 = 0x00000386
    static let divePickingUp: UInt32 = 0x00000385
    static let slideKickSlideStop: UInt32 = 0x08000225
    static let forwardRollout: UInt32 = 0x010008A6
    static let backwardRollout: UInt32 = 0x010008AD
    static let turningAround: UInt32 = 0x00000443
    static let startSleeping: UInt32 = 0x0C400202
    static let panting: UInt32 = 0x0C400205
    static let coughing: UInt32 = 0x0C40020A
    static let shivering: UInt32 = 0x0C40020B
    static let jump: UInt32 = 0x03000880
    static let doubleJump: UInt32 = 0x03000881
    static let tripleJump: UInt32 = 0x01000882
    static let backflip: UInt32 = 0x01000883
    static let steepJump: UInt32 = 0x03000885
    static let wallKickAir: UInt32 = 0x03000886
    static let sideFlip: UInt32 = 0x01000887
    static let waterJump: UInt32 = 0x01000889
    static let dive: UInt32 = 0x0188088A
    static let longJump: UInt32 = 0x03000888
    static let flyingTripleJump: UInt32 = 0x03000894
    static let holdJump: UInt32 = 0x030008A0
    static let holdFreefall: UInt32 = 0x010008A1
    static let holdWaterJump: UInt32 = 0x010008A3
    static let lavaBoost: UInt32 = 0x010208B7
    static let slideKick: UInt32 = 0x018008AA
    static let jumpKick: UInt32 = 0x018008AC
    static let crazyBoxBounce: UInt32 = 0x000008AE
    static let throwing: UInt32 = 0x80000588
    static let heavyThrow: UInt32 = 0x80000589
    static let twirling: UInt32 = 0x108008A4
    static let metalWaterJump: UInt32 = 0x000044F8
    static let fallAfterStarGrab: UInt32 = 0x00001904
    static let emergeFromPipe: UInt32 = 0x00001923
    static let spawnSpinAirborne: UInt32 = 0x00001924
    static let specialExitAirborne: UInt32 = 0x0000192B
    static let specialDeathExit: UInt32 = 0x0000192C
}

struct SM64MarioActionMutation: Equatable, Sendable {
    let requestedAction: UInt32
    let action: UInt32
    let previousAction: UInt32
    let actionArgument: UInt32
    let actionState: UInt16
    let actionTimer: UInt16
    let flags: UInt32
    let velocity: SM64ObjectVector3
    let forwardVelocity: Float
    let faceAngle: SM64ObjectAngles
    let wallKickTimer: UInt8
    let peakHeight: Float
    let droppedHeldObject: Bool
    let droppedRiddenObject: Bool
    let hurtCounter: UInt8
}

extension SM64MarioState {
    private static let defaultFloorClass: Int16 = 0
    private static let verySlipperyFloorClass: Int16 = 0x13

    /// Applies `mario_set_forward_vel`, including the velocity components that
    /// the legacy action code derives from Mario's yaw.
    mutating func setForwardVelocity(_ value: Float) {
        forwardVelocity = value
        let yaw = Int16(truncatingIfNeeded: faceAngle.yaw)
        slideVelocityX = SM64CanonicalTrig.sins(yaw) * value
        slideVelocityZ = SM64CanonicalTrig.coss(yaw) * value
        velocity.x = slideVelocityX
        velocity.z = slideVelocityZ
    }

    private mutating func setRawForwardVelocity(_ value: Float) {
        forwardVelocity = value
    }

    private mutating func setYVelocityBasedOnForwardSpeed(
        initial: Float,
        multiplier: Float
    ) {
        velocity.y = initial + forwardVelocity * multiplier
        if squishTimer != 0 || quicksandDepth > 1 {
            velocity.y *= 0.5
        }
    }

    /// Value counterpart of `set_mario_action`. `floorClass` and
    /// `facingDownhill` are supplied by the terrain/action caller because the
    /// C implementation reads area/floor pointers at this boundary.
    @discardableResult
    mutating func setAction(
        _ requestedAction: UInt32,
        argument: UInt32 = 0,
        floorClass: Int16 = SM64MarioState.defaultFloorClass,
        facingDownhill: Bool = false
    ) -> SM64MarioActionMutation {
        var action = requestedAction

        switch requestedAction & SM64MarioActionBits.groupMask {
        case SM64MarioActionBits.movingGroup:
            let magnitude = min(intendedMagnitude, 8)
            if requestedAction == SM64MarioActionID.walking {
                if floorClass != Self.verySlipperyFloorClass
                    && forwardVelocity >= 0 && forwardVelocity < magnitude {
                    setRawForwardVelocity(magnitude)
                }
            } else if requestedAction == SM64MarioActionID.holdWalking {
                if forwardVelocity >= 0 && forwardVelocity < magnitude / 2 {
                    setRawForwardVelocity(magnitude / 2)
                }
            } else if requestedAction == SM64MarioActionID.beginSliding {
                action = facingDownhill
                    ? SM64MarioActionID.buttSlide
                    : SM64MarioActionID.stomachSlide
            } else if requestedAction == SM64MarioActionID.holdBeginSliding {
                action = facingDownhill
                    ? SM64MarioActionID.holdButtSlide
                    : SM64MarioActionID.holdStomachSlide
            }

        case SM64MarioActionBits.airborneGroup:
            if (squishTimer != 0 || quicksandDepth >= 1)
                && (requestedAction == SM64MarioActionID.doubleJump
                    || requestedAction == SM64MarioActionID.twirling) {
                action = SM64MarioActionID.jump
            }

            switch action {
            case SM64MarioActionID.doubleJump:
                setYVelocityBasedOnForwardSpeed(initial: 52, multiplier: 0.25)
                setRawForwardVelocity(forwardVelocity * 0.8)
            case SM64MarioActionID.backflip:
                setRawForwardVelocity(-16)
                setYVelocityBasedOnForwardSpeed(initial: 62, multiplier: 0)
            case SM64MarioActionID.tripleJump:
                setYVelocityBasedOnForwardSpeed(initial: 69, multiplier: 0)
                setRawForwardVelocity(forwardVelocity * 0.8)
            case SM64MarioActionID.flyingTripleJump:
                setYVelocityBasedOnForwardSpeed(initial: 82, multiplier: 0)
            case SM64MarioActionID.waterJump, SM64MarioActionID.holdWaterJump:
                if argument == 0 { setYVelocityBasedOnForwardSpeed(initial: 42, multiplier: 0) }
            case SM64MarioActionID.jump, SM64MarioActionID.holdJump:
                setYVelocityBasedOnForwardSpeed(initial: 42, multiplier: 0.25)
                setRawForwardVelocity(forwardVelocity * 0.8)
            case SM64MarioActionID.wallKickAir:
                setYVelocityBasedOnForwardSpeed(initial: 62, multiplier: 0)
                if forwardVelocity < 24 { setRawForwardVelocity(24) }
                wallKickTimer = 0
            case SM64MarioActionID.sideFlip:
                setYVelocityBasedOnForwardSpeed(initial: 62, multiplier: 0)
                setRawForwardVelocity(8)
                faceAngle.yaw = Int32(intendedYaw)
            case SM64MarioActionID.steepJump:
                setYVelocityBasedOnForwardSpeed(initial: 42, multiplier: 0.25)
                faceAngle.pitch = -0x2000
            case SM64MarioActionID.lavaBoost:
                velocity.y = 84
                if argument == 0 { setRawForwardVelocity(0) }
            case SM64MarioActionID.dive:
                setForwardVelocity(min(forwardVelocity + 15, 48))
            case SM64MarioActionID.longJump:
                setYVelocityBasedOnForwardSpeed(initial: 30, multiplier: 0)
                setRawForwardVelocity(min(forwardVelocity * 1.5, 48))
            case SM64MarioActionID.slideKick:
                velocity.y = 12
                if forwardVelocity < 32 { setRawForwardVelocity(32) }
            case SM64MarioActionID.jumpKick:
                velocity.y = 20
            default:
                break
            }
            peakHeight = position.y
            flags |= SM64MarioActionBits.unknown08

        case SM64MarioActionBits.submergedGroup:
            if action == SM64MarioActionID.metalWaterJump {
                velocity.y = 32
            }

        case SM64MarioActionBits.cutsceneGroup:
            switch action {
            case SM64MarioActionID.emergeFromPipe:
                velocity.y = 52
            case SM64MarioActionID.fallAfterStarGrab:
                setForwardVelocity(0)
            case SM64MarioActionID.spawnSpinAirborne:
                setForwardVelocity(2)
            case SM64MarioActionID.specialExitAirborne, SM64MarioActionID.specialDeathExit:
                velocity.y = 64
            default:
                break
            }

        default:
            break
        }

        let oldAction = self.action
        flags &= ~(SM64MarioActionBits.actionSoundPlayed | SM64MarioActionBits.marioSoundPlayed)
        if oldAction & SM64MarioActionBits.air == 0 {
            flags &= ~SM64MarioActionBits.unknown18
        }
        previousAction = oldAction
        self.action = action
        actionArgument = argument
        actionState = 0
        actionTimer = 0

        return SM64MarioActionMutation(
            requestedAction: requestedAction,
            action: action,
            previousAction: previousAction,
            actionArgument: actionArgument,
            actionState: actionState,
            actionTimer: actionTimer,
            flags: flags,
            velocity: velocity,
            forwardVelocity: forwardVelocity,
            faceAngle: faceAngle,
            wallKickTimer: wallKickTimer,
            peakHeight: peakHeight,
            droppedHeldObject: false,
            droppedRiddenObject: false,
            hurtCounter: hurtCounter
        )
    }

    @discardableResult
    mutating func dropAndSetAction(
        _ action: UInt32,
        argument: UInt32 = 0,
        floorClass: Int16 = SM64MarioState.defaultFloorClass,
        facingDownhill: Bool = false
    ) -> SM64MarioActionMutation {
        let hadHeldObject = heldObjectID != nil
        let hadRiddenObject = riddenObjectID != nil
        heldObjectID = nil
        riddenObjectID = nil
        let mutation = setAction(
            action,
            argument: argument,
            floorClass: floorClass,
            facingDownhill: facingDownhill
        )
        return SM64MarioActionMutation(
            requestedAction: mutation.requestedAction,
            action: mutation.action,
            previousAction: mutation.previousAction,
            actionArgument: mutation.actionArgument,
            actionState: mutation.actionState,
            actionTimer: mutation.actionTimer,
            flags: mutation.flags,
            velocity: mutation.velocity,
            forwardVelocity: mutation.forwardVelocity,
            faceAngle: mutation.faceAngle,
            wallKickTimer: mutation.wallKickTimer,
            peakHeight: mutation.peakHeight,
            droppedHeldObject: hadHeldObject,
            droppedRiddenObject: hadRiddenObject,
            hurtCounter: mutation.hurtCounter
        )
    }

    @discardableResult
    mutating func hurtAndSetAction(
        _ action: UInt32,
        argument: UInt32 = 0,
        hurtCounter: UInt8,
        floorClass: Int16 = SM64MarioState.defaultFloorClass,
        facingDownhill: Bool = false
    ) -> SM64MarioActionMutation {
        self.hurtCounter = hurtCounter
        return setAction(
            action,
            argument: argument,
            floorClass: floorClass,
            facingDownhill: facingDownhill
        )
    }
}
