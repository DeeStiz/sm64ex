import Foundation

struct SM64SmallPenguinObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SmallPenguinOutput
    let collision: SM64SmallPenguinCollisionResult?
    let movement: SM64SmallPenguinMovementResult?
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
        wallHitboxRadius: Float = 0,
        model: UInt32 = SM64SmallPenguinObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64SmallPenguinObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            position: position,
            moveYaw: moveYaw,
            wallHitboxRadius: wallHitboxRadius,
            in: engineState.objects
        ) else {
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
        wallHitboxRadius: Float = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        var state = SM64SmallPenguinState()
        state.moveYaw = moveYaw
        states[id] = state
        environments[id] = SM64SmallPenguinInput()
        _ = pool.mutate(id) { record in
            record.homePosition = position
            record.wallHitboxRadius = wallHitboxRadius
        }
        synchronize(
            id: id,
            state: state,
            position: position,
            output: nil,
            collision: nil,
            movement: nil,
            previousAction: state.action,
            pool: pool
        )
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
        environments frameEnvironments: [SM64ObjectID: SM64SmallPenguinInput] = [:],
        collisionWorld: SM64SurfaceCollisionWorld? = nil,
        advanceMovement: Bool = false
    ) -> SM64SmallPenguinSchedulerTickResult {
        environments = frameEnvironments
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(
                id: id,
                pool: pool,
                collisionWorld: collisionWorld,
                advanceMovement: advanceMovement
            )
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

    private func update(
        id: SM64ObjectID,
        pool: SM64ObjectPool,
        collisionWorld: SM64SurfaceCollisionWorld?,
        advanceMovement: Bool
    ) {
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
        let physicsEnabled = advanceMovement && collisionWorld != nil
            && state.heldState == SM64SmallPenguinBehavior.heldFree
        let collision = physicsEnabled ? collisionWorld.flatMap { world in
            SM64SmallPenguinCollision.resolve(
                SM64SmallPenguinCollisionInput(
                    position: record.position,
                    moveYaw: state.moveYaw,
                    wallHitboxRadius: record.wallHitboxRadius,
                    previousMoveFlags: record.moveFlags,
                    world: world
                )
            )
        } : nil
        let output = SM64SmallPenguinBehavior.update(input, state: state)
        state = output.state
        states[id] = state

        var behaviorPosition = collision?.position ?? record.position
        if output.resetHome {
            behaviorPosition = record.homePosition
        }
        if output.copiedToMario {
            behaviorPosition = input.marioPosition
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

        let candidatePosition: SM64ObjectVector3
        if physicsEnabled && state.heldState == SM64SmallPenguinBehavior.heldFree {
            candidatePosition = SM64ObjectVector3(
                x: behaviorPosition.x + SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity,
                y: behaviorPosition.y,
                z: behaviorPosition.z + SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
            )
        } else {
            candidatePosition = behaviorPosition
        }
        let movement = physicsEnabled ? movementResult(
            record: record,
            startPosition: behaviorPosition,
            candidatePosition: candidatePosition,
            previousMoveFlags: collision?.moveFlags ?? record.moveFlags,
            forwardVelocity: state.forwardVelocity,
            moveYaw: state.moveYaw,
            collisionWorld: collisionWorld
        ) : nil
        if let movement {
            state.forwardVelocity = movement.forwardVelocity
            states[id] = state
        }

        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)

        synchronize(
            id: id,
            state: state,
            position: movement?.position ?? candidatePosition,
            output: output,
            collision: collision,
            movement: movement,
            previousAction: previousAction,
            pool: pool
        )
        effectLog.append(
            SM64SmallPenguinObjectEffect(
                objectID: id,
                output: output,
                collision: collision,
                movement: movement,
                presentedEffects: delivery.presented
            )
        )
    }

    private func movementResult(
        record: SM64ObjectRecord,
        startPosition: SM64ObjectVector3,
        candidatePosition: SM64ObjectVector3,
        previousMoveFlags: UInt32,
        forwardVelocity: Float,
        moveYaw: Int16,
        collisionWorld: SM64SurfaceCollisionWorld?
    ) -> SM64SmallPenguinMovementResult? {
        guard let collisionWorld else { return nil }
        let intendedFloor = collisionWorld.findFloor(
            x: candidatePosition.x,
            y: record.position.y,
            z: candidatePosition.z
        )
        let intendedRoom: Int8 = intendedFloor.surfaceID.flatMap {
            collisionWorld.surface(withID: $0)?.room
        } ?? 0
        return SM64SmallPenguinMovement.resolve(
            SM64SmallPenguinMovementInput(
                startPosition: startPosition,
                candidatePosition: candidatePosition,
                velocityY: record.velocity.y,
                forwardVelocity: forwardVelocity,
                moveYaw: moveYaw,
                floorHeight: record.floorHeight,
                floorRoom: Int8(truncatingIfNeeded: record.floorRoom),
                objectRoom: Int8(truncatingIfNeeded: record.room),
                moveFlags: previousMoveFlags,
                gravity: -4,
                bounciness: -0.5,
                dragStrength: 0,
                buoyancy: 2,
                nativeStepScale: 1,
                intendedFloorHeight: intendedFloor.height,
                intendedFloorNormalY: intendedFloor.normalY ?? 0,
                intendedFloorRoom: intendedRoom,
                intendedFloorExists: intendedFloor.surfaceID != nil,
                waterLevel: collisionWorld.findWaterLevel(
                    x: candidatePosition.x,
                    z: candidatePosition.z
                ),
                activeFarAway: false
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
        collision: SM64SmallPenguinCollisionResult?,
        movement: SM64SmallPenguinMovementResult?,
        previousAction: Int32,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            if output?.copiedToMario == true {
                record.gfxPosition = SM64ObjectVector3.hiddenGfxOrigin
            }
            if let collision {
                record.floorHeight = collision.floorHeight
                record.floorType = collision.floorType
                record.moveFlags = collision.moveFlags
            }
            if let movement {
                record.velocity = movement.velocity
                record.forwardVelocity = movement.forwardVelocity
                record.moveFlags = movement.moveFlags
            }
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
