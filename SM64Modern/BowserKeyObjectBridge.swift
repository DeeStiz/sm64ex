import Foundation

struct SM64BowserKeyObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let action: SM64BowserKeyAction
    let effects: SM64BowserKeyEffect
    let timer: UInt32
    let scale: Float
    let faceYaw: Int16
    let faceRoll: Int16
    let graphYOffset: Float
    let tangible: Bool
    let markedForDeletion: Bool
}

struct SM64BowserKeySchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BowserKeyObjectEffectRecord]
}

/// Owner-thread bridge for the Bowser key level-list object. Movement flags
/// are copied in as input; the bridge owns hitbox state, interaction clearing,
/// and generation-safe scheduler retirement.
final class SM64BowserKeyObjectBridge {
    static let defaultModel: UInt32 = 0xCC // MODEL_BOWSER_KEY
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6B6579
    static let wallHitboxRadius: Float = 30
    static let gravity: Float = -400
    static let bounciness: Float = -70
    static let dragStrength: Float = 1000
    static let friction: Float = 1000
    static let buoyancy: Float = 200

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64BowserKeyState] = [:]
    private var inputs: [SM64ObjectID: SM64BowserKeyTickInput] = [:]
    private(set) var effectLog: [SM64BowserKeyObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64BowserKeyState? { states[id] }

    @discardableResult
    func spawnKey(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        angleVelocityYaw: Int16 = 0,
        model: UInt32 = SM64BowserKeyObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BowserKeyObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            position: position,
            faceYaw: faceYaw,
            angleVelocityYaw: angleVelocityYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bowser key could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        angleVelocityYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BowserKeyState(
            angleVelocityYaw: angleVelocityYaw,
            faceYaw: faceYaw
        )
        states[id] = state
        inputs[id] = SM64BowserKeyTickInput()
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
    func setInput(_ input: SM64BowserKeyTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    /// Clears per-tick effects before a shared scheduler pass.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    /// Advances one Bowser key in the enclosing scheduler without nesting a
    /// second object-list traversal.
    @discardableResult
    func updateInline(_ id: SM64ObjectID, pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil, states[id] != nil else { return false }
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
        inputs frameInputs: [SM64ObjectID: SM64BowserKeyTickInput] = [:]
    ) -> SM64BowserKeySchedulerTickResult {
        inputs = frameInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            _ = self?.updateInline(id, pool: pool)
        }
        pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        return SM64BowserKeySchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = states[id], let record = pool.record(for: id) else { return }
        let result = SM64BowserKeyKernel.tick(
            inputs[id] ?? defaultInput(for: record),
            state: &state
        )
        states[id] = state
        if result.effects.contains(.clearInteraction) {
            _ = pool.mutate(id) { $0.interactionStatus = 0 }
        }
        if state.markedForDeletion {
            _ = pool.markForDeletion(id)
        }
        synchronizeRecord(id: id, state: state, pool: pool)
        effectLog.append(
            SM64BowserKeyObjectEffectRecord(
                objectID: id,
                action: state.action,
                effects: result.effects,
                timer: state.timer,
                scale: state.scale,
                faceYaw: state.faceYaw,
                faceRoll: state.faceRoll,
                graphYOffset: state.graphYOffset,
                tangible: state.tangible,
                markedForDeletion: state.markedForDeletion
            )
        )
    }

    private func defaultInput(for record: SM64ObjectRecord) -> SM64BowserKeyTickInput {
        SM64BowserKeyTickInput(
            onGround: record.moveFlags & (1 << 1) != 0,
            landed: record.moveFlags & 1 != 0,
            interacted: record.interactionStatus & (1 << 15) != 0
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BowserKeyState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.faceAngles.yaw = Int32(state.faceYaw)
            record.faceAngles.roll = Int32(state.faceRoll)
            record.graphYOffset = state.graphYOffset
            record.velocity.y = state.velocityY
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.action = Int32(state.action.rawValue)
            record.wallHitboxRadius = Self.wallHitboxRadius
            record.gravity = Self.gravity
            record.dragStrength = Self.dragStrength
            record.friction = Self.friction
            record.buoyancy = Self.buoyancy
            record.hitboxRadius = SM64BowserKeyKernel.hitboxRadius
            record.hitboxHeight = SM64BowserKeyKernel.hitboxHeight
            record.hurtboxRadius = SM64BowserKeyKernel.hitboxRadius
            record.hurtboxHeight = SM64BowserKeyKernel.hitboxHeight
            record.interactionType = state.tangible ? SM64BowserKeyKernel.interactionType : 0
            record.intangibleTimer = state.tangible ? -1 : 1
            if state.markedForDeletion { record.interactionType = 0 }
        }
    }
}
