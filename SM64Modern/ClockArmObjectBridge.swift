import Foundation

struct SM64ClockArmObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64ClockArmOutput }
final class SM64ClockArmObjectBridge {
    static let hourBehaviorIdentity: UInt64 = 0x6268_765F_63686F
    static let minuteBehaviorIdentity: UInt64 = 0x6268_765F_636D69
    private struct State { let kind: SM64ClockArmKind; var surface: SM64ClockSurface }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64ClockArmObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, kind: SM64ClockArmKind, position: SM64ObjectVector3 = .zero, surface: SM64ClockSurface = .default) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: kind == .hour ? Self.hourBehaviorIdentity : Self.minuteBehaviorIdentity)
        guard attach(id, kind: kind, position: position, surface: surface, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned clock arm could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, kind: SM64ClockArmKind, position: SM64ObjectVector3, surface: SM64ClockSurface, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: kind, surface: surface)
        return pool.mutate(id) { record in record.position = position; record.angleVelocity.roll = kind == .hour ? -0x20 : -0x180; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func setSurface(_ surface: SM64ClockSurface, for id: SM64ObjectID) -> Bool { guard var state = states[id] else { return false }; state.surface = surface; states[id] = state; return true }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64ClockArmBehavior.update(.init(kind: state.kind, action: record.action, timer: record.timer, roll: record.faceAngles.roll, angleVelocity: record.angleVelocity.roll, surface: state.surface))
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.faceAngles.roll = output.roll; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
