import Foundation

struct SM64StarKeyCollectionPuffSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64StarKeyCollectionPuffSpawnerOutput
    let spawnedPuffs: [SM64ObjectID]
}

final class SM64StarKeyCollectionPuffSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_736B70
    private let puffBridge: SM64WhitePuffExplosionObjectBridge
    private var states: [SM64ObjectID: [SM64StarKeyPuffSeed]] = [:]
    private(set) var effectLog: [SM64StarKeyCollectionPuffSpawnerObjectEffectRecord] = []

    init(puffBridge: SM64WhitePuffExplosionObjectBridge) {
        self.puffBridge = puffBridge
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
        position: SM64ObjectVector3 = .zero,
        seeds: [SM64StarKeyPuffSeed] = SM64StarKeyCollectionPuffSpawnerObjectBridge.defaultSeeds
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, position: position, seeds: seeds, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned star-key puff spawner could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        seeds: [SM64StarKeyPuffSeed],
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = seeds
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64StarKeyCollectionPuffSpawnerObjectEffectRecord? {
        guard let seeds = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64StarKeyCollectionPuffSpawnerBehavior.update(.init(
            position: record.position,
            timer: record.timer,
            seeds: seeds
        ))
        var spawned: [SM64ObjectID] = []
        if output.spawnPuffs {
            for seed in output.seeds {
                guard let child = try? engineState.spawnObject(
                    in: .unimportant,
                    behaviorIdentity: SM64WhitePuffExplosionObjectBridge.defaultBehaviorIdentity,
                    parent: id
                ) else { continue }
                _ = puffBridge.attach(
                    child,
                    position: .init(x: output.position.x, y: output.position.y + 10, z: output.position.z),
                    velocity: seed.velocity,
                    gravity: 330,
                    dragStrength: 10,
                    initialScale: seed.scale,
                    behaviorParam: 2,
                    in: engineState.objects
                )
                spawned.append(child)
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
        }
        let effect = SM64StarKeyCollectionPuffSpawnerObjectEffectRecord(
            objectID: id,
            output: output,
            spawnedPuffs: spawned
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

    static let defaultSeeds: [SM64StarKeyPuffSeed] = (0..<20).map { index in
        // Deterministic replay fallback; live callers inject the C RNG values.
        let yaw = Int16(truncatingIfNeeded: index * 0x1337)
        let speed = 5 + Float(index % 5)
        let velocityY = 20 + Float(index % 6)
        return SM64StarKeyPuffSeed(
            velocity: .init(
                x: speed * SM64CanonicalTrig.sins(yaw),
                y: velocityY,
                z: speed * SM64CanonicalTrig.coss(yaw)
            ),
            scale: 3 + Float(index % 4) * 0.05
        )
    }
}
