import Foundation

struct SM64ShallowWaterWaveObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64ShallowWaterWaveOutput
    let spawnedDroplets: [SM64ObjectID]
}

final class SM64ShallowWaterWaveObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7377_7731
    static let splashBehaviorIdentity: UInt64 = 0x6268_765F_7373_7031
    static let particleFlag: UInt32 = 1 << 10
    static let splashParticleFlag: UInt32 = 1 << 12
    static let dropletBehaviorIdentity = SM64WaterDropletObjectBridge.defaultBehaviorIdentity

    private let dropletBridge: SM64WaterDropletObjectBridge?

    private struct State { let waterLevel: Float; let kind: SM64ShallowWaterParticleKind }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64ShallowWaterWaveObjectEffectRecord] = []

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
    func spawnWave(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100,
        activeParticleFlags: UInt32 = SM64ShallowWaterWaveObjectBridge.particleFlag
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(
            id,
            kind: .wave,
            position: position,
            waterLevel: waterLevel,
            activeParticleFlags: activeParticleFlags,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned shallow-water wave could not attach")
        }
        return id
    }

    @discardableResult
    func spawnSplash(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100,
        activeParticleFlags: UInt32 = SM64ShallowWaterWaveObjectBridge.splashParticleFlag
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.splashBehaviorIdentity
        )
        guard attach(
            id,
            kind: .splash,
            position: position,
            waterLevel: waterLevel,
            activeParticleFlags: activeParticleFlags,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned shallow-water splash could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64ShallowWaterParticleKind = .wave,
        position: SM64ObjectVector3,
        waterLevel: Float,
        activeParticleFlags: UInt32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(waterLevel: waterLevel, kind: kind)
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
    ) -> SM64ShallowWaterWaveObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64ShallowWaterWaveBehavior.update(
            SM64ShallowWaterWaveInput(
                kind: state.kind,
                position: record.position,
                timer: record.timer,
                activeParticleFlags: record.activeParticleFlags,
                particleFlag: state.kind == .wave ? Self.particleFlag : Self.splashParticleFlag,
                waterLevel: state.waterLevel
            )
        )
        var spawned: [SM64ObjectID] = []
        if output.spawnDropletCount > 0 {
            for _ in 0..<output.spawnDropletCount {
                if let child = try? engineState.spawnObject(
                    in: .unimportant,
                    behaviorIdentity: Self.dropletBehaviorIdentity,
                    parent: id
                ) {
                    spawned.append(child)
                    _ = engineState.objects.mutate(child) { next in
                        next.position = record.position
                        next.velocity.y = 20
                        next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                            | SM64ObjectScheduler.objectFlagBuildTransform
                    }
                    _ = dropletBridge?.attach(
                        child,
                        position: record.position,
                        velocityY: 20,
                        waterLevel: state.waterLevel,
                        in: engineState.objects
                    )
                }
            }
        }
        _ = engineState.objects.mutate(id) { next in
            if output.clearParticleFlag {
                next.activeParticleFlags &= ~(state.kind == .wave ? Self.particleFlag : Self.splashParticleFlag)
            }
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
        }
        let effect = SM64ShallowWaterWaveObjectEffectRecord(
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
