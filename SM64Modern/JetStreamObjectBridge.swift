import Foundation

struct SM64JetStreamObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64JetStreamOutput
}

final class SM64JetStreamObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6A6574
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64JetStreamObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, distanceToMario: Float = 10_000) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, distanceToMario: distanceToMario, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Jet Stream could not attach") }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, distanceToMario: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.distanceToMario = distanceToMario; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64JetStreamBehavior.update(.init(distanceToMario: record.distanceToMario, position: record.position, timer: record.timer))
        _ = engineState.objects.mutate(id) { next in next.timer = output.timer; next.graphFlags = output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | UInt16(0x10); next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
