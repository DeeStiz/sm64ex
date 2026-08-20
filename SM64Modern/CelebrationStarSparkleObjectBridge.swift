import Foundation

struct SM64CelebrationStarSparkleObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64CelebrationStarSparkleOutput }

final class SM64CelebrationStarSparkleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_637373
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64CelebrationStarSparkleObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnSparkle(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned celebration sparkle could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }; registered.insert(id); return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.graphYOffset = 25; record.animationState = -1; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64CelebrationStarSparkleObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64CelebrationStarSparkleBehavior.update(.init(position: record.position, timer: record.timer, animationState: record.animationState))
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.graphYOffset = output.graphYOffset; next.animationState = output.animationState; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64CelebrationStarSparkleObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
