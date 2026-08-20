import Foundation

struct SM64CastleCannonGrateObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64CastleCannonGrateOutput }

final class SM64CastleCannonGrateObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6331_3230
    private var starCounts: [SM64ObjectID: Int32] = [:]
    private(set) var effectLog: [SM64CastleCannonGrateObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { starCounts.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult func spawn(in engineState: SM64SwiftEngineState, totalStarCount: Int32 = 0, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID { let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity); guard attach(id, totalStarCount: totalStarCount, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned cannon grate could not attach") }; return id }
    @discardableResult func attach(_ id: SM64ObjectID, totalStarCount: Int32, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool { guard pool.record(for: id) != nil else { return false }; starCounts[id] = totalStarCount; return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.collisionDistance = 4_000; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform } }
    @discardableResult func setTotalStarCount(_ count: Int32, for id: SM64ObjectID) -> Bool { guard starCounts[id] != nil else { return false }; starCounts[id] = count; return true }
    @discardableResult func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64CastleCannonGrateObjectEffectRecord? { guard let count = starCounts[id], engineState.objects.record(for: id) != nil else { return nil }; let output = SM64CastleCannonGrateBehavior.update(.init(totalStarCount: count)); _ = engineState.objects.mutate(id) { next in next.collisionDistance = output.collisionDistance; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 } }; let effect = SM64CastleCannonGrateObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect }
    func remove(_ id: SM64ObjectID) { starCounts.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
