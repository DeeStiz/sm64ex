import Foundation

struct SM64TriangleParticleSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TriangleParticleSpawnerOutput
    let spawnedChildren: [SM64ObjectID]
}

final class SM64TriangleParticleSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_747270
    private struct State { let particleFlag: UInt32; let seeds: [SM64TinyStarParticleSeed]; let marioPosition: SM64ObjectVector3; let marioYaw: Int32 }
    private let particleBridge: SM64TriangleParticleObjectBridge
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TriangleParticleSpawnerObjectEffectRecord] = []
    init(particleBridge: SM64TriangleParticleObjectBridge) { self.particleBridge = particleBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, activeParticleFlags: UInt32 = 0, particleFlag: UInt32 = 0x1, seeds: [SM64TinyStarParticleSeed] = [], marioPosition: SM64ObjectVector3 = .zero, marioYaw: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, activeParticleFlags: activeParticleFlags, particleFlag: particleFlag, seeds: seeds, marioPosition: marioPosition, marioYaw: marioYaw, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned triangle particle spawner could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, activeParticleFlags: UInt32, particleFlag: UInt32, seeds: [SM64TinyStarParticleSeed], marioPosition: SM64ObjectVector3, marioYaw: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(particleFlag: particleFlag, seeds: seeds, marioPosition: marioPosition, marioYaw: marioYaw)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.activeParticleFlags = activeParticleFlags; record.graphFlags |= 0x10; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64TriangleParticleSpawnerObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64TriangleParticleSpawnerBehavior.update(.init(position: record.position, timer: record.timer, activeParticleFlags: record.activeParticleFlags, particleFlag: state.particleFlag, seeds: state.seeds))
        var children: [SM64ObjectID] = []
        if output.shouldSpawnChildren { for seed in output.seeds { if let child = try? particleBridge.spawnParticle(in: engineState, position: record.position, marioPosition: state.marioPosition, marioYaw: state.marioYaw, moveYaw: seed.moveYaw, forwardVelocity: seed.forwardVelocity, velocityY: seed.velocityY) { children.append(child) } } }
        _ = engineState.objects.mutate(id) { next in if output.clearParticleFlag { next.activeParticleFlags &= ~state.particleFlag }; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle }
        let effect = SM64TriangleParticleSpawnerObjectEffectRecord(objectID: id, output: output, spawnedChildren: children); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
