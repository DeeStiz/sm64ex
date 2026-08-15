import Foundation

enum SM64MarioLedgeCannonVariant: UInt8, Equatable, Sendable {
    case ledgeGrab = 0
    case ledgeClimbSlow = 1
    case ledgeClimbDown = 2
    case ledgeClimbFast = 3
    case inCannon = 4
}

enum SM64MarioLedgeCannonIntent: UInt8, Equatable, Sendable {
    case continueAction = 0
    case idle = 1
    case softBonk = 2
    case ledgeClimbFast = 3
    case ledgeClimbSlow1 = 4
    case ledgeClimbSlow2 = 5
    case ledgeGrab = 6
    case freefall = 7
    case inCannon = 8
    case shotFromCannon = 9
}

struct SM64MarioLedgeCannonActionInput: Equatable, Sendable {
    let variant: SM64MarioLedgeCannonVariant
    let input: SM64MarioInputFlags
    let actionState: UInt8
    let actionArgument: UInt32
    let actionTimer: UInt16
    let animationAtEnd: Bool
    let animationFrame: Int16
    let floorNormalY: Float
    let floorHeight: Float
    let ceilingHeight: Float
    let positionY: Float
    let heightAboveFloor: Float
    let intendedYaw: Int16
    let faceYaw: Int16
    let interactionHurts: Bool
    let soundPlayed: Bool
    let hasSpaceForMario: Bool
    let cannonActive: Bool
    let cannonPosition: SM64ObjectVector3
    let cannonObjectPitch: Int16
    let cannonObjectYaw: Int16
    let cannonInputYaw: Int16
    let stickX: Float
    let stickY: Float
    let startFacePitch: Int16
    let startFaceYaw: Int16
}

struct SM64MarioLedgeCannonActionResult: Equatable, Sendable {
    let variant: SM64MarioLedgeCannonVariant
    let intent: SM64MarioLedgeCannonIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionState: UInt8
    let actionTimer: UInt16
    let animationID: UInt16
    let faceYaw: Int16
    let facePitch: Int16
    let cannonInputYaw: Int16
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let forwardVelocity: Float
    let shouldHideMario: Bool
    let shouldShowMario: Bool
    let shouldMarkCannonInteracted: Bool
    let shouldPlayWhoa: Bool
    let shouldPlayClimbSound: Bool
    let shouldPlayLandingSound: Bool
    let shouldPlayCannonAimSound: Bool
    let shouldQueueRumble: Bool
    let shouldResetRumble: Bool
    let shouldReleaseLedge: Bool
    let shouldSyncGraphics: Bool
}

/// Value counterpart of the ledge-grab/climb and cannon automatic callers.
/// Collision, camera, object mutation, animation/audio installation, and
/// effect delivery remain explicit owner-thread operations.
enum SM64MarioLedgeCannonAction {
    private static let idleOnLedge: UInt16 = 0x33
    private static let slowLedgeGrab: UInt16 = 0x00
    private static let climbDownLedge: UInt16 = 0x1C
    private static let fastLedgeGrab: UInt16 = 0x34
    private static let dive: UInt16 = 0x88

    static func update(
        _ input: SM64MarioLedgeCannonActionInput
    ) -> SM64MarioLedgeCannonActionResult? {
        guard finite(input) else { return nil }
        switch input.variant {
        case .ledgeGrab: return ledgeGrab(input)
        case .ledgeClimbSlow: return ledgeClimbSlow(input)
        case .ledgeClimbDown: return ledgeClimbDown(input)
        case .ledgeClimbFast: return ledgeClimbFast(input)
        case .inCannon: return inCannon(input)
        }
    }

    private static func ledgeGrab(
        _ input: SM64MarioLedgeCannonActionInput
    ) -> SM64MarioLedgeCannonActionResult {
        let timer = min(input.actionTimer &+ 1, 10)
        let intendedDYaw = Int16(truncatingIfNeeded: Int32(input.intendedYaw) - Int32(input.faceYaw))
        if input.floorNormalY < 0.9063078 || input.input.contains(.zPressed)
            || input.input.contains(.offFloor) {
            return release(input)
        }
        if input.input.contains(.aPressed) && input.hasSpaceForMario {
            return transition(input, intent: .ledgeClimbFast,
                              action: SM64MarioActionID.ledgeClimbFast, actionTimer: timer)
        }
        if input.input.contains(.unknown10) {
            return release(input, actionArgument: input.interactionHurts ? 1 : 0)
        }
        if timer == 10 && input.input.contains(.nonzeroAnalog) {
            if intendedDYaw >= -0x4000 && intendedDYaw <= 0x4000 {
                if input.hasSpaceForMario {
                    return transition(input, intent: .ledgeClimbSlow1,
                                      action: SM64MarioActionID.ledgeClimbSlow1,
                                      actionTimer: timer)
                }
            } else {
                return release(input)
            }
        }
        if input.hasSpaceForMario && input.heightAboveFloor < 100 {
            return transition(input, intent: .ledgeClimbFast,
                              action: SM64MarioActionID.ledgeClimbFast,
                              actionTimer: timer)
        }
        return result(
            input, intent: .continueAction, action: nil, actionTimer: timer,
            animationID: Self.idleOnLedge,
            shouldPlayWhoa: input.actionArgument == 0, shouldSyncGraphics: true
        )
    }

