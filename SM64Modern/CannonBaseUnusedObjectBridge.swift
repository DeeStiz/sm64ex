import Foundation

struct SM64CannonBaseUnusedObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64CannonBaseUnusedOutput }

final class SM64CannonBaseUnusedObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_636275
    private var velocities: [SM64ObjectID: Float] = [:]
    private(set) var effectLog: [SM64CannonBaseUnusedObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { velocities.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, velocityY: Float = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, velocityY: velocityY, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned unused cannon base could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, velocityY: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }; velocities[id] = velocityY; return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.velocity.y = velocityY; record.animationState = -1; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64CannonBaseUnusedObjectEffectRecord? {
        guard let velocityY = velocities[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64CannonBaseUnusedBehavior.update(.init(position: record.position, velocityY: velocityY, timer: record.timer, animationState: record.animationState))
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.animationState = output.animationState; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64CannonBaseUnusedObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { velocities.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
