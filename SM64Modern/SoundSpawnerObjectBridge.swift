import Foundation

struct SM64SoundSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SoundSpawnerOutput
}

final class SM64SoundSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_736E64
    private var soundIDs: [SM64ObjectID: Int32] = [:]
    private(set) var effectLog: [SM64SoundSpawnerObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { soundIDs.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, soundID: Int32 = 0, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, soundID: soundID, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned sound spawner could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, soundID: Int32, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        soundIDs[id] = soundID
        return pool.mutate(id) { record in record.position = position; record.soundStateID = soundID; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let soundID = soundIDs[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64SoundSpawnerBehavior.update(.init(timer: record.timer, soundID: soundID))
        _ = engineState.objects.mutate(id) { next in next.timer = output.timer; if output.shouldDelete { next.activeFlags = 0 } }
        effectLog.append(.init(objectID: id, output: output)); return true
    }

    func remove(_ id: SM64ObjectID) { soundIDs.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