    private static func ledgeClimbSlow(
        _ input: SM64MarioLedgeCannonActionInput
    ) -> SM64MarioLedgeCannonActionResult {
        if input.input.contains(.offFloor) { return release(input) }
        let end = input.actionTimer >= 28
            && !input.input.intersection([.nonzeroAnalog, .aPressed, .offFloor, .aboveSlide]).isEmpty
        if end {
            return transition(input, intent: .idle, action: SM64MarioActionID.idle,
                              actionTimer: input.actionTimer)
        }
        return result(
            input, intent: input.animationFrame == 17 ? .ledgeClimbSlow2 : .continueAction,
            action: input.animationFrame == 17 ? SM64MarioActionID.ledgeClimbSlow2 : nil,
            actionTimer: input.actionTimer &+ 1, animationID: Self.slowLedgeGrab,
            shouldPlayClimbSound: input.actionTimer == 10, shouldSyncGraphics: true
        )
    }

    private static func ledgeClimbDown(
        _ input: SM64MarioLedgeCannonActionInput
    ) -> SM64MarioLedgeCannonActionResult {
        if input.input.contains(.offFloor) { return release(input) }
        return result(
            input, intent: input.animationAtEnd ? .ledgeGrab : .continueAction,
            action: input.animationAtEnd ? SM64MarioActionID.ledgeGrab : nil,
            actionArgument: 1, animationID: Self.climbDownLedge,
            shouldPlayWhoa: !input.soundPlayed, shouldSyncGraphics: true
        )
    }

    private static func ledgeClimbFast(
        _ input: SM64MarioLedgeCannonActionInput
    ) -> SM64MarioLedgeCannonActionResult {
        if input.input.contains(.offFloor) { return release(input) }
        return result(
            input, intent: input.animationAtEnd ? .idle : .continueAction,
            action: input.animationAtEnd ? SM64MarioActionID.idle : nil,
            animationID: Self.fastLedgeGrab,
            shouldPlayWhoa: !input.soundPlayed,
            shouldPlayLandingSound: input.animationFrame == 8,
            shouldSyncGraphics: true
        )
    }

    private static func inCannon(
        _ input: SM64MarioLedgeCannonActionInput
    ) -> SM64MarioLedgeCannonActionResult {
        var actionState = input.actionState
        var facePitch = input.startFacePitch
        var faceYaw = input.startFaceYaw
        var cannonInputYaw = input.cannonInputYaw
        var position = input.cannonPosition
        var velocity = SM64ObjectVector3.zero
        var forwardVelocity: Float = 0
        if actionState == 0 {
            actionState = 1
            position.y += 350
        } else if actionState == 1 {
            if input.cannonActive {
                facePitch = input.cannonObjectPitch
                faceYaw = input.cannonObjectYaw
                cannonInputYaw = 0
                actionState = 2
            }
        } else {
            facePitch = Int16(clamping: Int32(facePitch) - Int32(input.stickY * 10))
            cannonInputYaw = Int16(clamping: Int32(cannonInputYaw)
                - Int32(input.stickX * 10))
            facePitch = min(max(facePitch, 0), 0x38E3)
            cannonInputYaw = min(max(cannonInputYaw, -0x4000), 0x4000)
            faceYaw = input.cannonObjectYaw &+ cannonInputYaw
            if input.input.contains(.aPressed) {
                forwardVelocity = 100 * SM64CanonicalTrig.coss(facePitch)
                velocity.y = 100 * SM64CanonicalTrig.sins(facePitch)
                position.x += 120 * SM64CanonicalTrig.coss(facePitch) * SM64CanonicalTrig.sins(faceYaw)
                position.y += 120 * SM64CanonicalTrig.sins(facePitch)
                position.z += 120 * SM64CanonicalTrig.coss(facePitch) * SM64CanonicalTrig.coss(faceYaw)
                return result(
                    input, intent: .shotFromCannon,
                    action: SM64MarioActionID.shotFromCannon, actionState: actionState,
                    animationID: Self.dive, faceYaw: faceYaw, facePitch: facePitch,
                    cannonInputYaw: cannonInputYaw, position: position, velocity: velocity,
                    forwardVelocity: forwardVelocity, shouldShowMario: true,
                    shouldQueueRumble: true, shouldSyncGraphics: true
                )
            }
        }
        let aimed = facePitch != input.startFacePitch || faceYaw != input.startFaceYaw
        return result(
            input, intent: .continueAction, action: nil, actionState: actionState,
            animationID: Self.dive, faceYaw: faceYaw, facePitch: facePitch,
            cannonInputYaw: cannonInputYaw, position: position, velocity: velocity,
            forwardVelocity: forwardVelocity, shouldHideMario: actionState == 1,
            shouldMarkCannonInteracted: input.actionState == 0,
            shouldPlayCannonAimSound: aimed, shouldResetRumble: aimed,
            shouldSyncGraphics: true
        )
    }

