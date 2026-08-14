import Foundation

enum SM64MarioHeldWalkingVariant: UInt8, Equatable, Sendable {
    case light = 0
    case heavy = 1
    case decelerating = 2
}

enum SM64MarioHeldWalkingIntent: UInt8, Equatable, Sendable {
    case continueGround = 0
    case crazyBoxBounce = 1
    case walking = 2
    case beginSliding = 3
    case throwing = 4
    case heavyThrow = 5
    case jump = 6
    case decelerating = 7
    case holdHeavyIdle = 8
    case crouchSlide = 9
    case holdFreefall = 10
    case holdIdle = 11
    case holdWalking = 12
}

struct SM64MarioHeldWalkingActionInput: Equatable, Sendable {
    let variant: SM64MarioHeldWalkingVariant
    let input: SM64MarioInputFlags
    let terrainIsSlide: Bool
    let facingDownhill: Bool
    let dropInteraction: Bool
    let jumpingBox: Bool
    let intendedMagnitude: Float
    let intendedYaw: Int16
    let faceYaw: Int16
    let forwardVelocity: Float
    let quicksandDepth: Float
    let floorNormalY: Float
    let floorIsSlow: Bool
    let floorClass: SM64MarioFloorClass
    let responsiveCheat: Bool
    let cheatsEnabled: Bool
    let actionTimer: UInt16
    let animationPastFrame1: Bool
    let animationPastFrame2: Bool
    let velocityY: Float
    let groundStep: SM64MarioGroundStepInput
}

struct SM64MarioHeldWalkingAnimation: Equatable, Sendable {
    let animationID: UInt16
    let acceleration: Int32
    let actionTimer: UInt16
    let soundFrame0: Int16
    let soundFrame1: Int16
}

struct SM64MarioHeldWalkingActionResult: Equatable, Sendable {
    let variant: SM64MarioHeldWalkingVariant
    let intent: SM64MarioHeldWalkingIntent
    let action: UInt32?
    let actionArgument: UInt32
    let faceYaw: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let actionTimer: UInt16
    let groundStep: SM64MarioGroundStepResult?
    let animation: SM64MarioHeldWalkingAnimation?
    let particleDust: Bool
    let reflectedBonk: Bool
    let shouldDropHeldObject: Bool
    let shouldPlayStepSound: Bool
}

/// Value counterpart of the held moving/decelerating action family. The
/// owner thread supplies object/interaction facts and applies the returned
/// action, animation, collision, and effect intents after this pure decision.
enum SM64MarioHeldWalkingAction {
    private static let slowWalkWithLightObject: UInt16 = 0x18
    private static let walkWithLightObject: UInt16 = 0x16
    private static let runWithLightObject: UInt16 = 0x17
    private static let walkWithHeavyObject: UInt16 = 0xBB
    private static let idleWithLightObject: UInt16 = 0x3F

