import Foundation

struct SM64StaticCheckeredPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64StaticCheckeredPlatformOutput
}

/// Owner-thread adapter for the debug-controlled static checkered platform.
/// Debug inputs are copied per object, avoiding a Swift dependency on C's
/// mutable `gDebugInfo` storage.
final class SM64StaticCheckeredPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_736370
    static let defaultModel: UInt32 = 0

    private struct State: Sendable {
        let mode: Int32
        let debugPitch: Int32
        let debugYaw: Int32
        let debugRoll: Int32
        let debugVelocityPitch: Int32
        let debugVelocityYaw: Int32
        let debugVelocityRoll: Int32
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64StaticCheckeredPlatformObjectEffectRecord] = []

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
        mode: Int32 = 0,
        debugPitch: Int32 = 0,
        debugYaw: Int32 = 0,
        debugRoll: Int32 = 0,
        debugVelocityPitch: Int32 = 0,
        debugVelocityYaw: Int32 = 0,
        debugVelocityRoll: Int32 = 0,
        model: UInt32 = SM64StaticCheckeredPlatformObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64StaticCheckeredPlatformObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            mode: mode,
            debugPitch: debugPitch,
            debugYaw: debugYaw,
            debugRoll: debugRoll,
            debugVelocityPitch: debugVelocityPitch,
            debugVelocityYaw: debugVelocityYaw,
            debugVelocityRoll: debugVelocityRoll,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned static checkered platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        mode: Int32,
        debugPitch: Int32 = 0,
        debugYaw: Int32 = 0,
        debugRoll: Int32 = 0,
        debugVelocityPitch: Int32 = 0,
        debugVelocityYaw: Int32 = 0,
        debugVelocityRoll: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, (0...3).contains(mode) else { return false }
        registered.insert(id)
        states[id] = State(
            mode: mode,
            debugPitch: debugPitch,
            debugYaw: debugYaw,
            debugRoll: debugRoll,
            debugVelocityPitch: debugVelocityPitch,
            debugVelocityYaw: debugVelocityYaw,
            debugVelocityRoll: debugVelocityRoll
        )
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64StaticCheckeredPlatformObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              let platformState = states[id] else { return nil }
        let output = SM64StaticCheckeredPlatformBehavior.update(
            SM64StaticCheckeredPlatformInput(
                mode: platformState.mode,
                facePitch: record.faceAngles.pitch,
                faceYaw: record.faceAngles.yaw,
                faceRoll: record.faceAngles.roll,
                velocityPitch: record.angleVelocity.pitch,
                velocityYaw: record.angleVelocity.yaw,
                velocityRoll: record.angleVelocity.roll,
                debugPitch: platformState.debugPitch,
                debugYaw: platformState.debugYaw,
                debugRoll: platformState.debugRoll,
                debugVelocityPitch: platformState.debugVelocityPitch,
                debugVelocityYaw: platformState.debugVelocityYaw,
                debugVelocityRoll: platformState.debugVelocityRoll
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.faceAngles.pitch = output.facePitch
            next.faceAngles.yaw = output.faceYaw
            next.faceAngles.roll = output.faceRoll
            next.angleVelocity.pitch = output.velocityPitch
            next.angleVelocity.yaw = output.velocityYaw
            next.angleVelocity.roll = output.velocityRoll
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64StaticCheckeredPlatformObjectEffectRecord(objectID: id, output: output)
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
