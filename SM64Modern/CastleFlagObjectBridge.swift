import Foundation

struct SM64CastleFlagObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64CastleFlagOutput }
final class SM64CastleFlagObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_666C67
    private struct State { var initialized: Bool; let randomFrame: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64CastleFlagObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, randomFrame: Int32 = 0, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID { let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity); guard attach(id, randomFrame: randomFrame, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned castle flag could not attach") }; return id }
    @discardableResult
    func attach(_ id: SM64ObjectID, randomFrame: Int32, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool { guard pool.record(for: id) != nil else { return false }; states[id] = State(initialized: false, randomFrame: randomFrame); return pool.mutate(id) { record in record.position = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform } }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool { guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }; let output = SM64CastleFlagBehavior.update(.init(initialized: state.initialized, animationFrame: record.animationState, randomFrame: state.randomFrame)); state.initialized = output.initialized; states[id] = state; _ = engineState.objects.mutate(id) { next in next.animationState = output.animationFrame; next.timer = output.timer }; effectLog.append(.init(objectID: id, output: output)); return true }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
