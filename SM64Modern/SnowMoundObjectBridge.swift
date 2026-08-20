import Foundation

struct SM64SlidingSnowMoundObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64SlidingSnowMoundOutput }
struct SM64SnowMoundSpawnerObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64SnowMoundSpawnerOutput; let spawnedChild: SM64ObjectID? }

final class SM64SnowMoundObjectBridge {
    static let slidingBehaviorIdentity: UInt64 = 0x6268_765F_73736D
    static let spawnerBehaviorIdentity: UInt64 = 0x6268_765F_736D73
    private struct SpawnerState: Sendable { var distanceToMario: Float; var marioY: Float }
    private var sliding: Set<SM64ObjectID> = []
    private var spawners: [SM64ObjectID: SpawnerState] = [:]
    private(set) var slidingEffectLog: [SM64SlidingSnowMoundObjectEffectRecord] = []
    private(set) var spawnerEffectLog: [SM64SnowMoundSpawnerObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        var ids = Array(sliding); ids.append(contentsOf: spawners.keys)
        return ids.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot }
    }
    func beginExternalTick() { slidingEffectLog.removeAll(keepingCapacity: true); spawnerEffectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSliding(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, parent: SM64ObjectID? = nil) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.slidingBehaviorIdentity, parent: parent)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned sliding snow mound could not attach") }
        sliding.insert(id); return id
    }

    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.spawnerBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned snow mound spawner could not attach") }
        spawners[id] = SpawnerState(distanceToMario: 10_000, marioY: position.y); return id
    }

    @discardableResult
    func setSpawnerInput(distanceToMario: Float, marioY: Float, for id: SM64ObjectID) -> Bool { guard spawners[id] != nil else { return false }; spawners[id] = SpawnerState(distanceToMario: distanceToMario, marioY: marioY); return true }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        if let spawner = spawners[id], let record = engineState.objects.record(for: id) {
            let output = SM64SnowMoundBehavior.updateSpawner(.init(timer: record.timer, distanceToMario: spawner.distanceToMario, marioY: spawner.marioY, positionY: record.position.y))
            var child: SM64ObjectID?
            if output.spawnChild { child = try? spawnSliding(in: engineState, position: record.position, parent: id); if let child { _ = engineState.objects.mutate(child) { $0.scale = .init(x: output.childScale, y: output.childScale, z: output.childScale) } } }
            _ = engineState.objects.mutate(id) { $0.timer = output.timer }
            spawnerEffectLog.append(.init(objectID: id, output: output, spawnedChild: child)); return true
        }
        guard sliding.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64SnowMoundBehavior.updateSliding(.init(action: record.action, timer: record.timer, position: record.position, homeZ: record.homePosition.z))
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.position = output.position; next.velocity = output.velocity; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        slidingEffectLog.append(.init(objectID: id, output: output)); return true
    }

    func remove(_ id: SM64ObjectID) { sliding.remove(id); spawners.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
