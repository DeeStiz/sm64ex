import Foundation

struct SM64SwingPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SwingPlatformOutput
}

/// Owner-thread adapter for `bhvSwingPlatform`. The value kernel owns the
/// exact accumulated angle/speed update; the bridge owns the copied float
/// state, level-list lifetime, and render-facing roll mutation.
final class SM64SwingPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7377_70
    static let defaultModel: UInt32 = 0

    private var registered: Set<SM64ObjectID> = []
    private var angle: [SM64ObjectID: Float] = [:]
    private var speed: [SM64ObjectID: Float] = [:]
    private(set) var effectLog: [SM64SwingPlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnSwingPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceRoll: Int32 = 0,
        model: UInt32 = SM64SwingPlatformObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64SwingPlatformObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, position: position, faceRoll: faceRoll, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned swing platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        faceRoll: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        angle[id] = SM64SwingPlatformBehavior.initialize()
        speed[id] = 0
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.roll = faceRoll
            record.angleVelocity.roll = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state: SM64SwiftEngineState
    ) -> SM64SwingPlatformObjectEffectRecord? {
        guard registered.contains(id), let record = state.objects.record(for: id) else { return nil }
        let output = SM64SwingPlatformBehavior.update(
            SM64SwingPlatformInput(
                angle: angle[id] ?? SM64SwingPlatformBehavior.initialize(),
                speed: speed[id] ?? 0,
                faceRoll: record.faceAngles.roll
            )
        )
        angle[id] = output.angle
        speed[id] = output.speed
        _ = state.objects.mutate(id) { next in
            next.faceAngles.roll = output.faceRoll
            next.angleVelocity.roll = output.angleVelocityRoll
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64SwingPlatformObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        angle.removeValue(forKey: id)
        speed.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
