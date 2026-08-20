import Foundation

struct SM64PyramidPillarTouchDetectorObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64PyramidPillarTouchDetectorOutput }

final class SM64PyramidPillarTouchDetectorObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_707464
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64PyramidPillarTouchDetectorObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, parent: SM64ObjectID, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity, parent: parent)
        guard engineState.objects.mutate(id, { record in record.position = position; record.parent = parent; record.interactionType = 1; record.hitboxRadius = 150; record.hitboxHeight = 300; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned pyramid pillar detector could not attach") }
        registered.insert(id); return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let parentCount = record.parent == id ? 0 : engineState.objects.record(for: record.parent)?.behaviorParams ?? 0
        let output = SM64PyramidPillarTouchDetectorBehavior.update(.init(parentTouchedCount: parentCount, collidedWithMario: record.interactionStatus != 0))
        _ = engineState.objects.mutate(id) { next in next.interactionStatus = 0; if output.deactivated { next.activeFlags = 0 } }
        if output.deactivated, record.parent != id { _ = engineState.objects.mutate(record.parent) { $0.behaviorParams = output.parentTouchedCount } }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
