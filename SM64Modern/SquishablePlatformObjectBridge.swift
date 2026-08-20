import Foundation

struct SM64SquishablePlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SquishablePlatformOutput
}

final class SM64SquishablePlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_737170
    static let defaultModel: UInt32 = 0

    private var timers: [SM64ObjectID: Int32] = [:]
    private(set) var effectLog: [SM64SquishablePlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        timers.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64SquishablePlatformObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            model: model,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("squishable platform attach failed")
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
        timers[id] = 0
        return pool.mutate(id) { record in
            record.position = position
            record.scale = SM64ObjectVector3(x: 1, y: 1, z: 1)
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle |
                SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64SquishablePlatformObjectEffectRecord? {
        guard let timer = timers[id], engineState.objects.record(for: id) != nil else {
            return nil
        }
        let output = SM64SquishablePlatformBehavior.update(
            SM64SquishablePlatformInput(platformTimer: timer)
        )
        timers[id] = output.platformTimer
        _ = engineState.objects.mutate(id) { record in
            record.scale.y = output.scaleY
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle |
                SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64SquishablePlatformObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        timers.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded {
            remove(id)
        }
        for id in registeredIDs where pool.record(for: id) == nil {
            remove(id)
        }
    }
}
