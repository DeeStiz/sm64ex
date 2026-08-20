import Foundation

struct SM64OrangeNumberInput: Equatable, Sendable {
    let timer: Int32
    let animationState: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
}

struct SM64OrangeNumberOutput: Equatable, Sendable {
    let timer: Int32
    let animationState: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
    let shouldDelete: Bool
    let spawnGoldenSparkles: Bool
}

enum SM64OrangeNumberBehavior {
    static func update(_ input: SM64OrangeNumberInput) -> SM64OrangeNumberOutput {
        var position = input.position
        position.y += input.velocityY
        var velocityY = input.velocityY - 2
        if velocityY < -21 { velocityY = 14 }
        return .init(
            timer: input.timer &+ 1,
            animationState: input.animationState,
            position: position,
            velocityY: velocityY,
            shouldDelete: input.timer == 35,
            spawnGoldenSparkles: input.timer == 35
        )
    }
}
