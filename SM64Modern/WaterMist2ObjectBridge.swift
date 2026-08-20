import Foundation

struct SM64WaterMist2ObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WaterMist2Output
}

final class SM64WaterMist2ObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_776D32
    private struct State { let waterLevel: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WaterMist2ObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnMist(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, waterLevel: waterLevel, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned water mist 2 could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, waterLevel: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(waterLevel: waterLevel)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64WaterMist2ObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64WaterMist2Behavior.update(SM64WaterMist2Input(homePosition: record.homePosition, waterLevel: state.waterLevel, randomOffsetX: 0, randomOffsetZ: 0, randomOpacity: 0))
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.opacity = output.opacity; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64WaterMist2ObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
