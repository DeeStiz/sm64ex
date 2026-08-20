import Foundation

struct SM64BubbleParticleSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BubbleParticleSpawnerOutput
    let spawnedChild: SM64ObjectID?
}

final class SM64BubbleParticleSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6270_7331
    static let particleFlag: UInt32 = 1 << 5
    static let childBehaviorIdentity = SM64SmallWaterWaveObjectBridge.defaultBehaviorIdentity

    private let smallWaterWaveBridge: SM64SmallWaterWaveObjectBridge?
    private struct State { let delay: Int32; let waterLevel: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BubbleParticleSpawnerObjectEffectRecord] = []

    init(smallWaterWaveBridge: SM64SmallWaterWaveObjectBridge? = nil) {
        self.smallWaterWaveBridge = smallWaterWaveBridge
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        delay: Int32 = 2,
        waterLevel: Float = 100,
        activeParticleFlags: UInt32 = SM64BubbleParticleSpawnerObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(
            id,
            position: position,
            delay: delay,
            waterLevel: waterLevel,
            activeParticleFlags: activeParticleFlags,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned bubble particle spawner could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        delay: Int32,
        waterLevel: Float,
        activeParticleFlags: UInt32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(delay: max(0, delay), waterLevel: waterLevel)
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
    ) -> SM64BubbleParticleSpawnerObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64BubbleParticleSpawnerBehavior.update(
            SM64BubbleParticleSpawnerInput(
                position: record.position,
                timer: record.timer,
                delay: state.delay,
                activeParticleFlags: record.activeParticleFlags,
                particleFlag: Self.particleFlag
            )
        )
        var child: SM64ObjectID?
        if output.spawnChild {
            child = try? engineState.spawnObject(
                in: .unimportant,
                behaviorIdentity: Self.childBehaviorIdentity,
                parent: id
            )
            if let child {
                _ = smallWaterWaveBridge?.attach(
                    child,
                    position: output.position,
                    waterLevel: state.waterLevel,
                    angleX: 0,
                    angleZ: 0,
                    angleVelocityX: 0x400,
                    angleVelocityZ: 0x400,
                    in: engineState.objects
                )
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.timer &+= 1
            if output.clearParticleFlag { next.activeParticleFlags &= ~Self.particleFlag }
            if output.shouldDeactivate { next.activeFlags = 0 }
        }
        let effect = SM64BubbleParticleSpawnerObjectEffectRecord(
            objectID: id,
            output: output,
            spawnedChild: child
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
