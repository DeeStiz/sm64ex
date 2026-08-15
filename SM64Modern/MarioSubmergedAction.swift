import Foundation

enum SM64MarioSubmergedVariant: UInt8, Equatable, Sendable {
    case waterIdle = 0
    case holdWaterIdle = 1
    case waterActionEnd = 2
    case holdWaterActionEnd = 3
    case drowning = 4
    case waterDeath = 5
    case waterShocked = 6
}

enum SM64MarioSubmergedIntent: UInt8, Equatable, Sendable {
    case continueAction = 0
    case metalWaterFall = 1
    case waterPunch = 2
    case waterThrow = 3
    case breaststroke = 4
    case holdBreaststroke = 5
    case waterIdle = 6
    case holdWaterIdle = 7
    case waterDeath = 8
    case deathWarp = 9
}

enum SM64MarioSubmergedEyeState: UInt8, Equatable, Sendable {
    case unchanged = 0
    case halfClosed = 1
    case dead = 2
}

struct SM64MarioSubmergedActionInput: Equatable, Sendable {
    let variant: SM64MarioSubmergedVariant
    let input: SM64MarioInputFlags
    let actionArgument: UInt32
    let actionTimer: UInt16
    let actionState: UInt8
    let animationReturnValue: Int16
    let animationFrame: Int16
    let animationPastEnd: Bool
    let facePitch: Int16
    let metalCap: Bool
    let dropObjectRequested: Bool
    let health: UInt16
}

struct SM64MarioSubmergedActionResult: Equatable, Sendable {
    let variant: SM64MarioSubmergedVariant
    let intent: SM64MarioSubmergedIntent
    let action: UInt32?
    let actionArgument: UInt32
    let actionTimer: UInt16
    let actionState: UInt8
    let animationID: UInt16
    let animationAcceleration: Int32
    let eyeState: SM64MarioSubmergedEyeState
    let shouldDropHeldObject: Bool
    let shouldSetMetalShock: Bool
    let shouldSetInvincibilityTimer: Bool
    let shouldPlayWaterStep: Bool
    let shouldPlayDrowningSound: Bool
    let shouldPlayShockSound: Bool
    let shouldSetCameraShake: Bool
    let shouldTriggerDeathWarp: Bool
}

/// Value state-machine counterpart of the first submerged action family.
/// Water collision/step, buoyancy, object interaction, camera effects, audio,
/// and animation installation are owner-thread effects; action priority and
/// state transitions are deterministic here.
enum SM64MarioSubmergedAction {
    private static let waterIdleAnimation: UInt16 = 0xB2
    private static let holdWaterIdleAnimation: UInt16 = 0xA4
    private static let waterActionEndAnimation: UInt16 = 0xAD
    private static let holdWaterActionEndAnimation: UInt16 = 0xA2
    private static let holdWaterGrabEndAnimation: UInt16 = 0xA3
    private static let drowningPart1Animation: UInt16 = 0xA5
    private static let drowningPart2Animation: UInt16 = 0xA6
    private static let waterDyingAnimation: UInt16 = 0xA7
    private static let shockedAnimation: UInt16 = 0x7A

    static func update(
        _ input: SM64MarioSubmergedActionInput
    ) -> SM64MarioSubmergedActionResult? {
        switch input.variant {
        case .waterIdle, .holdWaterIdle:
            return updateWaterIdle(input)
        case .waterActionEnd, .holdWaterActionEnd:
            return updateWaterActionEnd(input)
        case .drowning:
            return updateDrowning(input)
        case .waterDeath:
            return updateWaterDeath(input)
        case .waterShocked:
            return updateWaterShocked(input)
        }
    }