    static func update(
        _ input: SM64MarioHeldWalkingActionInput
    ) -> SM64MarioHeldWalkingActionResult? {
        guard finite(input) else { return nil }

        switch input.variant {
        case .light:
            if input.jumpingBox {
                return early(input, intent: .crazyBoxBounce, action: SM64MarioActionID.crazyBoxBounce)
            }
            if input.dropInteraction {
                return early(
                    input, intent: .walking, action: SM64MarioActionID.walking,
                    shouldDropHeldObject: true
                )
            }
            if beginsSliding(input) {
                return early(input, intent: .beginSliding, action: SM64MarioActionID.holdBeginSliding)
            }
            if input.input.contains(.bPressed) {
                return early(input, intent: .throwing, action: SM64MarioActionID.throwing)
            }
            if input.input.contains(.aPressed) {
                return early(input, intent: .jump, action: SM64MarioActionID.holdJump)
            }
            if input.input.contains(.unknown5) {
                return early(input, intent: .decelerating, action: SM64MarioActionID.holdDecelerating)
            }
            if input.input.contains(.zPressed) {
                return early(
                    input, intent: .crouchSlide, action: SM64MarioActionID.crouchSlide,
                    shouldDropHeldObject: true
                )
            }
            return ground(
                input, magnitudeScale: 0.4, wallCap: 16,
                intent: .continueGround, leftAction: SM64MarioActionID.holdFreefall,
                animation: holdWalkAnimation(input), dustThreshold: 10,
                dustMagnitudeScale: 0.4, shouldDropOnFreefall: false
            )

        case .heavy:
            if input.input.contains(.bPressed) {
                return early(input, intent: .heavyThrow, action: SM64MarioActionID.heavyThrow)
            }
            if beginsSliding(input) {
                return early(
                    input, intent: .beginSliding, action: SM64MarioActionID.beginSliding,
                    shouldDropHeldObject: true
                )
            }
            if input.input.contains(.unknown5) {
                return early(input, intent: .holdHeavyIdle, action: SM64MarioActionID.holdHeavyIdle)
            }
            return ground(
                input, magnitudeScale: 0.1, wallCap: 10,
                intent: .continueGround, leftAction: SM64MarioActionID.freefall,
                animation: heavyWalkAnimation(input), dustThreshold: nil,
                dustMagnitudeScale: 0, shouldDropOnFreefall: true
            )

        case .decelerating:
            if input.dropInteraction {
                return early(
                    input, intent: .walking, action: SM64MarioActionID.walking,
                    shouldDropHeldObject: true
                )
            }
            if beginsSliding(input) {
                return early(input, intent: .beginSliding, action: SM64MarioActionID.holdBeginSliding)
            }
            if input.input.contains(.bPressed) {
                return early(input, intent: .throwing, action: SM64MarioActionID.throwing)
            }
            if input.input.contains(.aPressed) {
                return early(input, intent: .jump, action: SM64MarioActionID.holdJump)
            }
            if input.input.contains(.zPressed) {
                return early(
                    input, intent: .crouchSlide, action: SM64MarioActionID.crouchSlide,
                    shouldDropHeldObject: true
                )
            }
            if input.input.contains(.nonzeroAnalog) {
                return early(input, intent: .holdWalking, action: SM64MarioActionID.holdWalking)
            }
            return decelerate(input)
        }
    }

    private static func ground(
        _ input: SM64MarioHeldWalkingActionInput,
        magnitudeScale: Float,
        wallCap: Float,
        intent: SM64MarioHeldWalkingIntent,
        leftAction: UInt32,
        animation: SM64MarioHeldWalkingAnimation,
        dustThreshold: Float?,
        dustMagnitudeScale: Float,
        shouldDropOnFreefall: Bool
    ) -> SM64MarioHeldWalkingActionResult? {
        let magnitude = input.intendedMagnitude * magnitudeScale
        guard let speed = SM64MarioGroundSpeed.update(
            SM64MarioGroundSpeedInput(
                intendedMagnitude: magnitude,
                forwardVelocity: input.forwardVelocity,
                quicksandDepth: input.quicksandDepth,
                floorNormalY: input.floorNormalY,
                intendedYaw: Int32(input.intendedYaw),
                faceYaw: Int32(input.faceYaw),
                floorIsSlow: input.floorIsSlow,
                responsiveCheat: input.responsiveCheat,
                cheatsEnabled: input.cheatsEnabled
            )
        ) else {
            return nil
        }

        let faceYaw = speed.faceYaw
        var forwardVelocity = speed.forwardVelocity
        var velocity = SM64ObjectVector3(
            x: SM64CanonicalTrig.sins(faceYaw) * forwardVelocity,
            y: input.groundStep.velocity.y,
            z: SM64CanonicalTrig.coss(faceYaw) * forwardVelocity
        )
        guard let groundStep = SM64MarioGroundStep.update(
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
        ) else {
            return nil
        }

        var action: UInt32?
        var resultIntent = intent
        var shouldDrop = false
        let reflected = false
        switch groundStep.result {
        case .leftGround:
            action = leftAction
            shouldDrop = shouldDropOnFreefall
        case .hitWall, .hitWallContinueQuarterSteps:
            if forwardVelocity > wallCap {
                forwardVelocity = wallCap
                velocity = SM64ObjectVector3(
                    x: SM64CanonicalTrig.sins(faceYaw) * forwardVelocity,
                    y: velocity.y,
                    z: SM64CanonicalTrig.coss(faceYaw) * forwardVelocity
                )
            }
        case .none:
            break
        }

        let dust: Bool
        if let threshold = dustThreshold {
            dust = input.intendedMagnitude * dustMagnitudeScale - forwardVelocity > threshold
        } else {
            dust = false
        }
        if groundStep.result == .leftGround {
            resultIntent = intent
        }
        return SM64MarioHeldWalkingActionResult(
            variant: input.variant, intent: resultIntent, action: action,
            actionArgument: 0, faceYaw: faceYaw, forwardVelocity: forwardVelocity,
            velocity: velocity, actionTimer: animation.actionTimer,
            groundStep: groundStep, animation: animation,
            particleDust: dust, reflectedBonk: reflected,
            shouldDropHeldObject: shouldDrop, shouldPlayStepSound: true
        )
    }

