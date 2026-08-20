import Foundation

struct SM64WfRotatingWoodenPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WfRotatingWoodenPlatformOutput
}

/// Owner-thread adapter for the Waterfall Fortress rotating wooden platform.
final class SM64WfRotatingWoodenPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_77726F
    static let defaultModel: UInt32 = 0

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64WfRotatingWoodenPlatformObjectEffectRecord] = []

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
    func spawnPlatform(
        in engineState: SM64SwiftEngineState,
        faceYaw: Int32 = 0,
        action: Int32 = 0,
        model: UInt32 = SM64WfRotatingWoodenPlatformObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64WfRotatingWoodenPlatformObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, faceYaw: faceYaw, action: action, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned WF rotating wooden platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        faceYaw: Int32 = 0,
        action: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, (0...1).contains(action) else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.faceAngles.yaw = faceYaw
            record.action = action
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WfRotatingWoodenPlatformObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64WfRotatingWoodenPlatformBehavior.update(
            SM64WfRotatingWoodenPlatformInput(
                action: record.action,
                timer: record.timer,
                faceYaw: record.faceAngles.yaw
            )
        )
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.faceAngles.yaw = output.faceYaw
            next.angleVelocity.yaw = output.angleVelocityYaw
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64WfRotatingWoodenPlatformObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { registered.remove(id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
