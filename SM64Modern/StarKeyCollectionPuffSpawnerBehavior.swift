import Foundation

struct SM64StarKeyPuffSeed: Equatable, Sendable {
    let velocity: SM64ObjectVector3
    let scale: Float
}

struct SM64StarKeyCollectionPuffSpawnerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let seeds: [SM64StarKeyPuffSeed]
}

struct SM64StarKeyCollectionPuffSpawnerOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let seeds: [SM64StarKeyPuffSeed]
    let spawnPuffs: Bool
    let shouldDeactivate: Bool
}

enum SM64StarKeyCollectionPuffSpawnerBehavior {
    static func update(_ input: SM64StarKeyCollectionPuffSpawnerInput) -> SM64StarKeyCollectionPuffSpawnerOutput {
        SM64StarKeyCollectionPuffSpawnerOutput(
            position: input.position,
            seeds: input.seeds,
            // Source `spawn_mist_particles_variable(0, 10, 30)` is one-shot.
            spawnPuffs: input.timer == 0,
            shouldDeactivate: input.timer >= 0
        )
    }
}
