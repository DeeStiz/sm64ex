import Foundation

enum SM64ChuckyaObjectKind: UInt8, Equatable, Sendable {
    case chuckya = 0
    case anchor = 1
}

struct SM64ChuckyaObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64ChuckyaObjectKind
    let effects: SM64ChuckyaEffect
    let action: SM64ChuckyaAction?
    let throwState: UInt8?
    let throwConsumed: Bool
    let markedForDeletion: Bool
}

struct SM64ChuckyaSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64ChuckyaObjectEffectRecord]
}

/// Owner-thread bridge for Chuckya and its anchored Mario child.
final class SM64ChuckyaObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_63686B
    static let anchorBehaviorIdentity: UInt64 = 0x6268_765F_636861
    static let defaultModel: UInt32 = 0xDF // MODEL_CHUCKYA

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64ChuckyaState] = [:]
    private var anchors: [SM64ObjectID: SM64ChuckyaAnchorState] = [:]
    private var parentForAnchor: [SM64ObjectID: SM64ObjectID] = [:]
    private var inputs: [SM64ObjectID: SM64ChuckyaTickInput] = [:]
    private(set) var effectLog: [SM64ChuckyaObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(states.keys) + Array(anchors.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64ChuckyaState? { states[id] }
    func anchorState(for id: SM64ObjectID) -> SM64ChuckyaAnchorState? { anchors[id] }

    @discardableResult
    func spawnChuckya(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64ChuckyaObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64ChuckyaObjectBridge.defaultBehaviorIdentity
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
            preconditionFailure("newly spawned Chuckya could not attach")
        }
        guard let anchor = try? engineState.objects.spawn(
            in: .generalActor,
            model: 0,
            behaviorIdentity: Self.anchorBehaviorIdentity,
            parent: id
        ) else { return id }
        anchors[anchor] = SM64ChuckyaAnchorState()
        parentForAnchor[anchor] = id
        synchronizeAnchor(id: anchor, state: anchors[anchor]!, pool: engineState.objects)
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
        let state = SM64ChuckyaState(homeX: homeX, homeY: homeY, homeZ: homeZ, moveYaw: moveYaw)
        states[id] = state
        inputs[id] = SM64ChuckyaTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64ChuckyaTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64ChuckyaTickInput] = [:]
    ) -> SM64ChuckyaSchedulerTickResult {
        inputs = frameInputs
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            states.removeValue(forKey: id)
            anchors.removeValue(forKey: id)
            parentForAnchor.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        for id in Array(anchors.keys) where engineState.objects.record(for: id) == nil {
            anchors.removeValue(forKey: id)
            parentForAnchor.removeValue(forKey: id)
        }
        return SM64ChuckyaSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if var chuckya = states[id], pool.record(for: id) != nil {
            let previousAction = chuckya.action
            let input = inputs[id] ?? defaultInput(for: id, pool: pool)
            let result = SM64ChuckyaKernel.tick(input, state: &chuckya)
            states[id] = chuckya
            synchronizeRecord(id: id, state: chuckya, pool: pool, previousAction: previousAction)
            if chuckya.markedForDeletion {
                effectRouter.enqueue(objectID: id, kind: .markForDeletion)
                deliveryLog.append(effectRouter.deliver(to: pool))
            }
            effectLog.append(
                SM64ChuckyaObjectEffectRecord(
                    objectID: id,
                    kind: .chuckya,
                    effects: result.effects,
                    action: chuckya.action,
                    throwState: chuckya.throwState,
                    throwConsumed: false,
                    markedForDeletion: chuckya.markedForDeletion
                )
            )
            return
        }

        guard var anchor = anchors[id],
              let parentID = parentForAnchor[id],
              let parent = states[parentID],
              pool.record(for: id) != nil else { return }
        let result = SM64ChuckyaKernel.tickAnchor(parent: parent, state: &anchor)
        anchors[id] = anchor
        synchronizeAnchor(id: id, state: anchor, pool: pool)
        effectLog.append(
            SM64ChuckyaObjectEffectRecord(
                objectID: id,
                kind: .anchor,
                effects: result.effects,
                action: nil,
                throwState: nil,
                throwConsumed: anchor.throwConsumed,
                markedForDeletion: false
            )
        )
    }

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64ChuckyaTickInput {
        guard let record = pool.record(for: id) else { return SM64ChuckyaTickInput() }
        let dx = record.position.x - record.homePosition.x
        let dz = record.position.z - record.homePosition.z
        return SM64ChuckyaTickInput(
            distanceFromMarioHome: record.distanceToMario,
            lateralDistanceHome: (dx * dx + dz * dz).squareRoot(),
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            angleToHome: Int16(truncatingIfNeeded: record.angleToHome),
            floorCollisionFlags: record.moveFlags,
            grabbedMario: record.interactionStatus & (1 << 1) != 0,
            grabEscapeCount: 0,
            overFloor: record.floorHeight != 0,
            animationNearEnd: record.animationState != 0,
            animationFrame: UInt32(truncatingIfNeeded: record.animationState),
            heldState: SM64ChuckyaHeldState(rawValue: UInt8(truncatingIfNeeded: record.heldState)) ?? .free
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64ChuckyaState,
        pool: SM64ObjectPool,
        previousAction: SM64ChuckyaAction
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
            record.subAction = Int32(state.subAction)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.animationState = state.animationState
            record.heldState = UInt32(state.heldState.rawValue)
            record.interactionSubtype = state.hitbox.interactionSubtype
            record.intangibleTimer = state.tangible ? 0 : 1
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.numLootCoins = 5
            record.graphFlags = state.hidden ? record.graphFlags | 0x10 : record.graphFlags & ~0x10
            record.gravity = -400
            record.dragStrength = 1000
            record.friction = 1000
            record.buoyancy = 200
        }
    }

    private func synchronizeAnchor(
        id: SM64ObjectID,
        state: SM64ChuckyaAnchorState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.parentRelativePosition = SM64ObjectVector3(x: 0, y: -60, z: 150)
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
        }
    }
}
