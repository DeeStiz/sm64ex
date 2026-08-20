import Foundation

struct SM64MistParticleSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64MistParticleSpawnerOutput
    let spawnedPuff1: SM64ObjectID?
    let spawnedPuff2: SM64ObjectID?
}

final class SM64MistParticleSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6D707331
    static let particleFlag: UInt32 = 1 << 0
    private let puffBridge: SM64MistParticleObjectBridge?
    private var states: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64MistParticleSpawnerObjectEffectRecord] = []
    init(puffBridge: SM64MistParticleObjectBridge? = nil) { self.puffBridge = puffBridge }
    var registeredIDs: [SM64ObjectID] { states.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, activeParticleFlags: UInt32 = SM64MistParticleSpawnerObjectBridge.particleFlag) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, activeParticleFlags: activeParticleFlags, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned mist spawner could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, activeParticleFlags: UInt32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states.insert(id)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.activeParticleFlags = activeParticleFlags; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64MistParticleSpawnerObjectEffectRecord? {
        guard states.contains(id), let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64MistParticleSpawnerBehavior.update(SM64MistParticleSpawnerInput(position: record.position, timer: record.timer, activeParticleFlags: record.activeParticleFlags, particleFlag: Self.particleFlag))
        var puff1: SM64ObjectID?
        var puff2: SM64ObjectID?
        if output.spawnPuff1 { puff1 = try? engineState.spawnObject(in: .default, behaviorIdentity: SM64MistParticleObjectBridge.puff1BehaviorIdentity, parent: id); if let puff1 { _ = puffBridge?.attach(puff1, kind: .puff1, position: output.position, initialOffsetX: 0, initialOffsetZ: 0, moveYaw: 0, forwardVelocity: 0, velocityY: 0, in: engineState.objects) } }
        if output.spawnPuff2 { puff2 = try? engineState.spawnObject(in: .unimportant, behaviorIdentity: SM64MistParticleObjectBridge.puff2BehaviorIdentity, parent: id); if let puff2 { _ = puffBridge?.attach(puff2, kind: .puff2, position: output.position, initialOffsetX: 0, initialOffsetZ: 0, moveYaw: 0, forwardVelocity: 0, velocityY: 0, in: engineState.objects) } }
        _ = engineState.objects.mutate(id) { next in if output.clearParticleFlag { next.activeParticleFlags &= ~Self.particleFlag }; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 } }
        let effect = SM64MistParticleSpawnerObjectEffectRecord(objectID: id, output: output, spawnedPuff1: puff1, spawnedPuff2: puff2); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
