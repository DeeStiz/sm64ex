import Foundation

struct SM64SpindelObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64SpindelOutput }

final class SM64SpindelObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_73706C
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64SpindelObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.collisionDataIdentity = 0x53504E; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Spindel could not attach") }
        registered.insert(id); return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64SpindelBehavior.update(.init(timer: record.timer, phase: record.behaviorParams, direction: record.animationState, position: record.position, homeY: record.homePosition.y, movePitch: record.moveAngles.pitch))
        _ = engineState.objects.mutate(id) { next in next.timer = output.timer; next.behaviorParams = output.phase; next.animationState = output.direction; next.position = output.position; next.velocity.z = output.velocityZ; next.moveAngles.pitch = output.movePitch; next.angleVelocity.pitch = output.angleVelocityPitch; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