    private static func release(
        _ input: SM64MarioLedgeCannonActionInput,
        actionArgument: UInt32 = 0
    ) -> SM64MarioLedgeCannonActionResult {
        result(
            input, intent: .softBonk, action: SM64MarioActionID.softBonk,
            actionArgument: actionArgument, velocity: .init(x: 0, y: 0, z: 0),
            forwardVelocity: -8, shouldReleaseLedge: true, shouldSyncGraphics: true
        )
    }

    private static func transition(
        _ input: SM64MarioLedgeCannonActionInput,
        intent: SM64MarioLedgeCannonIntent,
        action: UInt32?, actionArgument: UInt32 = 0,
        actionState: UInt8? = nil, actionTimer: UInt16? = nil
    ) -> SM64MarioLedgeCannonActionResult {
        result(input, intent: intent, action: action, actionArgument: actionArgument,
               actionState: actionState, actionTimer: actionTimer)
    }

    private static func result(
        _ input: SM64MarioLedgeCannonActionInput,
        intent: SM64MarioLedgeCannonIntent,
        action: UInt32?, actionArgument: UInt32 = 0,
        actionState: UInt8? = nil, actionTimer: UInt16? = nil,
        animationID: UInt16 = 0, faceYaw: Int16? = nil, facePitch: Int16? = nil,
        cannonInputYaw: Int16? = nil, position: SM64ObjectVector3 = .zero,
        velocity: SM64ObjectVector3 = .zero, forwardVelocity: Float = 0,
        shouldHideMario: Bool = false, shouldShowMario: Bool = false,
        shouldMarkCannonInteracted: Bool = false, shouldPlayWhoa: Bool = false,
        shouldPlayClimbSound: Bool = false, shouldPlayLandingSound: Bool = false,
        shouldPlayCannonAimSound: Bool = false, shouldQueueRumble: Bool = false,
        shouldResetRumble: Bool = false, shouldReleaseLedge: Bool = false,
        shouldSyncGraphics: Bool = false
    ) -> SM64MarioLedgeCannonActionResult {
        SM64MarioLedgeCannonActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: actionArgument, actionState: actionState ?? input.actionState,
            actionTimer: actionTimer ?? input.actionTimer, animationID: animationID,
            faceYaw: faceYaw ?? input.faceYaw, facePitch: facePitch ?? input.startFacePitch,
            cannonInputYaw: cannonInputYaw ?? input.cannonInputYaw, position: position,
            velocity: velocity, forwardVelocity: forwardVelocity,
            shouldHideMario: shouldHideMario, shouldShowMario: shouldShowMario,
            shouldMarkCannonInteracted: shouldMarkCannonInteracted,
            shouldPlayWhoa: shouldPlayWhoa, shouldPlayClimbSound: shouldPlayClimbSound,
            shouldPlayLandingSound: shouldPlayLandingSound,
            shouldPlayCannonAimSound: shouldPlayCannonAimSound,
            shouldQueueRumble: shouldQueueRumble, shouldResetRumble: shouldResetRumble,
            shouldReleaseLedge: shouldReleaseLedge, shouldSyncGraphics: shouldSyncGraphics
        )
    }

    private static func finite(_ input: SM64MarioLedgeCannonActionInput) -> Bool {
        input.floorNormalY.isFinite && input.floorHeight.isFinite
            && input.ceilingHeight.isFinite && input.positionY.isFinite
            && input.heightAboveFloor.isFinite && input.stickX.isFinite
            && input.stickY.isFinite && input.cannonPosition.x.isFinite
            && input.cannonPosition.y.isFinite && input.cannonPosition.z.isFinite
    }
}
