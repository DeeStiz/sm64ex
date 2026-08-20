import Foundation

struct SM64BetaMovingFlamesObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BetaMovingFlamesOutput }
struct SM64BetaMovingFlamesSpawnObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BetaMovingFlamesSpawnOutput; let spawnedChild: SM64ObjectID? }

final class SM64BetaMovingFlamesObjectBridge {
    static let spawnBehaviorIdentity: UInt64 = 0x6268_765F_626D6673
    static let flameBehaviorIdentity: UInt64 = 0x6268_765F_626D66
    private struct FlameState { let moveYaw: Int32; var movingFlameTimer: Int32 }
    private var spawners: Set<SM64ObjectID> = []
    private var flames: [SM64ObjectID: FlameState] = [:]
    private(set) var spawnEffectLog: [SM64BetaMovingFlamesSpawnObjectEffectRecord] = []
    private(set) var effectLog: [SM64BetaMovingFlamesObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { (Array(spawners) + Array(flames.keys)).sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { spawnEffectLog.removeAll(keepingCapacity: true); effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.spawnBehaviorIdentity)
        guard attachSpawner(id, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Beta moving-flame spawner could not attach") }
        return id
    }
    @discardableResult
    func attachSpawner(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }; spawners.insert(id); return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func attachFlame(_ id: SM64ObjectID, position: SM64ObjectVector3, moveYaw: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }; flames[id] = FlameState(moveYaw: moveYaw, movingFlameTimer: 0); return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.scale = .init(x: 5, y: 5, z: 5); record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if spawners.contains(id) { return updateSpawner(id, state: engineState) != nil }
        if flames[id] != nil { return updateFlame(id, state: engineState) != nil }
        return false
    }
    private func updateSpawner(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64BetaMovingFlamesSpawnObjectEffectRecord? {
        guard let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64BetaMovingFlamesSpawnBehavior.update(.init(position: record.position, timer: record.timer, action: record.action))
        var child: SM64ObjectID?
        if output.spawnChild { child = try? engineState.spawnObject(in: .level, behaviorIdentity: Self.flameBehaviorIdentity, parent: id); if let child { _ = attachFlame(child, position: output.position, moveYaw: record.moveAngles.yaw, in: engineState.objects) } }
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer &+= 1 }
        let effect = SM64BetaMovingFlamesSpawnObjectEffectRecord(objectID: id, output: output, spawnedChild: child); spawnEffectLog.append(effect); return effect
    }
    private func updateFlame(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64BetaMovingFlamesObjectEffectRecord? {
        guard var state = flames[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64BetaMovingFlamesBehavior.update(.init(position: record.position, moveYaw: state.moveYaw, movingFlameTimer: state.movingFlameTimer, animationState: record.animationState)); state.movingFlameTimer = output.movingFlameTimer; flames[id] = state
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.forwardVelocity = output.forwardVelocity; next.animationState = output.animationState; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.timer &+= 1; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64BetaMovingFlamesObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { spawners.remove(id); flames.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
