import Foundation

enum SM64MarioSwimmingVariant: UInt8, Equatable, Sendable {
    case breaststroke = 0
    case swimmingEnd = 1
    case flutterKick = 2
    case holdBreaststroke = 3
    case holdSwimmingEnd = 4
    case holdFlutterKick = 5
}

enum SM64MarioWaterStepOutcome: UInt8, Equatable, Sendable {
    case none = 0
    case hitFloor = 1
    case hitCeiling = 2
    case hitWall = 3
    case cancelled = 4
}

enum SM64MarioSwimmingIntent: UInt8, Equatable, Sendable {
    case continueSwimming = 0
    case metalWaterFall = 1
    case waterPunch = 2
    case waterThrow = 3
    case waterJump = 4
    case holdWaterJump = 5
    case flutterKick = 6
    case holdFlutterKick = 7
    case waterActionEnd = 8
    case holdWaterActionEnd = 9
    case swimmingEnd = 10
    case holdSwimmingEnd = 11
    case holdWaterIdle = 12
    case breaststroke = 13
    case holdBreaststroke = 14
}

struct SM64MarioSwimmingActionInput: Equatable, Sendable {
    let variant: SM64MarioSwimmingVariant
    let input: SM64MarioInputFlags
    let actionArgument: UInt32
    let actionTimer: UInt16
    let actionState: UInt8
    let swimStrength: Int16
    let stickX: Float
    let stickY: Float
    let faceYaw: Int16
    let facePitch: Int16
    let faceRoll: Int16
    let angleVelocityY: Int16
    let forwardVelocity: Float
    let buoyancy: Float
    let floorPitch: Int16?
    let waterStep: SM64MarioWaterStepOutcome
    let metalCap: Bool
    let dropObjectRequested: Bool
    let waterJumpReady: Bool
}

struct SM64MarioSwimmingActionResult: Equatable, Sendable {
    let variant: SM64MarioSwimmingVariant
    let intent: SM64MarioSwimmingIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionTimer: UInt16
    let actionState: UInt8
    let swimStrength: Int16
    let animationID: UInt16
    let faceYaw: Int16
    let facePitch: Int16
    let faceRoll: Int16
    let angleVelocityY: Int16
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let shouldDropHeldObject: Bool
    let shouldPlaySwimmingSound: Bool
    let shouldPlayFastSwimmingSound: Bool
    let shouldPlaySwimmingNoise: Bool
    let shouldResetFloatGlobals: Bool
    let shouldPlayWaterStep: Bool
}

/// Value counterpart of the shared submerged swimming step and its six
/// breaststroke/swimming-end/flutter-kick callers. Water collision/current,
/// object interaction, animation/audio installation, and surface particles
/// remain explicit owner-thread effects.
enum SM64MarioSwimmingAction {
    private static let minimumSwimStrength: Int16 = 160
    private static let swimPart1Animation: UInt16 = 0xAA
    private static let swimPart2Animation: UInt16 = 0xAB
    private static let flutterKickAnimation: UInt16 = 0xAC
    private static let holdSwimPart1Animation: UInt16 = 0x9F
    private static let holdSwimPart2Animation: UInt16 = 0xA0
    private static let holdFlutterKickAnimation: UInt16 = 0xA1

    static func update(
        _ input: SM64MarioSwimmingActionInput
    ) -> SM64MarioSwimmingActionResult? {
        guard input.stickX.isFinite, input.stickY.isFinite,
              input.forwardVelocity.isFinite, input.buoyancy.isFinite else {
            return nil
        }
        switch input.variant {
        case .breaststroke, .holdBreaststroke:
            return updateBreaststroke(input)
        case .swimmingEnd, .holdSwimmingEnd:
            return updateSwimmingEnd(input)
        case .flutterKick, .holdFlutterKick:
            return updateFlutterKick(input)
        }
    }

