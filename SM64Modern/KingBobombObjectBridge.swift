import Foundation

struct SM64KingBobombEnvironment: Equatable, Sendable {
    var input: SM64KingBobombInput

    init(input: SM64KingBobombInput = SM64KingBobombInput()) {
        self.input = input
    }
}

struct SM64KingBobombObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64KingBobombOutput
    let presentedEffects: [SM64OwnerThreadEffectIntent]
}

struct SM64KingBobombSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64KingBobombObjectEffect]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for `bhv_king_bobomb_loop`. The value kernel owns the
/// action machine; this seam owns generation-safe records, held-state input,
/// typed presentation intents, and end-of-frame retirement.
final class SM64KingBobombObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6B626D
    static let defaultModel: UInt32 = 0x56 // MODEL_KING_BOBOMB
    static let interactionSubtypeGrabsMario: UInt32 = 0x0000_0004
    static let starEffectValue: Int32 = 1

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64KingBobombState] = [:]
    private var environments: [SM64ObjectID: SM64KingBobombEnvironment] = [:]
    private(set) var effectLog: [SM64KingBobombObjectEffect] = []
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

    func state(for id: SM64ObjectID) -> SM64KingBobombState? { states[id] }

    @discardableResult
    func spawnKingBobomb(
        in engineState: SM64SwiftEngineState,
        homeY: Float = 0,
        positionY: Float? = nil,
        action: Int32 = SM64KingBobombBehavior.initializeAction,
        model: UInt32 = SM64KingBobombObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64KingBobombObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity,
            drawingDistance: 5_000
        )
        guard attach(
            id,
            homeY: homeY,
            positionY: positionY,
            action: action,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned King Bob-omb could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        homeY: Float = 0,
        positionY: Float? = nil,
        action: Int32 = SM64KingBobombBehavior.initializeAction,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        var state = SM64KingBobombState(homeY: homeY, positionY: positionY, moveYaw: 0)
        state.action = action
        states[id] = state
        environments[id] = SM64KingBobombEnvironment(
            input: SM64KingBobombInput(positionY: state.positionY)
        )
        _ = pool.mutate(id) { record in
            record.position.y = state.positionY
            record.homePosition.y = homeY
            record.activeFlags |= SM64ObjectPool.activeFlagActive
        }
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: action, animation: 0)
        return true
    }

    @discardableResult
    func setEnvironment(_ environment: SM64KingBobombEnvironment, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        environments[id] = environment
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        environments frameEnvironments: [SM64ObjectID: SM64KingBobombEnvironment] = [:]
    ) -> SM64KingBobombSchedulerTickResult {
        environments = frameEnvironments
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, engineState: engineState, pool: pool)
        }
        for id in schedulerResult.unloaded {
            states.removeValue(forKey: id)
            environments.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
            environments.removeValue(forKey: id)
        }
        return SM64KingBobombSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(
        id: SM64ObjectID,
        engineState: SM64SwiftEngineState,
        pool: SM64ObjectPool
    ) {
        guard let oldState = states[id], let record = pool.record(for: id) else { return }
        let input = environments[id]?.input ?? defaultInput(for: oldState, record: record)
        let previousAction = oldState.action
        let output = SM64KingBobombBehavior.update(input, state: oldState)
        states[id] = output.state
        _ = pool.mutate(id) { $0.heldState = UInt32(input.heldState.rawValue) }
        synchronizeRecord(
            id: id,
            state: output.state,
            pool: pool,
            previousAction: previousAction,
            animation: output.animation,
            clearInteraction: output.effects.contains(.clearGrab)
        )

        for sound in output.soundValues {
            effectRouter.enqueue(objectID: id, kind: .sound, value: sound)
        }
        for sound in output.soundSpawnerValues {
            effectRouter.enqueue(objectID: id, kind: .sound, value: sound, auxiliary: 1)
        }
        if output.effects.contains(.bossMusic) {
            effectRouter.enqueue(objectID: id, kind: .music, value: 1)
        }
        if output.effects.contains(.stopBossMusic) {
            effectRouter.enqueue(objectID: id, kind: .music, value: 0)
        }
        if output.effects.contains(.mist) {
            effectRouter.enqueue(objectID: id, kind: .particle, value: 1)
        }
        if output.effects.contains(.triangleBreak) {
            effectRouter.enqueue(objectID: id, kind: .particle, value: 2)
        }
        if output.cameraShake != 0 {
            effectRouter.enqueue(objectID: id, kind: .cameraShake, value: output.cameraShake)
        } else if output.effects.contains(.shake) {
            effectRouter.enqueue(objectID: id, kind: .cameraShake, value: 1)
        }
        if output.dialogRequested, output.dialogID > 0 {
            effectRouter.enqueue(objectID: id, kind: .dialog, value: output.dialogID)
        }
        if output.starPosition != nil {
            effectRouter.enqueue(objectID: id, kind: .star, value: Self.starEffectValue)
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)
        effectLog.append(
            SM64KingBobombObjectEffect(
                objectID: id,
                output: output,
                presentedEffects: delivery.presented
            )
        )
        _ = engineState.setCurrentObject(nil)
    }

    private func defaultInput(
        for state: SM64KingBobombState,
        record: SM64ObjectRecord
    ) -> SM64KingBobombInput {
        SM64KingBobombInput(
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            positionY: record.position.y,
            dialogComplete: record.dialogState != 0,
            animationFrame: Int16(truncatingIfNeeded: record.animationState),
            animationNearEnd: record.animationState != 0,
            landed: record.moveFlags & 1 != 0,
            onGround: record.moveFlags & 1 != 0,
            grabbedMario: record.heldState == UInt32(SM64KingBobombHeldState.held.rawValue),
            marioFarBelow: record.position.y - state.homeY < -1_200,
            heldState: SM64KingBobombHeldState(rawValue: Int32(record.heldState)) ?? .free
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64KingBobombState,
        pool: SM64ObjectPool,
        previousAction: Int32,
        animation: Int32,
        clearInteraction: Bool = false
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position.y = state.positionY
            record.homePosition.y = state.homeY
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.action = state.action
            record.previousAction = previousAction
            record.subAction = state.subAction
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.animationState = animation
            record.health = state.health
            record.interactionType = state.tangible ? UInt32(state.interactionMode) : 0
            record.interactionSubtype = state.tangible && state.holdable
                ? Self.interactionSubtypeGrabsMario
                : 0
            record.intangibleTimer = state.tangible ? -1 : 1
            record.graphFlags = state.hidden ? record.graphFlags | 0x10 : record.graphFlags & ~0x10
            record.drawingDistance = 5_000
            record.gravity = state.gravity
            record.buoyancy = 0
            if clearInteraction { record.interactionStatus = 0 }
        }
    }
}
