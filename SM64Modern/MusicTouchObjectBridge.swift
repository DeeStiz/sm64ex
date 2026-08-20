import Foundation

struct SM64MusicTouchObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64MusicTouchOutput }
final class SM64MusicTouchObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6D7470
    private var distances: [SM64ObjectID: Float] = [:]; private(set) var effectLog: [SM64MusicTouchObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { distances.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, distanceToMario: Float = 10_000, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID { let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity); guard attach(id, distanceToMario: distanceToMario, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned music-touch object could not attach") }; return id }
    @discardableResult
    func attach(_ id: SM64ObjectID, distanceToMario: Float, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool { guard pool.record(for: id) != nil else { return false }; distances[id] = distanceToMario; return pool.mutate(id) { record in record.position = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform } }
    @discardableResult
    func setDistance(_ distance: Float, for id: SM64ObjectID) -> Bool { guard distances[id] != nil else { return false }; distances[id] = distance; return true }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool { guard let distance = distances[id], let record = engineState.objects.record(for: id) else { return false }; let output = SM64MusicTouchBehavior.update(.init(action: record.action, timer: record.timer, distanceToMario: distance)); _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer }; effectLog.append(.init(objectID: id, output: output)); return true }
    func remove(_ id: SM64ObjectID) { distances.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