    private static func updateBreaststroke(
        _ input: SM64MarioSwimmingActionInput
    ) -> SM64MarioSwimmingActionResult {
        let held = input.variant == .holdBreaststroke
        if input.metalCap {
            return transition(
                input, intent: .metalWaterFall,
                action: held ? SM64MarioActionID.holdMetalWaterFalling
                    : SM64MarioActionID.metalWaterFalling,
                argument: held ? 0 : 1
            )
        }
        if held && input.dropObjectRequested {
            return transition(
                input, intent: .holdWaterIdle, action: SM64MarioActionID.waterIdle,
                shouldDropHeldObject: true
            )
        }
        if input.input.contains(.bPressed) {
            return transition(
                input, intent: held ? .waterThrow : .waterPunch,
                action: held ? SM64MarioActionID.waterThrow : SM64MarioActionID.waterPunch
            )
        }

        var timer = input.actionTimer &+ 1
        var state = input.actionState
        var strength = input.actionArgument == 0
            ? Self.minimumSwimStrength : input.swimStrength
        var forwardVelocity = input.forwardVelocity
        if timer == (held ? 17 : 14) {
            return transition(
                input,
                intent: held ? .holdFlutterKick : .flutterKick,
                action: held ? SM64MarioActionID.holdFlutterKick
                    : SM64MarioActionID.flutterKick
            )
        }
        if input.waterJumpReady {
            return transition(
                input,
                intent: held ? .holdWaterJump : .waterJump,
                action: held ? SM64MarioActionID.holdWaterJump
                    : SM64MarioActionID.waterJump
            )
        }
        if timer < 6 { forwardVelocity += 0.5 }
        if timer >= 9 { forwardVelocity += 1.5 }
        if timer >= 2 {
            if timer < 6 && input.input.contains(.aPressed) { state = 1 }
            if timer == 9 && state == 1 {
                state = 0
                timer = 1
                strength = Self.minimumSwimStrength
            }
        }
        let kinematics = swimmingStep(
            input: input, forwardVelocity: forwardVelocity,
            decelerationThreshold: Float(strength) / 10
        )
        return SM64MarioSwimmingActionResult(
            variant: input.variant, intent: .continueSwimming, action: nil,
            actionArgument: 0, actionTimer: timer, actionState: state,
            swimStrength: strength,
            animationID: held ? Self.holdSwimPart1Animation : Self.swimPart1Animation,
            faceYaw: kinematics.faceYaw, facePitch: kinematics.facePitch,
            faceRoll: kinematics.faceRoll, angleVelocityY: kinematics.angleVelocityY,
            forwardVelocity: kinematics.forwardVelocity, velocity: kinematics.velocity,
            shouldDropHeldObject: false,
            shouldPlaySwimmingSound: timer == 1,
            shouldPlayFastSwimmingSound: timer == 1 && strength != Self.minimumSwimStrength,
            shouldPlaySwimmingNoise: false, shouldResetFloatGlobals: timer == 1,
            shouldPlayWaterStep: true
        )
    }

    private static func updateSwimmingEnd(
        _ input: SM64MarioSwimmingActionInput
    ) -> SM64MarioSwimmingActionResult {
        let held = input.variant == .holdSwimmingEnd
        if input.metalCap {
            return transition(
                input, intent: .metalWaterFall,
                action: held ? SM64MarioActionID.holdMetalWaterFalling
                    : SM64MarioActionID.metalWaterFalling,
                argument: 1
            )
        }
        if held && input.dropObjectRequested {
            return transition(
                input, intent: .holdWaterIdle, action: SM64MarioActionID.waterIdle,
                shouldDropHeldObject: true
            )
        }
        if input.input.contains(.bPressed) {
            return transition(
                input, intent: held ? .waterThrow : .waterPunch,
                action: held ? SM64MarioActionID.waterThrow : SM64MarioActionID.waterPunch
            )
        }
        if input.actionTimer >= 15 {
            return transition(
                input, intent: held ? .holdWaterActionEnd : .waterActionEnd,
                action: held ? SM64MarioActionID.holdWaterActionEnd
                    : SM64MarioActionID.waterActionEnd
            )
        }
        if input.waterJumpReady {
            return transition(
                input, intent: held ? .holdWaterJump : .waterJump,
                action: held ? SM64MarioActionID.holdWaterJump
                    : SM64MarioActionID.waterJump
            )
        }
        var strength = input.swimStrength
        if input.input.contains(.aDown) && input.actionTimer >= 7 {
            if input.actionTimer == 7 && strength < 280 { strength += 10 }
            return transition(
                input,
                intent: held ? .holdBreaststroke : .breaststroke,
                action: held ? SM64MarioActionID.holdBreaststroke
                    : SM64MarioActionID.breaststroke,
                argument: 1, swimStrength: strength
            )
        }
        if input.actionTimer >= 7 { strength = Self.minimumSwimStrength }
        let timer = input.actionTimer &+ 1
        let kinematics = swimmingStep(
            input: input, forwardVelocity: input.forwardVelocity - 0.25,
            decelerationThreshold: Float(strength) / 10
        )
        return SM64MarioSwimmingActionResult(
            variant: input.variant, intent: .continueSwimming, action: nil,
            actionArgument: input.actionArgument, actionTimer: timer,
            actionState: input.actionState, swimStrength: strength,
            animationID: held ? Self.holdSwimPart2Animation : Self.swimPart2Animation,
            faceYaw: kinematics.faceYaw, facePitch: kinematics.facePitch,
            faceRoll: kinematics.faceRoll, angleVelocityY: kinematics.angleVelocityY,
            forwardVelocity: kinematics.forwardVelocity, velocity: kinematics.velocity,
            shouldDropHeldObject: false, shouldPlaySwimmingSound: false,
            shouldPlayFastSwimmingSound: false, shouldPlaySwimmingNoise: false,
            shouldResetFloatGlobals: false, shouldPlayWaterStep: true
        )
    }

