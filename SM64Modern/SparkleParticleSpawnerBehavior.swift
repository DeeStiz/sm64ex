import Foundation

struct SM64SparkleParticleSpawnerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let animationState: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
    let randomOffset: SM64ObjectVector3
}

struct SM64SparkleParticleSpawnerOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let animationState: Int32
    let graphYOffset: Float
    let clearParticleFlag: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhvSparkleParticleSpawner`.
enum SM64SparkleParticleSpawnerBehavior {
    static func update(_ input: SM64SparkleParticleSpawnerInput) -> SM64SparkleParticleSpawnerOutput {
        let firstTick = input.timer == 0
        var position = input.position
        var animationState = input.animationState
        if firstTick {
            position.x += input.randomOffset.x
            position.y += input.randomOffset.y
            position.z += input.randomOffset.z
            animationState = -1
        }
        animationState &+= 1
        return SM64SparkleParticleSpawnerOutput(
            position: position,
            animationState: animationState,
            graphYOffset: 25,
            clearParticleFlag: firstTick && (input.activeParticleFlags & input.particleFlag != 0),
            shouldDeactivate: input.timer >= 11
        )
    }
}
