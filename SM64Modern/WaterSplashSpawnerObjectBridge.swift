import Foundation

struct SM64WaterSplashSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WaterSplashSpawnerOutput
    let spawnedDroplets: [SM64ObjectID]
}

final class SM64WaterSplashSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7773_7031
    static let particleFlag: UInt32 = 1 << 6
    static let dropletBehaviorIdentity = SM64WaterDropletObjectBridge.defaultBehaviorIdentity

    private let dropletBridge: SM64WaterDropletObjectBridge?
    private struct State { let waterLevel: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WaterSplashSpawnerObjectEffectRecord] = []

    init(dropletBridge: SM64WaterDropletObjectBridge? = nil) {
        self.dropletBridge = dropletBridge
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSplash(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100,
        activeParticleFlags: UInt32 = SM64WaterSplashSpawnerObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(
            id,
            position: position,
            waterLevel: waterLevel,
            activeParticleFlags: activeParticleFlags,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned water splash spawner could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        waterLevel: Float,
        activeParticleFlags: UInt32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(waterLevel: waterLevel)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.activeParticleFlags = activeParticleFlags
            record.animationState = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WaterSplashSpawnerObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64WaterSplashSpawnerBehavior.update(
            SM64WaterSplashSpawnerInput(
                position: record.position,
                timer: record.timer,
                activeParticleFlags: record.activeParticleFlags,
                particleFlag: Self.particleFlag,
                waterLevel: state.waterLevel
            )
        )
        var spawned: [SM64ObjectID] = []
        for _ in 0..<output.spawnDropletCount {
            if let child = try? engineState.spawnObject(
                in: .unimportant,
                behaviorIdentity: Self.dropletBehaviorIdentity,
                parent: id
            ) {
                spawned.append(child)
                _ = dropletBridge?.attach(
                    child,
                    position: output.position,
                    velocityY: 20,
                    waterLevel: state.waterLevel,
                    in: engineState.objects
                )
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.animationState = output.animationState
            next.timer &+= 1
            if output.clearParticleFlag { next.activeParticleFlags &= ~Self.particleFlag }
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64WaterSplashSpawnerObjectEffectRecord(
            objectID: id,
            output: output,
            spawnedDroplets: spawned
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
