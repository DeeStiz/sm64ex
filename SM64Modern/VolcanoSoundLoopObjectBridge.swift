import Foundation

struct SM64VolcanoSoundLoopObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64VolcanoSoundLoopOutput
}

final class SM64VolcanoSoundLoopObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_76736C

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64VolcanoSoundLoopObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnLoop(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned volcano sound loop could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64VolcanoSoundLoopObjectEffectRecord? {
        guard registered.contains(id), engineState.objects.record(for: id) != nil else {
            return nil
        }
        let effect = SM64VolcanoSoundLoopObjectEffectRecord(
            objectID: id,
            output: SM64VolcanoSoundLoopBehavior.update()
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
