import Foundation

struct SM64PiranhaPlantObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let action: SM64PiranhaPlantAction
    let effects: SM64PiranhaPlantEffect
    let spawnedChildren: [SM64ObjectID]
    let markedForDeletion: Bool
}

struct SM64PiranhaPlantSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64PiranhaPlantObjectEffectRecord]
}

/// Owner-thread bridge for Piranha Plants. Purple attack particles and blue
/// coin loot are transient unimportant children; the plant itself remains a
/// stable general-actor record through its shrink/wait/respawn cycle.
final class SM64PiranhaPlantObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7070_6C
    static let plantModel: UInt32 = 0x64 // MODEL_PIRANHA_PLANT
    static let purpleParticleModel: UInt32 = 0xAA // MODEL_PURPLE_MARBLE
    static let blueCoinModel: UInt32 = 0x76 // MODEL_BLUE_COIN

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64PiranhaPlantState] = [:]
    private var inputs: [SM64ObjectID: SM64PiranhaPlantTickInput] = [:]
    private(set) var effectLog: [SM64PiranhaPlantObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64PiranhaPlantState? {
        states[id]
    }

    func contains(_ id: SM64ObjectID) -> Bool {
        states[id] != nil
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        input: SM64PiranhaPlantTickInput? = nil,
        pool: SM64ObjectPool
    ) -> SM64PiranhaPlantObjectEffectRecord? {
        guard states[id] != nil else { return nil }
        if let input { inputs[id] = input }
        let count = effectLog.count
        update(id: id, pool: pool)
        return effectLog.count > count ? effectLog.last : nil
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        inputs.removeValue(forKey: id)
    }

    @discardableResult
    func spawnPlant(
        in engineState: SM64SwiftEngineState,
        action: SM64PiranhaPlantAction = .idle,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64PiranhaPlantObjectBridge.plantModel,
        behaviorIdentity: UInt64 = SM64PiranhaPlantObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            action: action,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            moveYaw: moveYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Piranha Plant could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        action: SM64PiranhaPlantAction = .idle,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64PiranhaPlantState(
            action: action,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            moveYaw: moveYaw
        )
        states[id] = state
        inputs[id] = SM64PiranhaPlantTickInput()
        synchronizeRecord(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64PiranhaPlantTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64PiranhaPlantTickInput] = [:]
    ) -> SM64PiranhaPlantSchedulerTickResult {
        inputs = frameInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            _ = self?.updateInline(id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            remove(id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            remove(id)
        }
        return SM64PiranhaPlantSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var plant = states[id], pool.record(for: id) != nil else { return }
        let input = inputs[id] ?? defaultInput(for: id, pool: pool)
        let result = SM64PiranhaPlantKernel.tick(input, state: &plant)
        states[id] = plant
        synchronizeRecord(id: id, state: plant, pool: pool)

        var spawnedChildren: [SM64ObjectID] = []
        if result.effects.contains(.particles) {
            for _ in 0..<20 {
                if let child = spawnTransient(
                    model: Self.purpleParticleModel,
                    behaviorIdentity: 0x6268_765F_707572,
                    parent: id,
                    pool: pool
                ) {
                    spawnedChildren.append(child)
                }
            }
        }
        if result.effects.contains(.blueCoin),
           let child = spawnTransient(
               model: Self.blueCoinModel,
               behaviorIdentity: 0x6268_765F_62636F,
               parent: id,
               pool: pool
           ) {
            spawnedChildren.append(child)
        }
        effectLog.append(
            SM64PiranhaPlantObjectEffectRecord(
                objectID: id,
                action: plant.action,
                effects: result.effects,
                spawnedChildren: spawnedChildren,
                markedForDeletion: plant.markedForDeletion
            )
        )
    }

    private func spawnTransient(
        model: UInt32,
        behaviorIdentity: UInt64,
        parent: SM64ObjectID,
        pool: SM64ObjectPool
    ) -> SM64ObjectID? {
        guard let child = try? pool.spawn(
            in: .unimportant,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        ) else { return nil }
        effectRouter.enqueue(objectID: child, kind: .markForDeletion)
        deliveryLog.append(effectRouter.deliver(to: pool))
        return child
    }

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64PiranhaPlantTickInput {
        guard let record = pool.record(for: id) else { return SM64PiranhaPlantTickInput() }
        return SM64PiranhaPlantTickInput(
            activeWithinRadius: record.distanceToMario < record.drawingDistance,
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            marioMovingFast: record.forwardVelocity > 10 || record.velocity.y > 10,
            marioMetalCap: record.interactionSubtype & (1 << 5) != 0,
            interacted: record.interactionStatus & (1 << 15) != 0,
            wasAttacked: record.interactionStatus & (1 << 14) != 0,
            nearAnimationEnd: record.animationState != 0,
            biteAnimationFrame: Int16(truncatingIfNeeded: record.animationState)
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64PiranhaPlantState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.action = Int32(state.action.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.opacity = state.opacity
            record.graphFlags = state.hidden
                ? record.graphFlags | 0x10
                : record.graphFlags & ~UInt16(0x10)
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
        }
    }
}
