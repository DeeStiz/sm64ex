import Foundation

struct SM64BreathParticleSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BreathParticleSpawnerOutput
    let spawnedMist: SM64ObjectID?
}

final class SM64BreathParticleSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6272_7031
    static let particleFlag: UInt32 = 1 << 17
    static let mistBehaviorIdentity = SM64WaterMistObjectBridge.defaultBehaviorIdentity

    private let waterMistBridge: SM64WaterMistObjectBridge?
    private var states: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64BreathParticleSpawnerObjectEffectRecord] = []

    init(waterMistBridge: SM64WaterMistObjectBridge? = nil) {
        self.waterMistBridge = waterMistBridge
    }

    var registeredIDs: [SM64ObjectID] { states.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        activeParticleFlags: UInt32 = SM64BreathParticleSpawnerObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, activeParticleFlags: activeParticleFlags, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned breath particle spawner could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        activeParticleFlags: UInt32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.activeParticleFlags = activeParticleFlags
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64BreathParticleSpawnerObjectEffectRecord? {
        guard states.contains(id), let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64BreathParticleSpawnerBehavior.update(
            SM64BreathParticleSpawnerInput(
                position: record.position,
                timer: record.timer,
                activeParticleFlags: record.activeParticleFlags,
                particleFlag: Self.particleFlag
            )
        )
        var mist: SM64ObjectID?
        if output.spawnMist {
            mist = try? engineState.spawnObject(
                in: .unimportant,
                behaviorIdentity: Self.mistBehaviorIdentity,
                parent: id
            )
            if let mist {
                _ = waterMistBridge?.attach(
                    mist,
                    position: output.position,
                    moveYaw: record.moveAngles.yaw,
                    randomOffsetX: 0,
                    randomOffsetZ: 0,
                    in: engineState.objects
                )
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.timer &+= 1
            if output.clearParticleFlag { next.activeParticleFlags &= ~Self.particleFlag }
            if output.shouldDeactivate { next.activeFlags = 0 }
        }
        let effect = SM64BreathParticleSpawnerObjectEffectRecord(objectID: id, output: output, spawnedMist: mist)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
