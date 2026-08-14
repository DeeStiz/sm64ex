import Foundation

enum SM64MarioSlideBody: UInt8, Equatable, Sendable {
    case butt = 0
    case stomach = 1
}

enum SM64MarioSlideIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case jump = 1
    case rollout = 2
    case stopped = 3
    case freefall = 4
    case groundBonk = 5
}

struct SM64MarioSlideActionInput: Equatable, Sendable {
    let body: SM64MarioSlideBody
    let input: SM64MarioInputFlags
    let actionTimer: UInt16
    let floorClass: SM64MarioFloorClass
    let floorIsSlope: Bool
    let floorIsSlippery: Bool
    let floorNormalX: Float
    let floorNormalY: Float
    let floorNormalZ: Float
    let intendedYaw: Int16
    let intendedMagnitude: Float
    let faceYaw: Int16
    let slideYaw: Int16
    let forwardVelocity: Float
    let slideVelocityX: Float
    let slideVelocityZ: Float
    let groundStep: SM64MarioGroundStepInput
    let wall: SM64MarioGroundWallProbe?
}

struct SM64MarioSlideActionResult: Equatable, Sendable {
    let body: SM64MarioSlideBody
    let intent: SM64MarioSlideIntent
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
}

/// Value counterpart of the common butt/stomach slide action bodies. Sound,
/// rumble, body tilt, floor alignment, and action mutation are returned as
/// explicit intents for owner-thread application.
enum SM64MarioSlideAction {
    private static let buttAnimation: UInt16 = 0x91
    private static let stomachAnimation: UInt16 = 0x89

