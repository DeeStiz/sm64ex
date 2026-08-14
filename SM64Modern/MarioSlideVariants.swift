import Foundation

/// The moving-action slide bodies that sit beside the common butt/stomach
/// slide boundary. These are deliberately value inputs: interaction status,
/// animation state, and collision probes are sampled by the owner thread and
/// effects are returned for application after the pure action decision.
enum SM64MarioSlideVariant: UInt8, Equatable, Sendable {
    case holdButt = 0
    case holdStomach = 1
    case crouch = 2
    case slideKick = 3
    case dive = 4
}

enum SM64MarioSlideVariantIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case dropToButtSlide = 1
    case dropToStomachSlide = 2
    case jump = 3
    case longJump = 4
    case slideKick = 5
    case movePunching = 6
    case braking = 7
    case rollout = 8
    case stop = 9
    case freefall = 10
    case backwardGroundKnockback = 11
    case grabbedObject = 12
}

struct SM64MarioSlideVariantInput: Equatable, Sendable {
    let variant: SM64MarioSlideVariant
    let slide: SM64MarioSlideActionInput
    let dropInteraction: Bool
    let animationAtEnd: Bool
    let interactObjectGrabbable: Bool
    let landingSoundAlreadyPlayed: Bool
}

struct SM64MarioSlideVariantResult: Equatable, Sendable {
    let variant: SM64MarioSlideVariant
    let intent: SM64MarioSlideVariantIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionTimer: UInt16
    let faceYaw: Int16
    let slideYaw: Int16
    let forwardVelocity: Float
    let slideVelocityX: Float
    let slideVelocityZ: Float
    let velocity: SM64ObjectVector3
    let sliding: SM64MarioSlidingResult?
    let groundStep: SM64MarioGroundStepResult?
    let animationID: UInt16?
    let particleDust: Bool
    let verticalStar: Bool
    let reflectedBonk: Bool
    let shouldAlignWithFloor: Bool
    let shouldTiltBody: Bool
    let highSpeedHoohoo: Bool
    let queueRumble: Bool
    let shouldPlayLandingSound: Bool
    let shouldGrabObject: Bool
    let grabPositionLightObject: Bool
}

/// Value counterpart of `act_hold_butt_slide`, `act_hold_stomach_slide`,
/// `act_crouch_slide`, `act_slide_kick_slide`, and `act_dive_slide`.
///
/// The common-slide helper intentionally keeps the same order as C:
/// timer/exit checks, scalar sliding, four-quarter ground step, wall response,
/// and finally graphics/effect intents. No raw Mario/object pointers cross
/// this boundary.
enum SM64MarioSlideVariants {
    private static let holdButtAnimation: UInt16 = 0x45
    private static let slideKickAnimation: UInt16 = 0x8C
    private static let diveAnimation: UInt16 = 0x88
    private static let crouchAnimation: UInt16 = 0x97

