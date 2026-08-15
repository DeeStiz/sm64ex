import Foundation

enum SM64ElevatorSound: UInt8, Equatable, Sendable {
    case movement = 1
    case quietPound = 2
    case metalPound = 3
}

struct SM64ElevatorInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let positionY: Float
    let velocityY: Float
    let bottomY: Float
    let topY: Float
    let midpointY: Float
    /// Matches `oElevatorUnk100`: 0 for standard, 1 for RR, 2 for custom.
    let platformKind: UInt32
    let marioPositionY: Float
    let marioOnPlatform: Bool
    let marioInAirAction: Bool
}

struct SM64ElevatorOutput: Equatable, Sendable {
    let action: Int32
    let positionY: Float
    let velocityY: Float
    let sound: SM64ElevatorSound?
    let shakeSmall: Bool
}

/// Value counterpart of `elevator_act_0...4` and their observable intents.
/// Timer advancement and object-list ownership remain with the scheduler.
enum SM64ElevatorBehavior {
    static func update(_ input: SM64ElevatorInput) -> SM64ElevatorOutput {
        var action = input.action
        var positionY = input.positionY
        var velocityY = input.velocityY
        var sound: SM64ElevatorSound?
        var shakeSmall = false

        switch input.action {
        case 0:
            velocityY = 0
            if input.platformKind == 2 {
                if input.marioOnPlatform {
                    action = positionY > input.midpointY ? 2 : 1
                }
            } else if input.marioPositionY > input.midpointY || input.platformKind == 1 {
                positionY = input.topY
                if input.marioOnPlatform { action = 2 }
            } else {
                positionY = input.bottomY
                if input.marioOnPlatform { action = 1 }
            }
        case 1:
            sound = .movement
            if input.timer == 0 && input.marioOnPlatform {
                sound = .quietPound
                shakeSmall = true
            }
            velocityY = approachSigned(value: velocityY, target: 10, increment: 2)
            positionY += velocityY
            if positionY > input.topY {
                positionY = input.topY
                if input.platformKind == 2 || input.platformKind == 1 {
                    action = 3
                } else if input.marioPositionY < input.midpointY {
                    action = 2
                } else {
                    action = 3
                }
            }
        case 2:
            sound = .movement
            if input.timer == 0 && input.marioOnPlatform {
                sound = .quietPound
                shakeSmall = true
            }
            velocityY = approachSigned(value: velocityY, target: -10, increment: -2)
            positionY += velocityY
            if positionY < input.bottomY {
                positionY = input.bottomY
                if input.platformKind == 1 {
                    action = 4
                } else if input.platformKind == 2 {
                    action = 3
                } else if input.marioPositionY > input.midpointY {
                    action = 1
                } else {
                    action = 3
                }
            }
        case 3:
            velocityY = 0
            if input.timer == 0 {
                sound = .metalPound
                shakeSmall = true
            }
            if !input.marioInAirAction && !input.marioOnPlatform {
                action = 0
            }
        case 4:
            velocityY = 0
            if input.timer == 0 {
                sound = .metalPound
                shakeSmall = true
            }
            if !input.marioInAirAction && !input.marioOnPlatform {
                action = 1
            }
        default:
            break
        }

        return SM64ElevatorOutput(
            action: action,
            positionY: positionY,
            velocityY: velocityY,
            sound: sound,
            shakeSmall: shakeSmall
        )
    }

    private static func approachSigned(
        value: Float,
        target: Float,
        increment: Float
    ) -> Float {
        var result = value + increment
        if increment >= 0 {
            if result > target { result = target }
        } else if result < target {
            result = target
        }
        return result
    }
}
