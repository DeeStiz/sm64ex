import Foundation

struct SM64GoldenCoinSparklesInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let randomOffsets: [SM64ObjectVector3]
}

struct SM64GoldenCoinSparklesOutput: Equatable, Sendable {
    let childPositions: [SM64ObjectVector3]
    let shouldSpawnChildren: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhvGoldenCoinSparkles` and its three native calls.
enum SM64GoldenCoinSparklesBehavior {
    static func update(_ input: SM64GoldenCoinSparklesInput) -> SM64GoldenCoinSparklesOutput {
        let childPositions = input.randomOffsets.map { offset in
            SM64ObjectVector3(
                x: input.position.x + offset.x,
                y: input.position.y + offset.y,
                z: input.position.z + offset.z
            )
        }
        return SM64GoldenCoinSparklesOutput(
            childPositions: childPositions,
            shouldSpawnChildren: !childPositions.isEmpty,
            shouldDeactivate: true
        )
    }
}
