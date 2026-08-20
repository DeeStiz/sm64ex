import Foundation

struct SM64RotatingPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64RotatingPlatformOutput
}

/// Owner-thread adapter for `bhvRotatingPlatform`. The value kernel owns the
/// idle/spin action machine and signed high-byte speed semantics; the bridge
/// owns level-list lifetime and face-yaw/angle-velocity record mutation.
final class SM64RotatingPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7274_70
    static let defaultModel: UInt32 = 0

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64RotatingPlatformObjectEffectRecord] = []

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
    func spawnRotatingPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        speedByte: Int8 = 0,
        action: Int32 = 0,
        model: UInt32 = SM64RotatingPlatformObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64RotatingPlatformObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            position: position,
            faceYaw: faceYaw,
            speedByte: speedByte,
            action: action,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned rotating platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        speedByte: Int8 = 0,
        action: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.yaw = Int32(faceYaw)
            record.action = action
            record.timer = 0
            record.behaviorParams = Int32(UInt32(UInt8(bitPattern: speedByte)) << 24)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state: SM64SwiftEngineState
    ) -> SM64RotatingPlatformObjectEffectRecord? {
        guard registered.contains(id), let record = state.objects.record(for: id) else { return nil }
        let speedByte = Int8(truncatingIfNeeded: record.behaviorParams >> 24)
        let output = SM64RotatingPlatformBehavior.update(
            SM64RotatingPlatformInput(
                action: record.action,
                timer: record.timer,
                speedByte: speedByte,
                faceYaw: Int16(truncatingIfNeeded: record.faceAngles.yaw)
            )
        )
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = state.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.faceAngles.yaw = Int32(output.faceYaw)
            next.angleVelocity.yaw = Int32(output.angleVelocityYaw)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64RotatingPlatformObjectEffectRecord(objectID: id, output: output)
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
