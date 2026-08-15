import Foundation

enum SM64MarioGrabbedIntent: UInt8, Equatable, Sendable {
    case continueAction = 0
    case thrownForward = 1
    case thrownBackward = 2
}

struct SM64MarioGrabbedActionInput: Equatable, Sendable {
    let interactionStatus: UInt32
    let usedObjectYaw: Int16
    let graphicsPosition: SM64ObjectVector3
    let faceYaw: Int16
    let forwardVelocity: Float
}

struct SM64MarioGrabbedActionResult: Equatable, Sendable {
    let intent: SM64MarioGrabbedIntent
    let action: UInt32?
    let actionArgument: UInt32
    let animationID: UInt16
    let faceYaw: Int16
    let position: SM64ObjectVector3
    let shouldQueueRumble: Bool
    let rumbleDistance: UInt16
    let shouldSyncGraphics: Bool
}

/// Value counterpart of `act_grabbed` in `mario_actions_automatic.c`.
/// Interaction status/object transforms and effect delivery remain explicit
/// owner-thread operations.
enum SM64MarioGrabbedAction {
    private static let interactionThrown = 1 << 2
    private static let interactionHeld = 1 << 6
    private static let beingGrabbedAnimation: UInt16 = 0x58

    static func update(
        _ input: SM64MarioGrabbedActionInput
    ) -> SM64MarioGrabbedActionResult? {
        guard input.graphicsPosition.x.isFinite,
              input.graphicsPosition.y.isFinite,
              input.graphicsPosition.z.isFinite,
              input.forwardVelocity.isFinite else { return nil }

        guard input.interactionStatus & UInt32(interactionThrown) != 0 else {
            return SM64MarioGrabbedActionResult(
                intent: .continueAction, action: nil, actionArgument: 0,
                animationID: Self.beingGrabbedAnimation, faceYaw: input.faceYaw,
                position: input.graphicsPosition, shouldQueueRumble: false,
                rumbleDistance: 0, shouldSyncGraphics: false
            )
        }

        let thrown = input.interactionStatus & UInt32(interactionHeld) == 0
        return SM64MarioGrabbedActionResult(
            intent: input.forwardVelocity >= 0 ? .thrownForward : .thrownBackward,
            action: input.forwardVelocity >= 0
                ? SM64MarioActionID.thrownForward : SM64MarioActionID.thrownBackward,
            actionArgument: thrown ? 1 : 0, animationID: 0,
            faceYaw: input.usedObjectYaw, position: input.graphicsPosition,
            shouldQueueRumble: true, rumbleDistance: 60, shouldSyncGraphics: true
        )
    }
}

enum SM64MarioTornadoIntent: UInt8, Equatable, Sendable {
    case continueAction = 0
    case twirling = 1
}

struct SM64MarioTornadoActionInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let usedObjectPosition: SM64ObjectVector3
    let usedObjectHitboxHeight: Float
    let tornadoPositionY: Float
    let tornadoYawVelocity: Int16
    let angleVelocityY: Int16
    let twirlYaw: Int16
    let actionArgument: UInt32
    let actionTimer: UInt16
    let faceYaw: Int16
    let floorHeight: Float
    let floorFound: Bool
    let nextFloorHeight: Float
    /// Position after the owner-thread wall query. Keeping this result outside
    /// the value kernel preserves the collision pointer/arena boundary.
    let wallAdjustedPosition: SM64ObjectVector3
    let animationPastEnd: Bool
}

struct SM64MarioTornadoActionResult: Equatable, Sendable {
    let intent: SM64MarioTornadoIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionTimer: UInt16
    let animationID: UInt16
    /// Candidate position before the owner-thread wall query.
    let proposedPosition: SM64ObjectVector3
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let floorHeight: Float
    let tornadoPositionY: Float
    let tornadoYawVelocity: Int16
    let angleVelocityY: Int16
    let twirlYaw: Int16
    let graphicsYaw: Int16
    let shouldUpdateFloor: Bool
    let shouldPlayTwirlSound: Bool
    let shouldResetRumble: Bool
    let shouldSyncGraphics: Bool
}

/// Value counterpart of `act_tornado_twirling` in
/// `mario_actions_automatic.c`. The tornado object, wall/floor queries,
/// animation/audio installation, graphics update, and rumble delivery remain
/// owner-thread effects.
enum SM64MarioTornadoAction {
    private static let startTwirlAnimation: UInt16 = 0x95
    private static let twirlAnimation: UInt16 = 0x94

