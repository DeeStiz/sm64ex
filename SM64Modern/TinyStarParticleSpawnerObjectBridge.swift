import Foundation

struct SM64TinyStarParticleSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TinyStarParticleSpawnerOutput
    let spawnedChildren: [SM64ObjectID]
}

final class SM64TinyStarParticleSpawnerObjectBridge {
    static let verticalBehaviorIdentity: UInt64 = 0x6268_765F_767374
    static let horizontalBehaviorIdentity: UInt64 = 0x6268_765F_687374

    private struct State {
        let kind: SM64TinyStarParticleSpawnerKind
        let particleFlag: UInt32
        let seeds: [SM64TinyStarParticleSeed]
        let marioPosition: SM64ObjectVector3
        let marioYaw: Int32
    }

    private let particleBridge: SM64TinyStarParticleObjectBridge
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TinyStarParticleSpawnerObjectEffectRecord] = []

    init(particleBridge: SM64TinyStarParticleObjectBridge) {
        self.particleBridge = particleBridge
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnSpawner(
        in engineState: SM64SwiftEngineState,
        kind: SM64TinyStarParticleSpawnerKind,
        position: SM64ObjectVector3 = .zero,
        activeParticleFlags: UInt32 = 0,
        particleFlag: UInt32 = 0x1,
        seeds: [SM64TinyStarParticleSeed] = [],
        marioPosition: SM64ObjectVector3 = .zero,
        marioYaw: Int32 = 0
    ) throws -> SM64ObjectID {
        let identity = kind == .vertical ? Self.verticalBehaviorIdentity : Self.horizontalBehaviorIdentity
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: identity)
        guard attach(
            id,
            kind: kind,
            position: position,
            activeParticleFlags: activeParticleFlags,
            particleFlag: particleFlag,
            seeds: seeds,
            marioPosition: marioPosition,
            marioYaw: marioYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned tiny-star particle spawner could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64TinyStarParticleSpawnerKind,
        position: SM64ObjectVector3,
        activeParticleFlags: UInt32,
        particleFlag: UInt32,
        seeds: [SM64TinyStarParticleSeed],
        marioPosition: SM64ObjectVector3,
        marioYaw: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            kind: kind,
            particleFlag: particleFlag,
            seeds: seeds,
            marioPosition: marioPosition,
            marioYaw: marioYaw
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.activeParticleFlags = activeParticleFlags
            record.graphFlags |= 0x10
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64TinyStarParticleSpawnerObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64TinyStarParticleSpawnerBehavior.update(
            SM64TinyStarParticleSpawnerInput(
                kind: state.kind,
                position: record.position,
                timer: record.timer,
                activeParticleFlags: record.activeParticleFlags,
                particleFlag: state.particleFlag,
                seeds: state.seeds
            )
        )
        var spawnedChildren: [SM64ObjectID] = []
        if output.shouldSpawnChildren {
            for seed in output.seeds {
                if let child = try? particleBridge.spawnParticle(
                    in: engineState,
                    kind: state.kind == .vertical ? .wall : .pound,
                    position: record.position,
                    marioPosition: state.marioPosition,
                    marioYaw: state.marioYaw,
                    moveYaw: seed.moveYaw,
                    forwardVelocity: seed.forwardVelocity,
                    velocityY: seed.velocityY
                ) {
                    spawnedChildren.append(child)
                }
            }
        }
        _ = engineState.objects.mutate(id) { next in
            if output.clearParticleFlag { next.activeParticleFlags &= ~state.particleFlag }
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
        let effect = SM64TinyStarParticleSpawnerObjectEffectRecord(
            objectID: id,
            output: output,
            spawnedChildren: spawnedChildren
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
