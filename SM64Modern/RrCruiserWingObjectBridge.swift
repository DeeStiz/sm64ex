import Foundation

struct SM64RrCruiserWingObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64RrCruiserWingOutput }

final class SM64RrCruiserWingObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_727277
    private struct State: Sendable { let baseYaw: Int32; let basePitch: Int32; let reverse: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64RrCruiserWingObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, baseYaw: Int32 = 0, basePitch: Int32 = 0, reverse: Bool = false, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.faceAngles.yaw = baseYaw; record.faceAngles.pitch = basePitch; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned RR cruiser wing could not attach") }
        states[id] = State(baseYaw: baseYaw, basePitch: basePitch, reverse: reverse); return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64RrCruiserWingBehavior.update(.init(timer: record.timer, baseYaw: state.baseYaw, basePitch: state.basePitch, reverse: state.reverse))
        _ = engineState.objects.mutate(id) { next in next.timer = output.timer; next.faceAngles.yaw = output.faceYaw; next.faceAngles.pitch = output.facePitch; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
