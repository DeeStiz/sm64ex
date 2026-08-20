import Foundation

struct SM64TreeParticleSpawnerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let activeParticleFlags: UInt32
    let particleFlag: UInt32
    let snowMode: Bool
    let spawnDecision: Float
    let randomScale: Float
    let randomYaw: Int32
    let randomForwardUnit: Float
    let randomVerticalUnit: Float
    let randomFacePitch: Int32
    let randomFaceRoll: Int32
}

struct SM64TreeParticleSpawnerOutput: Equatable, Sendable {
    let childKind: SM64TreeParticleKind?
    let childPosition: SM64ObjectVector3
    let childScale: Float
    let childMoveYaw: Int32
    let childForwardVelocity: Float
    let childVelocityY: Float
    let childFacePitch: Int32
    let childFaceRoll: Int32
    let clearParticleFlag: Bool
    let shouldSpawnChild: Bool
    let shouldDeactivate: Bool
}

enum SM64TreeParticleSpawnerBehavior {
    static func update(_ input: SM64TreeParticleSpawnerInput) -> SM64TreeParticleSpawnerOutput {
        let firstTick = input.timer == 0
        let shouldSpawn = firstTick && (input.snowMode ? input.spawnDecision < 0.5 : input.spawnDecision < 0.3)
        let kind: SM64TreeParticleKind? = shouldSpawn ? (input.snowMode ? .snow : .leaf) : nil
        let scale = input.snowMode ? input.randomScale : input.randomScale * 3
        let forwardVelocity = input.snowMode ? input.randomForwardUnit * 5 : input.randomForwardUnit * 5 + 5
        return SM64TreeParticleSpawnerOutput(
            childKind: kind,
            childPosition: input.position,
            childScale: scale,
            childMoveYaw: input.randomYaw,
            childForwardVelocity: forwardVelocity,
            childVelocityY: input.randomVerticalUnit * 15,
            childFacePitch: input.snowMode ? 0 : input.randomFacePitch,
            childFaceRoll: input.snowMode ? 0 : input.randomFaceRoll,
            clearParticleFlag: firstTick && (input.activeParticleFlags & input.particleFlag != 0),
            shouldSpawnChild: shouldSpawn,
            shouldDeactivate: input.timer >= 1
        )
    }
}