    static func update(
        _ input: SM64MarioSlideActionInput
    ) -> SM64MarioSlideActionResult? {
        guard input.intendedMagnitude.isFinite,
              input.floorNormalX.isFinite,
              input.floorNormalY.isFinite,
              input.floorNormalZ.isFinite,
              input.forwardVelocity.isFinite,
              input.slideVelocityX.isFinite,
              input.slideVelocityZ.isFinite else {
            return nil
        }

        var actionTimer = input.actionTimer
        if actionTimer == 5 {
            if input.body == .butt {
                if input.input.contains(.aPressed) {
                    return early(.jump, action: SM64MarioActionID.jump, input: input, actionTimer: actionTimer)
                }
            } else if !input.input.contains(.aboveSlide),
                      input.input.contains(.aPressed) || input.input.contains(.bPressed) {
                let action = input.forwardVelocity >= 0
                    ? SM64MarioActionID.forwardRollout
                    : SM64MarioActionID.backwardRollout
                return early(.rollout, action: action, input: input, actionTimer: actionTimer)
            }
        } else {
            actionTimer &+= 1
        }

        guard let sliding = SM64MarioSliding.update(
            SM64MarioSlidingInput(
                floorClass: input.floorClass,
                floorIsSlope: input.floorIsSlope,
                floorNormalX: input.floorNormalX,
                floorNormalY: input.floorNormalY,
                floorNormalZ: input.floorNormalZ,
                intendedYaw: input.intendedYaw,
                intendedMagnitude: input.intendedMagnitude,
                faceYaw: input.faceYaw,
                slideYaw: input.slideYaw,
                forwardVelocity: input.forwardVelocity,
                slideVelocityX: input.slideVelocityX,
                slideVelocityZ: input.slideVelocityZ,
                stopSpeed: 4
            )
        ) else {
            return nil
        }

        let stopAction = input.body == .butt
            ? SM64MarioActionID.buttSlideStop
            : SM64MarioActionID.stomachSlideStop
        let airAction = input.body == .butt
            ? SM64MarioActionID.buttSlideAir
            : SM64MarioActionID.freefall
        let animation = input.body == .butt ? buttAnimation : stomachAnimation

        if sliding.stopped {
            return result(
                body: input.body, intent: .stopped, action: stopAction,
                actionTimer: actionTimer, input: input, slide: sliding,
                groundStep: nil, animationID: nil, particleDust: false,
                verticalStar: false, reflectedBonk: false,
                shouldAlignWithFloor: false, highSpeedHoohoo: false
            )
        }

        let stepInput = SM64MarioGroundStepInput(
            position: input.groundStep.position,
            velocity: sliding.velocity,
            floor: input.groundStep.floor,
            faceYaw: Int32(sliding.faceYaw),
            nativeStepScale: input.groundStep.nativeStepScale,
            ridingShell: input.groundStep.ridingShell,
            terrainSoundAddend: input.groundStep.terrainSoundAddend,
            quarterProbes: input.groundStep.quarterProbes
        )
        guard let groundStep = SM64MarioGroundStep.update(stepInput) else {
            return nil
        }

        switch groundStep.result {
        case .leftGround:
            return result(
                body: input.body, intent: .freefall, action: airAction,
                actionTimer: actionTimer, input: input, slide: sliding,
                groundStep: groundStep, animationID: nil, particleDust: false,
                verticalStar: false, reflectedBonk: false,
                shouldAlignWithFloor: false,
                highSpeedHoohoo: abs(sliding.forwardVelocity) > 50
            )

        case .none:
            return result(
                body: input.body, intent: .continueGround, action: nil,
                actionTimer: actionTimer, input: input, slide: sliding,
                groundStep: groundStep, animationID: animation, particleDust: true,
                verticalStar: false, reflectedBonk: false,
                shouldAlignWithFloor: true, highSpeedHoohoo: false
            )

        case .hitWall, .hitWallContinueQuarterSteps:
            if !input.floorIsSlippery {
                if sliding.forwardVelocity > 16 {
                    return result(
                        body: input.body, intent: .groundBonk,
                        action: SM64MarioActionID.groundBonk,
                        actionTimer: actionTimer, input: input, slide: sliding,
                        groundStep: groundStep, animationID: nil, particleDust: false,
                        verticalStar: true, reflectedBonk: true,
                        shouldAlignWithFloor: true, highSpeedHoohoo: false
                    )
                }
                var stopped = sliding
                stopped = SM64MarioSlidingResult(
                    stopped: true, faceYaw: stopped.faceYaw, slideYaw: stopped.slideYaw,
                    forwardVelocity: 0, slideVelocityX: 0, slideVelocityZ: 0,
                    velocity: SM64ObjectVector3(x: 0, y: stopped.velocity.y, z: 0),
                    shouldUpdateMovingSand: stopped.shouldUpdateMovingSand,
                    shouldUpdateWindyGround: stopped.shouldUpdateWindyGround
                )
                return result(
                    body: input.body, intent: .stopped, action: stopAction,
                    actionTimer: actionTimer, input: input, slide: stopped,
                    groundStep: groundStep, animationID: nil, particleDust: false,
                    verticalStar: false, reflectedBonk: false,
                    shouldAlignWithFloor: true, highSpeedHoohoo: false
                )
            }

            guard let wall = input.wall else {
                return result(
                    body: input.body, intent: .continueGround, action: nil,
                    actionTimer: actionTimer, input: input, slide: sliding,
                    groundStep: groundStep, animationID: animation, particleDust: false,
                    verticalStar: false, reflectedBonk: false,
                    shouldAlignWithFloor: true, highSpeedHoohoo: false
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
                x: slideSpeed * SM64CanonicalTrig.sins(wallSlideYaw),
                y: 0,
                z: slideSpeed * SM64CanonicalTrig.coss(wallSlideYaw)
            )
            let wallSlide = SM64MarioSlidingResult(
                stopped: false, faceYaw: sliding.faceYaw, slideYaw: wallSlideYaw,
                forwardVelocity: sliding.forwardVelocity,
                slideVelocityX: wallVelocity.x, slideVelocityZ: wallVelocity.z,
                velocity: wallVelocity,
                shouldUpdateMovingSand: sliding.shouldUpdateMovingSand,
                shouldUpdateWindyGround: sliding.shouldUpdateWindyGround
            )
            return result(
                body: input.body, intent: .continueGround, action: nil,
                actionTimer: actionTimer, input: input, slide: wallSlide,
                groundStep: groundStep, animationID: animation, particleDust: false,
                verticalStar: false, reflectedBonk: false,
                shouldAlignWithFloor: true, highSpeedHoohoo: false
            )
        }
    }

    private static func early(
        _ intent: SM64MarioSlideIntent,
        action: UInt32,
        input: SM64MarioSlideActionInput,
        actionTimer: UInt16
    ) -> SM64MarioSlideActionResult {
        SM64MarioSlideActionResult(
            body: input.body, intent: intent, action: action, actionArgument: 0,
            actionTimer: actionTimer, faceYaw: input.faceYaw, slideYaw: input.slideYaw,
            forwardVelocity: input.forwardVelocity,
            slideVelocityX: input.slideVelocityX, slideVelocityZ: input.slideVelocityZ,
            velocity: input.groundStep.velocity, sliding: nil, groundStep: nil,
            animationID: nil, particleDust: false, verticalStar: false,
            reflectedBonk: false, shouldAlignWithFloor: false,
            shouldTiltBody: input.body == .butt, highSpeedHoohoo: false
        )
    }

    private static func result(
        body: SM64MarioSlideBody,
        intent: SM64MarioSlideIntent,
        action: UInt32?,
        actionTimer: UInt16,
        input: SM64MarioSlideActionInput,
        slide: SM64MarioSlidingResult,
        groundStep: SM64MarioGroundStepResult?,
        animationID: UInt16?,
        particleDust: Bool,
        verticalStar: Bool,
        reflectedBonk: Bool,
        shouldAlignWithFloor: Bool,
        highSpeedHoohoo: Bool
    ) -> SM64MarioSlideActionResult {
        SM64MarioSlideActionResult(
            body: body, intent: intent, action: action, actionArgument: 0,
            actionTimer: actionTimer, faceYaw: slide.faceYaw,
            slideYaw: slide.slideYaw, forwardVelocity: slide.forwardVelocity,
            slideVelocityX: slide.slideVelocityX, slideVelocityZ: slide.slideVelocityZ,
            velocity: slide.velocity, sliding: slide, groundStep: groundStep,
            animationID: animationID, particleDust: particleDust,
            verticalStar: verticalStar, reflectedBonk: reflectedBonk,
            shouldAlignWithFloor: shouldAlignWithFloor,
            shouldTiltBody: body == .butt, highSpeedHoohoo: highSpeedHoohoo
        )
    }
}
