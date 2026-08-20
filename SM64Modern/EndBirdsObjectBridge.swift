import Foundation

struct SM64EndBirdsObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64EndBirdsOutput
}

final class SM64EndBirdsObjectBridge {
    static let birds1BehaviorIdentity: UInt64 = 0x6268_765F_656231
    static let birds2BehaviorIdentity: UInt64 = 0x6268_765F_656232
    static let birdsModel: UInt32 = 0x2A

    private struct State {
        let role: SM64EndBirdsRole
        let targetPosition: SM64ObjectVector3
        var cutsceneTimer: Int32
        var endBirdVelocity: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64EndBirdsObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBirds1(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try spawn(in: engineState, role: .birds1, position: position, targetPosition: .init(x: -554, y: 3044, z: -1314))
    }

    @discardableResult
    func spawnBirds2(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, targetPosition: SM64ObjectVector3 = .init(x: 0, y: 0, z: 14_000)) throws -> SM64ObjectID {
        try spawn(in: engineState, role: .birds2, position: position, targetPosition: targetPosition)
    }

    @discardableResult
    private func spawn(in engineState: SM64SwiftEngineState, role: SM64EndBirdsRole, position: SM64ObjectVector3, targetPosition: SM64ObjectVector3) throws -> SM64ObjectID {
        let identity = role == .birds1 ? Self.birds1BehaviorIdentity : Self.birds2BehaviorIdentity
        let id = try engineState.spawnObject(in: .default, model: Self.birdsModel, behaviorIdentity: identity)
        guard attach(id, role: role, position: position, targetPosition: targetPosition, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned ending bird could not attach")
        }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, role: SM64EndBirdsRole, position: SM64ObjectVector3, targetPosition: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(role: role, targetPosition: targetPosition, cutsceneTimer: 1, endBirdVelocity: 30)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.scale = .init(x: 0.7, y: 0.7, z: 0.7)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setCutsceneTimer(_ value: Int32, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.cutsceneTimer = value
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64EndBirdsBehavior.update(.init(role: state.role, action: record.action, timer: record.timer, position: record.position, targetPosition: state.targetPosition, cutsceneTimer: state.cutsceneTimer, endBirdVelocity: state.endBirdVelocity))
        state.endBirdVelocity = output.forwardVelocity
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.position = output.position
            next.forwardVelocity = output.forwardVelocity
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
