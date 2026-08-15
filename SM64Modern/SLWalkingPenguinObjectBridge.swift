import Foundation

struct SM64SLWalkingPenguinObjectState: Equatable, Sendable {
    var action: Int32 = SM64SLWalkingPenguinBehavior.movingForwards
    var currentStep: Int32 = 0
    var currentStepTimer: Int32 = 0
    var timer: Int32 = 0
    var moveYaw: Int16

    init(moveYaw: Int16 = 0) {
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
        model: UInt32 = SM64SLWalkingPenguinObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64SLWalkingPenguinObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, position: position, moveYaw: moveYaw, in: engineState.objects) else {
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
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64SLWalkingPenguinObjectState(moveYaw: moveYaw)
        states[id] = state
        synchronize(
            id: id,
            state: state,
            position: position,
            output: nil,
            previousAction: state.action,
            pool: pool
        )
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        advanceNativeDynamics: Bool = true
    ) -> SM64SLWalkingPenguinSchedulerTickResult {
        effectLog.removeAll(keepingCapacity: true)
        let schedulerResult = scheduler.update(
            state: engineState,
            advanceNativeDynamics: advanceNativeDynamics
        ) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
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

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = states[id], let record = pool.record(for: id) else { return }
        let previousAction = state.action
        let output = SM64SLWalkingPenguinBehavior.update(
            SM64SLWalkingPenguinInput(
                action: state.action,
                timer: state.timer,
                currentStep: state.currentStep,
                currentStepTimer: state.currentStepTimer,
                position: record.position,
                moveYaw: state.moveYaw
            )
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
            position: output.nextPosition,
            output: output,
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
                completedTurn: output.completedTurn
            )
        )
    }

    private func synchronize(
        id: SM64ObjectID,
        state: SM64SLWalkingPenguinObjectState,
        position: SM64ObjectVector3,
        output: SM64SLWalkingPenguinOutput?,
        previousAction: Int32,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.homePosition = position
            record.forwardVelocity = output?.forwardVelocity ?? 0
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.action = state.action
            record.previousAction = previousAction
            record.timer = state.timer
            record.animationState = output?.animation ?? 0
            record.angleVelocity.yaw = Int32(output?.angleVelocityYaw ?? 0)
            if output?.animation == SM64SLWalkingPenguinBehavior.idleAnimation {
                record.graphFlags &= ~SM64ObjectScheduler.graphRenderHasAnimation
            } else {
                record.graphFlags |= SM64ObjectScheduler.graphRenderHasAnimation
            }
        }
    }
}
