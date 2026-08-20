import Foundation

struct SM64SslMovingPyramidWallObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64SslMovingPyramidWallOutput }

final class SM64SslMovingPyramidWallObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_73706D
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64SslMovingPyramidWallObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, positionY: Float = 0, start: SM64SslPyramidWallStart = .high) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        let initial = SM64SslMovingPyramidWallBehavior.initialize(positionY, start: start)
        guard engineState.objects.mutate(id, { record in
            record.position.y = initial.positionY
            record.homePosition.y = positionY
            record.action = initial.action
            record.timer = initial.timer
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned SSL pyramid wall could not attach") }
        registered.insert(id); return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64SslMovingPyramidWallBehavior.update(.init(action: record.action, timer: record.timer, positionY: record.position.y))
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.position.y = output.positionY; next.velocity.y = output.velocityY; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
