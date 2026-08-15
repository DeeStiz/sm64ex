import Foundation

struct SM64SLWalkingPenguinObjectState: Equatable, Sendable {
    var action: Int32 = SM64SLWalkingPenguinBehavior.movingForwards
    var currentStep: Int32 = 0
    var currentStepTimer: Int32 = 0
    var timer: Int32 = 0
    let homePosition: SM64ObjectVector3
    var moveYaw: Int16

    init(homePosition: SM64ObjectVector3 = .zero, moveYaw: Int16 = 0) {
        self.homePosition = homePosition
        self.moveYaw = moveYaw
    }
}

struct SM64SLWalkingPenguinObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let action: Int32
    let currentStep: Int32
    let currentStepTimer: Int32
    let forwardVelocity: Float
    let animation: Int32
    let animationSpeed: Float
    let angleVelocityYaw: Int16
    let moveYaw: Int16
    let completedTurn: Bool
    let collision: SM64SLWalkingPenguinCollisionResult?
    let movement: SM64SLWalkingPenguinMovementResult?
}

struct SM64SLWalkingPenguinSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64SLWalkingPenguinObjectEffect]
}

/// Owner-thread bridge for the Snowman Land walking penguin. The behavior
/// kernel is value-only; this bridge owns the generation-safe object ID,
/// action/timer state, transform fields, and animation intent.
final class SM64SLWalkingPenguinObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_736C70
    static let defaultModel: UInt32 = 0x8A

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64SLWalkingPenguinObjectState] = [:]
    private(set) var effectLog: [SM64SLWalkingPenguinObjectEffect] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64SLWalkingPenguinObjectState? {
        states[id]
    }

    @discardableResult
    func spawnPenguin(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        wallHitboxRadius: Float = 0,
        model: UInt32 = SM64SLWalkingPenguinObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64SLWalkingPenguinObjectBridge.defaultBehaviorIdentity
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
            preconditionFailure("newly spawned walking penguin could not attach")
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
        let state = SM64SLWalkingPenguinObjectState(homePosition: position, moveYaw: moveYaw)
        states[id] = state
        _ = pool.mutate(id) { record in
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
    func tick(
        state engineState: SM64SwiftEngineState,
        advanceNativeDynamics: Bool = true,
        collisionWorld: SM64SurfaceCollisionWorld? = nil,
        advanceMovement: Bool = false
    ) -> SM64SLWalkingPenguinSchedulerTickResult {
        effectLog.removeAll(keepingCapacity: true)
        let schedulerResult = scheduler.update(
            state: engineState,
            advanceNativeDynamics: advanceNativeDynamics
        ) { [weak self] id, pool in
            self?.update(
                id: id,
                pool: pool,
                collisionWorld: collisionWorld,
                advanceMovement: advanceMovement
            )
        }
        for id in schedulerResult.unloaded {
            states.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
        }
        return SM64SLWalkingPenguinSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog
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
        let prepass = (advanceMovement ? collisionWorld : nil).flatMap { world in
            SM64SLWalkingPenguinCollision.resolve(
                SM64SLWalkingPenguinCollisionInput(
                    position: record.position,
                    moveYaw: state.moveYaw,
                    wallHitboxRadius: record.wallHitboxRadius,
                    previousMoveFlags: record.moveFlags,
                    world: world
                )
            )
        }
        let behaviorPosition = prepass?.position ?? record.position
        let output = SM64SLWalkingPenguinBehavior.update(
            SM64SLWalkingPenguinInput(
                action: state.action,
                timer: state.timer,
                currentStep: state.currentStep,
                currentStepTimer: state.currentStepTimer,
                position: behaviorPosition,
                moveYaw: state.moveYaw
            )
        )
        let postBehaviorCollision = (!advanceMovement ? collisionWorld : nil).flatMap { world in
            SM64SLWalkingPenguinCollision.resolve(
                SM64SLWalkingPenguinCollisionInput(
                    position: output.nextPosition,
                    moveYaw: output.moveYaw,
                    wallHitboxRadius: record.wallHitboxRadius,
                    previousMoveFlags: record.moveFlags,
                    world: world
                )
            )
        }
        let collision = prepass ?? postBehaviorCollision
        let movement = movementResult(
            record: record,
            startPosition: prepass?.position ?? record.position,
            floorHeight: prepass?.floorHeight ?? record.floorHeight,
            candidatePosition: output.nextPosition,
            previousMoveFlags: prepass?.moveFlags ?? postBehaviorCollision?.moveFlags ?? record.moveFlags,
            forwardVelocity: output.forwardVelocity,
            moveYaw: output.moveYaw,
            collisionWorld: collisionWorld,
            enabled: advanceMovement
        )

        state.action = output.action
        state.currentStep = output.currentStep
        state.currentStepTimer = output.currentStepTimer
        state.moveYaw = output.moveYaw
        state.timer = output.action == previousAction ? state.timer &+ 1 : 0
        states[id] = state

        synchronize(
            id: id,
            state: state,
            position: movement?.position ?? collision?.position ?? output.nextPosition,
            output: output,
            collision: collision,
            movement: movement,
            previousAction: previousAction,
            pool: pool
        )
        effectLog.append(
            SM64SLWalkingPenguinObjectEffect(
                objectID: id,
                action: output.action,
                currentStep: output.currentStep,
                currentStepTimer: output.currentStepTimer,
                forwardVelocity: output.forwardVelocity,
                animation: output.animation,
                animationSpeed: output.animationSpeed,
                angleVelocityYaw: output.angleVelocityYaw,
                moveYaw: output.moveYaw,
                completedTurn: output.completedTurn,
                collision: collision,
                movement: movement
            )
        )
    }

    private func movementResult(
        record: SM64ObjectRecord,
        startPosition: SM64ObjectVector3,
        floorHeight: Float,
        candidatePosition: SM64ObjectVector3,
        previousMoveFlags: UInt32,
        forwardVelocity: Float,
        moveYaw: Int16,
        collisionWorld: SM64SurfaceCollisionWorld?,
        enabled: Bool
    ) -> SM64SLWalkingPenguinMovementResult? {
        guard enabled, let collisionWorld else { return nil }
        let intendedFloor = collisionWorld.findFloor(
            x: candidatePosition.x,
            y: record.position.y,
            z: candidatePosition.z
        )
        let intendedRoom: Int8 = intendedFloor.surfaceID.flatMap {
            collisionWorld.surface(withID: $0)?.room
        } ?? 0
        return SM64SLWalkingPenguinMovement.resolve(
            SM64SLWalkingPenguinMovementInput(
                startPosition: startPosition,
                candidatePosition: candidatePosition,
                velocityY: record.velocity.y,
                forwardVelocity: forwardVelocity,
                moveYaw: moveYaw,
                floorHeight: floorHeight,
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

    private func synchronize(
        id: SM64ObjectID,
        state: SM64SLWalkingPenguinObjectState,
        position: SM64ObjectVector3,
        output: SM64SLWalkingPenguinOutput?,
        collision: SM64SLWalkingPenguinCollisionResult?,
        movement: SM64SLWalkingPenguinMovementResult?,
        previousAction: Int32,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.homePosition = state.homePosition
            if let collision {
                record.floorHeight = collision.floorHeight
                record.floorType = collision.floorType
                record.moveFlags = collision.moveFlags
            }
            record.forwardVelocity = output?.forwardVelocity ?? 0
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.action = state.action
            record.previousAction = previousAction
            record.timer = state.timer
            record.animationState = output?.animation ?? 0
            record.angleVelocity.yaw = Int32(output?.angleVelocityYaw ?? 0)
            if let movement {
                record.velocity = movement.velocity
                record.forwardVelocity = movement.forwardVelocity
                record.moveFlags = movement.moveFlags
            }
            if output?.animation == SM64SLWalkingPenguinBehavior.idleAnimation {
                record.graphFlags &= ~SM64ObjectScheduler.graphRenderHasAnimation
            } else {
                record.graphFlags |= SM64ObjectScheduler.graphRenderHasAnimation
            }
        }
    }
}
