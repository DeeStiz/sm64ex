import Foundation

enum SM64MarioLandingVariant: UInt8, Equatable, Hashable, Sendable {
    case jump = 0
    case freefall = 1
    case sideFlip = 2
    case holdJump = 3
    case holdFreefall = 4
    case longJump = 5
    case doubleJump = 6
    case tripleJump = 7
    case backflip = 8
}

enum SM64MarioLandingIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case verySteep = 1
    case beginSliding = 2
    case firstPersonEnd = 3
    case animationEnd = 4
    case aPressed = 5
    case offFloor = 6
    case dropHeldObject = 7
    case freefall = 8
}

struct SM64MarioLandingActionInput: Equatable, Sendable {
    let variant: SM64MarioLandingVariant
    let input: SM64MarioInputFlags
    let actionTimer: UInt16
    let doubleJumpTimer: UInt8
    let quicksandDepth: Float
    let heldObjectPresent: Bool
    let dropInteraction: Bool
    let floorIsSteep: Bool
    let floorNormalY: Float
    let floorClass: SM64MarioFloorClass
    let terrainIsSlide: Bool
    let facingDownhill: Bool
    let floorIsQuicksand: Bool
    let longJumpIsSlow: Bool
    let wingCap: Bool
    let squishTimer: UInt8
    let previousAction: UInt32
    let forwardVelocity: Float
    let faceYaw: Int16
    let floorNormalX: Float
    let floorNormalZ: Float
    let floorAngle: Int16
    let groundStep: SM64MarioGroundStepInput
}

struct SM64MarioLandingActionResult: Equatable, Sendable {
    let variant: SM64MarioLandingVariant
    let intent: SM64MarioLandingIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionTimer: UInt16
    let doubleJumpTimer: UInt8
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let groundStep: SM64MarioGroundStepResult?
    let animationID: UInt16?
    let particleDust: Bool
    let shouldPlayLandingSound: Bool
    let shouldClearAPressed: Bool
    let shouldDropHeldObject: Bool
    let shouldFlipSideFlipYaw: Bool
    let quicksandDepth: Float
}

/// Value counterpart of `common_landing_action`, `common_landing_cancels`,
/// and the standard landing variants. It keeps action transitions, timer
/// mutation, landing acceleration, ground-step outcomes, and presentation
/// effects explicit for the owner thread.
enum SM64MarioLandingAction {
    private struct Descriptor {
        let numFrames: UInt16
        let doubleJumpTimer: UInt8
        let verySteepAction: UInt32
        let endAction: UInt32
        let aPressedAction: UInt32
        let offFloorAction: UInt32
        let slideAction: UInt32
        let airAction: UInt32
        let animationID: UInt16
    }

