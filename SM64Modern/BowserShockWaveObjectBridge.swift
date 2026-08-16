import Foundation

struct SM64BowserShockWaveObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let effects: SM64BowserShockWaveEffect
    let timer: UInt32
    let scale: Float
    let opacity: Int32
    let interactedMario: Bool
    let markedForDeletion: Bool
}

struct SM64BowserShockWaveSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BowserShockWaveObjectEffectRecord]
}

/// Owner-thread bridge for Bowser's shockwave accessory. The value kernel
/// decides the expanding/fading ring and the bridge owns Mario interaction
/// mutation plus generation-safe object retirement.
final class SM64BowserShockWaveObjectBridge {
    static let defaultModel: UInt32 = 0x68 // MODEL_BOWSER_WAVE
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_627377
    static let marioInteractionBit: Int32 = 1 << 4

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64BowserShockWaveState] = [:]
    private var inputs: [SM64ObjectID: SM64BowserShockWaveTickInput] = [:]
    private(set) var effectLog: [SM64BowserShockWaveObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64BowserShockWaveState? { states[id] }

    @discardableResult
    func setState(
        _ state: SM64BowserShockWaveState,
        for id: SM64ObjectID,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard states[id] != nil, pool.record(for: id) != nil else { return false }
        states[id] = state
        synchronizeRecord(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func spawnShockWave(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64BowserShockWaveObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BowserShockWaveObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bowser shockwave could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = SM64BowserShockWaveState()
        inputs[id] = SM64BowserShockWaveTickInput()
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.homePosition = position
            record.opacity = 255
        }
        synchronizeRecord(id: id, state: states[id]!, pool: pool)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64BowserShockWaveTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    /// Clears per-tick effect records before a shared scheduler pass.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    /// Advances one shockwave in the enclosing scheduler, optionally applying
    /// its interaction bit to the generation-checked Mario record.
    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        pool: SM64ObjectPool,
        marioID: SM64ObjectID? = nil
    ) -> Bool {
        guard pool.record(for: id) != nil, states[id] != nil else { return false }
        update(id: id, pool: pool, marioID: marioID)
        return true
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        inputs.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil {
            remove(id)
        }
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64BowserShockWaveTickInput] = [:],
        marioID: SM64ObjectID? = nil
    ) -> SM64BowserShockWaveSchedulerTickResult {
        inputs = frameInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            _ = self?.updateInline(id, pool: pool, marioID: marioID)
        }
        pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        return SM64BowserShockWaveSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool, marioID: SM64ObjectID?) {
        guard var shockWave = states[id], let record = pool.record(for: id) else { return }
        let result = SM64BowserShockWaveKernel.tick(
            inputs[id] ?? SM64BowserShockWaveTickInput(),
            state: &shockWave
        )
        states[id] = shockWave
        synchronizeRecord(id: id, state: shockWave, pool: pool)
        let interactedMario: Bool
        if result.effects.contains(.interactMario), let marioID,
           pool.record(for: marioID) != nil {
            interactedMario = pool.mutate(marioID) { mario in
                mario.interactionStatus |= Self.marioInteractionBit
            }
        } else {
            interactedMario = false
        }
        if shockWave.markedForDeletion {
            _ = pool.markForDeletion(id)
        }
        effectLog.append(
            SM64BowserShockWaveObjectEffectRecord(
                objectID: id,
                effects: result.effects,
                timer: shockWave.timer,
                scale: shockWave.scale,
                opacity: shockWave.opacity,
                interactedMario: interactedMario,
                markedForDeletion: shockWave.markedForDeletion
            )
        )
        _ = record
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BowserShockWaveState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.opacity = state.opacity
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.action = 0
        }
    }
}
