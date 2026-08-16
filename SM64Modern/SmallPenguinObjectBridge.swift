import Foundation

struct SM64SmallPenguinObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SmallPenguinOutput
    let presentedEffects: [SM64OwnerThreadEffectIntent]
}

struct SM64SmallPenguinSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64SmallPenguinObjectEffect]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for `bhv_small_penguin_loop`. The value kernel owns
/// action/timer decisions; this bridge owns generation-safe object records,
/// held-state presentation, behavior identity changes, transform flags, and
/// transient sound delivery.
final class SM64SmallPenguinObjectBridge {
    static let defaultModel: UInt32 = 0x57 // MODEL_PENGUIN
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_73706E
    static let babyBehaviorIdentity: UInt64 = 0x6268_765F_706273
    static let walkingSoundValue: Int32 = 6
    static let diveSoundValue: Int32 = 7
    static let heldYellSoundValue: Int32 = 8

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64SmallPenguinState] = [:]
    private var environments: [SM64ObjectID: SM64SmallPenguinInput] = [:]
    private(set) var effectLog: [SM64SmallPenguinObjectEffect] = []
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

    func state(for id: SM64ObjectID) -> SM64SmallPenguinState? {
        states[id]
    }

    @discardableResult
    func spawnPenguin(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64SmallPenguinObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64SmallPenguinObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, position: position, moveYaw: moveYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned small penguin could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        var state = SM64SmallPenguinState()
        state.moveYaw = moveYaw
        states[id] = state
        environments[id] = SM64SmallPenguinInput()
        synchronize(id: id, state: state, position: position, output: nil, previousAction: state.action, pool: pool)
        return true
    }

    @discardableResult
    func setEnvironment(_ environment: SM64SmallPenguinInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        environments[id] = environment
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        environments frameEnvironments: [SM64ObjectID: SM64SmallPenguinInput] = [:]
    ) -> SM64SmallPenguinSchedulerTickResult {
        environments = frameEnvironments
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            states.removeValue(forKey: id)
            environments.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
            environments.removeValue(forKey: id)
        }
        return SM64SmallPenguinSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = states[id], let record = pool.record(for: id) else { return }
        let previousAction = state.action
        var input = environments[id] ?? defaultEnvironment(for: record)
        state.heldState = input.heldState
        input = SM64SmallPenguinInput(
            distanceToMario: input.distanceToMario,
            angleToMario: input.angleToMario,
            nearestMotherExists: input.nearestMotherExists,
            nearestMotherDistance: input.nearestMotherDistance,
            angleToMother: input.angleToMother,
            marioDiveSliding: input.marioDiveSliding,
            marioFarAway: input.marioFarAway,
            marioPosition: input.marioPosition,
            soundStateID: input.soundStateID,
            globalTimer: input.globalTimer,
            hasBabyBehavior: input.hasBabyBehavior,
            randomUnknown110: input.randomUnknown110,
            randomUnknown108: input.randomUnknown108,
            randomUnknown104: input.randomUnknown104,
            heldState: input.heldState
        )
        let output = SM64SmallPenguinBehavior.update(input, state: state)
        state = output.state
        states[id] = state

        if output.resetHome {
            _ = pool.mutate(id) { object in
                object.position = object.homePosition
            }
        }
        if output.copiedToMario {
            _ = pool.mutate(id) { object in
                object.position = input.marioPosition
                object.gfxPosition = SM64ObjectVector3.hiddenGfxOrigin
            }
        }
        if output.setSmallPenguinBehavior {
            _ = pool.mutate(id) { object in
                object.behaviorIdentity = Self.defaultBehaviorIdentity
                object.currentBehaviorCommandIdentity = Self.defaultBehaviorIdentity
            }
        }
        if output.thrown || output.dropped {
            _ = pool.mutate(id) { object in
                object.activeFlags |= SM64ObjectPool.activeFlagActive
            }
        }

        if output.playWalkingSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: Self.walkingSoundValue)
        }
        if output.playDiveSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: Self.diveSoundValue)
        }
        if output.playHeldYellSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: Self.heldYellSoundValue)
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)

        let position = pool.record(for: id)?.position ?? record.position
        synchronize(
            id: id,
            state: state,
            position: position,
            output: output,
            previousAction: previousAction,
            pool: pool
        )
        effectLog.append(
            SM64SmallPenguinObjectEffect(
                objectID: id,
                output: output,
                presentedEffects: delivery.presented
            )
        )
    }

    private func defaultEnvironment(for record: SM64ObjectRecord) -> SM64SmallPenguinInput {
        SM64SmallPenguinInput(
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            soundStateID: record.soundStateID,
            globalTimer: UInt64(record.timer >= 0 ? record.timer : 0),
            hasBabyBehavior: record.behaviorIdentity == Self.babyBehaviorIdentity,
            heldState: Int32(record.heldState)
        )
    }

    private func synchronize(
        id: SM64ObjectID,
        state: SM64SmallPenguinState,
        position: SM64ObjectVector3,
        output: SM64SmallPenguinOutput?,
        previousAction: Int32,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.forwardVelocity = state.forwardVelocity
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.angleVelocity.yaw = Int32(output?.angleVelocityYaw ?? 0)
            record.action = state.action
            record.previousAction = previousAction
            record.timer = state.timer
            record.animationState = state.animation
            record.heldState = UInt32(max(0, state.heldState))
            if state.animation == SM64SmallPenguinBehavior.idleAnimation {
                record.graphFlags &= ~SM64ObjectScheduler.graphRenderHasAnimation
            } else {
                record.graphFlags |= SM64ObjectScheduler.graphRenderHasAnimation
            }
        }
    }
}