    static func update(
        _ input: SM64MarioLandingActionInput
    ) -> SM64MarioLandingActionResult? {
        guard input.quicksandDepth.isFinite,
              input.floorNormalY.isFinite,
              input.floorNormalX.isFinite,
              input.floorNormalZ.isFinite,
              input.forwardVelocity.isFinite,
              input.groundStep.position.x.isFinite,
              input.groundStep.position.y.isFinite,
              input.groundStep.position.z.isFinite,
              input.groundStep.velocity.x.isFinite,
              input.groundStep.velocity.y.isFinite,
              input.groundStep.velocity.z.isFinite else {
            return nil
        }

        let descriptor = descriptor(for: input)
        let clearA = input.variant == .tripleJump
            || ((input.variant == .longJump || input.variant == .backflip)
                && !input.input.contains(.zDown))
        let aPressed = input.input.contains(.aPressed) && !clearA

        if (input.variant == .holdJump || input.variant == .holdFreefall),
           input.dropInteraction {
            return cancel(
                input: input, descriptor: descriptor,
                intent: .dropHeldObject,
                action: input.variant == .holdJump
                    ? SM64MarioActionID.jumpLandStop
                    : SM64MarioActionID.freefallLandStop,
                actionTimer: input.actionTimer,
                doubleJumpTimer: input.doubleJumpTimer,
                clearA: clearA,
                drop: true
            )
        }

        if input.floorNormalY < 0.2923717 {
            return cancel(
                input: input, descriptor: descriptor, intent: .verySteep,
                action: descriptor.verySteepAction, actionTimer: input.actionTimer,
                doubleJumpTimer: descriptor.doubleJumpTimer,
                clearA: clearA, drop: false
            )
        }

        var actionTimer = input.actionTimer
        let doubleJumpTimer = descriptor.doubleJumpTimer

        if input.input.contains(.aboveSlide),
           input.terrainIsSlide || input.forwardVelocity <= -1 || input.facingDownhill {
            return cancel(
                input: input, descriptor: descriptor, intent: .beginSliding,
                action: descriptor.slideAction, actionTimer: actionTimer,
                doubleJumpTimer: doubleJumpTimer, clearA: clearA, drop: false
            )
        }

        if input.input.contains(.firstPerson) {
            return cancel(
                input: input, descriptor: descriptor, intent: .firstPersonEnd,
                action: descriptor.endAction, actionTimer: actionTimer,
                doubleJumpTimer: doubleJumpTimer, clearA: clearA, drop: false
            )
        }

        actionTimer &+= 1
        if actionTimer >= descriptor.numFrames {
            return cancel(
                input: input, descriptor: descriptor, intent: .animationEnd,
                action: descriptor.endAction, actionTimer: actionTimer,
                doubleJumpTimer: doubleJumpTimer, clearA: clearA, drop: false
            )
        }

        if aPressed {
            let selection: (action: UInt32, drop: Bool)
            if input.variant == .doubleJump {
                let action: UInt32
                if input.wingCap {
                    action = SM64MarioActionID.flyingTripleJump
                } else if input.forwardVelocity > 20 {
                    action = SM64MarioActionID.tripleJump
                } else {
                    action = SM64MarioActionID.jump
                }
                selection = (action, false)
            } else {
                selection = jumpingAction(
                    requested: descriptor.aPressedAction,
                    input: input
                )
            }
            return cancel(
                input: input, descriptor: descriptor, intent: .aPressed,
                action: selection.action, actionTimer: actionTimer,
                doubleJumpTimer: doubleJumpTimer, clearA: clearA,
                drop: selection.drop
            )
        }

        if input.input.contains(.offFloor) {
            return cancel(
                input: input, descriptor: descriptor, intent: .offFloor,
                action: descriptor.offFloorAction, actionTimer: actionTimer,
                doubleJumpTimer: doubleJumpTimer, clearA: clearA, drop: false
            )
        }

        var forwardVelocity = input.forwardVelocity
        var velocity: SM64ObjectVector3
        if input.input.contains(.nonzeroAnalog) {
            guard let slope = SM64MarioSlope.update(
                SM64MarioSlopeInput(
                    floorClass: input.floorClass,
                    terrainIsSlide: input.terrainIsSlide,
                    floorNormalX: input.floorNormalX,
                    floorNormalY: input.floorNormalY,
                    floorNormalZ: input.floorNormalZ,
                    floorAngle: input.floorAngle,
                    faceYaw: input.faceYaw,
                    forwardVelocity: forwardVelocity,
                    action: currentAction(for: input.variant)
                )
            ) else { return nil }
            forwardVelocity = slope.forwardVelocity
            if !slope.floorIsSlope {
                forwardVelocity *= 0.98
                if forwardVelocity * forwardVelocity < 1 { forwardVelocity = 0 }
            }
            velocity = SM64ObjectVector3(
                x: SM64CanonicalTrig.sins(input.faceYaw) * forwardVelocity,
                y: slope.velocity.y,
                z: SM64CanonicalTrig.coss(input.faceYaw) * forwardVelocity
            )
        } else if forwardVelocity >= 16 {
            guard let deceleration = SM64MarioSlopeDeceleration.update(
                SM64MarioSlopeDecelerationInput(
                    coefficient: 2,
                    floorClass: input.floorClass,
                    terrainIsSlide: input.terrainIsSlide,
                    floorNormalX: input.floorNormalX,
                    floorNormalY: input.floorNormalY,
                    floorNormalZ: input.floorNormalZ,
                    floorAngle: input.floorAngle,
                    faceYaw: input.faceYaw,
                    forwardVelocity: forwardVelocity,
                    action: currentAction(for: input.variant)
                )
            ) else { return nil }
            forwardVelocity = deceleration.forwardVelocity
            velocity = deceleration.slope.velocity
        } else {
            velocity = SM64ObjectVector3(
                x: input.groundStep.velocity.x,
                y: 0,
                z: input.groundStep.velocity.z
            )
        }

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
        ) else { return nil }

