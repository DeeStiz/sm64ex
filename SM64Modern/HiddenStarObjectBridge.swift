import Foundation

struct SM64HiddenStarObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64HiddenStarParentOutput
    let spawnedStar: SM64ObjectID?
}

struct SM64HiddenStarTriggerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64HiddenStarTriggerOutput
    let parentID: SM64ObjectID?
}

final class SM64HiddenStarObjectBridge {
    static let hiddenStarBehaviorIdentity: UInt64 = 0x6268_765F_6873_7431
    static let triggerBehaviorIdentity: UInt64 = 0x6268_765F_6873_7432
    static let bowserCourseRedCoinStarBehaviorIdentity: UInt64 = 0x6268_765F_6873_7433

    private enum Kind { case parent, trigger }
    private struct ParentState { var action: SM64HiddenStarAction; var counter: Int32; let requiredCounter: Int32 }
    private struct TriggerState { let parentID: SM64ObjectID?; var collidedWithMario: Bool }

    private let starSpawnBridge: SM64StarSpawnCoordinatesObjectBridge?
    private var kinds: [SM64ObjectID: Kind] = [:]
    private var parents: [SM64ObjectID: ParentState] = [:]
    private var triggers: [SM64ObjectID: TriggerState] = [:]
    private(set) var parentEffectLog: [SM64HiddenStarObjectEffectRecord] = []
    private(set) var triggerEffectLog: [SM64HiddenStarTriggerObjectEffectRecord] = []

    init(starSpawnBridge: SM64StarSpawnCoordinatesObjectBridge? = nil) { self.starSpawnBridge = starSpawnBridge }

    var registeredIDs: [SM64ObjectID] {
        Set(kinds.keys).sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { parentEffectLog.removeAll(keepingCapacity: true); triggerEffectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnHiddenStar(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, initialTriggerCounter: Int32 = 0) throws -> SM64ObjectID {
        try spawnParent(in: engineState, identity: Self.hiddenStarBehaviorIdentity, position: position, initialTriggerCounter: initialTriggerCounter, requiredCounter: 5)
    }

    @discardableResult
    func spawnBowserCourseRedCoinStar(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, initialTriggerCounter: Int32 = 0) throws -> SM64ObjectID {
        try spawnParent(in: engineState, identity: Self.bowserCourseRedCoinStarBehaviorIdentity, position: position, initialTriggerCounter: initialTriggerCounter, requiredCounter: 8)
    }

    private func spawnParent(in engineState: SM64SwiftEngineState, identity: UInt64, position: SM64ObjectVector3, initialTriggerCounter: Int32, requiredCounter: Int32) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: identity)
        guard attachParent(id, position: position, initialTriggerCounter: initialTriggerCounter, requiredCounter: requiredCounter, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned hidden star could not attach") }
        return id
    }

    @discardableResult
    func spawnTrigger(in engineState: SM64SwiftEngineState, parent: SM64ObjectID? = nil, position: SM64ObjectVector3 = .zero, collidedWithMario: Bool = false) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.triggerBehaviorIdentity, parent: parent)
        guard attachTrigger(id, parent: parent, position: position, collidedWithMario: collidedWithMario, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned hidden-star trigger could not attach") }
        return id
    }

    @discardableResult
    func attachParent(_ id: SM64ObjectID, position: SM64ObjectVector3, initialTriggerCounter: Int32, requiredCounter: Int32 = 5, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        kinds[id] = .parent; parents[id] = ParentState(action: .waiting, counter: initialTriggerCounter, requiredCounter: requiredCounter)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.hitboxRadius = 0; record.hitboxHeight = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func attachTrigger(_ id: SM64ObjectID, parent: SM64ObjectID?, position: SM64ObjectVector3, collidedWithMario: Bool, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        kinds[id] = .trigger; triggers[id] = TriggerState(parentID: parent, collidedWithMario: collidedWithMario)
        return pool.mutate(id) { record in record.position = position; record.parent = parent ?? record.parent; record.hitboxRadius = 100; record.hitboxHeight = 100; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func setTriggerCollision(_ collided: Bool, for id: SM64ObjectID) -> Bool { guard var state = triggers[id] else { return false }; state.collidedWithMario = collided; triggers[id] = state; return true }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let kind = kinds[id], let record = engineState.objects.record(for: id) else { return false }
        switch kind {
        case .parent:
            guard var state = parents[id] else { return false }
            let output = SM64HiddenStarBehavior.updateParent(.init(action: state.action, timer: record.timer, triggerCounter: state.counter, requiredCounter: state.requiredCounter))
            var child: SM64ObjectID?
            if output.spawnStar, let starSpawnBridge { child = try? starSpawnBridge.spawnStar(in: engineState, starCollected: false, position: record.position, homePosition: record.position) }
            state.action = output.action; state.counter = output.triggerCounter; parents[id] = state
            _ = engineState.objects.mutate(id) { next in next.timer &+= 1; if output.shouldDelete { next.activeFlags = 0 } }
            parentEffectLog.append(.init(objectID: id, output: output, spawnedStar: child))
        case .trigger:
            guard var state = triggers[id] else { return false }
            let parent = state.parentID.flatMap { parents[$0] }
            let output = SM64HiddenStarBehavior.updateTrigger(.init(triggerCounter: parent?.counter ?? 0, collidedWithMario: state.collidedWithMario, requiredCounter: parent?.requiredCounter ?? 5))
            if let parentID = state.parentID, var parentState = parents[parentID], state.collidedWithMario { parentState.counter = output.triggerCounter; parents[parentID] = parentState }
            state.collidedWithMario = false; triggers[id] = state
            _ = engineState.objects.mutate(id) { next in next.timer &+= 1; if output.shouldDelete { next.activeFlags = 0 } }
            triggerEffectLog.append(.init(objectID: id, output: output, parentID: state.parentID))
        }
        return true
    }

    func remove(_ id: SM64ObjectID) { kinds.removeValue(forKey: id); parents.removeValue(forKey: id); triggers.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
