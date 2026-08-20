import Foundation

struct SM64SparkleSpawnerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let randomOffset: SM64ObjectVector3
    let randomScale: Float
}

struct SM64SparkleSpawnerOutput: Equatable, Sendable {
    let childPosition: SM64ObjectVector3
    let childScale: Float
    let shouldSpawnSparkle: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_sparkle_spawn_loop`.
enum SM64SparkleSpawnerBehavior {
    static func update(_ input: SM64SparkleSpawnerInput) -> SM64SparkleSpawnerOutput {
        SM64SparkleSpawnerOutput(
            childPosition: SM64ObjectVector3(
                x: input.position.x + input.randomOffset.x,
                y: input.position.y + input.randomOffset.y,
                z: input.position.z + input.randomOffset.z
            ),
            childScale: input.randomScale,
            shouldSpawnSparkle: true,
            shouldDeactivate: input.timer > 1
        )
    }
}
