import Foundation

struct SM64EnvironmentGateObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64EnvironmentGateOutput
}

final class SM64EnvironmentGateObjectBridge {
    static let bowserSubDoorBehaviorIdentity: UInt64 = 0x6268_765F_627364
    static let bowsersSubBehaviorIdentity: UInt64 = 0x6268_765F_627373
    static let moatGrillsBehaviorIdentity: UInt64 = 0x6268_765F_6D6772
    static let invisibleObjectsUnderBridgeBehaviorIdentity: UInt64 = 0x6268_765F_6D6F62

    private struct State { let role: SM64EnvironmentGateRole; var submarineUnlocked: Bool; var moatDrained: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64EnvironmentGateObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, role: SM64EnvironmentGateRole, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: role == .invisibleObjectsUnderBridge ? .default : .surface, behaviorIdentity: Self.identity(for: role))
        guard attach(id, role: role, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned environment gate could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, role: SM64EnvironmentGateRole, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(role: role, submarineUnlocked: false, moatDrained: false)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.collisionDistance = role == .invisibleObjectsUnderBridge ? 0 : 20_000; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func setInputs(for id: SM64ObjectID, submarineUnlocked: Bool? = nil, moatDrained: Bool? = nil) -> Bool {
        guard var state = states[id] else { return false }
        if let submarineUnlocked { state.submarineUnlocked = submarineUnlocked }
        if let moatDrained { state.moatDrained = moatDrained }
        states[id] = state; return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64EnvironmentGateBehavior.update(.init(role: state.role, timer: record.timer, submarineUnlocked: state.submarineUnlocked, moatDrained: state.moatDrained))
        _ = engineState.objects.mutate(id) { next in next.timer = output.timer; if output.modelNone { next.model = 0 }; if output.shouldDelete { next.activeFlags = 0 } }
        effectLog.append(.init(objectID: id, output: output)); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }

    static func identity(for role: SM64EnvironmentGateRole) -> UInt64 {
        switch role { case .bowserSubDoor: return bowserSubDoorBehaviorIdentity; case .bowsersSub: return bowsersSubBehaviorIdentity; case .moatGrills: return moatGrillsBehaviorIdentity; case .invisibleObjectsUnderBridge: return invisibleObjectsUnderBridgeBehaviorIdentity }
    }
}
