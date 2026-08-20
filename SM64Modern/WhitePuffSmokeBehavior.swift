import Foundation

struct SM64WhitePuffSmokeInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let animationState: Int32
    let initialScale: Float
}

struct SM64WhitePuffSmokeOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let scale: Float
    let animationState: Int32
    let shouldDeactivate: Bool
}

enum SM64WhitePuffSmokeBehavior {
    static func update(_ input: SM64WhitePuffSmokeInput) -> SM64WhitePuffSmokeOutput {
        var position = input.position
        if input.timer == 0 {
            // `ADD_FLOAT(oPosY, -100)` precedes the native initializer.
            position.y -= 100
        }
        return SM64WhitePuffSmokeOutput(
            position: position,
            scale: input.initialScale,
            animationState: input.animationState &+ 1,
            // `BEGIN_REPEAT(10)` runs on timers 0...9, then DEACTIVATE().
            shouldDeactivate: input.timer >= 9
        )
    }
}