    static func update(
        _ input: SM64MarioSlideVariantInput
    ) -> SM64MarioSlideVariantResult? {
        guard finite(input.slide) else { return nil }

        switch input.variant {
        case .holdButt:
            if input.dropInteraction {
                return early(
                    input, intent: .dropToButtSlide,
                    action: SM64MarioActionID.buttSlide,
                    shouldTiltBody: true
                )
            }
            var timer = input.slide.actionTimer
            if timer == 5 {
                if input.slide.input.contains(.aPressed) {
                    return early(
                        input, intent: .jump,
                        action: SM64MarioActionID.holdJump,
                        shouldTiltBody: true,
                        actionTimer: timer
                    )
                }
            } else {
                timer &+= 1
            }
            return common(
                input, actionTimer: timer, stopAction: SM64MarioActionID.holdButtSlideStop,
                airAction: SM64MarioActionID.holdButtSlideAir,
                animation: Self.holdButtAnimation, stopSpeed: 4,
                shouldTiltBody: true
            )

        case .holdStomach:
            if input.dropInteraction {
                return early(
                    input, intent: .dropToStomachSlide,
                    action: SM64MarioActionID.stomachSlide,
                    shouldTiltBody: false
                )
            }
            return stomach(
                input, stopAction: SM64MarioActionID.divePickingUp,
                airAction: SM64MarioActionID.holdFreefall
            )

        case .crouch:
            if input.slide.input.contains(.aboveSlide) {
                return early(
                    input, intent: .dropToButtSlide,
                    action: SM64MarioActionID.buttSlide,
                    shouldTiltBody: true
                )
            }

            var timer = input.slide.actionTimer
            if timer < 30 {
                timer &+= 1
                if input.slide.input.contains(.aPressed), input.slide.forwardVelocity > 10 {
                    return early(
                        input, intent: .longJump,
                        action: SM64MarioActionID.longJump,
                        shouldTiltBody: false,
                        actionTimer: timer
                    )
                }
            }
            if input.slide.input.contains(.bPressed) {
                if input.slide.forwardVelocity >= 10 {
                    return early(
                        input, intent: .slideKick,
                        action: SM64MarioActionID.slideKick,
                        shouldTiltBody: false,
                        actionTimer: timer
                    )
                }
                return early(
                    input, intent: .movePunching,
                    action: SM64MarioActionID.movePunching,
                    actionArgument: 9,
                    shouldTiltBody: false,
                    actionTimer: timer
                )
            }
            if input.slide.input.contains(.aPressed) {
                return early(
                    input, intent: .jump,
                    action: SM64MarioActionID.jump,
                    shouldTiltBody: false,
                    actionTimer: timer
                )
            }
            if input.slide.input.contains(.firstPerson) {
                return early(
                    input, intent: .braking,
                    action: SM64MarioActionID.braking,
                    shouldTiltBody: false,
                    actionTimer: timer
                )
            }
            return common(
                input, actionTimer: timer, stopAction: SM64MarioActionID.crouching,
                airAction: SM64MarioActionID.freefall,
                animation: Self.crouchAnimation, stopSpeed: 4,
                shouldTiltBody: false
            )

        case .slideKick:
            if input.slide.input.contains(.aPressed) {
                return early(
                    input, intent: .rollout,
                    action: SM64MarioActionID.forwardRollout,
                    shouldTiltBody: false,
                    queueRumble: true
                )
            }
            if input.animationAtEnd, input.slide.forwardVelocity < 1 {
                return early(
                    input, intent: .stop,
                    action: SM64MarioActionID.slideKickSlideStop,
                    shouldTiltBody: false
                )
            }
            guard let sliding = SM64MarioSliding.update(
                SM64MarioSlidingInput(
                    floorClass: input.slide.floorClass,
                    floorIsSlope: input.slide.floorIsSlope,
                    floorNormalX: input.slide.floorNormalX,
                    floorNormalY: input.slide.floorNormalY,
                    floorNormalZ: input.slide.floorNormalZ,
                    intendedYaw: input.slide.intendedYaw,
                    intendedMagnitude: input.slide.intendedMagnitude,
                    faceYaw: input.slide.faceYaw,
                    slideYaw: input.slide.slideYaw,
                    forwardVelocity: input.slide.forwardVelocity,
                    slideVelocityX: input.slide.slideVelocityX,
                    slideVelocityZ: input.slide.slideVelocityZ,
                    stopSpeed: 1
                )
            ), !sliding.stopped else {
                return early(
                    input, intent: .stop,
                    action: SM64MarioActionID.slideKickSlideStop,
                    shouldTiltBody: false
                )
            }
            guard let step = step(input.slide, velocity: sliding.velocity, faceYaw: sliding.faceYaw) else {
                return nil
            }
            switch step.result {
            case .leftGround:
                return result(
                    input, intent: .freefall, action: SM64MarioActionID.freefall,
                    actionArgument: 2, actionTimer: input.slide.actionTimer,
                    sliding: sliding, groundStep: step, animation: Self.slideKickAnimation,
                    particleDust: true, verticalStar: false, reflectedBonk: false,
                    shouldAlignWithFloor: false, shouldTiltBody: false,
                    highSpeedHoohoo: false, queueRumble: false,
                    shouldPlayLandingSound: false, shouldGrabObject: false,
                    grabPositionLightObject: false
                )
            case .hitWall, .hitWallContinueQuarterSteps:
                return result(
                    input, intent: .backwardGroundKnockback,
                    action: SM64MarioActionID.backwardGroundKnockback,
                    actionArgument: 0, actionTimer: input.slide.actionTimer,
                    sliding: sliding, groundStep: step, animation: Self.slideKickAnimation,
                    particleDust: true, verticalStar: true, reflectedBonk: true,
                    shouldAlignWithFloor: false, shouldTiltBody: false,
                    highSpeedHoohoo: false, queueRumble: false,
                    shouldPlayLandingSound: false, shouldGrabObject: false,
                    grabPositionLightObject: false
                )
            case .none:
                return result(
                    input, intent: .continueGround, action: nil,
                    actionArgument: 0, actionTimer: input.slide.actionTimer,
                    sliding: sliding, groundStep: step, animation: Self.slideKickAnimation,
                    particleDust: true, verticalStar: false, reflectedBonk: false,
                    shouldAlignWithFloor: false, shouldTiltBody: false,
                    highSpeedHoohoo: false, queueRumble: false,
                    shouldPlayLandingSound: false, shouldGrabObject: false,
                    grabPositionLightObject: false
                )
            }

        case .dive:
            if !input.slide.input.contains(.aboveSlide),
               input.slide.input.contains(.aPressed) || input.slide.input.contains(.bPressed) {
                return early(
                    input, intent: .rollout,
                    action: input.slide.forwardVelocity > 0
                        ? SM64MarioActionID.forwardRollout
                        : SM64MarioActionID.backwardRollout,
                    shouldTiltBody: false,
                    queueRumble: true
                )
            }

            guard let sliding = SM64MarioSliding.update(
                SM64MarioSlidingInput(
                    floorClass: input.slide.floorClass,
                    floorIsSlope: input.slide.floorIsSlope,
                    floorNormalX: input.slide.floorNormalX,
                    floorNormalY: input.slide.floorNormalY,
                    floorNormalZ: input.slide.floorNormalZ,
                    intendedYaw: input.slide.intendedYaw,
                    intendedMagnitude: input.slide.intendedMagnitude,
                    faceYaw: input.slide.faceYaw,
                    slideYaw: input.slide.slideYaw,
                    forwardVelocity: input.slide.forwardVelocity,
                    slideVelocityX: input.slide.slideVelocityX,
                    slideVelocityZ: input.slide.slideVelocityZ,
                    stopSpeed: 8
                )
            ) else {
                return nil
            }

            var stopped = false
            var forwardVelocity = sliding.forwardVelocity
            var velocity = sliding.velocity
            var action: UInt32?
            var intent: SM64MarioSlideVariantIntent = .continueGround
            if sliding.stopped, input.animationAtEnd {
                stopped = true
                forwardVelocity = 0
                velocity.x = 0
                velocity.z = 0
                action = SM64MarioActionID.stomachSlideStop
                intent = .stop
            }

            let updatedSliding = stopped
                ? SM64MarioSlidingResult(
                    stopped: true, faceYaw: sliding.faceYaw, slideYaw: sliding.slideYaw,
                    forwardVelocity: 0, slideVelocityX: 0, slideVelocityZ: 0,
                    velocity: velocity,
                    shouldUpdateMovingSand: sliding.shouldUpdateMovingSand,
                    shouldUpdateWindyGround: sliding.shouldUpdateWindyGround
                )
                : sliding

            if input.interactObjectGrabbable {
                return result(
                    input, intent: .grabbedObject, action: action,
                    actionArgument: 0, actionTimer: input.slide.actionTimer,
                    sliding: updatedSliding, groundStep: nil, animation: Self.diveAnimation,
                    particleDust: false, verticalStar: false, reflectedBonk: false,
                    shouldAlignWithFloor: false, shouldTiltBody: false,
                    highSpeedHoohoo: false, queueRumble: false,
                    shouldPlayLandingSound: !input.landingSoundAlreadyPlayed,
                    shouldGrabObject: true, grabPositionLightObject: true,
                    overrideForwardVelocity: forwardVelocity,
                    overrideVelocity: velocity
                )
            }

            guard !stopped, let common = common(
                input, actionTimer: input.slide.actionTimer,
                stopAction: SM64MarioActionID.stomachSlideStop,
                airAction: SM64MarioActionID.freefall,
                animation: Self.diveAnimation, stopSpeed: 8,
                shouldTiltBody: false
            ) else {
                if stopped {
                    return result(
                        input, intent: intent, action: action,
                        actionArgument: 0, actionTimer: input.slide.actionTimer,
                        sliding: updatedSliding, groundStep: nil, animation: nil,
                        particleDust: false, verticalStar: false, reflectedBonk: false,
                        shouldAlignWithFloor: false, shouldTiltBody: false,
                        highSpeedHoohoo: false, queueRumble: false,
                        shouldPlayLandingSound: !input.landingSoundAlreadyPlayed,
                        shouldGrabObject: false, grabPositionLightObject: false,
                        overrideForwardVelocity: forwardVelocity,
                        overrideVelocity: velocity
                    )
                }
                return nil
            }
            return SM64MarioSlideVariantResult(
                variant: common.variant, intent: common.intent, action: common.action,
                actionArgument: common.actionArgument, actionTimer: common.actionTimer,
                faceYaw: common.faceYaw, slideYaw: common.slideYaw,
                forwardVelocity: common.forwardVelocity,
                slideVelocityX: common.slideVelocityX, slideVelocityZ: common.slideVelocityZ,
                velocity: common.velocity, sliding: common.sliding,
                groundStep: common.groundStep, animationID: common.animationID,
                particleDust: common.particleDust, verticalStar: common.verticalStar,
                reflectedBonk: common.reflectedBonk,
                shouldAlignWithFloor: common.shouldAlignWithFloor,
                shouldTiltBody: common.shouldTiltBody,
                highSpeedHoohoo: common.highSpeedHoohoo,
                queueRumble: common.queueRumble,
                shouldPlayLandingSound: !input.landingSoundAlreadyPlayed,
                shouldGrabObject: false, grabPositionLightObject: false
            )
        }
    }

