import Foundation

enum SM64ClamShellAction: Int32, Equatable, Sendable { case closed = 0; case opening = 1 }

struct SM64ClamShellInput: Equatable, Sendable {
    let action: SM64ClamShellAction
    let timer: Int32
    let shakeTimer: Int32
    let distanceToMario: Float
    let animationFrame25: Bool
    let animationFrame8: Bool
    let animationFrame30: Bool
    let renderingEnabled: Bool
}

struct SM64ClamShellOutput: Equatable, Sendable {
    let action: SM64ClamShellAction
    let timer: Int32
    let shakeTimer: Int32
    let scale: SM64ObjectVector3
    let tangible: Bool
    let shakeY: Float
    let spawnBubbleCount: Int
}

enum SM64ClamShellBehavior {
    static func update(_ input: SM64ClamShellInput) -> SM64ClamShellOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var shakeTimer = input.shakeTimer
        var tangible = false
        var shakeY: Float = 0
        var bubbles = 0

        switch input.action {
        case .closed:
            if input.animationFrame25 {
                tangible = true
                shakeTimer = 10
                timer = 0
            } else if input.timer > 150 && input.distanceToMario < 500 {
                action = .opening
                timer = 0
            } else if shakeTimer > 0 {
                shakeTimer -= 1
                shakeY = 3
            }
        case .opening:
            if input.timer > 150 {
                action = .closed
                timer = 0
            } else if input.renderingEnabled && input.animationFrame8 {
                bubbles = 12
            } else if input.animationFrame30 {
                tangible = false
            }
        }

        return .init(
            action: action,
            timer: timer,
            shakeTimer: shakeTimer,
            scale: .init(x: 1, y: 1.5, z: 1),
            tangible: tangible,
            shakeY: shakeY,
            spawnBubbleCount: bubbles
        )
    }
}
