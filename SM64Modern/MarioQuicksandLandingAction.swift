import Foundation

enum SM64MarioQuicksandLandingVariant: UInt8, Equatable, Sendable {
    case light = 0
    case held = 1
}

enum SM64MarioQuicksandLandingIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case freefall = 1
    case endLanding = 2
}

struct SM64MarioQuicksandLandingActionInput: Equatable, Sendable {
    let variant: SM64MarioQuicksandLandingVariant
    let actionTimer: UInt16
    let quicksandDepth: Float
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

struct SM64MarioQuicksandLandingActionResult: Equatable, Sendable {
    let variant: SM64MarioQuicksandLandingVariant
    let intent: SM64MarioQuicksandLandingIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionTimer: UInt16
    let quicksandDepth: Float
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let groundStep: SM64MarioGroundStepResult?
    let animationID: UInt16
    let shouldPlayJumpSound: Bool
}

/// Value counterpart of `quicksand_jump_land_action`, including the light and
/// held-object animation/action variants.
enum SM64MarioQuicksandLandingAction {
    static func update(
        _ input: SM64MarioQuicksandLandingActionInput
    ) -> SM64MarioQuicksandLandingActionResult? {
        guard input.quicksandDepth.isFinite,
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

        var actionTimer = input.actionTimer
        let inJumpAnimation = actionTimer < 6
        actionTimer &+= 1
        var quicksandDepth = input.quicksandDepth
        let animationID: UInt16
        let shouldPlayJumpSound: Bool
        if inJumpAnimation {
            quicksandDepth -= (7 - Float(actionTimer)) * 0.8
            if quicksandDepth < 1 {
                quicksandDepth = 1.1
            }
            animationID = input.variant == .light ? 0x4D : 0x41
            shouldPlayJumpSound = true
        } else {
            if actionTimer >= 13 {
                return SM64MarioQuicksandLandingActionResult(
                    variant: input.variant,
                    intent: .endLanding,
                    action: input.variant == .light
                        ? SM64MarioActionID.jumpLandStop
                        : SM64MarioActionID.holdJumpLandStop,
                    actionArgument: 0,
                    actionTimer: actionTimer,
                    quicksandDepth: quicksandDepth,
                    forwardVelocity: input.forwardVelocity,
                    velocity: input.groundStep.velocity,
                    groundStep: nil,
                    animationID: input.variant == .light ? 0x4E : 0x40,
                    shouldPlayJumpSound: false
                )
            }
            animationID = input.variant == .light ? 0x4E : 0x40
            shouldPlayJumpSound = false
        }

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
                action: input.variant == .light
                    ? SM64MarioActionID.quicksandJumpLand
                    : SM64MarioActionID.holdQuicksandJumpLand
            )
        ) else {
            return nil
        }
        var forwardVelocity = slope.forwardVelocity
        if !slope.floorIsSlope {
            forwardVelocity *= 0.95
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
        let leftGround = groundStep.result == .leftGround
        return SM64MarioQuicksandLandingActionResult(
            variant: input.variant,
            intent: leftGround ? .freefall : .continueGround,
            action: leftGround
                ? (input.variant == .light
                    ? SM64MarioActionID.freefall
                    : SM64MarioActionID.holdFreefall)
                : nil,
            actionArgument: 0,
            actionTimer: actionTimer,
            quicksandDepth: quicksandDepth,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            groundStep: groundStep,
            animationID: animationID,
            shouldPlayJumpSound: shouldPlayJumpSound
        )
    }
}
