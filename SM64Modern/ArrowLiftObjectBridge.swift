import Foundation

struct SM64ArrowLiftObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ArrowLiftOutput
}

/// Owner-thread adapter for `bhvArrowLift`. The value kernel owns the exact
/// action/timer gate and canonical movement vectors; this bridge owns the
/// object-list lifetime, displacement storage, and POD record mutation.
final class SM64ArrowLiftObjectBridge {
    // Stable source identity used by the Swift behavior manifest and schema-4
    // object traces. The suffix is an intentionally compact `bhv_arlf` token.
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6172_6C66
    static let defaultModel: UInt32 = 0

    private var registered: Set<SM64ObjectID> = []
    private var displacement: [SM64ObjectID: Float] = [:]
    private(set) var effectLog: [SM64ArrowLiftObjectEffectRecord] = []

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
    func spawnArrowLift(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        model: UInt32 = SM64ArrowLiftObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64ArrowLiftObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, position: position, faceYaw: faceYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned arrow lift could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        displacement[id] = 0
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.yaw = Int32(faceYaw)
            record.moveAngles.yaw = Int32(faceYaw)
            record.action = 0
            record.timer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        pool: SM64ObjectPool
    ) -> SM64ArrowLiftObjectEffectRecord? {
        guard registered.contains(id), let record = pool.record(for: id) else { return nil }
        let output = SM64ArrowLiftBehavior.update(
            SM64ArrowLiftInput(
                action: record.action,
                timer: record.timer,
                faceYaw: Int16(truncatingIfNeeded: record.faceAngles.yaw),
                displacement: displacement[id] ?? 0,
                marioIsOnPlatform: record.platform != nil
            )
        )
        displacement[id] = output.displacement
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = pool.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.moveAngles.yaw = Int32(output.moveYaw)
            next.forwardVelocity = output.forwardVelocity
            next.velocity.x = output.deltaX
            next.velocity.y = output.velocityY
            next.velocity.z = output.deltaZ
            next.position.x += output.deltaX
            next.position.y += output.velocityY
            next.position.z += output.deltaZ
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64ArrowLiftObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        displacement.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
