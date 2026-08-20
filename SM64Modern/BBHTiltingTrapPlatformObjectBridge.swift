import Foundation

struct SM64BBHTiltingTrapPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BBHTiltingTrapPlatformOutput
}

/// Owner-thread adapter for the BBH tilting trap. Collision/presentation
/// remain engine consumers; Swift owns the scalar tilt and action reducer.
final class SM64BBHTiltingTrapPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626274
    static let defaultModel: UInt32 = 0

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64BBHTiltingTrapPlatformObjectEffectRecord] = []

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
        facePitch: Int32 = 0,
        model: UInt32 = SM64BBHTiltingTrapPlatformObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BBHTiltingTrapPlatformObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, facePitch: facePitch, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned BBH tilting trap platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, facePitch: Int32 = 0, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.faceAngles.pitch = facePitch
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64BBHTiltingTrapPlatformObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64BBHTiltingTrapPlatformBehavior.update(
            SM64BBHTiltingTrapPlatformInput(
                timer: record.timer,
                previousAction: record.previousAction,
                distanceToMario: record.distanceToMario,
                angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
                facePitch: record.faceAngles.pitch,
                angleVelocityPitch: record.angleVelocity.pitch,
                marioOnPlatform: record.platform == id
            )
        )
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.faceAngles.pitch = output.facePitch
            next.angleVelocity.pitch = output.angleVelocityPitch
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64BBHTiltingTrapPlatformObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { registered.remove(id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
