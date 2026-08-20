import Foundation

struct SM64RotatingOctagonalPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64RotatingOctagonalPlatformOutput
}

/// Owner-thread adapter for the authored rotating-octagonal platform table.
final class SM64RotatingOctagonalPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6F6374
    static let defaultModel: UInt32 = 0

    private struct State {
        let angleVelocityYaw: Int32
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64RotatingOctagonalPlatformObjectEffectRecord] = []

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
        collisionModelIndex: UInt8 = 0,
        speedIndex: UInt8 = 0,
        model: UInt32 = SM64RotatingOctagonalPlatformObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64RotatingOctagonalPlatformObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, faceYaw: faceYaw, collisionModelIndex: collisionModelIndex,
                     speedIndex: speedIndex, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned rotating octagonal platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        faceYaw: Int32 = 0,
        collisionModelIndex: UInt8,
        speedIndex: UInt8,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, speedIndex < 4 else { return false }
        let initialization = SM64RotatingOctagonalPlatformBehavior.initialize(
            collisionModelIndex: collisionModelIndex,
            speedIndex: speedIndex
        )
        registered.insert(id)
        states[id] = State(angleVelocityYaw: initialization.angleVelocityYaw)
        return pool.mutate(id) { record in
            record.faceAngles.yaw = faceYaw
            record.angleVelocity.yaw = initialization.angleVelocityYaw
            record.behaviorParams = Int32(collisionModelIndex) << 16
            record.behaviorParams |= Int32(speedIndex) << 24
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64RotatingOctagonalPlatformObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id),
              let platformState = states[id] else { return nil }
        let output = SM64RotatingOctagonalPlatformBehavior.update(
            SM64RotatingOctagonalPlatformInput(
                faceYaw: record.faceAngles.yaw,
                angleVelocityYaw: platformState.angleVelocityYaw
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.faceAngles.yaw = output.faceYaw
            next.angleVelocity.yaw = output.angleVelocityYaw
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64RotatingOctagonalPlatformObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        states.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
