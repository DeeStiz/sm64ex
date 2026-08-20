import Foundation

enum SM64BompVariant: UInt8, Equatable, Sendable {
    case small = 0
    case large = 1
}

enum SM64BompAction: UInt8, Equatable, Sendable {
    case wait = 0
    case pokeOut = 1
    case extend = 2
    case retract = 3
}

struct SM64BompInput: Equatable, Sendable {
    let variant: SM64BompVariant
    let action: SM64BompAction
    let timer: Int32
    let position: SM64ObjectVector3
    let forwardVelocity: Float
    let moveYaw: Int32
}

struct SM64BompOutput: Equatable, Sendable {
    let variant: SM64BompVariant
    let action: SM64BompAction
    let timer: Int32
    let position: SM64ObjectVector3
    let forwardVelocity: Float
    let moveYaw: Int32
    let sound: Bool
    let clamped: Bool
}

enum SM64BompBehavior {
    static let waitThreshold: Int32 = 101
    static let pokeOutBoundary: Float = 3_450
    static let extendBoundary: Float = 3_830
    static let retractBoundary: Float = 3_330

    static func update(_ input: SM64BompInput) -> SM64BompOutput {
        var action = input.action
        var timer = input.timer
        var position = input.position
        var forwardVelocity = input.forwardVelocity
        var moveYaw = input.moveYaw
        var sound = false
        var clamped = false

        switch input.action {
        case .wait:
            if input.timer >= waitThreshold {
                action = .pokeOut
                forwardVelocity = 30
            }
        case .pokeOut:
            if position.x > pokeOutBoundary {
                position.x = pokeOutBoundary
                forwardVelocity = 0
                clamped = true
            }
            if input.timer == 15 {
                action = .extend
                forwardVelocity = input.variant == .small ? 40 : 10
                sound = true
            }
        case .extend:
            if position.x > extendBoundary {
                position.x = extendBoundary
                forwardVelocity = 0
                clamped = true
            }
            if input.timer == 60 {
                action = .retract
                forwardVelocity = 10
                moveYaw &-= 0x8000
                sound = true
            }
        case .retract:
            if position.x < retractBoundary {
                position.x = retractBoundary
                forwardVelocity = 0
                clamped = true
            }
            if input.timer == 90 {
                action = .pokeOut
                forwardVelocity = 25
                moveYaw &-= 0x8000
            }
        }

        if action != input.action { timer = 0 }
        else { timer = input.timer &+ 1 }

        return SM64BompOutput(
            variant: input.variant,
            action: action,
            timer: timer,
            position: position,
            forwardVelocity: forwardVelocity,
            moveYaw: moveYaw,
            sound: sound,
            clamped: clamped
        )
    }
}
