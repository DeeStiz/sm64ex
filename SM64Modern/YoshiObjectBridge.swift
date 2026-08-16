import Foundation

/// Owner-thread environment for one Yoshi tick. The optional input keeps all
/// save, camera, dialog, and collision facts immutable at the value boundary.
struct SM64YoshiEnvironment: Equatable, Sendable {
    var input: SM64YoshiInput

    init(input: SM64YoshiInput = SM64YoshiInput()) {
        self.input = input
    }
}

struct SM64YoshiObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64YoshiOutput
    let spawnedRespawners: [SM64ObjectID]
    let presentedEffects: [SM64OwnerThreadEffectIntent]
}

struct SM64YoshiSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64YoshiObjectEffect]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for `bhv_yoshi_loop`. It keeps object IDs and mutable
/// records on the engine owner thread while exposing lives/triple-jump and
/// respawner requests as typed value effects for their eventual services.
final class SM64YoshiObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_797368
    static let respawnerBehaviorIdentity: UInt64 = 0x6268_765F_727370
    static let defaultModel: UInt32 = 0xC3 // MODEL_YOSHI
    static let npcInteractionSubtype: UInt32 = 0x0000_4000 // INT_SUBTYPE_NPC
    static let walkingSoundValue: Int32 = Int32(bitPattern: 0x306E_2081)
    static let puzzleJingleValue: Int32 = 0x0000_0010
    static let alertSoundValue: Int32 = Int32(bitPattern: 0x306F_3081)
    static let collectOneUpSoundValue: Int32 = Int32(bitPattern: 0x3058_FF81)
    static let gainLifeSoundValue: Int32 = Int32(bitPattern: 0x7015_0081)

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64YoshiState] = [:]
    private var environments: [SM64ObjectID: SM64YoshiEnvironment] = [:]
    private(set) var effectLog: [SM64YoshiObjectEffect] = []
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

    func state(for id: SM64ObjectID) -> SM64YoshiState? {
        states[id]
    }

    @discardableResult
    func spawnYoshi(
        in engineState: SM64SwiftEngineState,
        action: Int32 = SM64YoshiBehavior.idleAction,
        position: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 3_174, z: -5_625),
        moveYaw: Int16 = 0,
        model: UInt32 = SM64YoshiObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64YoshiObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity,
            drawingDistance: 4_000
        )
        guard attach(
            id,
            action: action,
            position: position,
            moveYaw: moveYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Yoshi could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        action: Int32 = SM64YoshiBehavior.idleAction,
        position: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 3_174, z: -5_625),
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64YoshiState(action: action, moveYaw: moveYaw)
        states[id] = state
        environments[id] = SM64YoshiEnvironment()
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.activeFlags |= SM64ObjectPool.activeFlagActive
            record.behaviorParams2ndByte = 0
        }
        synchronizeRecord(
            id: id,
            state: state,
            previousAction: action,
            animation: 0,
            position: position,
            pool: pool
        )
        return true
    }

    @discardableResult
    func setEnvironment(_ environment: SM64YoshiEnvironment, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        environments[id] = environment
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        environments frameEnvironments: [SM64ObjectID: SM64YoshiEnvironment] = [:]
    ) -> SM64YoshiSchedulerTickResult {
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
        return SM64YoshiSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(id: SM64ObjectID, engineState: SM64SwiftEngineState, pool: SM64ObjectPool) {
        guard var state = states[id], let record = pool.record(for: id) else { return }
        let previousAction = state.action
        let environment = environments[id] ?? defaultEnvironment(for: state, record: record, engineState: engineState)
        let input = environment.input
        let output = SM64YoshiBehavior.update(input, state: state)
        state = output.state
        states[id] = state

        if output.activeTimeStop {
            engineState.addTimeStop([.enabled, .dialog])
        }
        if output.clearTimeStop {
            engineState.removeTimeStop([.enabled, .dialog])
        }

        var position = record.position
        if output.state.action == SM64YoshiBehavior.creditsAction, input.endingCameraEvent {
            position = SM64ObjectVector3(x: -1_798, y: 3_174, z: -3_644)
        }
        synchronizeRecord(
            id: id,
            state: state,
            previousAction: previousAction,
            animation: output.animation,
            position: position,
            pool: pool,
            activeTimeStop: output.activeTimeStop,
            clearTimeStop: output.clearTimeStop,
            clearInteraction: output.clearInteraction
        )

        var spawnedRespawners: [SM64ObjectID] = []
        if output.respawnerRequested,
           let respawner = try? pool.spawn(
               in: .spawner,
               model: Self.defaultModel,
               behaviorIdentity: Self.respawnerBehaviorIdentity,
               drawingDistance: 3_000
           ) {
            let source = pool.record(for: id)
            _ = pool.mutate(respawner) { record in
                record.position = source?.position ?? .zero
                record.homePosition = source?.homePosition ?? .zero
                record.respawnInfoType = 1
                record.respawnInfoIdentity = Self.defaultBehaviorIdentity
                record.objectFlags |= SM64ObjectScheduler.objectFlagBuildTransform
            }
            spawnedRespawners.append(respawner)
        }

        if output.playWalkSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: Self.walkingSoundValue)
        }
        if output.playPuzzleJingle {
            effectRouter.enqueue(objectID: id, kind: .sound, value: Self.puzzleJingleValue)
        }
        if output.playAlertSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: Self.alertSoundValue)
        }
        if output.playExtraLifeSound {
            let value = output.specialTripleJump
                ? Self.collectOneUpSoundValue
                : Self.gainLifeSoundValue
            effectRouter.enqueue(objectID: id, kind: .sound, value: value)
        }
        if output.dialogRequested, output.dialogID > 0 {
            effectRouter.enqueue(objectID: id, kind: .dialog, value: output.dialogID)
        }
        if output.cameraRequest != 0 {
            effectRouter.enqueue(objectID: id, kind: .cameraShake, value: output.cameraRequest)
        }
        if output.deactivated {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)
        effectLog.append(
            SM64YoshiObjectEffect(
                objectID: id,
                output: output,
                spawnedRespawners: spawnedRespawners,
                presentedEffects: delivery.presented
            )
        )
    }

    private func defaultEnvironment(
        for state: SM64YoshiState,
        record: SM64ObjectRecord,
        engineState: SM64SwiftEngineState
    ) -> SM64YoshiEnvironment {
        let dx = state.homeX - record.position.x
        let dz = state.homeZ - record.position.z
        return SM64YoshiEnvironment(
            input: SM64YoshiInput(
                animationFrame: Int16(truncatingIfNeeded: record.animationState),
                timer: record.timer,
                positionX: record.position.x,
                positionY: record.position.y,
                positionZ: record.position.z,
                closeToHome: (dx * dx + dz * dz).squareRoot() < 200,
                angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
                interacted: record.interactionStatus & Int32(1 << 15) != 0,
                dialogOpenResult: Int32(record.dialogState),
                dialogResult: Int32(record.dialogResponse),
                endingCameraEvent: false,
                globalTimer: engineState.globals.frame,
                lives: 3,
                randomChosenHome: state.chosenHome,
                randomBlinkTimer: state.blinkTimer
            )
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64YoshiState,
        previousAction: Int32,
        animation: Int32,
        position: SM64ObjectVector3,
        pool: SM64ObjectPool,
        activeTimeStop: Bool = false,
        clearTimeStop: Bool = false,
        clearInteraction: Bool = false
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.homePosition.x = state.homeX
            record.homePosition.z = state.homeZ
            record.drawingDistance = 4_000
            record.gravity = 2
            record.friction = 0.9
            record.buoyancy = 1.3
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.action = state.action
            record.previousAction = previousAction
            record.timer = state.timer
            record.animationState = animation
            record.behaviorParams = state.chosenHome
            record.interactionSubtype |= Self.npcInteractionSubtype
            if activeTimeStop {
                record.activeFlags |= SM64ObjectPool.activeFlagInitiatedTimeStop
            }
            if clearTimeStop {
                record.activeFlags &= ~SM64ObjectPool.activeFlagInitiatedTimeStop
            }
            if clearInteraction {
                record.interactionStatus = 0
            }
        }
    }
}
