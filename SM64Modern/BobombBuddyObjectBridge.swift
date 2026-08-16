import Foundation

/// Immutable owner-thread inputs for one Bob-omb Buddy tick. The optional
/// cannon ID is a generation-safe replacement for C's nearest-object pointer;
/// when present, the bridge derives cannon existence from the live pool.
struct SM64BobombBuddyEnvironment: Equatable, Sendable {
    var input: SM64BobombBuddyInput
    let nearestCannonID: SM64ObjectID?

    init(
        input: SM64BobombBuddyInput = SM64BobombBuddyInput(),
        nearestCannonID: SM64ObjectID? = nil
    ) {
        self.input = input
        self.nearestCannonID = nearestCannonID
    }
}

struct SM64BobombBuddyObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BobombBuddyOutput
    let nearestCannonID: SM64ObjectID?
    let presentedEffects: [SM64OwnerThreadEffectIntent]
}

struct SM64BobombBuddySchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BobombBuddyObjectEffect]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for `bhv_bobomb_buddy_loop`. All mutable object fields,
/// time-stop flags, generation checks, and effect delivery stay on the Swift
/// engine owner thread; the value reducer remains pointer-free and testable.
final class SM64BobombBuddyObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6262_62
    static let defaultModel: UInt32 = 0xC3 // MODEL_BOBOMB_BUDDY
    static let cannonClosedBehaviorIdentity: UInt64 = 0x6268_765F_63636C
    static let walkingSoundValue: Int32 = Int32(bitPattern: 0x5027_0081)
    static let readSignSoundValue: Int32 = Int32(bitPattern: 0x045B_FF81)
    static let npcInteractionSubtype: UInt32 = 0x0000_4000 // INT_SUBTYPE_NPC

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64BobombBuddyState] = [:]
    private var environments: [SM64ObjectID: SM64BobombBuddyEnvironment] = [:]
    private(set) var effectLog: [SM64BobombBuddyObjectEffect] = []
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

    func state(for id: SM64ObjectID) -> SM64BobombBuddyState? {
        states[id]
    }

    @discardableResult
    func spawnBuddy(
        in engineState: SM64SwiftEngineState,
        role: Int32 = SM64BobombBuddyBehavior.adviceRole,
        action: Int32 = SM64BobombBuddyBehavior.idleAction,
        cannonStatus: Int32 = SM64BobombBuddyBehavior.cannonUnopened,
        hasTalked: Bool = false,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64BobombBuddyObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BobombBuddyObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity,
            drawingDistance: 3_000
        )
        guard attach(
            id,
            role: role,
            action: action,
            cannonStatus: cannonStatus,
            hasTalked: hasTalked,
            position: position,
            moveYaw: moveYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bob-omb Buddy could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        role: Int32 = SM64BobombBuddyBehavior.adviceRole,
        action: Int32 = SM64BobombBuddyBehavior.idleAction,
        cannonStatus: Int32 = SM64BobombBuddyBehavior.cannonUnopened,
        hasTalked: Bool = false,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BobombBuddyState(
            action: action,
            role: role,
            cannonStatus: cannonStatus,
            hasTalked: hasTalked,
            moveYaw: moveYaw,
            blinkTimer: 0
        )
        states[id] = state
        environments[id] = SM64BobombBuddyEnvironment()
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams2ndByte = 0
        }
        synchronizeRecord(
            id: id,
            state: state,
            previousAction: state.action,
            animationFrame: 0,
            adviceDialogID: nil,
            pool: pool
        )
        return true
    }

    @discardableResult
    func setEnvironment(_ environment: SM64BobombBuddyEnvironment, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        environments[id] = environment
        return true
    }

    /// Clears per-tick effects before a shared scheduler pass. The engine
    /// context remains the sole list-traversal owner.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    /// Advances one Bob-omb Buddy in the enclosing scheduler without nesting
    /// another object-list traversal.
    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState,
        pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, states[id] != nil else { return false }
        update(id: id, engineState: engineState, pool: pool)
        return true
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        environments.removeValue(forKey: id)
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
        environments frameEnvironments: [SM64ObjectID: SM64BobombBuddyEnvironment] = [:]
    ) -> SM64BobombBuddySchedulerTickResult {
        environments = frameEnvironments
        beginExternalTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            _ = self?.updateInline(id, state: engineState, pool: pool)
        }
        pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        return SM64BobombBuddySchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(id: SM64ObjectID, engineState: SM64SwiftEngineState, pool: SM64ObjectPool) {
        guard var state = states[id], let record = pool.record(for: id) else { return }
        let previousAction = state.action
        let environment = environments[id] ?? defaultEnvironment(for: state, record: record)
        var input = environment.input
        if let cannonID = environment.nearestCannonID {
            input.nearestCannonExists = pool.record(for: cannonID) != nil
        }
        let output = SM64BobombBuddyBehavior.update(input, state: state)
        state = output.state
        states[id] = state

        if output.activeTimeStop {
            engineState.addTimeStop([.enabled, .dialog])
        }
        if output.clearTimeStop {
            engineState.removeTimeStop([.enabled, .dialog])
        }
        synchronizeRecord(
            id: id,
            state: state,
            previousAction: previousAction,
            animationFrame: input.animationFrame,
            adviceDialogID: input.adviceDialogID > 0 ? input.adviceDialogID : nil,
            pool: pool,
            activeTimeStop: output.activeTimeStop,
            clearTimeStop: output.clearTimeStop,
            clearInteraction: output.clearInteraction
        )

        if output.playWalkingSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: Self.walkingSoundValue)
        }
        if output.playReadSignSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: Self.readSignSoundValue)
        }
        if output.dialogRequested, output.dialogID > 0 {
            effectRouter.enqueue(objectID: id, kind: .dialog, value: output.dialogID)
        }
        if output.cameraRequest != 0 {
            // The shared sink's cameraShake channel carries the authored
            // prepare-cannon request until the camera owner gains a typed
            // cutscene request domain.
            effectRouter.enqueue(objectID: id, kind: .cameraShake, value: output.cameraRequest)
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)
        effectLog.append(
            SM64BobombBuddyObjectEffect(
                objectID: id,
                output: output,
                nearestCannonID: environment.nearestCannonID,
                presentedEffects: delivery.presented
            )
        )
    }

    private func defaultEnvironment(
        for state: SM64BobombBuddyState,
        record: SM64ObjectRecord
    ) -> SM64BobombBuddyEnvironment {
        SM64BobombBuddyEnvironment(
            input: SM64BobombBuddyInput(
                animationFrame: Int16(truncatingIfNeeded: record.animationState),
                distanceToMario: record.distanceToMario,
                angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
                interacted: record.interactionStatus & Int32(1 << 15) != 0,
                dialogOpenResult: Int32(record.dialogState),
                adviceDialogResult: Int32(record.dialogResponse),
                adviceDialogID: record.behaviorParams2ndByte,
                cannonFirstDialogResult: Int32(record.dialogResponse),
                nearestCannonExists: false,
                cannonCutsceneResult: record.subAction,
                cannonSecondDialogResult: Int32(record.dialogResponse),
                courseIsBob: true,
                randomBlinkTimer: state.blinkTimer
            )
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BobombBuddyState,
        previousAction: Int32,
        animationFrame: Int16,
        adviceDialogID: Int32?,
        pool: SM64ObjectPool,
        activeTimeStop: Bool = false,
        clearTimeStop: Bool = false,
        clearInteraction: Bool = false
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.drawingDistance = 3_000
            record.gravity = 2.5
            record.friction = 0.8
            record.buoyancy = 1.3
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.action = state.action
            record.previousAction = previousAction
            record.subAction = state.cannonStatus
            record.timer = Int32(truncatingIfNeeded: state.blinkTimer)
            record.behaviorParams = state.role
            if let adviceDialogID {
                record.behaviorParams2ndByte = adviceDialogID
            }
            record.interactionSubtype |= Self.npcInteractionSubtype
            record.animationState = Int32(animationFrame)
            if activeTimeStop {
                record.activeFlags |= SM64ObjectPool.activeFlagInitiatedTimeStop
            }
            if clearTimeStop {
                record.activeFlags &= ~SM64ObjectPool.activeFlagInitiatedTimeStop
            }
            // C clears oInteractStatus at the end of every buddy loop. The
            // explicit output flag still records dialog cleanup semantics.
            if clearInteraction || record.interactionStatus != 0 {
                record.interactionStatus = 0
            }
        }
    }
}
