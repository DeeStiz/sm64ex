import Foundation

struct SM64TuxiesMotherObjectState: Equatable, Sendable {
    var action: Int32 = SM64TuxiesMotherBehavior.followChild
    var subAction: Int32 = SM64TuxiesMotherBehavior.subIdle
    var moveYaw: Int16 = 0
    var childID: SM64ObjectID?
}

struct SM64TuxiesMotherEnvironment: Equatable, Sendable {
    let motherBehaviorParam: UInt8
    let childBehaviorParam: UInt8
    let childExists: Bool
    let childDistance: Float
    let childHeldState: Int32
    let nearbyHeldActor: Bool
    let lateralDistanceToMarioHome: Float
    let marioOnPlatform: Bool
    let canActivateText: Bool
    let dialogResult: Int32
    let angleToMario: Int16
    let soundStateID: Int32
    let animationFrameOne: Bool
    let globalTimer: UInt64

    init(
        motherBehaviorParam: UInt8 = 1,
        childBehaviorParam: UInt8 = 1,
        childExists: Bool = false,
        childDistance: Float = .greatestFiniteMagnitude,
        childHeldState: Int32 = SM64TuxiesMotherBehavior.heldFree,
        nearbyHeldActor: Bool = false,
        lateralDistanceToMarioHome: Float = 0,
        marioOnPlatform: Bool = false,
        canActivateText: Bool = false,
        dialogResult: Int32 = 0,
        angleToMario: Int16 = 0,
        soundStateID: Int32 = 1,
        animationFrameOne: Bool = false,
        globalTimer: UInt64 = 0
    ) {
        self.motherBehaviorParam = motherBehaviorParam
        self.childBehaviorParam = childBehaviorParam
        self.childExists = childExists
        self.childDistance = childDistance
        self.childHeldState = childHeldState
        self.nearbyHeldActor = nearbyHeldActor
        self.lateralDistanceToMarioHome = lateralDistanceToMarioHome
        self.marioOnPlatform = marioOnPlatform
        self.canActivateText = canActivateText
        self.dialogResult = dialogResult
        self.angleToMario = angleToMario
        self.soundStateID = soundStateID
        self.animationFrameOne = animationFrameOne
        self.globalTimer = globalTimer
    }
}

struct SM64TuxiesMotherObjectEffect: Equatable, Sendable {
    let objectID: SM64ObjectID
    let childID: SM64ObjectID?
    let output: SM64TuxiesMotherOutput
    let eyesSelectedCase: Int32
    let spawnedChildren: [SM64ObjectID]
    let presentedEffects: [SM64OwnerThreadEffectIntent]
}