    private static func stomach(
        _ input: SM64MarioSlideVariantInput,
        stopAction: UInt32,
        airAction: UInt32
    ) -> SM64MarioSlideVariantResult? {
        var timer = input.slide.actionTimer
        if timer == 5 {
            if !input.slide.input.contains(.aboveSlide),
               input.slide.input.contains(.aPressed) || input.slide.input.contains(.bPressed) {
                return early(
                    input, intent: .rollout,
                    action: input.slide.forwardVelocity >= 0
                        ? SM64MarioActionID.forwardRollout
                        : SM64MarioActionID.backwardRollout,
                    shouldTiltBody: false,
                    actionTimer: timer,
                    queueRumble: true
                )
            }
        } else {
            timer &+= 1
        }
        return common(
            input, actionTimer: timer, stopAction: stopAction,
            airAction: airAction, animation: Self.diveAnimation,
            stopSpeed: 4, shouldTiltBody: false
        )
    }

    private static func common(
        _ input: SM64MarioSlideVariantInput,
        actionTimer: UInt16,
        stopAction: UInt32,
        airAction: UInt32,
        animation: UInt16,
        stopSpeed: Float,
        shouldTiltBody: Bool
    ) -> SM64MarioSlideVariantResult? {
        guard let sliding = SM64MarioSliding.update(
            SM64MarioSlidingInput(
                floorClass: input.slide.floorClass,
                floorIsSlope: input.slide.floorIsSlope,
                floorNormalX: input.slide.floorNormalX,
                floorNormalY: input.slide.floorNormalY,
                floorNormalZ: input.slide.floorNormalZ,
                intendedYaw: input.slide.intendedYaw,
                intendedMagnitude: input.slide.intendedMagnitude,
                faceYaw: input.slide.faceYaw,
                slideYaw: input.slide.slideYaw,
                forwardVelocity: input.slide.forwardVelocity,
                slideVelocityX: input.slide.slideVelocityX,
                slideVelocityZ: input.slide.slideVelocityZ,
                stopSpeed: stopSpeed
            )
        ) else {
            return nil
        }

        if sliding.stopped {
            return result(
                input, intent: .stop, action: stopAction,
                actionArgument: 0, actionTimer: actionTimer, sliding: sliding,
                groundStep: nil, animation: nil, particleDust: false,
                verticalStar: false, reflectedBonk: false,
                shouldAlignWithFloor: false, shouldTiltBody: shouldTiltBody,
                highSpeedHoohoo: false, queueRumble: false,
                shouldPlayLandingSound: false, shouldGrabObject: false,
                grabPositionLightObject: false
            )
        }

        guard let groundStep = step(input.slide, velocity: sliding.velocity, faceYaw: sliding.faceYaw) else {
            return nil
        }
        switch groundStep.result {
        case .leftGround:
            return result(
                input, intent: .freefall, action: airAction,
                actionArgument: 0, actionTimer: actionTimer, sliding: sliding,
                groundStep: groundStep, animation: nil, particleDust: false,
                verticalStar: false, reflectedBonk: false,
                shouldAlignWithFloor: false, shouldTiltBody: shouldTiltBody,
                highSpeedHoohoo: abs(sliding.forwardVelocity) > 50,
                queueRumble: false, shouldPlayLandingSound: false,
                shouldGrabObject: false, grabPositionLightObject: false
            )

        case .none:
            return result(
                input, intent: .continueGround, action: nil,
                actionArgument: 0, actionTimer: actionTimer, sliding: sliding,
                groundStep: groundStep, animation: animation, particleDust: true,
                verticalStar: false, reflectedBonk: false,
                shouldAlignWithFloor: true, shouldTiltBody: shouldTiltBody,
                highSpeedHoohoo: false, queueRumble: false,
                shouldPlayLandingSound: false, shouldGrabObject: false,
                grabPositionLightObject: false
            )

        case .hitWall, .hitWallContinueQuarterSteps:
            if !input.slide.floorIsSlippery {
                if sliding.forwardVelocity > 16 {
                    return result(
                        input, intent: .backwardGroundKnockback,
                        action: SM64MarioActionID.groundBonk,
                        actionArgument: 0, actionTimer: actionTimer, sliding: sliding,
                        groundStep: groundStep, animation: nil, particleDust: false,
                        verticalStar: true, reflectedBonk: true,
                        shouldAlignWithFloor: true, shouldTiltBody: shouldTiltBody,
                        highSpeedHoohoo: false, queueRumble: false,
                        shouldPlayLandingSound: false, shouldGrabObject: false,
                        grabPositionLightObject: false
                    )
                }
                let stopped = SM64MarioSlidingResult(
                    stopped: true, faceYaw: sliding.faceYaw, slideYaw: sliding.slideYaw,
                    forwardVelocity: 0, slideVelocityX: 0, slideVelocityZ: 0,
                    velocity: SM64ObjectVector3(x: 0, y: sliding.velocity.y, z: 0),
                    shouldUpdateMovingSand: sliding.shouldUpdateMovingSand,
                    shouldUpdateWindyGround: sliding.shouldUpdateWindyGround
                )
                return result(
                    input, intent: .stop, action: stopAction,
                    actionArgument: 0, actionTimer: actionTimer, sliding: stopped,
                    groundStep: groundStep, animation: nil, particleDust: false,
                    verticalStar: false, reflectedBonk: false,
                    shouldAlignWithFloor: true, shouldTiltBody: shouldTiltBody,
                    highSpeedHoohoo: false, queueRumble: false,
                    shouldPlayLandingSound: false, shouldGrabObject: false,
                    grabPositionLightObject: false
                )
            }

            guard let wall = input.slide.wall else {
                return result(
                    input, intent: .continueGround, action: nil,
                    actionArgument: 0, actionTimer: actionTimer, sliding: sliding,
                    groundStep: groundStep, animation: animation, particleDust: false,
                    verticalStar: false, reflectedBonk: false,
                    shouldAlignWithFloor: true, shouldTiltBody: shouldTiltBody,
                    highSpeedHoohoo: false, queueRumble: false,
                    shouldPlayLandingSound: false, shouldGrabObject: false,
                    grabPositionLightObject: false
                )
            }
            let wallAngle = SM64CanonicalTrig.atan2s(y: wall.normalZ, x: wall.normalX)
            var slideSpeed = sqrt(sliding.slideVelocityX * sliding.slideVelocityX
                + sliding.slideVelocityZ * sliding.slideVelocityZ) * 0.9
            if slideSpeed < 4 { slideSpeed = 4 }
            let wallSlideYaw = Int16(
                truncatingIfNeeded: Int32(wallAngle)
                    - Int32(Int16(truncatingIfNeeded: Int32(sliding.slideYaw) - Int32(wallAngle)))
                    + 0x8000
            )
            let wallVelocity = SM64ObjectVector3(
                x: slideSpeed * SM64CanonicalTrig.sins(wallSlideYaw), y: 0,
                z: slideSpeed * SM64CanonicalTrig.coss(wallSlideYaw)
            )
            let redirected = SM64MarioSlidingResult(
                stopped: false, faceYaw: sliding.faceYaw, slideYaw: wallSlideYaw,
                forwardVelocity: sliding.forwardVelocity,
                slideVelocityX: wallVelocity.x, slideVelocityZ: wallVelocity.z,
                velocity: wallVelocity,
                shouldUpdateMovingSand: sliding.shouldUpdateMovingSand,
                shouldUpdateWindyGround: sliding.shouldUpdateWindyGround
            )
            return result(
                input, intent: .continueGround, action: nil,
                actionArgument: 0, actionTimer: actionTimer, sliding: redirected,
                groundStep: groundStep, animation: animation, particleDust: false,
                verticalStar: false, reflectedBonk: false,
                shouldAlignWithFloor: true, shouldTiltBody: shouldTiltBody,
                highSpeedHoohoo: false, queueRumble: false,
                shouldPlayLandingSound: false, shouldGrabObject: false,
                grabPositionLightObject: false
            )
        }
    }

