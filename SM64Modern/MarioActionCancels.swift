import Foundation

struct SM64MarioActionDecision: Equatable, Sendable {
    let action: UInt32?
    let argument: UInt32
    let faceYaw: Int16?
    let shouldDropHeldObject: Bool
}

struct SM64MarioActionCancelContext: Equatable, Sendable {
    var floorNormalY: Float = 1
    var terrainIsSnow: Bool = false
    var heldObjectPresent: Bool = false
}

/// Pure common-cancel decisions shared by the stationary action bodies. The
/// caller applies the decision through `setAction`; this layer only preserves
/// C's input priority and pointer-free effects.
enum SM64MarioActionCancels {
    private static let steepFloorNormal: Float = 0.29237169

    static func idle(
        state: SM64MarioState,
        context: SM64MarioActionCancelContext
    ) -> SM64MarioActionDecision {
        if state.quicksandDepth > 30 { return transition(SM64MarioActionID.inQuicksand, drop: context.heldObjectPresent) }
        if state.input.contains(.inPoisonGas) { return transition(SM64MarioActionID.coughing, drop: context.heldObjectPresent) }
        if state.actionArgument & 1 == 0 && state.health < 0x300 {
            return transition(SM64MarioActionID.panting, drop: context.heldObjectPresent)
        }

        let common = commonIdle(state: state, context: context)
        if common.action != nil { return common }

        if state.actionState == 3 {
            return transition(context.terrainIsSnow ? SM64MarioActionID.shivering : SM64MarioActionID.startSleeping,
                              drop: context.heldObjectPresent)
        }
        return common
    }

    static func commonIdle(
        state: SM64MarioState,
        context: SM64MarioActionCancelContext
    ) -> SM64MarioActionDecision {
        if context.floorNormalY < steepFloorNormal {
            return transition(SM64MarioActionID.freefall, drop: context.heldObjectPresent)
        }
        if state.input.contains(.unknown10) {
            return transition(SM64MarioActionID.shockwaveBounce, drop: context.heldObjectPresent)
        }
        if state.input.contains(.aPressed) {
            return transition(SM64MarioActionID.jump, drop: context.heldObjectPresent)
        }
        if state.input.contains(.offFloor) {
            return transition(SM64MarioActionID.freefall, drop: context.heldObjectPresent)
        }
        if state.input.contains(.aboveSlide) {
            return transition(SM64MarioActionID.beginSliding, drop: context.heldObjectPresent)
        }
        if state.input.contains(.firstPerson) {
            return transition(SM64MarioActionID.firstPerson, drop: context.heldObjectPresent)
        }
        if state.input.contains(.nonzeroAnalog) {
            return SM64MarioActionDecision(
                action: SM64MarioActionID.walking,
                argument: 0,
                faceYaw: state.intendedYaw,
                shouldDropHeldObject: context.heldObjectPresent
            )
        }
        if state.input.contains(.bPressed) {
            return transition(SM64MarioActionID.punching, drop: context.heldObjectPresent)
        }
        if state.input.contains(.zDown) {
            return transition(SM64MarioActionID.startCrouching, drop: context.heldObjectPresent)
        }
        return SM64MarioActionDecision(
            action: nil,
            argument: 0,
            faceYaw: nil,
            shouldDropHeldObject: context.heldObjectPresent
        )
    }

    static func crouching(
        state: SM64MarioState,
        context: SM64MarioActionCancelContext
    ) -> SM64MarioActionDecision {
        if state.input.contains(.unknown10) {
            return transition(SM64MarioActionID.shockwaveBounce, drop: context.heldObjectPresent)
        }
        if state.input.contains(.aPressed) {
            return transition(SM64MarioActionID.backflip, drop: context.heldObjectPresent)
        }
        if state.input.contains(.offFloor) {
            return transition(SM64MarioActionID.freefall, drop: context.heldObjectPresent)
        }
        if state.input.contains(.aboveSlide) {
            return transition(SM64MarioActionID.beginSliding, drop: context.heldObjectPresent)
        }
        if state.input.contains(.firstPerson) || !state.input.contains(.zDown) {
            return transition(SM64MarioActionID.stopCrouching, drop: context.heldObjectPresent)
        }
        if state.input.contains(.nonzeroAnalog) {
            return transition(SM64MarioActionID.startCrawling, drop: context.heldObjectPresent)
        }
        if state.input.contains(.bPressed) {
            return SM64MarioActionDecision(
                action: SM64MarioActionID.punching,
                argument: 9,
                faceYaw: nil,
                shouldDropHeldObject: context.heldObjectPresent
            )
        }
        return SM64MarioActionDecision(
            action: nil,
            argument: 0,
            faceYaw: nil,
            shouldDropHeldObject: context.heldObjectPresent
        )
    }

    static func startCrouching(
        state: SM64MarioState,
        context: SM64MarioActionCancelContext
    ) -> SM64MarioActionDecision {
        if state.input.contains(.unknown10) {
            return transition(SM64MarioActionID.shockwaveBounce, drop: context.heldObjectPresent)
        }
        if state.input.contains(.offFloor) {
            return transition(SM64MarioActionID.freefall, drop: context.heldObjectPresent)
        }
        if state.input.contains(.aPressed) {
            return transition(SM64MarioActionID.backflip, drop: context.heldObjectPresent)
        }
        if state.input.contains(.aboveSlide) {
            return transition(SM64MarioActionID.beginSliding, drop: context.heldObjectPresent)
        }
        return SM64MarioActionDecision(
            action: nil,
            argument: 0,
            faceYaw: nil,
            shouldDropHeldObject: context.heldObjectPresent
        )
    }

    private static func transition(
        _ action: UInt32,
        drop: Bool
    ) -> SM64MarioActionDecision {
        SM64MarioActionDecision(
            action: action,
            argument: 0,
            faceYaw: nil,
            shouldDropHeldObject: drop
        )
    }
}
