import Foundation
struct SM64VanishCapObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64VanishCapOutput }
final class SM64VanishCapObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_76636170
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64VanishCapObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, forwardVelocity: Float = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.forwardVelocity = forwardVelocity; record.gravity = 1.2; record.friction = 0.999; record.buoyancy = 0.9; record.opacity = 150; record.hitboxRadius = 80; record.hitboxHeight = 80; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned vanish cap could not attach") }
        registered.insert(id); return id
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64VanishCapBehavior.update(.init(action: record.action, timer: record.timer, faceYaw: record.faceAngles.yaw, forwardVelocity: record.forwardVelocity, interacted: record.interactionStatus != 0))
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.faceAngles.yaw = output.faceYaw; next.gravity = output.gravity; next.friction = output.friction; next.buoyancy = output.buoyancy; next.opacity = output.opacity; next.hitboxRadius = output.hitboxRadius; next.hitboxHeight = output.hitboxHeight; next.interactionStatus = 0; if output.deactivated { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