        var quicksandDepth = input.quicksandDepth
        if input.floorIsQuicksand {
            quicksandDepth += (4 - Float(actionTimer)) * 3.5 - 0.5
        }
        let leftGround = groundStep.result == .leftGround
        let hitWall = groundStep.result == .hitWall
            || groundStep.result == .hitWallContinueQuarterSteps
        return SM64MarioLandingActionResult(
            variant: input.variant,
            intent: leftGround ? .freefall : .continueGround,
            action: leftGround ? descriptor.airAction : nil,
            actionArgument: 0,
            actionTimer: actionTimer,
            doubleJumpTimer: doubleJumpTimer,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            groundStep: groundStep,
            animationID: descriptor.animationID,
            particleDust: forwardVelocity > 16,
            shouldPlayLandingSound: true,
            shouldClearAPressed: clearA,
            shouldDropHeldObject: false,
            shouldFlipSideFlipYaw: input.variant == .sideFlip && !hitWall,
            quicksandDepth: quicksandDepth
        )
    }

    private static func descriptor(
        for input: SM64MarioLandingActionInput
    ) -> Descriptor {
        switch input.variant {
        case .jump:
            return Descriptor(
                numFrames: 4, doubleJumpTimer: 5,
                verySteepAction: SM64MarioActionID.freefall,
                endAction: SM64MarioActionID.jumpLandStop,
                aPressedAction: SM64MarioActionID.doubleJump,
                offFloorAction: SM64MarioActionID.freefall,
                slideAction: SM64MarioActionID.beginSliding,
                airAction: SM64MarioActionID.freefall, animationID: 0x4E
            )
        case .freefall:
            return Descriptor(
                numFrames: 4, doubleJumpTimer: 5,
                verySteepAction: SM64MarioActionID.freefall,
                endAction: SM64MarioActionID.freefallLandStop,
                aPressedAction: SM64MarioActionID.doubleJump,
                offFloorAction: SM64MarioActionID.freefall,
                slideAction: SM64MarioActionID.beginSliding,
                airAction: SM64MarioActionID.freefall, animationID: 0x57
            )
        case .sideFlip:
            return Descriptor(
                numFrames: 4, doubleJumpTimer: 5,
                verySteepAction: SM64MarioActionID.freefall,
                endAction: SM64MarioActionID.sideFlipLandStop,
                aPressedAction: SM64MarioActionID.doubleJump,
                offFloorAction: SM64MarioActionID.freefall,
                slideAction: SM64MarioActionID.beginSliding,
                airAction: SM64MarioActionID.freefall, animationID: 0xBE
            )
        case .holdJump:
            return Descriptor(
                numFrames: 4, doubleJumpTimer: 5,
                verySteepAction: SM64MarioActionID.holdFreefall,
                endAction: SM64MarioActionID.holdJumpLandStop,
                aPressedAction: SM64MarioActionID.holdJump,
                offFloorAction: SM64MarioActionID.holdFreefall,
                slideAction: SM64MarioActionID.holdBeginSliding,
                airAction: SM64MarioActionID.holdFreefall, animationID: 0x40
            )
        case .holdFreefall:
            return Descriptor(
                numFrames: 4, doubleJumpTimer: 5,
                verySteepAction: SM64MarioActionID.holdFreefall,
                endAction: SM64MarioActionID.holdFreefallLandStop,
                aPressedAction: SM64MarioActionID.holdJump,
                offFloorAction: SM64MarioActionID.holdFreefall,
                slideAction: SM64MarioActionID.holdBeginSliding,
                airAction: SM64MarioActionID.holdFreefall, animationID: 0x42
            )
        case .longJump:
            return Descriptor(
                numFrames: 6, doubleJumpTimer: 5,
                verySteepAction: SM64MarioActionID.freefall,
                endAction: SM64MarioActionID.longJumpLandStop,
                aPressedAction: SM64MarioActionID.longJump,
                offFloorAction: SM64MarioActionID.freefall,
                slideAction: SM64MarioActionID.beginSliding,
                airAction: SM64MarioActionID.freefall,
                animationID: input.longJumpIsSlow ? 0x12 : 0x11
            )
        case .doubleJump:
            return Descriptor(
                numFrames: 4, doubleJumpTimer: 5,
                verySteepAction: SM64MarioActionID.freefall,
                endAction: SM64MarioActionID.doubleJumpLandStop,
                aPressedAction: SM64MarioActionID.jump,
                offFloorAction: SM64MarioActionID.freefall,
                slideAction: SM64MarioActionID.beginSliding,
                airAction: SM64MarioActionID.freefall, animationID: 0x4B
            )
        case .tripleJump:
            return Descriptor(
                numFrames: 4, doubleJumpTimer: 0,
                verySteepAction: SM64MarioActionID.freefall,
                endAction: SM64MarioActionID.tripleJumpLandStop,
                aPressedAction: 0,
                offFloorAction: SM64MarioActionID.freefall,
                slideAction: SM64MarioActionID.beginSliding,
                airAction: SM64MarioActionID.freefall, animationID: 0xC0
            )
        case .backflip:
            return Descriptor(
                numFrames: 4, doubleJumpTimer: 0,
                verySteepAction: SM64MarioActionID.freefall,
                endAction: SM64MarioActionID.backflipLandStop,
                aPressedAction: SM64MarioActionID.backflip,
                offFloorAction: SM64MarioActionID.freefall,
                slideAction: SM64MarioActionID.beginSliding,
                airAction: SM64MarioActionID.freefall, animationID: 0xC0
            )
        }
    }

    private static func jumpingAction(
        requested: UInt32,
        input: SM64MarioLandingActionInput
    ) -> (action: UInt32, drop: Bool) {
        if input.quicksandDepth >= 11 {
            return (
                input.heldObjectPresent
                    ? SM64MarioActionID.holdQuicksandJumpLand
                    : SM64MarioActionID.quicksandJumpLand,
                false
            )
        }
        if input.floorIsSteep {
            return (SM64MarioActionID.steepJump, true)
        }
        return (requested, false)
    }

    private static func currentAction(for variant: SM64MarioLandingVariant) -> UInt32 {
        switch variant {
        case .jump: return SM64MarioActionID.jumpLand
        case .freefall: return SM64MarioActionID.freefallLand
        case .sideFlip: return SM64MarioActionID.sideFlipLand
        case .holdJump: return SM64MarioActionID.holdJumpLand
        case .holdFreefall: return SM64MarioActionID.holdFreefallLand
        case .longJump: return SM64MarioActionID.longJumpLand
        case .doubleJump: return SM64MarioActionID.doubleJumpLand
        case .tripleJump: return SM64MarioActionID.tripleJumpLand
        case .backflip: return SM64MarioActionID.backflipLand
        }
    }

    private static func cancel(
        input: SM64MarioLandingActionInput,
        descriptor: Descriptor,
        intent: SM64MarioLandingIntent,
        action: UInt32,
        actionTimer: UInt16,
        doubleJumpTimer: UInt8,
        clearA: Bool,
        drop: Bool
    ) -> SM64MarioLandingActionResult {
        SM64MarioLandingActionResult(
            variant: input.variant,
            intent: intent,
            action: action,
            actionArgument: 0,
            actionTimer: actionTimer,
            doubleJumpTimer: doubleJumpTimer,
            forwardVelocity: input.forwardVelocity,
            velocity: input.groundStep.velocity,
            groundStep: nil,
            animationID: nil,
            particleDust: false,
            shouldPlayLandingSound: false,
            shouldClearAPressed: clearA,
            shouldDropHeldObject: drop,
            shouldFlipSideFlipYaw: false,
            quicksandDepth: input.quicksandDepth
        )
    }
}