    private static func step(
        _ input: SM64MarioSlideActionInput,
        velocity: SM64ObjectVector3,
        faceYaw: Int16
    ) -> SM64MarioGroundStepResult? {
        SM64MarioGroundStep.update(
            SM64MarioGroundStepInput(
                position: input.groundStep.position,
                velocity: velocity,
                floor: input.groundStep.floor,
                faceYaw: Int32(faceYaw),
                nativeStepScale: input.groundStep.nativeStepScale,
                ridingShell: input.groundStep.ridingShell,
                terrainSoundAddend: input.groundStep.terrainSoundAddend,
                quarterProbes: input.groundStep.quarterProbes
            )
        )
    }

    private static func finite(_ input: SM64MarioSlideActionInput) -> Bool {
        input.intendedMagnitude.isFinite
            && input.floorNormalX.isFinite && input.floorNormalY.isFinite
            && input.floorNormalZ.isFinite && input.forwardVelocity.isFinite
            && input.slideVelocityX.isFinite && input.slideVelocityZ.isFinite
            && input.groundStep.position.x.isFinite
            && input.groundStep.position.y.isFinite
            && input.groundStep.position.z.isFinite
            && input.groundStep.velocity.x.isFinite
            && input.groundStep.velocity.y.isFinite
            && input.groundStep.velocity.z.isFinite
    }

