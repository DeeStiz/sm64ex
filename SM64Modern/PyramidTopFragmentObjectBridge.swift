import Foundation

struct SM64PyramidTopFragmentObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64PyramidTopFragmentOutput }

final class SM64PyramidTopFragmentObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_707466
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64PyramidTopFragmentObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, scale: Float = 0.8) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.scale = .init(x: scale, y: scale, z: scale); record.timer = 0; record.faceAngles = .zero; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned pyramid fragment could not attach") }
        registered.insert(id); return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64PyramidTopFragmentBehavior.update(.init(timer: record.timer, faceYaw: record.faceAngles.yaw, facePitch: record.faceAngles.pitch, scale: record.scale.x))
        _ = engineState.objects.mutate(id) { next in next.timer = output.timer; next.faceAngles.yaw = output.faceYaw; next.faceAngles.pitch = output.facePitch; next.friction = output.friction; next.buoyancy = output.buoyancy; next.animationState = output.animationState; if output.deactivated { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
