import Foundation

struct SM64BooCageObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BooCageOutput }
final class SM64BooCageObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626361
    private struct State { var parentAlive: Bool; var parentID: SM64ObjectID?; var moveFlags: UInt32; var marioCollided: Bool }
    private var states: [SM64ObjectID: State] = [:]; private(set) var effectLog: [SM64BooCageObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, parent: SM64ObjectID? = nil, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID { let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity, parent: parent); guard attach(id, parent: parent, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned boo cage could not attach") }; return id }
    @discardableResult
    func attach(_ id: SM64ObjectID, parent: SM64ObjectID?, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool { guard pool.record(for: id) != nil else { return false }; states[id] = State(parentAlive: true, parentID: parent, moveFlags: 0, marioCollided: false); return pool.mutate(id) { record in record.position = position; record.parent = parent ?? record.parent; record.hitboxRadius = 120; record.hitboxHeight = 300; record.graphYOffset = 10; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform } }
    @discardableResult
    func setInputs(for id: SM64ObjectID, parentAlive: Bool? = nil, moveFlags: UInt32? = nil, marioCollided: Bool? = nil) -> Bool { guard var state = states[id] else { return false }; if let parentAlive { state.parentAlive = parentAlive }; if let moveFlags { state.moveFlags = moveFlags }; if let marioCollided { state.marioCollided = marioCollided }; states[id] = state; return true }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool { guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }; let parentRecord = state.parentID.flatMap { engineState.objects.record(for: $0) }; let output = SM64BooCageBehavior.update(.init(action: record.action, timer: record.timer, position: record.position, velocityY: record.velocity.y, parentAlive: state.parentAlive, parentPosition: parentRecord?.position ?? record.position, parentYaw: parentRecord?.faceAngles.yaw ?? 0, moveFlags: state.moveFlags, marioCollided: state.marioCollided)); state.moveFlags = 0; state.marioCollided = false; states[id] = state; _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.position = output.position; next.velocity.y = output.velocityY; next.intangibleTimer = output.tangible ? 0 : -1; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }; effectLog.append(.init(objectID: id, output: output)); return true }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
