import Foundation

struct SM64SeesawPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SeesawPlatformOutput
}

/// Owner-thread adapter for `bhvSeesawPlatform`. The value kernel owns the
/// exact platform rotation and return-to-zero math; this bridge owns the
/// copied pitch velocity, platform relation, object lifetime, and record
/// mutation.
final class SM64SeesawPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7373_77
    static let defaultModel: UInt32 = 0

    private var registered: Set<SM64ObjectID> = []
    private var pitchVelocity: [SM64ObjectID: Float] = [:]
    private(set) var effectLog: [SM64SeesawPlatformObjectEffectRecord] = []

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
    func spawnSeesawPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        behaviorByte: UInt8 = 0,
        model: UInt32 = SM64SeesawPlatformObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64SeesawPlatformObjectBridge.defaultBehaviorIdentity
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
            behaviorByte: behaviorByte,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned seesaw platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        behaviorByte: UInt8,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        pitchVelocity[id] = 0
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.yaw = Int32(faceYaw)
            record.behaviorParams2ndByte = Int32(behaviorByte)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state: SM64SwiftEngineState
    ) -> SM64SeesawPlatformObjectEffectRecord? {
        guard registered.contains(id), let record = state.objects.record(for: id) else { return nil }
        let output = SM64SeesawPlatformBehavior.update(
            SM64SeesawPlatformInput(
                facePitch: record.faceAngles.pitch,
                pitchVelocity: pitchVelocity[id] ?? 0,
                distanceToMario: record.distanceToMario,
                angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
                moveAngleYaw: Int16(truncatingIfNeeded: record.moveAngles.yaw),
                marioIsOnPlatform: record.platform != nil
            )
        )
        pitchVelocity[id] = output.pitchVelocity
        _ = state.objects.mutate(id) { next in
            next.faceAngles.pitch = output.facePitch
            next.angleVelocity.pitch = Int32(output.pitchVelocity)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64SeesawPlatformObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        pitchVelocity.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
