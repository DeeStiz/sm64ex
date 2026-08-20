import Foundation

struct SM64BubObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BubOutput
    let spawnedChildren: [SM64ObjectID]
}

final class SM64BubObjectBridge {
    static let bubBehaviorIdentity: UInt64 = 0x6268_765F_627562
    static let chirpChirpBehaviorIdentity: UInt64 = 0x6268_765F_636370
    static let chirpChirpUnusedBehaviorIdentity: UInt64 = 0x6268_765F_636375
    static let defaultModel: UInt32 = 0x70 // MODEL_BUB

    private struct State {
        let role: SM64BubRole
        var action: Int32
        var parent: SM64ObjectID?
        var childCount: Int
        var randomFleeTrigger: Bool
        var interacted: Bool
        var parentDuplicate: Bool
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BubObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, childCount: Int = 1, position: SM64ObjectVector3 = .zero, identity: UInt64 = SM64BubObjectBridge.chirpChirpBehaviorIdentity) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: identity)
        guard attachSpawner(id, childCount: childCount, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Bub spawner could not attach") }
        return id
    }

    @discardableResult
    func attachSpawner(_ id: SM64ObjectID, childCount: Int, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(role: .spawner, action: 0, parent: nil, childCount: childCount, randomFleeTrigger: false, interacted: false, parentDuplicate: false)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func spawnBub(in engineState: SM64SwiftEngineState, parent: SM64ObjectID? = nil, position: SM64ObjectVector3 = .zero, randomFleeTrigger: Bool = false) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, model: Self.defaultModel, behaviorIdentity: Self.bubBehaviorIdentity, parent: parent)
        guard attachBub(id, parent: parent, position: position, randomFleeTrigger: randomFleeTrigger, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Bub could not attach") }
        return id
    }

    @discardableResult
    func attachBub(_ id: SM64ObjectID, parent: SM64ObjectID?, position: SM64ObjectVector3, randomFleeTrigger: Bool, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(role: .bub, action: 0, parent: parent, childCount: 0, randomFleeTrigger: randomFleeTrigger, interacted: false, parentDuplicate: false)
        return pool.mutate(id) { record in
            record.position = position; record.homePosition = position; record.interactionType = 1 << 1; record.damageOrCoinValue = 1; record.hitboxRadius = 20; record.hitboxHeight = 10; record.gravity = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setBubInput(randomFleeTrigger: Bool = false, interacted: Bool = false, parentDuplicate: Bool = false, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.randomFleeTrigger = randomFleeTrigger; state.interacted = interacted; state.parentDuplicate = parentDuplicate; states[id] = state; return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        if state.role == .spawner {
            let output = SM64BubBehavior.updateSpawner(action: state.action, timer: record.timer, distanceToMario: record.distanceToMario, marioY: record.position.y, positionY: record.position.y, childCount: state.childCount)
            var children: [SM64ObjectID] = []
            if output.spawnedChildren > 0 { for _ in 0..<output.spawnedChildren { if let child = try? spawnBub(in: engineState, parent: id, position: record.position) { children.append(child) } } }
            state.action = output.action; states[id] = state; _ = engineState.objects.mutate(id) { $0.action = output.action; $0.timer = output.timer }
            effectLog.append(.init(objectID: id, output: output, spawnedChildren: children)); return true
        }
        let parentDuplicate = state.parentDuplicate || state.parent.flatMap { engineState.objects.record(for: $0)?.action == 2 } == true
        let output = SM64BubBehavior.updateBub(action: state.action, timer: record.timer, position: record.position, moveYaw: record.moveAngles.yaw, forwardVelocity: record.forwardVelocity, waterLevel: record.floorHeight, targetY: record.position.y + 100, angleToMario: record.angleToMario, angleToHome: record.angleToHome, distanceToMario: record.distanceToMario, lateralDistanceHome: record.angleToHome == 0 ? 0 : 1000, randomFleeTrigger: state.randomFleeTrigger, interacted: state.interacted, parentDuplicate: parentDuplicate)
        state.action = output.action; state.randomFleeTrigger = false; state.interacted = false; state.parentDuplicate = false; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.position = output.position; next.moveAngles.yaw = output.moveYaw; next.forwardVelocity = output.forwardVelocity; next.velocity.y = output.velocityY; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output, spawnedChildren: [])); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
