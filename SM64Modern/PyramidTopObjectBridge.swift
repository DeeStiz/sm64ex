import Foundation

struct SM64PyramidTopObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64PyramidTopOutput }

final class SM64PyramidTopObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_707479
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64PyramidTopObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned pyramid top could not attach") }
        registered.insert(id); return id
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64PyramidTopBehavior.update(.init(action: record.action, timer: record.timer, pillarsTouched: record.behaviorParams, faceYaw: record.faceAngles.yaw, angleVelocityYaw: record.angleVelocity.yaw, velocityY: record.velocity.y, position: record.position, homePosition: record.homePosition))
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.faceAngles.yaw = output.faceYaw; next.angleVelocity.yaw = output.angleVelocityYaw; next.velocity.y = output.velocityY; next.position = output.position; if output.deactivated { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
