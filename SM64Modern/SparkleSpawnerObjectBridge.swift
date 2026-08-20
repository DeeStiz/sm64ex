import Foundation

struct SM64SparkleSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SparkleSpawnerOutput
    let spawnedSparkle: SM64ObjectID?
}

final class SM64SparkleSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7370_7370

    private struct State {
        let randomOffset: SM64ObjectVector3
        let randomScale: Float
    }

    private let sparkleBridge: SM64SparkleObjectBridge
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64SparkleSpawnerObjectEffectRecord] = []

    init(sparkleBridge: SM64SparkleObjectBridge) {
        self.sparkleBridge = sparkleBridge
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
        randomOffset: SM64ObjectVector3 = .zero,
        randomScale: Float = 1
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(
            id,
            position: position,
            randomOffset: randomOffset,
            randomScale: randomScale,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned sparkle spawner could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        randomOffset: SM64ObjectVector3,
        randomScale: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(randomOffset: randomOffset, randomScale: randomScale)
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
    ) -> SM64SparkleSpawnerObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64SparkleSpawnerBehavior.update(
            SM64SparkleSpawnerInput(
                position: record.position,
                timer: record.timer,
                randomOffset: state.randomOffset,
                randomScale: state.randomScale
            )
        )
        var spawnedSparkle: SM64ObjectID?
        if output.shouldSpawnSparkle {
            spawnedSparkle = try? sparkleBridge.spawnSparkle(
                in: engineState,
                position: output.childPosition,
                parent: id
            )
            if let spawnedSparkle {
                _ = engineState.objects.mutate(spawnedSparkle) { child in
                    child.scale = SM64ObjectVector3(
                        x: output.childScale,
                        y: output.childScale,
                        z: output.childScale
                    )
                }
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64SparkleSpawnerObjectEffectRecord(
            objectID: id,
            output: output,
            spawnedSparkle: spawnedSparkle
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
