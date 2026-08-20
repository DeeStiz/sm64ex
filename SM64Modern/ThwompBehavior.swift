import Foundation

enum SM64ThwompVariant: UInt8, Equatable, Sendable {
    case grindel = 0
    case thwomp2 = 1
    case thwomp = 2
}

enum SM64ThwompAction: UInt8, Equatable, Sendable {
    case wait = 0
    case startFall = 1
    case falling = 2
    case landed = 3
    case pause = 4
}

struct SM64ThwompInput: Equatable, Sendable {
    let variant: SM64ThwompVariant
    let action: SM64ThwompAction
    let timer: Int32
    let behaviorByte: Int32
    let positionY: Float
    let homeY: Float
    let velocityY: Float
    let distanceToMario: Float
    let randomWaitTimer: Float
    let randomPauseTimer: Float
}

struct SM64ThwompOutput: Equatable, Sendable {
    let variant: SM64ThwompVariant
    let action: SM64ThwompAction
    let timer: Int32
    let positionY: Float
    let velocityY: Float
    let sound: Bool
    let shake: Bool
}

enum SM64ThwompBehavior {
    static func update(_ input: SM64ThwompInput) -> SM64ThwompOutput {
        var action = input.action
        var timer = input.timer
        var positionY = input.positionY
        var velocityY = input.velocityY
        var sound = false
        var shake = false

        switch input.action {
        case .wait:
            if input.behaviorByte + 40 < input.timer {
                action = .startFall
                positionY += 5
            } else {
                positionY += 10
            }
        case .startFall:
            if Float(input.timer) > input.randomWaitTimer {
                action = .falling
            }
        case .falling:
            velocityY -= 4
            positionY += velocityY
            if positionY < input.homeY {
                positionY = input.homeY
                velocityY = 0
                action = .landed
            }
        case .landed:
            if input.timer == 0 && input.distanceToMario < 1500 {
                sound = true
                shake = true
            }
            if input.timer > 9 {
                action = .pause
            }
        case .pause:
            if Float(input.timer) > input.randomPauseTimer {
                action = .wait
            }
        }

        timer = action == input.action ? input.timer &+ 1 : 0
        return SM64ThwompOutput(
            variant: input.variant,
            action: action,
            timer: timer,
            positionY: positionY,
            velocityY: velocityY,
            sound: sound,
            shake: shake
        )
    }
}