    private static func updateFlutterKick(
        _ input: SM64MarioSwimmingActionInput
    ) -> SM64MarioSwimmingActionResult {
        let held = input.variant == .holdFlutterKick
        if input.metalCap {
            return transition(
                input, intent: .metalWaterFall,
                action: held ? SM64MarioActionID.holdMetalWaterFalling
                    : SM64MarioActionID.metalWaterFalling,
                argument: 0
            )
        }
        if held && input.dropObjectRequested {
            return transition(
                input, intent: .holdWaterIdle, action: SM64MarioActionID.waterIdle,
                shouldDropHeldObject: true
            )
        }
        if input.input.contains(.bPressed) {
            return transition(
                input, intent: held ? .waterThrow : .waterPunch,
                action: held ? SM64MarioActionID.waterThrow : SM64MarioActionID.waterPunch
            )
        }
        if !input.input.contains(.aDown) {
            var strength = input.swimStrength
            if input.actionTimer == 0 && strength < 280 { strength += 10 }
            return transition(
                input, intent: held ? .holdSwimmingEnd : .swimmingEnd,
                action: held ? SM64MarioActionID.holdSwimmingEnd
                    : SM64MarioActionID.swimmingEnd,
                swimStrength: strength
            )
        }
        let forwardVelocity = SM64DeterministicPrimitives.approachFloat(
            current: input.forwardVelocity, target: 12, increment: 0.1, decrement: 0.15
        )
        let kinematics = swimmingStep(
            input: input, forwardVelocity: forwardVelocity,
            decelerationThreshold: Float(input.swimStrength) / 10
        )
        return SM64MarioSwimmingActionResult(
            variant: input.variant, intent: .continueSwimming, action: nil,
            actionArgument: input.actionArgument, actionTimer: held ? input.actionTimer : 1,
            actionState: input.actionState, swimStrength: input.swimStrength,
            animationID: forwardVelocity < 14
                ? (held ? Self.holdFlutterKickAnimation : Self.flutterKickAnimation) : 0,
            faceYaw: kinematics.faceYaw, facePitch: kinematics.facePitch,
            faceRoll: kinematics.faceRoll, angleVelocityY: kinematics.angleVelocityY,
            forwardVelocity: kinematics.forwardVelocity, velocity: kinematics.velocity,
            shouldDropHeldObject: false, shouldPlaySwimmingSound: false,
            shouldPlayFastSwimmingSound: false,
            shouldPlaySwimmingNoise: forwardVelocity < 14,
            shouldResetFloatGlobals: false, shouldPlayWaterStep: true
        )
    }

