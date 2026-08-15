import Foundation

enum SM64MarioAirMovementVariant: UInt8, Equatable, Sendable {
    case sideFlip = 0
    case wallKick = 1
    case longJump = 2
}

enum SM64MarioAirMovementIntent: UInt8, Equatable, Sendable {
    case preempt = 0
    case commonStep = 1
}

enum SM64MarioAirMovementSound: UInt8, Equatable, Sendable {
    case none = 0
    case terrainJump = 1
    case jump = 2
    case yahoo = 3
}

struct SM64MarioAirMovementActionInput: Equatable, Sendable {
    let variant: SM64MarioAirMovementVariant
    let commonInput: SM64MarioCommonAirActionInput
    let longJumpSlow: Bool
    let verticalWindActive: Bool
    let actionStateZero: Bool
    let animationFrame: Int16
}

struct SM64MarioAirMovementActionResult: Equatable, Sendable {
    let variant: SM64MarioAirMovementVariant
    let intent: SM64MarioAirMovementIntent
    let action: UInt32?
    let actionArgument: UInt32
    let animationID: UInt16
    let common: SM64MarioCommonAirActionResult?
    let sound: SM64MarioAirMovementSound
    let shouldQueueRumble: Bool
    let shouldFlipGraphicsYaw: Bool
    let shouldPlaySideFlipFrameSound: Bool
    let shouldPlayHereWeGoSound: Bool
}

/// Value callers for side-flip, wall-kick, and long-jump actions.
enum SM64MarioAirMovementAction {
    static func update(
        _ input: SM64MarioAirMovementActionInput
    ) -> SM64MarioAirMovementActionResult? {
        let flags = input.commonInput.input
        if flags.contains(.bPressed) && input.variant != .longJump {
            return transition(input, action: SM64MarioActionID.dive)
        }
        if flags.contains(.zPressed) && input.variant != .longJump {
            return transition(input, action: SM64MarioActionID.groundPound)
        }

        let descriptor = descriptor(for: input)
        let commonInput = SM64MarioCommonAirActionInput(
            landAction: descriptor.landAction, animationID: descriptor.animationID,
            input: input.commonInput.input,
            intendedMagnitude: input.commonInput.intendedMagnitude,
            intendedYaw: input.commonInput.intendedYaw,
            faceYaw: input.commonInput.faceYaw,
            forwardVelocity: input.commonInput.forwardVelocity,
            velocityY: input.commonInput.velocityY,
            wallAngle: input.commonInput.wallAngle,
            airStep: input.commonInput.airStep,
            fallDamageOrStuck: input.commonInput.fallDamageOrStuck,
            horizontalWindActive: input.commonInput.horizontalWindActive
        )
        guard let common = SM64MarioCommonAirAction.update(commonInput) else { return nil }

        let ledgeGrabbed = common.airStep == .grabbedLedge
        return SM64MarioAirMovementActionResult(
            variant: input.variant, intent: .commonStep,
            action: common.action, actionArgument: common.actionArgument,
            animationID: descriptor.animationID, common: common,
            sound: descriptor.sound,
            shouldQueueRumble: descriptor.queueRumble && common.action == descriptor.landAction,
            shouldFlipGraphicsYaw: input.variant == .sideFlip && !ledgeGrabbed,
            shouldPlaySideFlipFrameSound: input.variant == .sideFlip
                && input.animationFrame == 6,
            shouldPlayHereWeGoSound: input.variant == .longJump
                && input.verticalWindActive && input.actionStateZero
        )
    }

    private static func transition(
        _ input: SM64MarioAirMovementActionInput,
        action: UInt32
    ) -> SM64MarioAirMovementActionResult {
        SM64MarioAirMovementActionResult(
            variant: input.variant, intent: .preempt, action: action,
            actionArgument: 0, animationID: descriptor(for: input).animationID,
            common: nil, sound: .none, shouldQueueRumble: false,
            shouldFlipGraphicsYaw: false, shouldPlaySideFlipFrameSound: false,
            shouldPlayHereWeGoSound: false
        )
    }

    private static func descriptor(
        for input: SM64MarioAirMovementActionInput
    ) -> (landAction: UInt32, animationID: UInt16, sound: SM64MarioAirMovementSound,
          queueRumble: Bool) {
        switch input.variant {
        case .sideFlip:
            return (SM64MarioActionID.sideFlipLand, 0xBF, .terrainJump, false)
        case .wallKick:
            return (SM64MarioActionID.jumpLand, 0xCB, .jump, false)
        case .longJump:
            return (
                SM64MarioActionID.longJumpLand,
                input.longJumpSlow ? 0x14 : 0x13,
                .yahoo,
                true
            )
        }
    }
}