    private static func decelerate(
        _ input: SM64MarioHeldWalkingActionInput
    ) -> SM64MarioHeldWalkingActionResult? {
        guard let speed = SM64MarioDeceleratingSpeed.update(
            SM64MarioDeceleratingSpeedInput(
                forwardVelocity: input.forwardVelocity,
                faceYaw: input.faceYaw,
                velocityY: input.velocityY
            )
        ) else { return nil }

        if speed.stopped {
            return SM64MarioHeldWalkingActionResult(
                variant: input.variant, intent: .holdIdle, action: SM64MarioActionID.holdIdle,
                actionArgument: 0, faceYaw: input.faceYaw,
                forwardVelocity: 0, velocity: speed.velocity,
                actionTimer: input.actionTimer, groundStep: nil,
                animation: nil, particleDust: false, reflectedBonk: false,
                shouldDropHeldObject: false, shouldPlayStepSound: false
            )
        }

        let animationAcceleration = max(
            Int32((speed.forwardVelocity * 65_536).rounded(.towardZero)), 0x1000
        )
        var velocity = speed.velocity
        var forwardVelocity = speed.forwardVelocity
        var faceYaw = input.faceYaw
        var reflected = false
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

        if groundStep.result == .hitWall || groundStep.result == .hitWallContinueQuarterSteps {
            if input.floorClass == .verySlippery,
               let wall = input.groundStep.quarterProbes.compactMap(\.upperWall).first {
                let wallAngle = SM64CanonicalTrig.atan2s(y: wall.normalZ, x: wall.normalX)
                faceYaw = Int16(
                    truncatingIfNeeded: Int32(wallAngle)
                        - Int32(Int16(truncatingIfNeeded: Int32(input.faceYaw) - Int32(wallAngle)))
                )
                forwardVelocity = -speed.forwardVelocity
                velocity = SM64ObjectVector3(
                    x: SM64CanonicalTrig.sins(faceYaw) * forwardVelocity,
                    y: speed.velocity.y,
                    z: SM64CanonicalTrig.coss(faceYaw) * forwardVelocity
                )
                reflected = true
            } else {
                forwardVelocity = 0
                velocity = SM64ObjectVector3(x: 0, y: speed.velocity.y, z: 0)
            }
        }

        let animation: SM64MarioHeldWalkingAnimation
        if input.floorClass == .verySlippery {
            animation = SM64MarioHeldWalkingAnimation(
                animationID: Self.idleWithLightObject, acceleration: 0,
                actionTimer: input.actionTimer, soundFrame0: 0, soundFrame1: 0
            )
        } else {
            animation = SM64MarioHeldWalkingAnimation(
                animationID: Self.walkWithLightObject,
                acceleration: animationAcceleration,
                actionTimer: input.actionTimer,
                soundFrame0: 12, soundFrame1: 62
            )
        }
        return SM64MarioHeldWalkingActionResult(
            variant: input.variant, intent: .continueGround, action: nil,
            actionArgument: 0, faceYaw: faceYaw, forwardVelocity: forwardVelocity,
            velocity: velocity, actionTimer: input.actionTimer,
            groundStep: groundStep, animation: animation,
            particleDust: input.floorClass == .verySlippery,
            reflectedBonk: reflected, shouldDropHeldObject: false,
            shouldPlayStepSound: true
        )
    }

