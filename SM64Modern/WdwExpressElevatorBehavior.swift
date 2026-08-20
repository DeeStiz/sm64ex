import Foundation

enum SM64WdwExpressElevatorKind: UInt8, Equatable, Sendable {
    case elevator = 0
    case staticPlatform = 1
}

struct SM64WdwExpressElevatorInput: Equatable, Sendable {
    let kind: SM64WdwExpressElevatorKind
    let action: Int32
    let timer: Int32
    let positionY: Float
    let homeY: Float
    let marioOnPlatform: Bool
}

struct SM64WdwExpressElevatorOutput: Equatable, Sendable {
    let action: Int32
    let positionY: Float
    let velocityY: Float
    let playedSound: Bool
}

/// Value counterpart of `bhv_wdw_express_elevator_loop`; the alternate
/// surface identity is an explicit source no-op.
enum SM64WdwExpressElevatorBehavior {
    static func update(_ input: SM64WdwExpressElevatorInput)
        -> SM64WdwExpressElevatorOutput
    {
        guard input.kind == .elevator else {
            return SM64WdwExpressElevatorOutput(
                action: input.action,
                positionY: input.positionY,
                velocityY: 0,
                playedSound: false
            )
        }
        var action = input.action
        var positionY = input.positionY
        var velocityY: Float = 0
        var playedSound = false
        switch input.action {
        case 0:
            if input.marioOnPlatform { action = 1 }
        case 1:
            velocityY = -20
            positionY += velocityY
            playedSound = true
            if input.timer > 132 { action = 2 }
        case 2:
            if input.timer > 110 { action = 3 }
        case 3:
            velocityY = 10
            positionY += velocityY
            playedSound = true
            if positionY >= input.homeY {
                positionY = input.homeY
                action += 1
            }
        default:
            if !input.marioOnPlatform { action = 0 }
        }
        return SM64WdwExpressElevatorOutput(
            action: action,
            positionY: positionY,
            velocityY: velocityY,
            playedSound: playedSound
        )
    }
}