struct SM64TuxiesMotherSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64TuxiesMotherObjectEffect]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for Tuxie's mother and the small penguin she carries.
/// The mother kernel remains value-only; this bridge owns generation-safe child
/// links, dialog/star/audio delivery, record synchronization, and retirement.
final class SM64TuxiesMotherObjectBridge {
    static let defaultModel: UInt32 = 0x57 // MODEL_PENGUIN
    static let defaultMotherBehaviorIdentity: UInt64 = 0x6268_765F_74786D
    static let defaultSmallPenguinBehaviorIdentity: UInt64 = 0x6268_765F_73706E
    static let unusedChildBehaviorIdentity: UInt64 = 0x6268_765F_75736E
    static let babyChildBehaviorIdentity: UInt64 = 0x6268_765F_707362
    static let starBehaviorIdentity: UInt64 = 0x6268_765F_737463
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let walkingSoundValue: Int32 = 4
    static let yellSoundValue: Int32 = 5

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64TuxiesMotherObjectState] = [:]
    private var environments: [SM64ObjectID: SM64TuxiesMotherEnvironment] = [:]
    private(set) var effectLog: [SM64TuxiesMotherObjectEffect] = []
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

    func state(for id: SM64ObjectID) -> SM64TuxiesMotherObjectState? {
        states[id]
    }

    @discardableResult
    func spawnMother(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64TuxiesMotherObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TuxiesMotherObjectBridge.defaultMotherBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attachMother(id, position: position, moveYaw: moveYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Tuxie's mother could not attach")
        }
        return id
    }

    @discardableResult
    func spawnSmallPenguin(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil,
        model: UInt32 = SM64TuxiesMotherObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TuxiesMotherObjectBridge.defaultSmallPenguinBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        _ = engineState.objects.mutate(id) { record in
            record.position = position
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
        return id
    }

    @discardableResult
    func attachMother(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        childID: SM64ObjectID? = nil,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        if let childID, pool.record(for: childID) == nil { return false }
        states[id] = SM64TuxiesMotherObjectState(moveYaw: moveYaw, childID: childID)
        environments[id] = SM64TuxiesMotherEnvironment()
        if let childID {
            _ = pool.setParent(childID, parent: id)
        }
        synchronizeMother(id: id, state: states[id]!, position: position, previousAction: states[id]!.action, pool: pool)
        return true
    }

    @discardableResult
    func attachChild(_ childID: SM64ObjectID, to motherID: SM64ObjectID, in pool: SM64ObjectPool) -> Bool {
        guard states[motherID] != nil, pool.record(for: childID) != nil else { return false }
        states[motherID]?.childID = childID
        _ = pool.setParent(childID, parent: motherID)
        return true
    }

    @discardableResult
    func setEnvironment(_ environment: SM64TuxiesMotherEnvironment, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        environments[id] = environment
        return true
    }

    /// Clears per-tick owner receipts before shared dispatch traverses the
    /// general-actor Tuxie's-mother identity.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, pool: SM64ObjectPool) -> Bool {
        guard states[id] != nil, pool.record(for: id) != nil else { return false }
        update(id: id, pool: pool)
        return true
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        environments.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { retire(id: id, pool: pool) }
        for id in registeredIDs where pool.record(for: id) == nil {
            retire(id: id, pool: pool)
        }
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        environments frameEnvironments: [SM64ObjectID: SM64TuxiesMotherEnvironment] = [:]
    ) -> SM64TuxiesMotherSchedulerTickResult {
        environments = frameEnvironments
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        return SM64TuxiesMotherSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = states[id], let record = pool.record(for: id) else { return }
        let previousAction = state.action
        let environment = environments[id] ?? defaultEnvironment(for: id, state: state, record: record, pool: pool)
        let output = SM64TuxiesMotherBehavior.update(
            SM64TuxiesMotherInput(
                action: state.action,
                subAction: state.subAction,
                motherBehaviorParam: environment.motherBehaviorParam,
                childBehaviorParam: environment.childBehaviorParam,
                childExists: environment.childExists,
                childDistance: environment.childDistance,
                childHeldState: environment.childHeldState,
                nearbyHeldActor: environment.nearbyHeldActor,
                lateralDistanceToMarioHome: environment.lateralDistanceToMarioHome,
                marioOnPlatform: environment.marioOnPlatform,
                canActivateText: environment.canActivateText,
                dialogResult: environment.dialogResult,
                angleToMario: environment.angleToMario,
                moveYaw: state.moveYaw,
                soundStateID: environment.soundStateID,
                animationFrameOne: environment.animationFrameOne
            )
        )
        state.action = output.action
        state.subAction = output.subAction
        state.moveYaw = output.moveYaw
        states[id] = state
        let eyes = SM64TuxiesMotherEyes.update(
            SM64TuxiesMotherEyesInput(
                globalTimer: environment.globalTimer,
                objectBehaviorIdentity: record.behaviorIdentity,
                motherBehaviorIdentity: Self.defaultMotherBehaviorIdentity,
                forwardVelocity: output.forwardVelocity
            )
        )

        var spawnedChildren: [SM64ObjectID] = []
        if let childID = state.childID, pool.record(for: childID) != nil {
            if output.childSmallPenguinUnk88 {
                _ = pool.setParent(childID, parent: id)
            }
            if output.childInteractionSetMask != 0 {
                _ = pool.mutate(childID) { child in
                    child.interactionSubtype |= output.childInteractionSetMask
                }
            }
            if output.clearChildDropImmediate {
                _ = pool.mutate(childID) { child in
                    child.interactionSubtype &= ~SM64TuxiesMotherBehavior.interactionDropImmediately
                }
            }
            if output.childBehavior == SM64TuxiesMotherBehavior.childUnusedBehavior {
                _ = pool.mutate(childID) { child in
                    child.behaviorIdentity = Self.unusedChildBehaviorIdentity
                    child.currentBehaviorCommandIdentity = Self.unusedChildBehaviorIdentity
                    child.action = 0
                }
            } else if output.childBehavior == SM64TuxiesMotherBehavior.childBabyBehavior {
                _ = pool.mutate(childID) { child in
                    child.behaviorIdentity = Self.babyChildBehaviorIdentity
                    child.currentBehaviorCommandIdentity = Self.babyChildBehaviorIdentity
                    child.action = 0
                }
            }
        }

        if output.spawnStar,
           let star = try? pool.spawn(
               in: .level,
               model: Self.starModel,
               behaviorIdentity: Self.starBehaviorIdentity,
               parent: id
           ) {
            let parentPosition = pool.record(for: id)?.position ?? .zero
            _ = pool.mutate(star) { starRecord in
                starRecord.objectFlags |=
                    SM64ObjectScheduler.objectFlagBuildTransform |
                    SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                starRecord.position = SM64ObjectVector3(
                    x: parentPosition.x,
                    y: parentPosition.y + output.starSpawnYOffset,
                    z: parentPosition.z
                )
                starRecord.homePosition = output.starHomePosition ?? .zero
                starRecord.behaviorParams2ndByte = 0
            }
            spawnedChildren.append(star)
            effectRouter.enqueue(objectID: id, kind: .star)
        }
        if output.dialogRequested, output.dialogID > 0 {
            effectRouter.enqueue(objectID: id, kind: .dialog, value: output.dialogID)
        }
        if output.playWalkingSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: Self.walkingSoundValue)
        }
        if output.playYellSound {
            effectRouter.enqueue(objectID: id, kind: .sound, value: Self.yellSoundValue)
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)

        synchronizeMother(
            id: id,
            state: state,
            position: record.position,
            output: output,
            previousAction: previousAction,
            pool: pool
        )
        effectLog.append(
            SM64TuxiesMotherObjectEffect(
                objectID: id,
                childID: state.childID,
                output: output,
                eyesSelectedCase: eyes.selectedCase,
                spawnedChildren: spawnedChildren,
                presentedEffects: delivery.presented
            )
        )
    }

    private func defaultEnvironment(
        for id: SM64ObjectID,
        state: SM64TuxiesMotherObjectState,
        record: SM64ObjectRecord,
        pool: SM64ObjectPool
    ) -> SM64TuxiesMotherEnvironment {
        let child = state.childID.flatMap { pool.record(for: $0) }
        return SM64TuxiesMotherEnvironment(
            motherBehaviorParam: UInt8(truncatingIfNeeded: record.behaviorParams2ndByte),
            childBehaviorParam: UInt8(truncatingIfNeeded: child?.behaviorParams2ndByte ?? 0),
            childExists: child != nil,
            childDistance: child?.distanceToMario ?? .greatestFiniteMagnitude,
            childHeldState: Int32(child?.heldState ?? 0),
            nearbyHeldActor: false,
            lateralDistanceToMarioHome: record.distanceToMario,
            marioOnPlatform: record.platform == id,
            canActivateText: record.dialogState != 0,
            dialogResult: Int32(record.dialogResponse),
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            soundStateID: record.soundStateID,
            animationFrameOne: false,
            globalTimer: 0
        )
    }

    private func synchronizeMother(
        id: SM64ObjectID,
        state: SM64TuxiesMotherObjectState,
        position: SM64ObjectVector3,
        output: SM64TuxiesMotherOutput? = nil,
        previousAction: Int32,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.scale = SM64ObjectVector3(
                x: output?.scale ?? 1,
                y: output?.scale ?? 1,
                z: output?.scale ?? 1
            )
            record.forwardVelocity = output?.forwardVelocity ?? 0
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.angleVelocity.yaw = Int32(output?.angleVelocityYaw ?? 0)
            record.action = state.action
            record.previousAction = previousAction
            record.subAction = state.subAction
            record.animationState = output?.animation ?? SM64TuxiesMotherBehavior.idleAnimation
            if output?.activeFlagUnk10 == true {
                record.activeFlags |= UInt16(1 << 10)
            }
            if output?.clearInteractionStatus == true {
                record.interactionStatus = 0
            }
        }
    }

    private func retire(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard let state = states.removeValue(forKey: id) else { return }
        environments.removeValue(forKey: id)
        if let childID = state.childID, pool.record(for: childID) != nil {
            _ = pool.despawn(childID)
        }
    }
}
