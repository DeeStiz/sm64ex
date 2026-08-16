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
    let collision: SM64KingBobombCollisionResult?
    let movement: SM64KingBobombMovementResult?
    let homeArcStart: SM64KingBobombHomeArcStart?
    let spawnedChildren: [SM64ObjectID]
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
    static let defaultWallHitboxRadius: Float = 30
    static let interactionSubtypeGrabsMario: UInt32 = 0x0000_0004
    static let bossCameraModeValue: Int32 = 11 // CAMERA_MODE_BOSS_FIGHT
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let starBehaviorIdentity: UInt64 = 0x6268_765F_73746E
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
        position: SM64ObjectVector3? = nil,
        homePosition: SM64ObjectVector3? = nil,
        wallHitboxRadius: Float = SM64KingBobombObjectBridge.defaultWallHitboxRadius,
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
            position: position,
            homePosition: homePosition,
            wallHitboxRadius: wallHitboxRadius,
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
        position: SM64ObjectVector3? = nil,
        homePosition: SM64ObjectVector3? = nil,
        wallHitboxRadius: Float = SM64KingBobombObjectBridge.defaultWallHitboxRadius,
        action: Int32 = SM64KingBobombBehavior.initializeAction,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let initialPosition = position ?? SM64ObjectVector3(
            x: 0,
            y: positionY ?? homeY,
            z: 0
        )
        let resolvedHome = homePosition ?? SM64ObjectVector3(
            x: initialPosition.x,
            y: homeY,
            z: initialPosition.z
        )
        var state = SM64KingBobombState(homeY: resolvedHome.y, positionY: initialPosition.y, moveYaw: 0)
        state.action = action
        states[id] = state
        environments[id] = SM64KingBobombEnvironment(
            input: SM64KingBobombInput(positionY: state.positionY)
        )
        _ = pool.mutate(id) { record in
            record.position = initialPosition
            record.homePosition = resolvedHome
            record.wallHitboxRadius = wallHitboxRadius
            record.gravity = state.gravity
            record.dragStrength = 10
            record.buoyancy = 2
            record.activeFlags |= SM64ObjectPool.activeFlagActive
        }
        synchronizeRecord(
            id: id,
            state: state,
            position: initialPosition,
            collision: nil,
            movement: nil,
            pool: pool,
            previousAction: action,
            animation: 0
        )
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
        environments frameEnvironments: [SM64ObjectID: SM64KingBobombEnvironment] = [:],
        collisionWorld: SM64SurfaceCollisionWorld? = nil,
        advanceMovement: Bool = false,
        presentArenaCamera: Bool = false,
        spawnRewardStar: Bool = false
    ) -> SM64KingBobombSchedulerTickResult {
        environments = frameEnvironments
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(
                id: id,
                engineState: engineState,
                pool: pool,
                collisionWorld: collisionWorld,
                advanceMovement: advanceMovement,
                presentArenaCamera: presentArenaCamera,
                spawnRewardStar: spawnRewardStar
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
        return SM64KingBobombSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(
        id: SM64ObjectID,
        engineState: SM64SwiftEngineState,
        pool: SM64ObjectPool,
        collisionWorld: SM64SurfaceCollisionWorld?,
        advanceMovement: Bool,
        presentArenaCamera: Bool,
        spawnRewardStar: Bool
    ) {
        guard let oldState = states[id], let record = pool.record(for: id) else { return }
        let input = environments[id]?.input ?? defaultInput(for: oldState, record: record)
        let previousAction = oldState.action
        let physicsEnabled = advanceMovement
            && collisionWorld != nil
            && input.heldState == .free
        let collision = physicsEnabled ? collisionWorld.flatMap { world in
            SM64KingBobombCollision.resolve(
                SM64KingBobombCollisionInput(
                    position: record.position,
                    moveYaw: oldState.moveYaw,
                    forwardVelocity: oldState.forwardVelocity,
                    wallHitboxRadius: record.wallHitboxRadius,
                    previousMoveFlags: record.moveFlags,
                    world: world
                )
            )
        } : nil
        let behaviorPosition = collision?.position ?? record.position
        let candidatePosition = physicsEnabled
            ? SM64ObjectVector3(
                x: behaviorPosition.x + SM64CanonicalTrig.sins(oldState.moveYaw) * oldState.forwardVelocity,
                y: behaviorPosition.y,
                z: behaviorPosition.z + SM64CanonicalTrig.coss(oldState.moveYaw) * oldState.forwardVelocity
            )
            : behaviorPosition
        let homeStep = physicsEnabled && oldState.usingHomeMovement
            ? SM64KingBobombHomeMovement.step(
                SM64KingBobombHomeArcStepInput(
                    position: behaviorPosition,
                    moveYaw: oldState.moveYaw,
                    forwardVelocity: oldState.forwardVelocity,
                    velocityY: oldState.velocityY,
                    gravity: oldState.gravity,
                    nativeStepScale: 1
                )
            )
            : nil
        let movement: SM64KingBobombMovementResult?
        if let homeStep {
            movement = SM64KingBobombMovementResult(
                position: homeStep.position,
                velocity: homeStep.velocity,
                forwardVelocity: oldState.forwardVelocity,
                moveFlags: collision?.moveFlags ?? record.moveFlags,
                hitEdge: false,
                landed: false,
                onGround: false
            )
        } else if physicsEnabled && !oldState.usingHomeMovement {
            movement = movementResult(
                record: record,
                startPosition: behaviorPosition,
                candidatePosition: candidatePosition,
                floorHeight: collision?.floorHeight ?? record.floorHeight,
                floorRoom: collision?.floorRoom ?? Int8(truncatingIfNeeded: record.floorRoom),
                previousMoveFlags: collision?.moveFlags ?? record.moveFlags,
                forwardVelocity: oldState.forwardVelocity,
                moveYaw: oldState.moveYaw,
                collisionWorld: collisionWorld
            )
        } else {
            movement = nil
        }
        var behaviorState = oldState
        if let movement {
            behaviorState.velocityY = movement.velocity.y
            behaviorState.forwardVelocity = movement.forwardVelocity
        }
        var behaviorInput = input
        behaviorInput.positionY = movement?.position.y ?? behaviorPosition.y
        if let collision {
            behaviorInput.landed = collision.moveFlags & SM64KingBobombCollision.landed != 0
            behaviorInput.onGround = collision.moveFlags & SM64KingBobombCollision.onGround != 0
            behaviorInput.atHome = behaviorInput.atHome
                || abs(behaviorPosition.y - oldState.homeY) < 0.001
        }
        if let movement {
            behaviorInput.landed = movement.landed
            behaviorInput.onGround = movement.onGround
        }
        var output = SM64KingBobombBehavior.update(behaviorInput, state: behaviorState)
        let homeArcStart: SM64KingBobombHomeArcStart?
        if oldState.action == SM64KingBobombBehavior.returnHomeAction,
           oldState.subAction == 0,
           output.state.subAction == 1,
           output.state.usingHomeMovement {
            homeArcStart = SM64KingBobombHomeMovement.start(
                SM64KingBobombHomeArcInput(
                    currentPosition: movement?.position ?? behaviorPosition,
                    homePosition: record.homePosition,
                    initialVelocityY: 100,
                    gravity: -4
                )
            )
            if let homeArcStart {
                var state = output.state
                state.moveYaw = homeArcStart.moveYaw
                state.forwardVelocity = homeArcStart.forwardVelocity
                state.velocityY = homeArcStart.velocityY
                state.gravity = homeArcStart.gravity
                output = SM64KingBobombOutput(
                    state: state,
                    animation: output.animation,
                    dialogID: output.dialogID,
                    dialogRequested: output.dialogRequested,
                    effects: output.effects,
                    soundValues: output.soundValues,
                    soundSpawnerValues: output.soundSpawnerValues,
                    cameraShake: output.cameraShake,
                    starPosition: output.starPosition
                )
            }
        } else {
            homeArcStart = nil
        }
        states[id] = output.state
        _ = pool.mutate(id) { $0.heldState = UInt32(input.heldState.rawValue) }
        synchronizeRecord(
            id: id,
            state: output.state,
            position: SM64ObjectVector3(
                x: movement?.position.x ?? candidatePosition.x,
                y: output.state.positionY,
                z: movement?.position.z ?? candidatePosition.z
            ),
            collision: collision,
            movement: movement,
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
        var spawnedChildren: [SM64ObjectID] = []
        if spawnRewardStar,
           let starPosition = output.starPosition,
           let star = try? pool.spawn(
               in: .level,
               model: Self.starModel,
               behaviorIdentity: Self.starBehaviorIdentity,
               parent: id
           ) {
            let resolvedStarPosition = SM64ObjectVector3(
                x: starPosition.x,
                y: starPosition.y,
                z: starPosition.z
            )
            _ = pool.mutate(star) { starRecord in
                starRecord.objectFlags |=
                    SM64ObjectScheduler.objectFlagBuildTransform |
                    SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                starRecord.position = resolvedStarPosition
                starRecord.homePosition = resolvedStarPosition
                starRecord.behaviorParams2ndByte = 0
            }
            spawnedChildren.append(star)
        }
        if output.effects.contains(.bossMusic) {
            effectRouter.enqueue(objectID: id, kind: .music, value: 1)
        }
        if presentArenaCamera, output.effects.contains(.cameraFocus) {
            effectRouter.enqueue(
                objectID: id,
                kind: .cameraFocus,
                value: Self.bossCameraModeValue
            )
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
                collision: collision,
                movement: movement,
                homeArcStart: homeArcStart,
                spawnedChildren: spawnedChildren,
                presentedEffects: delivery.presented
            )
        )
        _ = engineState.setCurrentObject(nil)
    }

    private func movementResult(
        record: SM64ObjectRecord,
        startPosition: SM64ObjectVector3,
        candidatePosition: SM64ObjectVector3,
        floorHeight: Float,
        floorRoom: Int8,
        previousMoveFlags: UInt32,
        forwardVelocity: Float,
        moveYaw: Int16,
        collisionWorld: SM64SurfaceCollisionWorld?
    ) -> SM64KingBobombMovementResult? {
        guard let collisionWorld else { return nil }
        let intendedFloor = collisionWorld.findFloor(
            x: candidatePosition.x,
            y: record.position.y,
            z: candidatePosition.z
        )
        let intendedRoom: Int8 = intendedFloor.surfaceID.flatMap {
            collisionWorld.surface(withID: $0)?.room
        } ?? 0
        return SM64KingBobombCollision.move(
            SM64KingBobombMovementInput(
                startPosition: startPosition,
                candidatePosition: candidatePosition,
                velocityY: record.velocity.y,
                forwardVelocity: forwardVelocity,
                moveYaw: moveYaw,
                floorHeight: floorHeight,
                floorRoom: floorRoom,
                objectRoom: Int8(truncatingIfNeeded: record.room),
                moveFlags: previousMoveFlags,
                gravity: record.gravity == 0 ? -4 : record.gravity,
                bounciness: -0.5,
                dragStrength: record.dragStrength == 0 ? 10 : record.dragStrength,
                buoyancy: record.buoyancy == 0 ? 2 : record.buoyancy,
                nativeStepScale: 1,
                intendedFloorHeight: intendedFloor.height,
                intendedFloorNormalY: intendedFloor.normalY ?? 0,
                intendedFloorRoom: intendedRoom,
                intendedFloorExists: intendedFloor.surfaceID != nil,
                waterLevel: collisionWorld.findWaterLevel(
                    x: candidatePosition.x,
                    z: candidatePosition.z
                )
            )
        )
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
        position: SM64ObjectVector3,
        collision: SM64KingBobombCollisionResult?,
        movement: SM64KingBobombMovementResult?,
        pool: SM64ObjectPool,
        previousAction: Int32,
        animation: Int32,
        clearInteraction: Bool = false
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
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
            record.buoyancy = 2
            record.dragStrength = 10
            if let collision {
                record.floorHeight = collision.floorHeight
                record.floorType = collision.floorType
                record.floorRoom = Int16(collision.floorRoom)
                record.moveFlags = collision.moveFlags
            }
            if let movement {
                record.velocity = movement.velocity
                record.moveFlags = movement.moveFlags
            }
            if clearInteraction { record.interactionStatus = 0 }
        }
    }
}
