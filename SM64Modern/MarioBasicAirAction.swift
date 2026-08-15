import Foundation

enum SM64MarioBasicAirVariant: UInt8, Equatable, Sendable {
    case jump = 0
    case doubleJump = 1
    case tripleJump = 2
    case backflip = 3
    case freefall = 4
    case holdJump = 5
    case holdFreefall = 6
}

enum SM64MarioBasicAirIntent: UInt8, Equatable, Sendable {
    case preempt = 0
    case commonStep = 1
}

enum SM64MarioBasicAirSound: UInt8, Equatable, Sendable {
    case none = 0
    case terrainJump = 1
    case hoohoo = 2
    case yahWahHoo = 3
    case yahoo = 4
}

struct SM64MarioBasicAirActionInput: Equatable, Sendable {
    let variant: SM64MarioBasicAirVariant
    let actionArgument: UInt32
    let commonInput: SM64MarioCommonAirActionInput
    let dropRequested: Bool
    let heldObjectIsNPC: Bool
    let specialTripleJump: Bool
    let kickOrDiveAction: UInt32?
}

struct SM64MarioBasicAirActionResult: Equatable, Sendable {
    let variant: SM64MarioBasicAirVariant
    let intent: SM64MarioBasicAirIntent
    let action: UInt32?
    let actionArgument: UInt32
    let animationID: UInt16
    let common: SM64MarioCommonAirActionResult?
    let shouldPlayJumpSound: Bool
    let sound: SM64MarioBasicAirSound
    let shouldQueueRumble: Bool
    let shouldPlayFlipSounds: Bool
    let shouldDropHeldObject: Bool
}

/// Value callers for the basic airborne family. The shared air-step kernel
/// remains responsible for collision outcomes; this layer preserves each
/// caller's input priority, animation selection, and sound/rumble effects.
enum SM64MarioBasicAirAction {
    static func update(
        _ input: SM64MarioBasicAirActionInput
    ) -> SM64MarioBasicAirActionResult? {
        let flags = input.commonInput.input
        let variant = input.variant

        if let preempt = preemptAction(input: input, flags: flags) {
            return SM64MarioBasicAirActionResult(
                variant: variant, intent: .preempt, action: preempt.action,
                actionArgument: 0, animationID: animation(for: input), common: nil,
                shouldPlayJumpSound: false, sound: .none,
                shouldQueueRumble: false, shouldPlayFlipSounds: false,
                shouldDropHeldObject: preempt.drop
            )
        }

        let descriptor = descriptor(for: input)
        guard let common = SM64MarioCommonAirAction.update(
            commonInput(input, landAction: descriptor.landAction, animationID: descriptor.animationID)
        ) else { return nil }

        return SM64MarioBasicAirActionResult(
            variant: variant, intent: .commonStep, action: common.action,
            actionArgument: common.actionArgument, animationID: descriptor.animationID,
            common: common, shouldPlayJumpSound: true, sound: descriptor.sound,
            shouldQueueRumble: descriptor.queueRumbleOnLand
                && common.action == descriptor.landAction,
            shouldPlayFlipSounds: descriptor.playFlipSounds,
            shouldDropHeldObject: false
        )
    }

    private static func preemptAction(
        input: SM64MarioBasicAirActionInput,
        flags: SM64MarioInputFlags
    ) -> (action: UInt32, drop: Bool)? {
        switch input.variant {
        case .jump, .doubleJump:
            if let kickOrDiveAction = input.kickOrDiveAction {
                return (kickOrDiveAction, false)
            }
            if flags.contains(.zPressed) {
                return (SM64MarioActionID.groundPound, false)
            }
        case .tripleJump:
            if input.specialTripleJump { return (SM64MarioActionID.flyingTripleJump, false) }
            if flags.contains(.bPressed) { return (SM64MarioActionID.dive, false) }
            if flags.contains(.zPressed) { return (SM64MarioActionID.groundPound, false) }
        case .backflip:
            if flags.contains(.zPressed) { return (SM64MarioActionID.groundPound, false) }
        case .freefall:
            if flags.contains(.bPressed) { return (SM64MarioActionID.dive, false) }
            if flags.contains(.zPressed) { return (SM64MarioActionID.groundPound, false) }
        case .holdJump, .holdFreefall:
            if input.dropRequested { return (SM64MarioActionID.freefall, true) }
            if flags.contains(.bPressed) && !input.heldObjectIsNPC {
                return (SM64MarioActionID.airThrow, false)
            }
            if flags.contains(.zPressed) { return (SM64MarioActionID.groundPound, true) }
        }
        return nil
    }

    private static func animation(
        for input: SM64MarioBasicAirActionInput
    ) -> UInt16 {
        switch input.variant {
        case .jump: return 0x4D
        case .doubleJump: return input.commonInput.velocityY >= 0 ? 0x50 : 0x4C
        case .tripleJump: return 0xC1
        case .backflip: return 0x04
        case .freefall:
            switch input.actionArgument {
            case 0: return 0x56
            case 1: return 0x90
            default: return 0x53
            }
        case .holdJump: return 0x41
        case .holdFreefall: return input.actionArgument == 0 ? 0x43 : 0x44
        }
    }

    private static func descriptor(
        for input: SM64MarioBasicAirActionInput
    ) -> (landAction: UInt32, animationID: UInt16, sound: SM64MarioBasicAirSound,
          queueRumbleOnLand: Bool, playFlipSounds: Bool) {
        switch input.variant {
        case .jump:
            return (SM64MarioActionID.jumpLand, animation(for: input), .terrainJump, false, false)
        case .doubleJump:
            return (SM64MarioActionID.doubleJumpLand, animation(for: input), .hoohoo, false, false)
        case .tripleJump:
            return (SM64MarioActionID.tripleJumpLand, animation(for: input), .yahoo, true, true)
        case .backflip:
            return (SM64MarioActionID.backflipLand, animation(for: input), .yahWahHoo, true, true)
        case .freefall:
            return (SM64MarioActionID.freefallLand, animation(for: input), .none, false, false)
        case .holdJump:
            return (SM64MarioActionID.holdJumpLand, animation(for: input), .terrainJump, false, false)
        case .holdFreefall:
            return (SM64MarioActionID.holdFreefallLand, animation(for: input), .none, false, false)
        }
    }

    private static func commonInput(
        _ input: SM64MarioBasicAirActionInput,
        landAction: UInt32,
        animationID: UInt16
    ) -> SM64MarioCommonAirActionInput {
        let common = input.commonInput
        return SM64MarioCommonAirActionInput(
            landAction: landAction, animationID: animationID,
            input: common.input, intendedMagnitude: common.intendedMagnitude,
            intendedYaw: common.intendedYaw, faceYaw: common.faceYaw,
            forwardVelocity: common.forwardVelocity, velocityY: common.velocityY,
            wallAngle: common.wallAngle, airStep: common.airStep,
            fallDamageOrStuck: common.fallDamageOrStuck,
            horizontalWindActive: common.horizontalWindActive
        )
    }
}
