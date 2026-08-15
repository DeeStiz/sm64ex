import Foundation

struct SM64BulletBillObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let effects: SM64BulletBillEffect
    let action: SM64BulletBillAction
    let spawnedSmoke: SM64ObjectID?
}

struct SM64BulletBillSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BulletBillObjectEffectRecord]
}

/// Owner-thread adapter for the copied-POD Bullet Bill projectile. Smoke is a
/// short-lived child allocation: it is appended to the live general-actor
/// list, then marked for end-of-frame unload while the renderer/effect layer
/// consumes the value-only spawn intent.
final class SM64BulletBillObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_62626C
    static let defaultModel: UInt32 = 0x54 // MODEL_BULLET_BILL
    static let smokeModel: UInt32 = 0x96 // MODEL_SMOKE
    static let smokeBehaviorIdentity: UInt64 = 0x6268_765F_736D6B

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64BulletBillState] = [:]
    private var inputs: [SM64ObjectID: SM64BulletBillTickInput] = [:]
    private(set) var effectLog: [SM64BulletBillObjectEffectRecord] = []
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

    func state(for id: SM64ObjectID) -> SM64BulletBillState? {
        states[id]
    }

    @discardableResult
    func spawnBulletBill(
        in engineState: SM64SwiftEngineState,
        initialMoveYaw: Int16 = 0,
        moveYaw: Int16? = nil,
        objectList: SM64ObjectList = .generalActor,
        model: UInt32 = SM64BulletBillObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BulletBillObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: objectList,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, initialMoveYaw: initialMoveYaw, moveYaw: moveYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bullet Bill could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        initialMoveYaw: Int16 = 0,
        moveYaw: Int16? = nil,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BulletBillState(initialMoveYaw: initialMoveYaw, moveYaw: moveYaw)
        states[id] = state
        inputs[id] = SM64BulletBillTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64BulletBillTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64BulletBillTickInput] = [:]
    ) -> SM64BulletBillSchedulerTickResult {
        inputs = frameInputs
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }

        for id in schedulerResult.unloaded {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }

        return SM64BulletBillSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var bullet = states[id], let record = pool.record(for: id) else { return }
        let previousAction = bullet.action
        let input = inputs[id] ?? defaultInput(for: record)
        let result = SM64BulletBillKernel.tick(input, state: &bullet)
        var spawnedSmoke: SM64ObjectID?

        if result.effects.contains(.spawnSmoke),
           let smoke = try? pool.spawn(
               in: .generalActor,
               model: Self.smokeModel,
               behaviorIdentity: Self.smokeBehaviorIdentity,
               parent: id,
               drawingDistance: 1_000
        ) {
            spawnedSmoke = smoke
            effectRouter.enqueue(objectID: smoke, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }

        states[id] = bullet
        synchronizeRecord(
            id: id,
            state: bullet,
            pool: pool,
            previousAction: previousAction
        )
        effectLog.append(
            SM64BulletBillObjectEffectRecord(
                objectID: id,
                effects: result.effects,
                action: bullet.action,
                spawnedSmoke: spawnedSmoke
            )
        )
    }

    private func defaultInput(for record: SM64ObjectRecord) -> SM64BulletBillTickInput {
        SM64BulletBillTickInput(
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            moveFlags: record.moveFlags,
            homeY: record.homePosition.y,
            interacted: false
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BulletBillState,
        pool: SM64ObjectPool,
        previousAction: SM64BulletBillAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position.y = state.positionY
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.pitch = Int32(state.facePitch)
            record.faceAngles.roll = Int32(state.faceRoll)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.intangibleTimer = state.intangible ? 1 : -1
            record.interactionType = state.intangible ? 0 : 1
        }
    }
}
