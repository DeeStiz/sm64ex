import Foundation

struct SM64SunkenShipPartObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64SunkenShipPartOutput }

final class SM64SunkenShipPartObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_737370
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64SunkenShipPartObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, distanceToMario: Float = 19_000) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.distanceToMario = distanceToMario; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned sunken ship part could not attach") }
        registered.insert(id); return id
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64SunkenShipPartBehavior.update(.init(distanceToMario: record.distanceToMario))
        _ = engineState.objects.mutate(id) { next in next.opacity = output.opacity; if output.disableRendering { next.graphFlags |= 0x10 } }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
