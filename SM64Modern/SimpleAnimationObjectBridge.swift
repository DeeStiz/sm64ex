import Foundation

struct SM64SimpleAnimationObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SimpleAnimationOutput
}

final class SM64SimpleAnimationObjectBridge {
    static let randomTextureBehaviorIdentity: UInt64 = 0x6268_765F_726174
    static let unusedSixFrameBehaviorIdentity: UInt64 = 0x6268_765F_753666

    private struct State { let kind: SM64SimpleAnimationKind }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64SimpleAnimationObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, kind: SM64SimpleAnimationKind, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let identity = kind == .randomTexture ? Self.randomTextureBehaviorIdentity : Self.unusedSixFrameBehaviorIdentity
        let list: SM64ObjectList = kind == .randomTexture ? .level : .default
        let id = try engineState.spawnObject(in: list, behaviorIdentity: identity)
        guard attach(id, kind: kind, position: position, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned simple animation could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, kind: SM64SimpleAnimationKind, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: kind)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.animationState = -1; record.graphYOffset = kind == .randomTexture ? -16 : 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64SimpleAnimationObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64SimpleAnimationBehavior.update(.init(kind: state.kind, position: record.position, timer: record.timer, animationState: record.animationState))
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.animationState = output.animationState; next.graphYOffset = output.graphYOffset; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64SimpleAnimationObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