    private static func holdWalkAnimation(
        _ input: SM64MarioHeldWalkingActionInput
    ) -> SM64MarioHeldWalkingAnimation {
        var speed = max(input.intendedMagnitude * 0.4, input.forwardVelocity)
        if speed < 2 { speed = 2 }
        var timer = input.actionTimer
        while true {
            switch timer {
            case 0:
                if speed > 6 { timer = 1; continue }
                return animation(Self.slowWalkWithLightObject, speed, timer, 12, 62)
            case 1:
                if speed < 3 { timer = 0; continue }
                if speed > 11 { timer = 2; continue }
                return animation(Self.walkWithLightObject, speed, timer, 12, 62)
            case 2:
                if speed < 8 { timer = 1; continue }
                return animation(Self.runWithLightObject, speed / 2, timer, 10, 49)
            default:
                return animation(Self.slowWalkWithLightObject, speed, 0, 12, 62)
            }
        }
    }

    private static func heavyWalkAnimation(
        _ input: SM64MarioHeldWalkingActionInput
    ) -> SM64MarioHeldWalkingAnimation {
        animation(
            Self.walkWithHeavyObject,
            input.intendedMagnitude * 0.1,
            input.actionTimer, 26, 79
        )
    }

    private static func animation(
        _ id: UInt16,
        _ speed: Float,
        _ timer: UInt16,
        _ frame0: Int16,
        _ frame1: Int16
    ) -> SM64MarioHeldWalkingAnimation {
        let raw = Double(speed) * 65_536
        let acceleration: Int32
        if raw >= Double(Int32.max) {
            acceleration = Int32.max
        } else if raw <= Double(Int32.min) {
            acceleration = Int32.min
        } else {
            acceleration = Int32(raw)
        }
        return SM64MarioHeldWalkingAnimation(
            animationID: id, acceleration: acceleration,
            actionTimer: timer, soundFrame0: frame0, soundFrame1: frame1
        )
    }

    private static func beginsSliding(
        _ input: SM64MarioHeldWalkingActionInput
    ) -> Bool {
        input.input.contains(.aboveSlide)
            && (input.terrainIsSlide || input.forwardVelocity <= -1 || input.facingDownhill)
    }

    private static func finite(
        _ input: SM64MarioHeldWalkingActionInput
    ) -> Bool {
        input.intendedMagnitude.isFinite && input.forwardVelocity.isFinite
            && input.quicksandDepth.isFinite && input.floorNormalY.isFinite
            && input.velocityY.isFinite
            && input.groundStep.position.x.isFinite
            && input.groundStep.position.y.isFinite
            && input.groundStep.position.z.isFinite
            && input.groundStep.velocity.x.isFinite
            && input.groundStep.velocity.y.isFinite
            && input.groundStep.velocity.z.isFinite
    }

    private static func early(
        _ input: SM64MarioHeldWalkingActionInput,
        intent: SM64MarioHeldWalkingIntent,
        action: UInt32,
        shouldDropHeldObject: Bool = false
    ) -> SM64MarioHeldWalkingActionResult {
        SM64MarioHeldWalkingActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: 0, faceYaw: input.faceYaw,
            forwardVelocity: input.forwardVelocity,
            velocity: input.groundStep.velocity,
            actionTimer: input.actionTimer, groundStep: nil,
            animation: nil, particleDust: false, reflectedBonk: false,
            shouldDropHeldObject: shouldDropHeldObject,
            shouldPlayStepSound: false
        )
    }
}
