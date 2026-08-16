import Foundation

struct SM64KoopaShellObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64KoopaShellKind
    let effects: SM64KoopaShellEffect
    let action: SM64KoopaShellAction
    let spawnedChildren: [SM64ObjectID]
    let markedForDeletion: Bool
}

struct SM64KoopaShellSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64KoopaShellObjectEffectRecord]
}

/// Owner-thread bridge for the level-list Koopa shell and the underwater
/// holdable shell. Effect-only sparkle, wave, droplet, and flame objects are
/// allocated on the unimportant list and retired at the scheduler boundary.
final class SM64KoopaShellObjectBridge {
    static let defaultShellBehaviorIdentity: UInt64 = 0x6268_765F_6B73_68
    static let defaultUnderwaterBehaviorIdentity: UInt64 = 0x6268_765F_6B73_75
    static let shellModel: UInt32 = 0xBE // MODEL_KOOPA_SHELL
    static let sparkleModel: UInt32 = 0
    static let waveModel: UInt32 = 0xA3 // MODEL_WAVE_TRAIL
    static let waterDropModel: UInt32 = 0xA4 // MODEL_WHITE_PARTICLE_SMALL
    static let flameModel: UInt32 = 0x90 // MODEL_RED_FLAME

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var shells: [SM64ObjectID: SM64KoopaShellState] = [:]
    private var underwaters: [SM64ObjectID: SM64KoopaShellState] = [:]
    private var inputs: [SM64ObjectID: SM64KoopaShellTickInput] = [:]
    private var underwaterInputs: [SM64ObjectID: SM64KoopaShellTickInput] = [:]
    private(set) var effectLog: [SM64KoopaShellObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(shells.keys) + Array(underwaters.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64KoopaShellState? {
        shells[id] ?? underwaters[id]
    }

    @discardableResult
    func spawnShell(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0,
        forwardVelocity: Float = 0,
        parent: SM64ObjectID? = nil,
        model: UInt32 = SM64KoopaShellObjectBridge.shellModel,
        behaviorIdentity: UInt64 = SM64KoopaShellObjectBridge.defaultShellBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard attachShell(
            id,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Koopa shell could not attach")
        }
        return id
    }

    @discardableResult
    func attachShell(
        _ id: SM64ObjectID,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0,
        forwardVelocity: Float = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64KoopaShellState(
            kind: .shell,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            floorHeight: floorHeight,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity
        )
        shells[id] = state
        inputs[id] = SM64KoopaShellTickInput(floorHeight: floorHeight)
        synchronize(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func spawnUnderwaterShell(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        model: UInt32 = SM64KoopaShellObjectBridge.shellModel,
        behaviorIdentity: UInt64 = SM64KoopaShellObjectBridge.defaultUnderwaterBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attachUnderwater(
            id,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned underwater shell could not attach")
        }
        return id
    }

    @discardableResult
    func attachUnderwater(
        _ id: SM64ObjectID,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64KoopaShellState(
            kind: .underwater,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ
        )
        underwaters[id] = state
        underwaterInputs[id] = SM64KoopaShellTickInput()
        synchronize(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64KoopaShellTickInput, for id: SM64ObjectID) -> Bool {
        guard shells[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func setUnderwaterInput(_ input: SM64KoopaShellTickInput, for id: SM64ObjectID) -> Bool {
        guard underwaters[id] != nil else { return false }
        underwaterInputs[id] = input
        return true
    }

    /// Starts a shared-dispatch tick without running the standalone scheduler.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, pool: SM64ObjectPool) -> Bool {
        guard registeredIDs.contains(id), pool.record(for: id) != nil else { return false }
        update(id: id, pool: pool)
        return true
    }

    func remove(_ id: SM64ObjectID) {
        shells.removeValue(forKey: id)
        underwaters.removeValue(forKey: id)
        inputs.removeValue(forKey: id)
        underwaterInputs.removeValue(forKey: id)
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
        inputs frameInputs: [SM64ObjectID: SM64KoopaShellTickInput] = [:],
        underwaterInputs frameUnderwaterInputs: [SM64ObjectID: SM64KoopaShellTickInput] = [:]
    ) -> SM64KoopaShellSchedulerTickResult {
        inputs = frameInputs
        underwaterInputs = frameUnderwaterInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        return SM64KoopaShellSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if let shell = shells[id] {
            updateShell(id: id, state: shell, pool: pool)
        } else if let underwater = underwaters[id] {
            updateUnderwater(id: id, state: underwater, pool: pool)
        }
    }

    private func updateShell(
        id: SM64ObjectID,
        state initialState: SM64KoopaShellState,
        pool: SM64ObjectPool
    ) {
        var state = initialState
        let previousAction = state.action
        let result = SM64KoopaShellKernel.tick(
            inputs[id] ?? defaultInput(for: id, pool: pool),
            state: &state
        )
        let spawnedChildren = spawnEffects(result.effects, parent: id, pool: pool)
        shells[id] = state
        synchronize(id: id, state: state, pool: pool, previousAction: previousAction)
        if state.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        effectLog.append(
            SM64KoopaShellObjectEffectRecord(
                objectID: id,
                kind: .shell,
                effects: result.effects,
                action: state.action,
                spawnedChildren: spawnedChildren,
                markedForDeletion: state.markedForDeletion
            )
        )
    }

    private func updateUnderwater(
        id: SM64ObjectID,
        state initialState: SM64KoopaShellState,
        pool: SM64ObjectPool
    ) {
        var state = initialState
        let previousAction = state.action
        let result = SM64KoopaShellKernel.tick(
            underwaterInputs[id] ?? SM64KoopaShellTickInput(),
            state: &state
        )
        let spawnedChildren = result.effects.contains(.spawnMist)
            ? spawnMist(parent: id, pool: pool)
            : []
        underwaters[id] = state
        synchronize(id: id, state: state, pool: pool, previousAction: previousAction)
        if state.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        effectLog.append(
            SM64KoopaShellObjectEffectRecord(
                objectID: id,
                kind: .underwater,
                effects: result.effects,
                action: state.action,
                spawnedChildren: spawnedChildren,
                markedForDeletion: state.markedForDeletion
            )
        )
    }

    private func spawnEffects(
        _ effects: SM64KoopaShellEffect,
        parent: SM64ObjectID,
        pool: SM64ObjectPool
    ) -> [SM64ObjectID] {
        var children: [SM64ObjectID] = []
        if effects.contains(.spawnSparkle), let id = spawnTransient(model: Self.sparkleModel, parent: parent, pool: pool) {
            children.append(id)
        }
        if effects.contains(.spawnWaveTrail), let id = spawnTransient(model: Self.waveModel, parent: parent, pool: pool) {
            children.append(id)
        }
        if effects.contains(.spawnWaterDrop), let id = spawnTransient(model: Self.waterDropModel, parent: parent, pool: pool) {
            children.append(id)
        }
        if effects.contains(.spawnFlames) {
            for _ in 0..<2 {
                if let id = spawnTransient(model: Self.flameModel, parent: parent, pool: pool) {
                    children.append(id)
                }
            }
        }
        return children
    }

    private func spawnMist(parent: SM64ObjectID, pool: SM64ObjectPool) -> [SM64ObjectID] {
        guard let id = spawnTransient(model: 0, parent: parent, pool: pool) else { return [] }
        return [id]
    }

    private func spawnTransient(
        model: UInt32,
        parent: SM64ObjectID,
        pool: SM64ObjectPool
    ) -> SM64ObjectID? {
        guard let id = try? pool.spawn(
            in: .unimportant,
            model: model,
            behaviorIdentity: Self.defaultShellBehaviorIdentity,
            parent: parent,
            drawingDistance: 1_000
        ) else { return nil }
        effectRouter.enqueue(objectID: id, kind: .markForDeletion)
        deliveryLog.append(effectRouter.deliver(to: pool))
        return id
    }

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64KoopaShellTickInput {
        guard let record = pool.record(for: id) else { return SM64KoopaShellTickInput() }
        return SM64KoopaShellTickInput(
            moveFlags: record.moveFlags,
            wallYaw: Int16(truncatingIfNeeded: record.moveAngles.yaw),
            floorHeight: record.floorHeight,
            floorType: record.floorType,
            interacted: record.interactionStatus != 0,
            stopRiding: UInt32(bitPattern: record.interactionStatus) & (1 << 22) != 0
        )
    }

    private func synchronize(
        id: SM64ObjectID,
        state: SM64KoopaShellState,
        pool: SM64ObjectPool,
        previousAction: SM64KoopaShellAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.scale = .one
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveFlags = state.moveFlags
            record.floorHeight = state.floorHeight
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.faceYaw)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.heldState = UInt32(state.heldState.rawValue)
            record.hitboxDownOffset = state.hitbox.downOffset
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.health = Int32(state.hitbox.health)
            record.numLootCoins = Int32(state.hitbox.numLootCoins)
            record.interactionType = state.hidden || state.markedForDeletion ? 0 : state.hitbox.interactType
            record.intangibleTimer = state.hidden ? 1 : -1
        }
    }
}
