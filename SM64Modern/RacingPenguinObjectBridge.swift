import Foundation

/// Per-frame world facts supplied by the owner thread to the race behavior.
/// The bridge keeps mutable state; this descriptor is an immutable snapshot of
/// path, dialog, animation, and Mario inputs for one object tick.
struct SM64RacingPenguinEnvironment: Equatable, Sendable {
    let marioPositionY: Float
    let canActivateInitialText: Bool
    let initialDialogResponse: Int32
    let raceBeginComplete: Bool
    let pathStatus: Int32
    let pathWaypointFlags: UInt32
    let pathTargetYaw: Int16
    let animationAtEnd: Bool
    let finalAnimationAtEnd: Bool
    let canActivateFinalText: Bool
    let finalDialogResult: Int32
    let marioInAirAction: Bool

    init(
        marioPositionY: Float = 0,
        canActivateInitialText: Bool = false,
        initialDialogResponse: Int32 = 0,
        raceBeginComplete: Bool = false,
        pathStatus: Int32 = SM64RacingPenguinBehavior.pathNone,
        pathWaypointFlags: UInt32 = 0,
        pathTargetYaw: Int16 = 0,
        animationAtEnd: Bool = false,
        finalAnimationAtEnd: Bool = false,
        canActivateFinalText: Bool = false,
        finalDialogResult: Int32 = 0,
        marioInAirAction: Bool = false
    ) {
        self.marioPositionY = marioPositionY
        self.canActivateInitialText = canActivateInitialText
        self.initialDialogResponse = initialDialogResponse
        self.raceBeginComplete = raceBeginComplete
        self.pathStatus = pathStatus
        self.pathWaypointFlags = pathWaypointFlags
        self.pathTargetYaw = pathTargetYaw
        self.animationAtEnd = animationAtEnd
        self.finalAnimationAtEnd = finalAnimationAtEnd
        self.canActivateFinalText = canActivateFinalText
        self.finalDialogResult = finalDialogResult
        self.marioInAirAction = marioInAirAction
    }
}

struct SM64RacingPenguinObjectState: Equatable, Sendable {
    var action: Int32 = SM64RacingPenguinBehavior.waitForMario
    var timer: Int32 = 0
    var initTextCooldown: Int32 = 0
    var finalTextbox: Int32 = 0
    var marioWon = false
    var marioCheated = false
    var reachedBottom = false
    var weightedTargetSpeed: Float = 0
    var forwardVelocity: Float = 0
    var moveYaw: Int16 = 0
}

struct SM64RacingPenguinObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64RacingPenguinOutput
}

struct SM64RacingPenguinSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64RacingPenguinObjectEffect]
}

/// Owner-thread bridge for `bhv_racing_penguin_update`.  Object IDs and
/// scheduler traversal stay generation-safe while the race kernel remains
/// value-only and pointer-free.
final class SM64RacingPenguinObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_727063
    static let defaultModel: UInt32 = 0x93 // MODEL_PENGUIN_RACING

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64RacingPenguinObjectState] = [:]
    private var environments: [SM64ObjectID: SM64RacingPenguinEnvironment] = [:]
    private(set) var effectLog: [SM64RacingPenguinObjectEffect] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64RacingPenguinObjectState? {
        states[id]
    }

    @discardableResult
    func spawnPenguin(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64RacingPenguinObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64RacingPenguinObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, position: position, moveYaw: moveYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned racing penguin could not attach")
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
        let state = SM64RacingPenguinObjectState(moveYaw: moveYaw)
        states[id] = state
        environments[id] = SM64RacingPenguinEnvironment()
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
    func setEnvironment(_ environment: SM64RacingPenguinEnvironment, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        environments[id] = environment
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        environments frameEnvironments: [SM64ObjectID: SM64RacingPenguinEnvironment] = [:],
        advanceNativeDynamics: Bool = true
    ) -> SM64RacingPenguinSchedulerTickResult {
        environments = frameEnvironments
        effectLog.removeAll(keepingCapacity: true)
        let schedulerResult = scheduler.update(
            state: engineState,
            advanceNativeDynamics: advanceNativeDynamics
        ) { [weak self] id, pool in
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
        return SM64RacingPenguinSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = states[id], let record = pool.record(for: id) else { return }
        let previousAction = state.action
        let environment = environments[id] ?? SM64RacingPenguinEnvironment(
            marioPositionY: record.position.y
        )
        let output = SM64RacingPenguinBehavior.update(
            SM64RacingPenguinInput(
                action: state.action,
                timer: state.timer,
                positionY: record.position.y,
                marioPositionY: environment.marioPositionY,
                initTextCooldown: state.initTextCooldown,
                canActivateInitialText: environment.canActivateInitialText,
                initialDialogResponse: environment.initialDialogResponse,
                raceBeginComplete: environment.raceBeginComplete,
                pathStatus: environment.pathStatus,
                pathWaypointFlags: environment.pathWaypointFlags,
                pathTargetYaw: environment.pathTargetYaw,
                moveFlags: record.moveFlags,
                animationAtEnd: environment.animationAtEnd,
                finalAnimationAtEnd: environment.finalAnimationAtEnd,
                canActivateFinalText: environment.canActivateFinalText,
                finalDialogResult: environment.finalDialogResult,
                finalTextbox: state.finalTextbox,
                marioWon: state.marioWon,
                marioCheated: state.marioCheated,
                weightedTargetSpeed: state.weightedTargetSpeed,
                forwardVelocity: state.forwardVelocity,
                moveYaw: state.moveYaw,
                marioInAirAction: environment.marioInAirAction
            )
        )

        state.action = output.action
        state.initTextCooldown = output.initTextCooldown
        state.finalTextbox = output.finalTextbox
        state.marioWon = output.marioWon
        state.marioCheated = output.marioCheated
        state.reachedBottom = state.reachedBottom || output.reachedBottom
        state.weightedTargetSpeed = output.weightedTargetSpeed
        state.forwardVelocity = output.forwardVelocity
        state.moveYaw = output.moveYaw
        if output.resetTimer || output.action != previousAction {
            state.timer = 0
        } else {
            state.timer = state.timer &+ 1
        }
        states[id] = state

        synchronize(
            id: id,
            state: state,
            position: record.position,
            output: output,
            previousAction: previousAction,
            pool: pool
        )
        effectLog.append(SM64RacingPenguinObjectEffect(objectID: id, output: output))
    }

    private func synchronize(
        id: SM64ObjectID,
        state: SM64RacingPenguinObjectState,
        position: SM64ObjectVector3,
        output: SM64RacingPenguinOutput?,
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
            record.action = state.action
            record.previousAction = previousAction
            record.timer = state.timer
            record.animationState = output?.animation ?? SM64RacingPenguinBehavior.idleAnimation
            record.velocity.y = output?.setVelocityY ?? record.velocity.y
            if output?.animation == SM64RacingPenguinBehavior.idleAnimation {
                record.graphFlags &= ~SM64ObjectScheduler.graphRenderHasAnimation
            } else {
                record.graphFlags |= SM64ObjectScheduler.graphRenderHasAnimation
            }
        }
    }
}
