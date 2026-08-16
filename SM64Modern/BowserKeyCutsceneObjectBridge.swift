import Foundation

struct SM64BowserKeyCutsceneObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64BowserKeyCutsceneKind
    let effects: SM64BowserKeyCutsceneEffect
    let animationFrame: Int32
    let animation: Int32
    let scale: Float
    let timer: UInt32
    let markedForDeletion: Bool
}

struct SM64BowserKeyCutsceneSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BowserKeyCutsceneObjectEffectRecord]
}

/// Owner-thread bridge for the cutscene-only Bowser key scale callbacks.
/// Camera/dialog ownership remains outside this bounded object seam.
final class SM64BowserKeyCutsceneObjectBridge {
    static let defaultModel: UInt32 = 0xC8 // MODEL_BOWSER_KEY_CUTSCENE
    static let unlockDoorBehaviorIdentity: UInt64 = 0x6268_765F_6B75646F
    static let courseExitBehaviorIdentity: UInt64 = 0x6268_765F_6B637865

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64BowserKeyCutsceneState] = [:]
    private var inputs: [SM64ObjectID: SM64BowserKeyCutsceneTickInput] = [:]
    private(set) var effectLog: [SM64BowserKeyCutsceneObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64BowserKeyCutsceneState? { states[id] }

    @discardableResult
    func setState(
        _ state: SM64BowserKeyCutsceneState,
        for id: SM64ObjectID,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard states[id] != nil, pool.record(for: id) != nil else { return false }
        states[id] = state
        synchronizeRecord(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func spawn(
        kind: SM64BowserKeyCutsceneKind,
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64BowserKeyCutsceneObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let behaviorIdentity = kind == .unlockDoor
            ? Self.unlockDoorBehaviorIdentity
            : Self.courseExitBehaviorIdentity
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, kind: kind, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bowser key cutscene could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64BowserKeyCutsceneKind,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BowserKeyCutsceneState(kind: kind)
        states[id] = state
        inputs[id] = SM64BowserKeyCutsceneTickInput()
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.homePosition = position
        }
        synchronizeRecord(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64BowserKeyCutsceneTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    /// Starts a shared-dispatch tick without running the standalone scheduler.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, pool: SM64ObjectPool) -> Bool {
        guard states[id] != nil, pool.record(for: id) != nil else { return false }
        update(id: id, pool: pool)
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
        inputs frameInputs: [SM64ObjectID: SM64BowserKeyCutsceneTickInput] = [:]
    ) -> SM64BowserKeyCutsceneSchedulerTickResult {
        inputs = frameInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        return SM64BowserKeyCutsceneSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = states[id], let record = pool.record(for: id) else { return }
        let result = SM64BowserKeyCutsceneKernel.tick(
            inputs[id] ?? SM64BowserKeyCutsceneTickInput(animationFrame: record.animationState),
            state: &state
        )
        states[id] = state
        if state.markedForDeletion {
            _ = pool.markForDeletion(id)
        }
        synchronizeRecord(id: id, state: state, pool: pool)
        effectLog.append(
            SM64BowserKeyCutsceneObjectEffectRecord(
                objectID: id,
                kind: state.kind,
                effects: result.effects,
                animationFrame: state.animationFrame,
                animation: state.animation,
                scale: state.scale,
                timer: state.timer,
                markedForDeletion: state.markedForDeletion
            )
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BowserKeyCutsceneState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.animationState = state.animation
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.action = Int32(state.kind.rawValue)
        }
    }
}
