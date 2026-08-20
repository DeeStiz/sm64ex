import Foundation

struct SM64BlackSmokeUpwardInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let scale: Float
    let timer: Int32
}

struct SM64BlackSmokeUpwardOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let scale: Float
    let spawnChild: Bool
    let shouldDeactivate: Bool
}

enum SM64BlackSmokeUpwardBehavior {
    static func update(_ input: SM64BlackSmokeUpwardInput) -> SM64BlackSmokeUpwardOutput {
        SM64BlackSmokeUpwardOutput(
            position: input.position,
            scale: input.scale,
            // Source `BEGIN_REPEAT(4)` emits one child on timers 0...3.
            spawnChild: input.timer < 4,
            shouldDeactivate: input.timer >= 3
        )
    }
}
