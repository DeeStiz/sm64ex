import Foundation

struct SM64CoinSparklesObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CoinSparklesOutput
}

final class SM64CoinSparklesObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6373_706B

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64CoinSparklesObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnSparkles(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity,
            parent: parent
        )
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned coin sparkles could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.graphYOffset = 25
            record.animationState = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64CoinSparklesObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64CoinSparklesBehavior.update(
            SM64CoinSparklesInput(position: record.position, animationState: record.animationState)
        )
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.animationState = output.animationState
            next.graphYOffset = output.graphYOffset
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64CoinSparklesObjectEffectRecord(objectID: id, output: output)
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
