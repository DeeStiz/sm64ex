import Foundation

enum SM64MarioStationaryAnimationID {
    static let idleHeadLeft: UInt16 = 0xC3
    static let idleHeadRight: UInt16 = 0xC4
    static let idleHeadCenter: UInt16 = 0xC5
    static let standAgainstWall: UInt16 = 0x7E
    static let startCrouching: UInt16 = 0x97
    static let crouching: UInt16 = 0x98
}

struct SM64MarioStationaryActionInput: Equatable, Sendable {
    let action: UInt32
    let actionArgument: UInt32
    let actionState: UInt16
    let actionTimer: UInt16
    let cancelDecision: SM64MarioActionDecision
    let terrainIsSnow: Bool
    let animationAtEnd: Bool
    let animationPastEnd: Bool
    let floorBehindDeltaY: Float
    let floorBehindIsDynamic: Bool
}

struct SM64MarioStationaryActionResult: Equatable, Sendable {
    let action: UInt32?
    let actionArgument: UInt32
    let animationID: UInt16?
    let actionState: UInt16
    let actionTimer: UInt16
    let shouldRunStationaryGroundStep: Bool
    let shouldDropHeldObject: Bool
}

/// Value body for the idle, crouching, and start-crouching actions. Input
/// cancellation is supplied by `SM64MarioActionCancels`; this layer preserves
/// the body order, animation IDs, idle-cycle bookkeeping, and stationary-step
/// effect without touching an object or animation graph.
enum SM64MarioStationaryAction {
    static func update(_ input: SM64MarioStationaryActionInput) -> SM64MarioStationaryActionResult? {
        guard input.floorBehindDeltaY.isFinite,
              input.actionState <= 3 else { return nil }

        if input.cancelDecision.action != nil {
            return result(
                action: input.cancelDecision.action,
                argument: input.cancelDecision.argument,
                animationID: nil,
                actionState: input.actionState,
                actionTimer: input.actionTimer,
                shouldRunStationaryGroundStep: false,
                shouldDropHeldObject: input.cancelDecision.shouldDropHeldObject
            )
        }

        switch input.action {
        case SM64MarioActionID.idle:
            if input.actionState == 3 {
                return result(
                    action: input.terrainIsSnow
                        ? SM64MarioActionID.shivering
                        : SM64MarioActionID.startSleeping,
                    argument: 0,
                    animationID: nil,
                    actionState: input.actionState,
                    actionTimer: input.actionTimer,
                    shouldRunStationaryGroundStep: false,
                    shouldDropHeldObject: input.cancelDecision.shouldDropHeldObject
                )
            }

            let animationID: UInt16
            if input.actionArgument & 1 != 0 {
                animationID = SM64MarioStationaryAnimationID.standAgainstWall
            } else {
                switch input.actionState {
                case 0: animationID = SM64MarioStationaryAnimationID.idleHeadLeft
                case 1: animationID = SM64MarioStationaryAnimationID.idleHeadRight
                case 2: animationID = SM64MarioStationaryAnimationID.idleHeadCenter
                default: return nil
                }
            }

            var nextState = input.actionState
            var nextTimer = input.actionTimer
            if input.animationAtEnd && input.actionArgument & 1 == 0 {
                nextState &+= 1
                if nextState == 3 {
                    if input.floorBehindDeltaY < -24
                        || input.floorBehindDeltaY > 24
                        || input.floorBehindIsDynamic {
                        nextState = 0
                    } else {
                        nextTimer &+= 1
                        if nextTimer < 10 { nextState = 0 }
                    }
                }
            }

            return result(
                action: nil,
                argument: 0,
                animationID: animationID,
                actionState: nextState,
                actionTimer: nextTimer,
                shouldRunStationaryGroundStep: true,
                shouldDropHeldObject: input.cancelDecision.shouldDropHeldObject
            )

        case SM64MarioActionID.crouching:
            return result(
                action: nil,
                argument: 0,
                animationID: SM64MarioStationaryAnimationID.crouching,
                actionState: input.actionState,
                actionTimer: input.actionTimer,
                shouldRunStationaryGroundStep: true,
                shouldDropHeldObject: input.cancelDecision.shouldDropHeldObject
            )

        case SM64MarioActionID.startCrouching:
            return result(
                action: input.animationPastEnd ? SM64MarioActionID.crouching : nil,
                argument: 0,
                animationID: SM64MarioStationaryAnimationID.startCrouching,
                actionState: input.actionState,
                actionTimer: input.actionTimer,
                shouldRunStationaryGroundStep: true,
                shouldDropHeldObject: input.cancelDecision.shouldDropHeldObject
            )

        default:
            return nil
        }
    }

    private static func result(
        action: UInt32?,
        argument: UInt32,
        animationID: UInt16?,
        actionState: UInt16,
        actionTimer: UInt16,
        shouldRunStationaryGroundStep: Bool,
        shouldDropHeldObject: Bool
    ) -> SM64MarioStationaryActionResult {
        SM64MarioStationaryActionResult(
            action: action,
            actionArgument: argument,
            animationID: animationID,
            actionState: actionState,
            actionTimer: actionTimer,
            shouldRunStationaryGroundStep: shouldRunStationaryGroundStep,
            shouldDropHeldObject: shouldDropHeldObject
        )
    }
}
