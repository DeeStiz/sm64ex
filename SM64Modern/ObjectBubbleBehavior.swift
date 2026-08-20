import Foundation

struct SM64ObjectBubbleInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let waterLevel: Float
}

struct SM64ObjectBubbleOutput: Equatable, Sendable {
    let shouldDeactivate: Bool
    let spawnSplash: Bool
}

/// Value counterpart of `bhv_object_bubble_loop`.
enum SM64ObjectBubbleBehavior {
    static func update(_ input: SM64ObjectBubbleInput) -> SM64ObjectBubbleOutput {
        let aboveWater = input.position.y > input.waterLevel
        return SM64ObjectBubbleOutput(shouldDeactivate: aboveWater, spawnSplash: aboveWater)
    }
}
