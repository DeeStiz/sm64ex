import Foundation

struct SM64GoldenCoinSparklesObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64GoldenCoinSparklesOutput
    let spawnedChildren: [SM64ObjectID]
}

final class SM64GoldenCoinSparklesObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6763_7370

    private struct State {
        let randomOffsets: [SM64ObjectVector3]
    }

    private let coinSparklesBridge: SM64CoinSparklesObjectBridge
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64GoldenCoinSparklesObjectEffectRecord] = []

    init(coinSparklesBridge: SM64CoinSparklesObjectBridge) {
        self.coinSparklesBridge = coinSparklesBridge
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
    func spawnSparkles(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        randomOffsets: [SM64ObjectVector3] = Array(repeating: .zero, count: 3)
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, position: position, randomOffsets: randomOffsets, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned golden coin sparkles could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        randomOffsets: [SM64ObjectVector3],
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(randomOffsets: randomOffsets)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            // DISABLE_RENDERING clears the render-active bit in the C graph.
            record.graphFlags |= 0x10
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64GoldenCoinSparklesObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64GoldenCoinSparklesBehavior.update(
            SM64GoldenCoinSparklesInput(position: record.position, randomOffsets: state.randomOffsets)
        )
        var spawnedChildren: [SM64ObjectID] = []
        if output.shouldSpawnChildren {
            for position in output.childPositions {
                if let child = try? coinSparklesBridge.spawnSparkles(
                    in: engineState,
                    position: position,
                    parent: id
                ) {
                    spawnedChildren.append(child)
                }
            }
        }
        _ = engineState.objects.mutate(id) { next in
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
        let effect = SM64GoldenCoinSparklesObjectEffectRecord(
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
