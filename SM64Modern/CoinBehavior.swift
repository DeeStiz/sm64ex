import Foundation

enum SM64CoinKind: UInt8, Equatable, Sendable { case yellow = 0; case temporary = 1 }
struct SM64CoinInput: Equatable, Sendable {
    let kind: SM64CoinKind
    let timer: Int32
    let animationState: Int32
    let interacted: Bool
    let floorDistance: Float
}
struct SM64CoinOutput: Equatable, Sendable {
    let kind: SM64CoinKind
    let timer: Int32
    let animationState: Int32
    let visible: Bool
    let modelNoShadow: Bool
    let spawnGoldenSparkles: Bool
    let shouldDelete: Bool
    let hitboxRadius: Float
    let hitboxHeight: Float
    let damageOrCoinValue: Int32
}
enum SM64CoinBehavior {
    static func update(_ input: SM64CoinInput) -> SM64CoinOutput {
        var visible = true
        var shouldDelete = false
        var sparkles = false
        if input.interacted { sparkles = true; shouldDelete = true }
        if input.kind == .temporary && !input.interacted && input.timer >= 200 {
            let blinking = input.timer - 200
            visible = blinking % 2 == 0
            if blinking / 2 > 20 { shouldDelete = true; visible = false }
        }
        return .init(kind: input.kind, timer: input.timer &+ 1, animationState: input.animationState &+ 1, visible: visible, modelNoShadow: input.floorDistance > 500, spawnGoldenSparkles: sparkles, shouldDelete: shouldDelete, hitboxRadius: 100, hitboxHeight: 64, damageOrCoinValue: 1)
    }
}