    private static func early(
        _ input: SM64MarioSlideVariantInput,
        intent: SM64MarioSlideVariantIntent,
        action: UInt32,
        actionArgument: UInt32 = 0,
        shouldTiltBody: Bool,
        actionTimer: UInt16? = nil,
        queueRumble: Bool = false
    ) -> SM64MarioSlideVariantResult {
        SM64MarioSlideVariantResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: actionArgument, actionTimer: actionTimer ?? input.slide.actionTimer,
            faceYaw: input.slide.faceYaw, slideYaw: input.slide.slideYaw,
            forwardVelocity: input.slide.forwardVelocity,
            slideVelocityX: input.slide.slideVelocityX,
            slideVelocityZ: input.slide.slideVelocityZ,
            velocity: input.slide.groundStep.velocity, sliding: nil, groundStep: nil,
            animationID: nil, particleDust: false, verticalStar: false,
            reflectedBonk: false, shouldAlignWithFloor: false,
            shouldTiltBody: shouldTiltBody, highSpeedHoohoo: false,
            queueRumble: queueRumble, shouldPlayLandingSound: false,
            shouldGrabObject: false, grabPositionLightObject: false
        )
    }

    private static func result(
        _ input: SM64MarioSlideVariantInput,
        intent: SM64MarioSlideVariantIntent,
        action: UInt32?,
        actionArgument: UInt32,
        actionTimer: UInt16,
        sliding: SM64MarioSlidingResult,
        groundStep: SM64MarioGroundStepResult?,
        animation: UInt16?,
        particleDust: Bool,
        verticalStar: Bool,
        reflectedBonk: Bool,
        shouldAlignWithFloor: Bool,
        shouldTiltBody: Bool,
        highSpeedHoohoo: Bool,
        queueRumble: Bool,
        shouldPlayLandingSound: Bool,
        shouldGrabObject: Bool,
        grabPositionLightObject: Bool,
        overrideForwardVelocity: Float? = nil,
        overrideVelocity: SM64ObjectVector3? = nil
    ) -> SM64MarioSlideVariantResult {
        SM64MarioSlideVariantResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: actionArgument, actionTimer: actionTimer,
            faceYaw: sliding.faceYaw, slideYaw: sliding.slideYaw,
            forwardVelocity: overrideForwardVelocity ?? sliding.forwardVelocity,
            slideVelocityX: sliding.slideVelocityX,
            slideVelocityZ: sliding.slideVelocityZ,
            velocity: overrideVelocity ?? sliding.velocity,
            sliding: sliding, groundStep: groundStep, animationID: animation,
            particleDust: particleDust, verticalStar: verticalStar,
            reflectedBonk: reflectedBonk, shouldAlignWithFloor: shouldAlignWithFloor,
            shouldTiltBody: shouldTiltBody, highSpeedHoohoo: highSpeedHoohoo,
            queueRumble: queueRumble, shouldPlayLandingSound: shouldPlayLandingSound,
            shouldGrabObject: shouldGrabObject,
            grabPositionLightObject: grabPositionLightObject
        )
    }
}
