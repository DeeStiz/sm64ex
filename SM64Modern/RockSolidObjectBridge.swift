import Foundation

struct SM64RockSolidObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64RockSolidOutput }
final class SM64RockSolidObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_726F63
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64RockSolidObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned rock-solid object could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.collisionDistance = 1000; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64RockSolidBehavior.update(.init(timer: record.timer))
        _ = engineState.objects.mutate(id) { next in next.timer = output.timer }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
