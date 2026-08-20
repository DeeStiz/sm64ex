import Foundation

struct SM64EndCutsceneActorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64EndCutsceneActorOutput
}

final class SM64EndCutsceneActorObjectBridge {
    static let endPeachBehaviorIdentity: UInt64 = 0x6268_765F_657070
    static let endToadBehaviorIdentity: UInt64 = 0x6268_765F_657074
    static let peachModel: UInt32 = 0x53
    static let toadModel: UInt32 = 0x5A

    private var roles: [SM64ObjectID: SM64EndCutsceneActorRole] = [:]
    private var nearAnimationEnd: [SM64ObjectID: Bool] = [:]
    private(set) var effectLog: [SM64EndCutsceneActorObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        roles.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPeach(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try spawn(in: engineState, role: .peach, position: position)
    }

    @discardableResult
    func spawnToad(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        try spawn(in: engineState, role: .toad, position: position)
    }

    @discardableResult
    private func spawn(in engineState: SM64SwiftEngineState, role: SM64EndCutsceneActorRole, position: SM64ObjectVector3) throws -> SM64ObjectID {
        let identity = role == .peach ? Self.endPeachBehaviorIdentity : Self.endToadBehaviorIdentity
        let model = role == .peach ? Self.peachModel : Self.toadModel
        let id = try engineState.spawnObject(in: .default, model: model, behaviorIdentity: identity)
        guard attach(id, role: role, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned ending cutscene actor could not attach")
        }
        return id
    }

    @discardableResult
    private func attach(_ id: SM64ObjectID, role: SM64EndCutsceneActorRole, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        roles[id] = role
        nearAnimationEnd[id] = false
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.animationState = role == .peach ? 4 : (position.x >= 0 ? 4 : 5)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setNearAnimationEnd(_ value: Bool, for id: SM64ObjectID) -> Bool {
        guard roles[id] != nil else { return false }
        nearAnimationEnd[id] = value
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let role = roles[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64EndCutsceneActorBehavior.update(.init(
            role: role,
            animationIndex: record.animationState,
            positionX: record.position.x,
            nearAnimationEnd: nearAnimationEnd.removeValue(forKey: id) ?? false
        ))
        _ = engineState.objects.mutate(id) { next in
            next.animationState = output.animationIndex
            next.timer &+= 1
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { roles.removeValue(forKey: id); nearAnimationEnd.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
