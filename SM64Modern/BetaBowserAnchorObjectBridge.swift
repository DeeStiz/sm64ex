import Foundation

struct SM64BetaBowserAnchorObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BetaBowserAnchorOutput }
final class SM64BetaBowserAnchorObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626261
    private struct State { var marioPosition: SM64ObjectVector3; var marioYaw: Int32; var debugRadius: Float; var debugHeight: Float }
    private var states: [SM64ObjectID: State] = [:]; private(set) var effectLog: [SM64BetaBowserAnchorObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID { let id = try engineState.spawnObject(in: .destructive, behaviorIdentity: Self.defaultBehaviorIdentity); guard attach(id, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned beta Bowser anchor could not attach") }; return id }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool { guard pool.record(for: id) != nil else { return false }; states[id] = State(marioPosition: .zero, marioYaw: 0, debugRadius: 0, debugHeight: 0); return pool.mutate(id) { record in record.position = position; record.hitboxRadius = 100; record.hitboxHeight = 300; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform } }
    @discardableResult
    func setInputs(for id: SM64ObjectID, marioPosition: SM64ObjectVector3? = nil, marioYaw: Int32? = nil, debugRadius: Float? = nil, debugHeight: Float? = nil) -> Bool { guard var state = states[id] else { return false }; if let marioPosition { state.marioPosition = marioPosition }; if let marioYaw { state.marioYaw = marioYaw }; if let debugRadius { state.debugRadius = debugRadius }; if let debugHeight { state.debugHeight = debugHeight }; states[id] = state; return true }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool { guard let state = states[id], let _ = engineState.objects.record(for: id) else { return false }; let output = SM64BetaBowserAnchorBehavior.update(.init(marioPosition: state.marioPosition, marioYaw: state.marioYaw, debugRadius: state.debugRadius, debugHeight: state.debugHeight)); _ = engineState.objects.mutate(id) { next in next.position = output.position; next.hitboxRadius = output.hitboxRadius; next.hitboxHeight = output.hitboxHeight; next.interactionStatus = output.attackCollidedObjects ? 1 : 0; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }; effectLog.append(.init(objectID: id, output: output)); return true }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
