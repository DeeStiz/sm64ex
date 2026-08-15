import Foundation

enum SM64MarioWaterInteractionVariant: UInt8, Equatable, Sendable {
    case waterThrow = 0
    case waterPunch = 1
    case waterShellSwimming = 2
}

enum SM64MarioWaterInteractionIntent: UInt8, Equatable, Sendable {
    case continueAction = 0
    case waterIdle = 1
    case waterActionEnd = 2
    case holdWaterActionEnd = 3
    case flutterKick = 4
    case waterThrow = 5
}

struct SM64MarioWaterInteractionActionInput: Equatable, Sendable {
    let variant: SM64MarioWaterInteractionVariant
    let input: SM64MarioInputFlags
    let actionTimer: UInt16
    let actionState: UInt8
    let animationPastEnd: Bool
    let waterGrabFound: Bool
    let heldObjectIsShell: Bool
    let dropObjectRequested: Bool
    let forwardVelocity: Float
}

struct SM64MarioWaterInteractionActionResult: Equatable, Sendable {
    let variant: SM64MarioWaterInteractionVariant
    let intent: SM64MarioWaterInteractionIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionTimer: UInt16
    let actionState: UInt8
    let animationID: UInt16
    let forwardVelocity: Float
    let shouldThrowHeldObject: Bool
    let shouldQueueRumble: Bool
    let shouldGrabUsedObject: Bool
    let shouldSetGrabPosition: Bool
    let shouldDropHeldObject: Bool
    let shouldStopRidingShell: Bool
    let shouldStopShellMusic: Bool
    let shouldPlaySwimmingNoise: Bool
}

/// Value counterpart of water throw/punch/grab and underwater shell swimming.
/// Shared swim stepping, object lookup, animation/audio installation, and
/// shell ownership remain explicit owner-thread effects.
enum SM64MarioWaterInteractionAction {
    private static let waterThrowAnimation: UInt16 = 0xB1
    private static let grabPart1Animation: UInt16 = 0xB0
    private static let grabPart2Animation: UInt16 = 0xAF
    private static let pickupAnimation: UInt16 = 0xAE
    private static let holdFlutterAnimation: UInt16 = 0xA1

    static func update(
        _ input: SM64MarioWaterInteractionActionInput
    ) -> SM64MarioWaterInteractionActionResult? {
        guard input.forwardVelocity.isFinite else { return nil }
        switch input.variant {
        case .waterThrow:
            return updateThrow(input)
        case .waterPunch:
            return updatePunch(input)
        case .waterShellSwimming:
            return updateShellSwimming(input)
        }
    }

    private static func updateThrow(
        _ input: SM64MarioWaterInteractionActionInput
    ) -> SM64MarioWaterInteractionActionResult {
        let timer = input.actionTimer &+ 1
        let throwsObject = input.actionTimer == 5
        let ends = input.animationPastEnd
        return result(
            input, intent: ends ? .waterIdle : .continueAction,
            action: ends ? SM64MarioActionID.waterIdle : nil,
            actionTimer: timer, actionState: input.actionState,
            animationID: Self.waterThrowAnimation,
            shouldThrowHeldObject: throwsObject,
            shouldQueueRumble: throwsObject
        )
    }

    private static func updatePunch(
        _ input: SM64MarioWaterInteractionActionInput
    ) -> SM64MarioWaterInteractionActionResult {
        var forwardVelocity = input.forwardVelocity
        if forwardVelocity < 7 { forwardVelocity += 1 }
        switch input.actionState {
        case 0:
            let nextState: UInt8 = input.animationPastEnd
                ? (input.waterGrabFound ? 2 : 1) : 0
            return result(
                input, intent: .continueAction, action: nil,
                actionTimer: input.actionTimer, actionState: nextState,
                animationID: Self.grabPart1Animation,
                forwardVelocity: forwardVelocity,
                shouldGrabUsedObject: input.animationPastEnd && input.waterGrabFound,
                shouldSetGrabPosition: input.animationPastEnd && input.waterGrabFound
            )
        case 1:
            return result(
                input, intent: input.animationPastEnd ? .waterActionEnd : .continueAction,
                action: input.animationPastEnd ? SM64MarioActionID.waterActionEnd : nil,
                actionTimer: input.actionTimer, actionState: input.actionState,
                animationID: Self.grabPart2Animation,
                forwardVelocity: forwardVelocity
            )
        default:
            let shell = input.heldObjectIsShell
            let ends = input.animationPastEnd
            return result(
                input,
                intent: ends
                    ? (shell ? .waterThrow : .holdWaterActionEnd)
                    : .continueAction,
                action: ends
                    ? (shell ? SM64MarioActionID.waterShellSwimming
                        : SM64MarioActionID.holdWaterActionEnd) : nil,
                actionArgument: ends && !shell ? 1 : 0,
                actionTimer: input.actionTimer, actionState: input.actionState,
                animationID: Self.pickupAnimation,
                forwardVelocity: forwardVelocity
            )
        }
    }

    private static func updateShellSwimming(
        _ input: SM64MarioWaterInteractionActionInput
    ) -> SM64MarioWaterInteractionActionResult {
        if input.dropObjectRequested {
            return result(
                input, intent: .waterIdle, action: SM64MarioActionID.waterIdle,
                shouldDropHeldObject: true
            )
        }
        if input.input.contains(.bPressed) {
            return result(
                input, intent: .waterThrow, action: SM64MarioActionID.waterThrow
            )
        }
        if input.actionTimer == 240 {
            return result(
                input, intent: .flutterKick, action: SM64MarioActionID.flutterKick,
                shouldStopRidingShell: true, shouldStopShellMusic: true
            )
        }
        let forwardVelocity = SM64DeterministicPrimitives.approachFloat(
            current: input.forwardVelocity, target: 30, increment: 2, decrement: 1
        )
        return result(
            input, intent: .continueAction, action: nil,
            actionTimer: input.actionTimer &+ 1,
            animationID: Self.holdFlutterAnimation,
            forwardVelocity: forwardVelocity, shouldPlaySwimmingNoise: true
        )
    }

    private static func result(
        _ input: SM64MarioWaterInteractionActionInput,
        intent: SM64MarioWaterInteractionIntent,
        action: UInt32?,
        actionArgument: UInt32 = 0,
        actionTimer: UInt16? = nil,
        actionState: UInt8? = nil,
        animationID: UInt16 = 0,
        forwardVelocity: Float? = nil,
        shouldThrowHeldObject: Bool = false,
        shouldQueueRumble: Bool = false,
        shouldGrabUsedObject: Bool = false,
        shouldSetGrabPosition: Bool = false,
        shouldDropHeldObject: Bool = false,
        shouldStopRidingShell: Bool = false,
        shouldStopShellMusic: Bool = false,
        shouldPlaySwimmingNoise: Bool = false
    ) -> SM64MarioWaterInteractionActionResult {
        SM64MarioWaterInteractionActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: actionArgument, actionTimer: actionTimer ?? input.actionTimer,
            actionState: actionState ?? input.actionState, animationID: animationID,
            forwardVelocity: forwardVelocity ?? input.forwardVelocity,
            shouldThrowHeldObject: shouldThrowHeldObject,
            shouldQueueRumble: shouldQueueRumble,
            shouldGrabUsedObject: shouldGrabUsedObject,
            shouldSetGrabPosition: shouldSetGrabPosition,
            shouldDropHeldObject: shouldDropHeldObject,
            shouldStopRidingShell: shouldStopRidingShell,
            shouldStopShellMusic: shouldStopShellMusic,
            shouldPlaySwimmingNoise: shouldPlaySwimmingNoise
        )
    }
}
