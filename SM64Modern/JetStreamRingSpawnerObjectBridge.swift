import Foundation

struct SM64JetStreamRingSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64JetStreamRingSpawnerOutput
    let spawnedRing: SM64ObjectID?
}

final class SM64JetStreamRingSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6A7273
    private let ringBridge: SM64JetStreamWaterRingObjectBridge
    private var ringsCollected: [SM64ObjectID: Int32] = [:]
    private var nextRingIndex: [SM64ObjectID: Int32] = [:]
    private(set) var effectLog: [SM64JetStreamRingSpawnerObjectEffectRecord] = []

    init(ringBridge: SM64JetStreamWaterRingObjectBridge) { self.ringBridge = ringBridge }
    var registeredIDs: [SM64ObjectID] { ringsCollected.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Jet Stream ring spawner could not attach") }
        ringsCollected[id] = 0
        nextRingIndex[id] = 0
        return id
    }

    @discardableResult
    func setRingsCollected(_ value: Int32, for id: SM64ObjectID) -> Bool {
        guard ringsCollected[id] != nil else { return false }
        ringsCollected[id] = value
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let record = engineState.objects.record(for: id), let collected = ringsCollected[id], let next = nextRingIndex[id] else { return false }
        let output = SM64JetStreamRingSpawnerBehavior.update(.init(action: record.action, timer: record.timer, nextRingIndex: next, ringsCollected: collected))
        var child: SM64ObjectID?
        if output.spawnRing { child = try? ringBridge.spawnRing(in: engineState, position: record.position, parent: id); if let child { _ = engineState.objects.mutate(child) { $0.behaviorParams = output.ringIndex } } }
        nextRingIndex[id] = output.nextRingIndex
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.behaviorParams = output.nextRingIndex; if output.spawnStar { next.activeParticleFlags |= 1 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output, spawnedRing: child))
        return true
    }

    func remove(_ id: SM64ObjectID) { ringsCollected.removeValue(forKey: id); nextRingIndex.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