    static func update(
        _ input: SM64MarioTornadoActionInput
    ) -> SM64MarioTornadoActionResult? {
        guard finite(input) else { return nil }

        var velocity = input.velocity
        if velocity.y < 60 { velocity.y += 1 }

        var tornadoPositionY = input.tornadoPositionY + velocity.y
        if tornadoPositionY < 0 { tornadoPositionY = 0 }

        if tornadoPositionY > input.usedObjectHitboxHeight {
            if velocity.y < 20 { velocity.y = 20 }
            return result(
                input, intent: .twirling, action: SM64MarioActionID.twirling,
                actionArgument: 1, velocity: velocity,
                tornadoPositionY: tornadoPositionY, shouldSyncGraphics: false
            )
        }

        var angleVelocityY = input.angleVelocityY
        if angleVelocityY < 0x3000 { angleVelocityY &+= 0x0100 }
        var tornadoYawVelocity = input.tornadoYawVelocity
        if tornadoYawVelocity < 0x1000 { tornadoYawVelocity &+= 0x0100 }
        let twirlYaw = input.twirlYaw &+ angleVelocityY

        let dx = (input.position.x - input.usedObjectPosition.x) * 0.95
        let dz = (input.position.z - input.usedObjectPosition.z) * 0.95
        let sinAngle = SM64CanonicalTrig.sins(tornadoYawVelocity)
        let cosAngle = SM64CanonicalTrig.coss(tornadoYawVelocity)
        let nextPosition = SM64ObjectVector3(
            x: input.usedObjectPosition.x + dx * cosAngle + dz * sinAngle,
            y: input.usedObjectPosition.y + tornadoPositionY,
            z: input.usedObjectPosition.z - dx * sinAngle + dz * cosAngle
        )

        let position: SM64ObjectVector3
        let floorHeight: Float
        let shouldUpdateFloor: Bool
        if input.floorFound {
            position = input.wallAdjustedPosition
            floorHeight = input.nextFloorHeight
            shouldUpdateFloor = true
        } else {
            position = SM64ObjectVector3(
                x: input.position.x,
                y: max(input.wallAdjustedPosition.y, input.floorHeight),
                z: input.position.z
            )
            floorHeight = input.floorHeight
            shouldUpdateFloor = false
        }

        let actionArgument = input.animationPastEnd ? 1 : input.actionArgument
        let animationID = input.actionArgument == 0
            ? Self.startTwirlAnimation : Self.twirlAnimation
        return result(
            input, intent: .continueAction, action: nil,
            actionArgument: actionArgument, actionTimer: input.actionTimer &+ 1,
            animationID: animationID, proposedPosition: nextPosition,
            position: position, velocity: velocity,
            floorHeight: floorHeight, tornadoPositionY: tornadoPositionY,
            tornadoYawVelocity: tornadoYawVelocity, angleVelocityY: angleVelocityY,
            twirlYaw: twirlYaw, graphicsYaw: input.faceYaw &+ twirlYaw,
            shouldUpdateFloor: shouldUpdateFloor,
            shouldPlayTwirlSound: input.twirlYaw > twirlYaw,
            shouldResetRumble: true, shouldSyncGraphics: true
        )
    }

    private static func result(
        _ input: SM64MarioTornadoActionInput,
        intent: SM64MarioTornadoIntent,
        action: UInt32?, actionArgument: UInt32,
        actionTimer: UInt16? = nil, animationID: UInt16 = 0,
        proposedPosition: SM64ObjectVector3? = nil,
        position: SM64ObjectVector3? = nil, velocity: SM64ObjectVector3? = nil,
        floorHeight: Float? = nil, tornadoPositionY: Float? = nil,
        tornadoYawVelocity: Int16? = nil, angleVelocityY: Int16? = nil,
        twirlYaw: Int16? = nil, graphicsYaw: Int16? = nil,
        shouldUpdateFloor: Bool = false, shouldPlayTwirlSound: Bool = false,
        shouldResetRumble: Bool = false, shouldSyncGraphics: Bool = false
    ) -> SM64MarioTornadoActionResult {
        SM64MarioTornadoActionResult(
            intent: intent, action: action, actionArgument: actionArgument,
            actionTimer: actionTimer ?? input.actionTimer, animationID: animationID,
            proposedPosition: proposedPosition ?? input.position,
            position: position ?? input.position, velocity: velocity ?? input.velocity,
            floorHeight: floorHeight ?? input.floorHeight,
            tornadoPositionY: tornadoPositionY ?? input.tornadoPositionY,
            tornadoYawVelocity: tornadoYawVelocity ?? input.tornadoYawVelocity,
            angleVelocityY: angleVelocityY ?? input.angleVelocityY,
            twirlYaw: twirlYaw ?? input.twirlYaw,
            graphicsYaw: graphicsYaw ?? input.faceYaw &+ input.twirlYaw,
            shouldUpdateFloor: shouldUpdateFloor,
            shouldPlayTwirlSound: shouldPlayTwirlSound,
            shouldResetRumble: shouldResetRumble, shouldSyncGraphics: shouldSyncGraphics
        )
    }

    private static func finite(_ input: SM64MarioTornadoActionInput) -> Bool {
        input.position.x.isFinite && input.position.y.isFinite
            && input.position.z.isFinite && input.velocity.x.isFinite
            && input.velocity.y.isFinite && input.velocity.z.isFinite
            && input.usedObjectPosition.x.isFinite
            && input.usedObjectPosition.y.isFinite
            && input.usedObjectPosition.z.isFinite
            && input.usedObjectHitboxHeight.isFinite
            && input.tornadoPositionY.isFinite && input.floorHeight.isFinite
            && input.nextFloorHeight.isFinite
            && input.wallAdjustedPosition.x.isFinite
            && input.wallAdjustedPosition.y.isFinite
            && input.wallAdjustedPosition.z.isFinite
    }
}
