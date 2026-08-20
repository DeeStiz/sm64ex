import Foundation

struct SM64UnlockDoorStarObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64UnlockDoorStarOutput }

final class SM64UnlockDoorStarObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_756473
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64UnlockDoorStarObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, model: 0x2A, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.action = 0; record.timer = 0; record.moveAngles.yaw = 0x7800; record.angleVelocity.yaw = 0x1000; record.scale = .init(x: 0.5, y: 0.5, z: 0.5); record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned unlock-door star could not attach") }
        registered.insert(id); return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64UnlockDoorStarBehavior.update(.init(state: record.action, timer: record.timer, moveYaw: record.moveAngles.yaw, yawVelocity: record.angleVelocity.yaw, positionY: record.position.y, scale: record.scale.x))
        _ = engineState.objects.mutate(id) { next in next.action = output.state; next.timer = output.timer; next.moveAngles.yaw = output.moveYaw; next.angleVelocity.yaw = output.yawVelocity; next.position.y = output.positionY; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.graphFlags = output.hidden ? next.graphFlags | 0x10 : next.graphFlags & ~UInt16(0x10); if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
