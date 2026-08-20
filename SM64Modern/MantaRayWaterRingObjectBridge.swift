import Foundation

struct SM64MantaRayWaterRingObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64MantaRayWaterRingOutput
}

final class SM64MantaRayWaterRingObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6D7277
    private struct State { var opacity: Int32; var averageScale: Float; var marioNear: Bool; var crossed: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64MantaRayWaterRingObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnRing(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.opacity = 150; record.hitboxRadius = 75; record.hitboxHeight = 20; record.hitboxDownOffset = 20; record.interactionType = 1 << 25; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Manta Ray water ring could not attach") }
        states[id] = State(opacity: 150, averageScale: 0.1, marioNear: false, crossed: false)
        return id
    }

    @discardableResult
    func setCollectionInput(marioNear: Bool, crossedRingPlane: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.marioNear = marioNear; state.crossed = crossedRingPlane; states[id] = state; return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64MantaRayWaterRingBehavior.update(.init(action: record.action, timer: record.timer, opacity: state.opacity, averageScale: state.averageScale, marioNear: state.marioNear, crossedRingPlane: state.crossed))
        state.opacity = output.opacity; state.averageScale = output.averageScale; state.marioNear = false; state.crossed = false; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.opacity = output.opacity; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.intangibleTimer = output.action == 0 ? -1 : 1; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform; if output.shouldDelete { next.activeFlags = 0 } }
        effectLog.append(.init(objectID: id, output: output)); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
