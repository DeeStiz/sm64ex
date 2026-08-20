import Foundation

struct SM64SparkleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SparkleOutput
}

final class SM64SparkleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7370_6B6C

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64SparkleObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnSparkle(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            behaviorIdentity: Self.defaultBehaviorIdentity,
            parent: parent
        )
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned sparkle could not attach")
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
            record.animationState = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64SparkleObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64SparkleBehavior.update(
            SM64SparkleInput(position: record.position, animationState: record.animationState)
        )
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.animationState = output.animationState
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64SparkleObjectEffectRecord(objectID: id, output: output)
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