    private static func updateWaterIdle(
        _ input: SM64MarioSubmergedActionInput
    ) -> SM64MarioSubmergedActionResult {
        let held = input.variant == .holdWaterIdle
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
                input, intent: .waterIdle, action: SM64MarioActionID.waterIdle,
                shouldDropHeldObject: true
            )
        }
        if input.input.contains(.bPressed) {
            return transition(
                input, intent: held ? .waterThrow : .waterPunch,
                action: held ? SM64MarioActionID.waterThrow : SM64MarioActionID.waterPunch
            )
        }
        if input.input.contains(.aPressed) {
            return transition(
                input, intent: held ? .holdBreaststroke : .breaststroke,
                action: held ? SM64MarioActionID.holdBreaststroke
                    : SM64MarioActionID.breaststroke
            )
        }
        return baseResult(
            input, intent: .continueAction, action: nil, argument: 0,
            animationID: held ? Self.holdWaterIdleAnimation : Self.waterIdleAnimation,
            animationAcceleration: held ? 0 : (input.facePitch < -0x1000 ? 0x30000 : 0x10000)
        )
    }

    private static func updateWaterActionEnd(
        _ input: SM64MarioSubmergedActionInput
    ) -> SM64MarioSubmergedActionResult {
        let held = input.variant == .holdWaterActionEnd
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
                input, intent: .waterIdle, action: SM64MarioActionID.waterIdle,
                shouldDropHeldObject: true
            )
        }
        if input.input.contains(.bPressed) {
            return transition(
                input, intent: held ? .waterThrow : .waterPunch,
                action: held ? SM64MarioActionID.waterThrow : SM64MarioActionID.waterPunch
            )
        }
        if input.input.contains(.aPressed) {
            return transition(
                input, intent: held ? .holdBreaststroke : .breaststroke,
                action: held ? SM64MarioActionID.holdBreaststroke
                    : SM64MarioActionID.breaststroke
            )
        }
        if input.animationPastEnd {
            return transition(
                input, intent: held ? .holdWaterIdle : .waterIdle,
                action: held ? SM64MarioActionID.holdWaterIdle
                    : SM64MarioActionID.waterIdle
            )
        }
        let animation: UInt16
        if held {
            animation = input.actionArgument == 0
                ? Self.holdWaterActionEndAnimation : Self.holdWaterGrabEndAnimation
        } else {
            animation = Self.waterActionEndAnimation
        }
        return baseResult(
            input, intent: .continueAction, action: nil, argument: input.actionArgument,
            animationID: animation, animationAcceleration: 0
        )
    }

    private static func updateDrowning(
        _ input: SM64MarioSubmergedActionInput
    ) -> SM64MarioSubmergedActionResult {
        let secondPart = input.actionState != 0 || input.animationPastEnd
        let actionState: UInt8 = secondPart ? 1 : 0
        let animationID = secondPart ? Self.drowningPart2Animation : Self.drowningPart1Animation
        let deathWarp = secondPart && input.animationFrame == 30
        return baseResult(
            input, intent: deathWarp ? .deathWarp : .continueAction,
            action: nil, argument: 0, animationID: animationID,
            animationAcceleration: 0, actionTimer: input.actionTimer,
            actionState: actionState, eyeState: secondPart ? .dead : .halfClosed,
            shouldPlayDrowningSound: true, shouldTriggerDeathWarp: deathWarp
        )
    }

    private static func updateWaterDeath(
        _ input: SM64MarioSubmergedActionInput
    ) -> SM64MarioSubmergedActionResult {
        let deathWarp = input.animationFrame == 35
        return baseResult(
            input, intent: deathWarp ? .deathWarp : .continueAction,
            action: nil, argument: 0, animationID: Self.waterDyingAnimation,
            animationAcceleration: 0, eyeState: .dead,
            shouldTriggerDeathWarp: deathWarp
        )
    }

    private static func updateWaterShocked(
        _ input: SM64MarioSubmergedActionInput
    ) -> SM64MarioSubmergedActionResult {
        var actionTimer = input.actionTimer
        var action: UInt32?
        var intent: SM64MarioSubmergedIntent = .continueAction
        var setMetalShock = false
        if input.animationReturnValue == 0 {
            actionTimer &+= 1
            setMetalShock = true
        }
        if actionTimer >= 6 {
            intent = input.health < 0x100 ? .waterDeath : .waterIdle
            action = input.health < 0x100
                ? SM64MarioActionID.waterDeath : SM64MarioActionID.waterIdle
        }
        return baseResult(
            input, intent: intent, action: action, argument: 0,
            animationID: Self.shockedAnimation, animationAcceleration: 0,
            actionTimer: actionTimer, actionState: input.actionState,
            shouldSetMetalShock: setMetalShock,
            shouldSetInvincibilityTimer: actionTimer >= 6,
            shouldPlayShockSound: true, shouldSetCameraShake: true
        )
    }

    private static func transition(
        _ input: SM64MarioSubmergedActionInput,
        intent: SM64MarioSubmergedIntent,
        action: UInt32,
        argument: UInt32 = 0,
        shouldDropHeldObject: Bool = false
    ) -> SM64MarioSubmergedActionResult {
        baseResult(
            input, intent: intent, action: action, argument: argument,
            animationID: 0, animationAcceleration: 0,
            shouldDropHeldObject: shouldDropHeldObject
        )
    }

    private static func baseResult(
        _ input: SM64MarioSubmergedActionInput,
        intent: SM64MarioSubmergedIntent,
        action: UInt32?,
        argument: UInt32,
        animationID: UInt16,
        animationAcceleration: Int32,
        actionTimer: UInt16? = nil,
        actionState: UInt8? = nil,
        eyeState: SM64MarioSubmergedEyeState = .unchanged,
        shouldDropHeldObject: Bool = false,
        shouldSetMetalShock: Bool = false,
        shouldSetInvincibilityTimer: Bool = false,
        shouldPlayDrowningSound: Bool = false,
        shouldPlayShockSound: Bool = false,
        shouldSetCameraShake: Bool = false,
        shouldTriggerDeathWarp: Bool = false
    ) -> SM64MarioSubmergedActionResult {
        SM64MarioSubmergedActionResult(
            variant: input.variant, intent: intent, action: action,
            actionArgument: argument, actionTimer: actionTimer ?? input.actionTimer,
            actionState: actionState ?? input.actionState, animationID: animationID,
            animationAcceleration: animationAcceleration, eyeState: eyeState,
            shouldDropHeldObject: shouldDropHeldObject,
            shouldSetMetalShock: shouldSetMetalShock,
            shouldSetInvincibilityTimer: shouldSetInvincibilityTimer,
            shouldPlayWaterStep: true,
            shouldPlayDrowningSound: shouldPlayDrowningSound,
            shouldPlayShockSound: shouldPlayShockSound,
            shouldSetCameraShake: shouldSetCameraShake,
            shouldTriggerDeathWarp: shouldTriggerDeathWarp
        )
    }
}
