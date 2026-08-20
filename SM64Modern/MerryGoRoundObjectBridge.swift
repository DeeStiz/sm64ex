import Foundation

struct SM64MerryGoRoundObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64MerryGoRoundOutput }
final class SM64MerryGoRoundObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6D6772_31
    private struct State { var stopped: Bool; var marioOutsideLatched: Bool; var marioRoom: Int32 }
    private var states: [SM64ObjectID: State] = [:]; private(set) var effectLog: [SM64MerryGoRoundObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID { let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity); guard attach(id, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned merry-go-round could not attach") }; return id }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool { guard pool.record(for: id) != nil else { return false }; states[id] = State(stopped: false, marioOutsideLatched: false, marioRoom: 0); return pool.mutate(id) { record in record.position = position; record.collisionDistance = 2000; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform } }
    @discardableResult
    func setInputs(for id: SM64ObjectID, stopped: Bool? = nil, marioRoom: Int32? = nil) -> Bool { guard var state = states[id] else { return false }; if let stopped { state.stopped = stopped }; if let marioRoom { state.marioRoom = marioRoom }; states[id] = state; return true }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool { guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }; let output = SM64MerryGoRoundBehavior.update(.init(timer: record.timer, yaw: record.faceAngles.yaw, stopped: state.stopped, marioOutsideLatched: state.marioOutsideLatched, marioRoom: state.marioRoom)); state.marioOutsideLatched = output.marioOutsideLatched; states[id] = state; _ = engineState.objects.mutate(id) { next in next.timer = output.timer; next.moveAngles.yaw = output.yaw; next.faceAngles.yaw = output.yaw; next.angleVelocity.yaw = output.angleVelocity }; effectLog.append(.init(objectID: id, output: output)); return true }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
