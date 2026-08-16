import Foundation

struct SM64HeaveHoObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64HeaveHoObjectKind
    let effects: SM64HeaveHoEffect
    let action: SM64HeaveHoAction?
    let heldState: SM64HeaveHoHeldState?
    let throwConsumed: Bool
}

enum SM64HeaveHoObjectKind: UInt8, Equatable, Sendable {
    case heaveHo = 0
    case throwChild = 1
}

struct SM64HeaveHoSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64HeaveHoObjectEffectRecord]
}

/// Owner-thread bridge for Heave Ho and its stable Mario throw child.
final class SM64HeaveHoObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_68686F
    static let throwChildBehaviorIdentity: UInt64 = 0x6268_765F_686874
    static let defaultModel: UInt32 = 0x59 // MODEL_HEAVE_HO

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64HeaveHoState] = [:]
    private var throwChildren: [SM64ObjectID: SM64HeaveHoThrowChildState] = [:]
    private var parentForChild: [SM64ObjectID: SM64ObjectID] = [:]
    private var inputs: [SM64ObjectID: SM64HeaveHoTickInput] = [:]
    private(set) var effectLog: [SM64HeaveHoObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(states.keys) + Array(throwChildren.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64HeaveHoState? { states[id] }
    func throwChildState(for id: SM64ObjectID) -> SM64HeaveHoThrowChildState? { throwChildren[id] }

    @discardableResult
    func spawnHeaveHo(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64HeaveHoObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64HeaveHoObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Heave Ho could not attach")
        }
        guard let child = try? engineState.objects.spawn(
            in: .generalActor,
            model: 0,
            behaviorIdentity: Self.throwChildBehaviorIdentity,
            parent: id
        ) else { return id }
        throwChildren[child] = SM64HeaveHoThrowChildState()
        parentForChild[child] = id
        synchronizeThrowChild(id: child, state: throwChildren[child]!, pool: engineState.objects)
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64HeaveHoState(
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
        states[id] = state
        inputs[id] = SM64HeaveHoTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64HeaveHoTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    /// Starts a tick owned by the shared behavior dispatcher. The bridge's
    /// private scheduler is intentionally bypassed in that mode.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    /// Updates one Heave Ho parent or throw child without nesting another
    /// scheduler pass.
    @discardableResult
    func updateInline(_ id: SM64ObjectID, pool: SM64ObjectPool) -> Bool {
        guard (states[id] != nil || throwChildren[id] != nil), pool.record(for: id) != nil else {
            return false
        }
        update(id: id, pool: pool)
        return true
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        throwChildren.removeValue(forKey: id)
        parentForChild.removeValue(forKey: id)
        inputs.removeValue(forKey: id)
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64HeaveHoTickInput] = [:]
    ) -> SM64HeaveHoSchedulerTickResult {
        inputs = frameInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            remove(id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            remove(id)
        }
        for id in Array(throwChildren.keys) where engineState.objects.record(for: id) == nil {
            remove(id)
        }
        return SM64HeaveHoSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if var heaveHo = states[id], pool.record(for: id) != nil {
            let previousAction = heaveHo.action
            let input = inputs[id] ?? defaultInput(for: id, pool: pool)
            let result = SM64HeaveHoKernel.tick(input, state: &heaveHo)
            states[id] = heaveHo
            synchronizeRecord(id: id, state: heaveHo, pool: pool, previousAction: previousAction)
            if heaveHo.markedForDeletion {
                effectRouter.enqueue(objectID: id, kind: .markForDeletion)
                deliveryLog.append(effectRouter.deliver(to: pool))
            }
            effectLog.append(
                SM64HeaveHoObjectEffectRecord(
                    objectID: id,
                    kind: .heaveHo,
                    effects: result.effects,
                    action: heaveHo.action,
                    heldState: heaveHo.heldState,
                    throwConsumed: false
                )
            )
            return
        }

        guard var child = throwChildren[id],
              let parentID = parentForChild[id],
              let parent = states[parentID],
              pool.record(for: id) != nil else { return }
        let result = SM64HeaveHoKernel.tickThrowChild(parent: parent, state: &child)
        throwChildren[id] = child
        synchronizeThrowChild(id: id, state: child, pool: pool)
        effectLog.append(
            SM64HeaveHoObjectEffectRecord(
                objectID: id,
                kind: .throwChild,
                effects: result.effects,
                action: nil,
                heldState: nil,
                throwConsumed: child.throwConsumed
            )
        )
    }

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64HeaveHoTickInput {
        guard let record = pool.record(for: id) else { return SM64HeaveHoTickInput() }
        let dx = record.position.x - record.homePosition.x
        let dz = record.position.z - record.homePosition.z
        return SM64HeaveHoTickInput(
            waterLevelBelowObject: record.moveFlags & SM64HeaveHoKernel.inWaterFlag == 0,
            distanceToMario: record.distanceToMario,
            lateralDistanceHome: (dx * dx + dz * dz).squareRoot(),
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            angleToHome: Int16(truncatingIfNeeded: record.angleToHome),
            moveFlags: record.moveFlags,
            heldState: SM64HeaveHoHeldState(rawValue: UInt8(truncatingIfNeeded: record.heldState)) ?? .free,
            grabbedMario: record.interactionStatus & (1 << 1) != 0,
            animationNearEnd: record.animationState != 0,
            animationFrame: UInt32(truncatingIfNeeded: record.animationState)
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64HeaveHoState,
        pool: SM64ObjectPool,
        previousAction: SM64HeaveHoAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.scale = SM64ObjectVector3(x: 2, y: 2, z: 2)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.animationState = state.animationState
            record.heldState = UInt32(state.heldState.rawValue)
            record.interactionSubtype = state.hitbox.interactionSubtype
            record.intangibleTimer = state.tangible ? 0 : 1
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.graphFlags = state.hidden ? record.graphFlags | 0x10 : record.graphFlags & ~0x10
            record.gravity = -400
            record.dragStrength = 1000
            record.friction = 1000
            record.buoyancy = 600
        }
    }

    private func synchronizeThrowChild(
        id: SM64ObjectID,
        state: SM64HeaveHoThrowChildState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.parentRelativePosition = SM64ObjectVector3(x: 200, y: -50, z: 0)
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
        }
    }
}