    private static func transition(
        _ input: SM64MarioSwimmingActionInput,
        intent: SM64MarioSwimmingIntent,
        action: UInt32,
        argument: UInt32 = 0,
        shouldDropHeldObject: Bool = false,
        swimStrength: Int16? = nil
    ) -> SM64MarioSwimmingActionResult {
        SM64MarioSwimmingActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: argument, actionTimer: input.actionTimer,
            actionState: input.actionState, swimStrength: swimStrength ?? input.swimStrength,
            animationID: 0, faceYaw: input.faceYaw, facePitch: input.facePitch,
            faceRoll: input.faceRoll, angleVelocityY: input.angleVelocityY,
            forwardVelocity: input.forwardVelocity,
            velocity: SM64ObjectVector3(x: 0, y: input.buoyancy, z: 0),
            shouldDropHeldObject: shouldDropHeldObject,
            shouldPlaySwimmingSound: false, shouldPlayFastSwimmingSound: false,
            shouldPlaySwimmingNoise: false, shouldResetFloatGlobals: false,
            shouldPlayWaterStep: false
        )
    }

    private static func swimmingStep(
        input: SM64MarioSwimmingActionInput,
        forwardVelocity: Float,
        decelerationThreshold: Float
    ) -> (faceYaw: Int16, facePitch: Int16, faceRoll: Int16,
          angleVelocityY: Int16, forwardVelocity: Float,
          velocity: SM64ObjectVector3) {
        var angleVelocityY = Int16(
            truncatingIfNeeded: Int32(input.angleVelocityY)
        )
        let targetYawVelocity = Int32(-10 * input.stickX)
        if targetYawVelocity > 0 {
            if angleVelocityY < 0 {
                angleVelocityY = Int16(truncatingIfNeeded: Int32(angleVelocityY) + 0x40)
                if angleVelocityY > 0x10 { angleVelocityY = 0x10 }
            } else {
                angleVelocityY = Int16(truncatingIfNeeded: SM64DeterministicPrimitives.approachS32(
                    current: Int32(angleVelocityY), target: targetYawVelocity,
                    increment: 0x10, decrement: 0x20
                ))
            }
        } else if targetYawVelocity < 0 {
            if angleVelocityY > 0 {
                angleVelocityY = Int16(truncatingIfNeeded: Int32(angleVelocityY) - 0x40)
                if angleVelocityY < -0x10 { angleVelocityY = -0x10 }
            } else {
                angleVelocityY = Int16(truncatingIfNeeded: SM64DeterministicPrimitives.approachS32(
                    current: Int32(angleVelocityY), target: targetYawVelocity,
                    increment: 0x20, decrement: 0x10
                ))
            }
        } else {
            angleVelocityY = Int16(truncatingIfNeeded: SM64DeterministicPrimitives.approachS32(
                current: Int32(angleVelocityY), target: 0, increment: 0x40, decrement: 0x40
            ))
        }

        let faceYaw = Int16(
            truncatingIfNeeded: Int32(input.faceYaw) + Int32(angleVelocityY)
        )
        let faceRoll = Int16(truncatingIfNeeded: -Int32(angleVelocityY) * 8)
        let targetPitch = Int16(truncatingIfNeeded: Int32(-252 * input.stickY))
        let pitchVelocity: Int32 = input.facePitch < 0 ? 0x100 : 0x200
        let facePitch = Int16(truncatingIfNeeded: SM64DeterministicPrimitives.approachS32(
            current: Int32(input.facePitch), target: Int32(targetPitch),
            increment: pitchVelocity, decrement: pitchVelocity
        ))

        var speed = forwardVelocity
        if speed < 0 { speed = 0 }
        if speed > 28 { speed = 28 }
        if speed > decelerationThreshold { speed -= 0.5 }
        var finalPitch = facePitch
        switch input.waterStep {
        case .hitFloor:
            if let floorPitch = input.floorPitch, finalPitch < floorPitch { finalPitch = floorPitch }
        case .hitCeiling:
            if finalPitch > -0x3000 { finalPitch -= 0x100 }
        case .hitWall where input.stickY == 0:
            if finalPitch > 0 {
                finalPitch = min(finalPitch + 0x200, 0x3F00)
            } else {
                finalPitch = max(finalPitch - 0x200, -0x3F00)
            }
        case .none, .cancelled, .hitWall:
            break
        }
        let velocity = SM64ObjectVector3(
            x: speed * SM64CanonicalTrig.coss(finalPitch) * SM64CanonicalTrig.sins(faceYaw),
            y: speed * SM64CanonicalTrig.sins(finalPitch) + input.buoyancy,
            z: speed * SM64CanonicalTrig.coss(finalPitch) * SM64CanonicalTrig.coss(faceYaw)
        )
        return (faceYaw, finalPitch, faceRoll, angleVelocityY, speed, velocity)
    }
}
