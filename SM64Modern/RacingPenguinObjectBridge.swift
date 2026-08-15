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
    let pathWaypoints: [SM64RacingPenguinWaypoint]
    let animationAtEnd: Bool
    let finalAnimationAtEnd: Bool
    let canActivateFinalText: Bool
    let finalDialogResult: Int32
    let marioInAirAction: Bool
    let finishLineDistanceToMario: Float
    let finishLineMarioDeltaZ: Float
    let shortcutDistanceToMario: Float

    init(
        marioPositionY: Float = 0,
        canActivateInitialText: Bool = false,
        initialDialogResponse: Int32 = 0,
        raceBeginComplete: Bool = false,
        pathStatus: Int32 = SM64RacingPenguinBehavior.pathNone,
        pathWaypointFlags: UInt32 = 0,
        pathTargetYaw: Int16 = 0,
        pathWaypoints: [SM64RacingPenguinWaypoint] = [],
        animationAtEnd: Bool = false,
        finalAnimationAtEnd: Bool = false,
        canActivateFinalText: Bool = false,
        finalDialogResult: Int32 = 0,
        marioInAirAction: Bool = false,
        finishLineDistanceToMario: Float = .greatestFiniteMagnitude,
        finishLineMarioDeltaZ: Float = 0,
        shortcutDistanceToMario: Float = .greatestFiniteMagnitude
    ) {
        self.marioPositionY = marioPositionY
        self.canActivateInitialText = canActivateInitialText
        self.initialDialogResponse = initialDialogResponse
        self.raceBeginComplete = raceBeginComplete
        self.pathStatus = pathStatus
        self.pathWaypointFlags = pathWaypointFlags
        self.pathTargetYaw = pathTargetYaw
        self.pathWaypoints = pathWaypoints
        self.animationAtEnd = animationAtEnd
        self.finalAnimationAtEnd = finalAnimationAtEnd
        self.canActivateFinalText = canActivateFinalText
        self.finalDialogResult = finalDialogResult
        self.marioInAirAction = marioInAirAction
        self.finishLineDistanceToMario = finishLineDistanceToMario
        self.finishLineMarioDeltaZ = finishLineMarioDeltaZ
        self.shortcutDistanceToMario = shortcutDistanceToMario
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
    var pathWaypoints: [SM64RacingPenguinWaypoint] = []
    var pathStartIndex = 0
    var pathPreviousIndex = 0
    var pathPreviousFlags: Int32 = 0
    var pathInitialized = false
}

struct SM64RacingPenguinRaceChildIDs: Equatable, Sendable {
    let finishLine: SM64ObjectID
    let shortcutCheck: SM64ObjectID
}

struct SM64RacingPenguinObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64RacingPenguinOutput
    let raceChildren: SM64RacingPenguinRaceChildIDs?
    let path: SM64RacingPenguinPathOutput?
    let spawnedChildren: [SM64ObjectID]
    let presentedEffects: [SM64OwnerThreadEffectIntent]
}

