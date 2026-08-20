import Foundation

struct SM64CoinSparklesInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let animationState: Int32
}

struct SM64CoinSparklesOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let animationState: Int32
    let graphYOffset: Float
    let scale: Float
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhvCoinSparkles`.
enum SM64CoinSparklesBehavior {
    static func update(_ input: SM64CoinSparklesInput) -> SM64CoinSparklesOutput {
        SM64CoinSparklesOutput(
            position: input.position,
            animationState: input.animationState &+ 8,
            graphYOffset: 25,
            scale: 0.6,
            shouldDeactivate: true
        )
    }
}
