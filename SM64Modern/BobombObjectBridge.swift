import Foundation

struct SM64BobombObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let subtype: SM64BobombSubtype
    let heldState: SM64BobombHeldState
    let action: SM64BobombAction
    let effects: SM64BobombEffect
    let spawnedChildren: [SM64ObjectID]
    let markedForDeletion: Bool
}

struct SM64BobombSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BobombObjectEffectRecord]
}

/// Owner-thread bridge for the generic and stationary Bob-omb behaviors. The
/// C actor's explosion, fuse smoke, and coin are represented as transient
/// unimportant children so allocation and end-of-frame unload remain visible
/// without retaining C pointers.
final class SM64BobombObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626F_62
    static let bobombModel: UInt32 = 0xBC // MODEL_BLACK_BOBOMB
    static let explosionModel: UInt32 = 0xCD // MODEL_EXPLOSION
    static let smokeModel: UInt32 = 0x96 // MODEL_SMOKE
    static let coinModel: UInt32 = 0x74 // MODEL_YELLOW_COIN

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64BobombState] = [:]
    private var inputs: [SM64ObjectID: SM64BobombTickInput] = [:]
    private(set) var effectLog: [SM64BobombObjectEffectRecord] = []
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

    func state(for id: SM64ObjectID) -> SM64BobombState? {
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
        input: SM64BobombTickInput? = nil,
        pool: SM64ObjectPool
    ) -> SM64BobombObjectEffectRecord? {
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
    func spawnBobomb(
        in engineState: SM64SwiftEngineState,
        subtype: SM64BobombSubtype = .generic,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0,
        heldState: SM64BobombHeldState = .free,
        action: SM64BobombAction = .patrol,
        model: UInt32 = SM64BobombObjectBridge.bobombModel,
        behaviorIdentity: UInt64 = SM64BobombObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            subtype: subtype,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            floorHeight: floorHeight,
            moveYaw: moveYaw,
            heldState: heldState,
            action: action,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bob-omb could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        subtype: SM64BobombSubtype = .generic,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0,
        heldState: SM64BobombHeldState = .free,
        action: SM64BobombAction = .patrol,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BobombState(
            subtype: subtype,
            heldState: heldState,
            action: action,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            floorHeight: floorHeight,
            moveYaw: moveYaw
        )
        states[id] = state
        inputs[id] = SM64BobombTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64BobombTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64BobombTickInput] = [:]
    ) -> SM64BobombSchedulerTickResult {
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
        return SM64BobombSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var bobomb = states[id], pool.record(for: id) != nil else { return }
        let previousAction = bobomb.action
        let input = inputs[id] ?? defaultInput(for: id, pool: pool)
        let result = SM64BobombKernel.tick(input, state: &bobomb)
        states[id] = bobomb
        synchronizeRecord(id: id, state: bobomb, pool: pool, previousAction: previousAction)

        var spawnedChildren: [SM64ObjectID] = []
        if result.effects.contains(.explosion),
           let child = spawnTransient(
               model: Self.explosionModel,
               behaviorIdentity: 0x6268_765F_6578_70,
               parent: id,
               pool: pool
           ) {
            _ = pool.mutate(child) { $0.graphYOffset = 100 }
            spawnedChildren.append(child)
        }
        if result.effects.contains(.fuseSmoke),
           let child = spawnTransient(
               model: Self.smokeModel,
               behaviorIdentity: 0x6268_765F_736D_6B,
               parent: id,
               pool: pool
           ) {
            spawnedChildren.append(child)
        }
        if result.effects.contains(.coin),
           let child = spawnTransient(
               model: Self.coinModel,
               behaviorIdentity: 0x6268_765F_636F_69,
               parent: id,
               pool: pool
           ) {
            spawnedChildren.append(child)
        }

        if bobomb.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        effectLog.append(
            SM64BobombObjectEffectRecord(
                objectID: id,
                subtype: bobomb.subtype,
                heldState: bobomb.heldState,
                action: bobomb.action,
                effects: result.effects,
                spawnedChildren: spawnedChildren,
                markedForDeletion: bobomb.markedForDeletion
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

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64BobombTickInput {
        guard let record = pool.record(for: id) else { return SM64BobombTickInput() }
        let dx = record.position.x - record.homePosition.x
        let dz = record.position.z - record.homePosition.z
        let distanceFromHome = (dx * dx + dz * dz).squareRoot()
        let floorDeath = record.moveFlags & ((1 << 11) | (1 << 14)) != 0
        return SM64BobombTickInput(
            activeWithinRadius: record.distanceToMario < record.drawingDistance,
            distanceFromHome: distanceFromHome,
            homeRadiusExceeded: record.distanceToMario > 4_000,
            facingTowardMario: abs(Int32(record.angleToMario) - record.moveAngles.yaw) <= 0x2000,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            marioYaw: Int16(truncatingIfNeeded: record.moveAngles.yaw),
            marioX: record.position.x,
            marioY: record.position.y,
            marioZ: record.position.z,
            interacted: record.interactionStatus & (1 << 15) != 0,
            marioUnk1: record.interactionStatus & (1 << 1) != 0,
            touchedBobomb: record.interactionStatus & Int32(SM64BobombKernel.touchedBobombStatus) != 0,
            attackCollided: record.interactionStatus & (1 << 14) != 0,
            moveFlags: record.moveFlags,
            floorDeath: floorDeath
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BobombState,
        pool: SM64ObjectPool,
        previousAction: SM64BobombAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(
                x: state.positionX,
                y: state.positionY,
                z: state.positionZ
            )
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.gravity = state.gravity
            record.friction = state.friction
            record.buoyancy = state.buoyancy
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.faceYaw)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.subAction = Int32(state.subtype.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.heldState = UInt32(state.heldState.rawValue)
            record.behaviorParams2ndByte = Int32(state.subtype.rawValue)
            record.graphFlags = state.hidden
                ? record.graphFlags | SM64ObjectScheduler.graphRenderHasAnimation | 0x10
                : record.graphFlags & ~UInt16(0x10)
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.interactionSubtype = state.hitbox.interactionSubtype
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.health = Int32(state.hitbox.health)
            record.numLootCoins = Int32(state.hitbox.numLootCoins)
        }
    }
}