struct SM64RacingPenguinSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64RacingPenguinObjectEffect]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for `bhv_racing_penguin_update`.  Object IDs and
/// scheduler traversal stay generation-safe while the race kernel remains
/// value-only and pointer-free.
final class SM64RacingPenguinObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_727063
    static let defaultModel: UInt32 = 0x93 // MODEL_PENGUIN_RACING
    static let finishLineBehaviorIdentity: UInt64 = 0x6268_765F_72666C
    static let shortcutBehaviorIdentity: UInt64 = 0x6268_765F_727363
    static let smokeModel: UInt32 = 0x96 // MODEL_SMOKE
    static let smokeBehaviorIdentity: UInt64 = 0x6268_765F_707566
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let starBehaviorIdentity: UInt64 = 0x6268_765F_73746E
    static let starHomePosition = SM64ObjectVector3(x: -7_339, y: -5_700, z: -6_774)
    static let starSpawnYOffset: Float = 200

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64RacingPenguinObjectState] = [:]
    private var environments: [SM64ObjectID: SM64RacingPenguinEnvironment] = [:]
    private var raceChildren: [SM64ObjectID: SM64RacingPenguinRaceChildIDs] = [:]
    private(set) var effectLog: [SM64RacingPenguinObjectEffect] = []
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
        raceChildren.removeValue(forKey: id)
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
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
        advanceRaceChildren(state: engineState)
        let schedulerResult = scheduler.update(
            state: engineState,
            advanceNativeDynamics: advanceNativeDynamics
        ) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            if let children = raceChildren.removeValue(forKey: id) {
                _ = engineState.objects.despawn(children.finishLine)
                _ = engineState.objects.despawn(children.shortcutCheck)
            }
            states.removeValue(forKey: id)
            environments.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            if let children = raceChildren.removeValue(forKey: id) {
                _ = engineState.objects.despawn(children.finishLine)
                _ = engineState.objects.despawn(children.shortcutCheck)
            }
            states.removeValue(forKey: id)
            environments.removeValue(forKey: id)
        }
        return SM64RacingPenguinSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = states[id], let record = pool.record(for: id) else { return }
        let previousAction = state.action
        let previousFinalTextbox = state.finalTextbox
        let environment = environments[id] ?? SM64RacingPenguinEnvironment(
            marioPositionY: record.position.y
        )
        var pathOutput: SM64RacingPenguinPathOutput?
        var pathStatus = environment.pathStatus
        var pathWaypointFlags = environment.pathWaypointFlags
        var pathTargetYaw = environment.pathTargetYaw
        if state.pathInitialized, !state.pathWaypoints.isEmpty {
            let result = SM64RacingPenguinPath.update(
                SM64RacingPenguinPathInput(
                    waypoints: state.pathWaypoints,
                    startIndex: state.pathStartIndex,
                    previousIndex: state.pathPreviousIndex,
                    previousFlags: state.pathPreviousFlags,
                    position: record.position
                )
            )
            pathOutput = result
            pathStatus = result.status
            pathWaypointFlags = UInt32(bitPattern: result.previousFlags)
            pathTargetYaw = result.targetYaw
        }
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
                pathStatus: pathStatus,
                pathWaypointFlags: pathWaypointFlags,
                pathTargetYaw: pathTargetYaw,
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

        var children = raceChildren[id]
        if output.attachRaceObjects, children == nil {
            children = attachRaceObjects(parent: id, pool: pool)
        }

        if output.initializePath {
            if !environment.pathWaypoints.isEmpty {
                state.pathWaypoints = environment.pathWaypoints
            }
            state.pathStartIndex = 0
            state.pathPreviousIndex = 0
            state.pathPreviousFlags = 0
            state.pathInitialized = !state.pathWaypoints.isEmpty
        } else if let pathOutput {
            state.pathPreviousIndex = pathOutput.previousIndex
            state.pathPreviousFlags = pathOutput.previousFlags
        }

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

        var spawnedChildren: [SM64ObjectID] = []
        if output.spawnSmoke,
           let smoke = try? pool.spawn(
               in: .unimportant,
               model: Self.smokeModel,
               behaviorIdentity: Self.smokeBehaviorIdentity,
               parent: id
           ) {
            _ = pool.mutate(smoke) { record in
                record.objectFlags |=
                    SM64ObjectScheduler.objectFlagTransformRelativeToParent |
                    SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                record.parentRelativePosition = SM64ObjectVector3(x: 0, y: -100, z: 0)
                record.scale = SM64ObjectVector3(x: 4, y: 4, z: 4)
            }
            spawnedChildren.append(smoke)
            effectRouter.enqueue(objectID: smoke, kind: .markForDeletion)
        }
        if output.spawnStar,
           let star = try? pool.spawn(
               in: .level,
               model: Self.starModel,
               behaviorIdentity: Self.starBehaviorIdentity,
               parent: id
           ) {
            let parentPosition = pool.record(for: id)?.position ?? .zero
            _ = pool.mutate(star) { record in
                // `cur_obj_spawn_star_at_y_offset` temporarily raises the
                // source object by 200 before `spawn_star` copies its spawn
                // position, while the home target remains course-authored.
                record.objectFlags |=
                    SM64ObjectScheduler.objectFlagBuildTransform |
                    SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                record.position = SM64ObjectVector3(
                    x: parentPosition.x,
                    y: parentPosition.y + Self.starSpawnYOffset,
                    z: parentPosition.z
                )
                record.homePosition = Self.starHomePosition
                record.behaviorParams2ndByte = 0
            }
            spawnedChildren.append(star)
            effectRouter.enqueue(objectID: id, kind: .star)
        }
        if output.playRoughSlideSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: 1)
        }
        if output.playWalkingSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: 2)
        }
        if output.playPoundingSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: 3)
        }
        if output.cameraShakeSmall {
            effectRouter.enqueue(objectID: id, kind: .cameraShake, value: 1)
        }
        if output.finalDialogCompleted, previousFinalTextbox > 0 {
            effectRouter.enqueue(objectID: id, kind: .dialog, value: previousFinalTextbox)
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)

        synchronize(
            id: id,
            state: state,
            position: record.position,
            output: output,
            previousAction: previousAction,
            pool: pool
        )
        effectLog.append(
            SM64RacingPenguinObjectEffect(
                objectID: id,
                output: output,
                raceChildren: children,
                path: pathOutput,
                spawnedChildren: spawnedChildren,
                presentedEffects: delivery.presented
            )
        )
    }

    private func attachRaceObjects(parent: SM64ObjectID, pool: SM64ObjectPool)
        -> SM64RacingPenguinRaceChildIDs?
    {
        guard pool.record(for: parent) != nil else { return nil }
        guard let finishLine = try? pool.spawn(
            in: .surface,
            model: 0,
            behaviorIdentity: Self.finishLineBehaviorIdentity,
            parent: parent
        ) else { return nil }
        guard let shortcutCheck = try? pool.spawn(
            in: .surface,
            model: 0,
            behaviorIdentity: Self.shortcutBehaviorIdentity,
            parent: parent
        ) else {
            _ = pool.despawn(finishLine)
            return nil
        }
        let children = SM64RacingPenguinRaceChildIDs(
            finishLine: finishLine,
            shortcutCheck: shortcutCheck
        )
        raceChildren[parent] = children
        return children
    }

    private func advanceRaceChildren(state engineState: SM64SwiftEngineState) {
        for (parentID, children) in raceChildren {
            guard var parentState = states[parentID],
                  engineState.objects.record(for: parentID) != nil,
                  let environment = environments[parentID] else { continue }
            let finishOutput = SM64RacingPenguinRaceChildren.update(
                SM64RacingPenguinRaceChildInput(
                    kind: .finishLine,
                    parentReachedBottom: parentState.reachedBottom,
                    distanceToMario: environment.finishLineDistanceToMario,
                    marioDeltaZ: environment.finishLineMarioDeltaZ
                )
            )
            let shortcutOutput = SM64RacingPenguinRaceChildren.update(
                SM64RacingPenguinRaceChildInput(
                    kind: .shortcutCheck,
                    parentReachedBottom: parentState.reachedBottom,
                    distanceToMario: environment.shortcutDistanceToMario,
                    marioDeltaZ: 0
                )
            )
            parentState.marioWon = parentState.marioWon || finishOutput.marioWon
            parentState.marioCheated = parentState.marioCheated || shortcutOutput.marioCheated
            states[parentID] = parentState
            _ = engineState.objects.mutate(children.finishLine) { record in
                record.parent = parentID
            }
            _ = engineState.objects.mutate(children.shortcutCheck) { record in
                record.parent = parentID
            }
        }
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
