import Foundation

struct SM64FlameObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64FlameOutput
}

final class SM64FlameObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_66736C
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64FlameObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned static flame could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.scale = .init(x: 7, y: 7, z: 7)
            record.interactionType = 1 // INTERACT_FLAME
            record.hitboxRadius = 50
            record.hitboxHeight = 25
            record.hitboxDownOffset = 25
            record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64FlameObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64FlameBehavior.update(.init(position: record.position, timer: record.timer, animationState: record.animationState))
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.animationState = output.animationState
            next.interactionStatus = output.interactionStatus
            next.timer &+= 1
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64FlameObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
