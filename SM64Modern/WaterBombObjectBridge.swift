import Foundation

struct SM64WaterBombObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64WaterBombKind
    let effects: SM64WaterBombEffect
    let action: SM64WaterBombAction?
    let spawnedChildren: [SM64ObjectID]
    let markedForDeletion: Bool
}

struct SM64WaterBombSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64WaterBombObjectEffectRecord]
}

/// Owner-thread bridge for the water-bomb spawner, bomb, and shadow nodes.
/// The spawner allocates both children from the live general-actor list; the
/// scheduler therefore visits the bomb and shadow later in that same logical
/// frame, preserving the C callback and end-of-frame deletion order.
final class SM64WaterBombObjectBridge {
    static let defaultSpawnerBehaviorIdentity: UInt64 = 0x6268_765F_776273
    static let defaultBombBehaviorIdentity: UInt64 = 0x6268_765F_7762_6D
    static let defaultShadowBehaviorIdentity: UInt64 = 0x6268_765F_7762_73
    static let spawnerModel: UInt32 = 0
    static let bombModel: UInt32 = 0x54 // MODEL_WATER_BOMB
    static let shadowModel: UInt32 = 0x55 // MODEL_WATER_BOMB_SHADOW

    private let scheduler: SM64ObjectScheduler
    private var spawners: [SM64ObjectID: SM64WaterBombSpawnerState] = [:]
    private var bombs: [SM64ObjectID: SM64WaterBombState] = [:]
    private var shadows: [SM64ObjectID: SM64WaterBombShadowState] = [:]
    private var spawnerInputs: [SM64ObjectID: SM64WaterBombSpawnerTickInput] = [:]
    private var bombInputs: [SM64ObjectID: SM64WaterBombTickInput] = [:]
    private(set) var effectLog: [SM64WaterBombObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(spawners.keys) + Array(bombs.keys) + Array(shadows.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func spawnerState(for id: SM64ObjectID) -> SM64WaterBombSpawnerState? {
        spawners[id]
    }

    func bombState(for id: SM64ObjectID) -> SM64WaterBombState? {
        bombs[id]
    }

    func shadowState(for id: SM64ObjectID) -> SM64WaterBombShadowState? {
        shadows[id]
    }

    @discardableResult
    func spawnSpawner(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        radiusParameter: UInt16 = 0,
        model: UInt32 = SM64WaterBombObjectBridge.spawnerModel,
        behaviorIdentity: UInt64 = SM64WaterBombObjectBridge.defaultSpawnerBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attachSpawner(
            id,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            radiusParameter: radiusParameter,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned water-bomb spawner could not attach")
        }
        return id
    }

    @discardableResult
    func attachSpawner(
        _ id: SM64ObjectID,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        radiusParameter: UInt16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64WaterBombSpawnerState(
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            radiusParameter: radiusParameter
        )
        spawners[id] = state
        spawnerInputs[id] = SM64WaterBombSpawnerTickInput()
        synchronizeSpawner(id: id, state: state, pool: pool)
        return true
    }

    /// Allocates a standalone cannon bomb or a bomb whose parent is a
    /// spawner.  A cannon-created bomb starts in action 0 and remains
    /// intangible; a spawner-created bomb starts in action 1 and enters drop
    /// on its first callback.
    @discardableResult
    func spawnBomb(
        in engineState: SM64SwiftEngineState,
        action: SM64WaterBombAction = .initialize,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        parent: SM64ObjectID? = nil,
        model: UInt32 = SM64WaterBombObjectBridge.bombModel,
        behaviorIdentity: UInt64 = SM64WaterBombObjectBridge.defaultBombBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard attachBomb(
            id,
            action: action,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned water bomb could not attach")
        }
        return id
    }

    @discardableResult
    func attachBomb(
        _ id: SM64ObjectID,
        action: SM64WaterBombAction = .initialize,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64WaterBombState(
            action: action,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            floorHeight: floorHeight,
            moveYaw: moveYaw
        )
        bombs[id] = state
        bombInputs[id] = SM64WaterBombTickInput(floorHeight: floorHeight)
        synchronizeBomb(id: id, state: state, pool: pool, previousAction: action)
        return true
    }

    @discardableResult
    func attachShadow(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else { return false }
        _ = pool.setParent(id, parent: parent)
        let state = SM64WaterBombShadowState()
        shadows[id] = state
        synchronizeShadow(id: id, state: state, parentAction: .initialize, pool: pool)
        return true
    }

    @discardableResult
    func setSpawnerInput(_ input: SM64WaterBombSpawnerTickInput, for id: SM64ObjectID) -> Bool {
        guard spawners[id] != nil else { return false }
        spawnerInputs[id] = input
        return true
    }

    @discardableResult
    func setBombInput(_ input: SM64WaterBombTickInput, for id: SM64ObjectID) -> Bool {
        guard bombs[id] != nil else { return false }
        bombInputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        spawnerInputs frameSpawnerInputs: [SM64ObjectID: SM64WaterBombSpawnerTickInput] = [:],
        bombInputs frameBombInputs: [SM64ObjectID: SM64WaterBombTickInput] = [:]
    ) -> SM64WaterBombSchedulerTickResult {
        spawnerInputs = frameSpawnerInputs
        bombInputs = frameBombInputs
        effectLog.removeAll(keepingCapacity: true)

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }

        for id in schedulerResult.unloaded {
            spawners.removeValue(forKey: id)
            bombs.removeValue(forKey: id)
            shadows.removeValue(forKey: id)
            spawnerInputs.removeValue(forKey: id)
            bombInputs.removeValue(forKey: id)
        }
        for id in Array(spawners.keys) where engineState.objects.record(for: id) == nil {
            spawners.removeValue(forKey: id)
            spawnerInputs.removeValue(forKey: id)
        }
        for id in Array(bombs.keys) where engineState.objects.record(for: id) == nil {
            bombs.removeValue(forKey: id)
            bombInputs.removeValue(forKey: id)
        }
        for id in Array(shadows.keys) where engineState.objects.record(for: id) == nil {
            shadows.removeValue(forKey: id)
        }

        return SM64WaterBombSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if let spawner = spawners[id] {
            updateSpawner(id: id, state: spawner, pool: pool)
        } else if let bomb = bombs[id] {
            updateBomb(id: id, state: bomb, pool: pool)
        } else if let shadow = shadows[id] {
            updateShadow(id: id, state: shadow, pool: pool)
        }
    }

    private func updateSpawner(
        id: SM64ObjectID,
        state initialState: SM64WaterBombSpawnerState,
        pool: SM64ObjectPool
    ) {
        var state = initialState
        let input = spawnerInputs[id] ?? SM64WaterBombSpawnerTickInput()
        let result = SM64WaterBombKernel.tickSpawner(input, state: &state)
        var spawnedChildren: [SM64ObjectID] = []

        if result.effects.contains(.spawnBomb),
           let bombID = try? pool.spawn(
               in: .generalActor,
               model: Self.bombModel,
               behaviorIdentity: Self.defaultBombBehaviorIdentity,
               parent: id
           ) {
            let ahead = 28 * input.marioForwardVelocity + 100
            let bomb = SM64WaterBombState(
                action: .initialize,
                positionX: input.marioX + ahead * SM64CanonicalTrig.sins(input.marioMoveYaw),
                positionY: state.positionY + 2_000,
                positionZ: input.marioZ + ahead * SM64CanonicalTrig.coss(input.marioMoveYaw),
                floorHeight: pool.record(for: id)?.floorHeight ?? 0,
                moveYaw: input.marioMoveYaw
            )
            bombs[bombID] = bomb
            bombInputs[bombID] = SM64WaterBombTickInput(floorHeight: bomb.floorHeight)
            synchronizeBomb(id: bombID, state: bomb, pool: pool, previousAction: bomb.action)
            spawnedChildren.append(bombID)

            if let shadowID = try? pool.spawn(
                in: .generalActor,
                model: Self.shadowModel,
                behaviorIdentity: Self.defaultShadowBehaviorIdentity,
                parent: bombID
            ) {
                let shadow = SM64WaterBombShadowState()
                shadows[shadowID] = shadow
                synchronizeShadow(
                    id: shadowID,
                    state: shadow,
                    parentAction: bomb.action,
                    pool: pool
                )
                spawnedChildren.append(shadowID)
            }
        }

        spawners[id] = state
        synchronizeSpawner(id: id, state: state, pool: pool)
        effectLog.append(
            SM64WaterBombObjectEffectRecord(
                objectID: id,
                kind: .spawner,
                effects: result.effects,
                action: nil,
                spawnedChildren: spawnedChildren,
                markedForDeletion: false
            )
        )
    }

    private func updateBomb(
        id: SM64ObjectID,
        state initialState: SM64WaterBombState,
        pool: SM64ObjectPool
    ) {
        guard pool.record(for: id) != nil else { return }
        var state = initialState
        let previousAction = state.action
        let input = bombInputs[id] ?? defaultBombInput(for: id, pool: pool)
        let result = SM64WaterBombKernel.tickBomb(input, state: &state)
        bombs[id] = state

        if result.effects.contains(.clearSpawner),
           let parentID = pool.record(for: id)?.parent,
           var parent = spawners[parentID] {
            parent.bombActive = false
            spawners[parentID] = parent
            synchronizeSpawner(id: parentID, state: parent, pool: pool)
        }

        synchronizeBomb(id: id, state: state, pool: pool, previousAction: previousAction)
        if state.markedForDeletion { _ = pool.markForDeletion(id) }
        effectLog.append(
            SM64WaterBombObjectEffectRecord(
                objectID: id,
                kind: .bomb,
                effects: result.effects,
                action: state.action,
                spawnedChildren: [],
                markedForDeletion: state.markedForDeletion
            )
        )
    }

    private func updateShadow(
        id: SM64ObjectID,
        state initialState: SM64WaterBombShadowState,
        pool: SM64ObjectPool
    ) {
        guard let record = pool.record(for: id),
              let parent = bombs[record.parent] else {
            _ = pool.markForDeletion(id)
            shadows[id]?.markedForDeletion = true
            return
        }
        var state = initialState
        let result = SM64WaterBombKernel.tickShadow(parent: parent, state: &state)
        shadows[id] = state
        synchronizeShadow(id: id, state: state, parentAction: parent.action, pool: pool)
        if state.markedForDeletion { _ = pool.markForDeletion(id) }
        effectLog.append(
            SM64WaterBombObjectEffectRecord(
                objectID: id,
                kind: .shadow,
                effects: result.effects,
                action: parent.action,
                spawnedChildren: [],
                markedForDeletion: state.markedForDeletion
            )
        )
    }

    private func defaultBombInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64WaterBombTickInput {
        guard let record = pool.record(for: id) else { return SM64WaterBombTickInput() }
        return SM64WaterBombTickInput(
            moveFlags: record.moveFlags,
            interacted: record.interactionStatus != 0,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            floorHeight: record.floorHeight
        )
    }

    private func synchronizeSpawner(
        id: SM64ObjectID,
        state: SM64WaterBombSpawnerState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = record.position
            record.behaviorParams = Int32(state.radiusParameter)
            record.action = state.bombActive ? 1 : 0
            record.timer = Int32(truncatingIfNeeded: state.timer)
        }
    }

    private func synchronizeBomb(
        id: SM64ObjectID,
        state: SM64WaterBombState,
        pool: SM64ObjectPool,
        previousAction: SM64WaterBombAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.scale = SM64ObjectVector3(x: state.scaleX, y: state.scaleY, z: state.scaleZ)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.moveFlags = state.moveFlags
            record.floorHeight = state.floorHeight
            record.graphYOffset = 40 * state.scaleY
            record.hitboxDownOffset = state.hitbox.downOffset
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.health = Int32(state.hitbox.health)
            record.numLootCoins = Int32(state.hitbox.numLootCoins)
            record.interactionType = state.action == .drop ? state.hitbox.interactType : 0
        }
    }

    private func synchronizeShadow(
        id: SM64ObjectID,
        state: SM64WaterBombShadowState,
        parentAction: SM64WaterBombAction,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.scale = SM64ObjectVector3(x: state.scaleX, y: state.scaleY, z: state.scaleZ)
            record.action = Int32(parentAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.interactionType = 0
            record.intangibleTimer = 1
        }
    }
}
