import Foundation

struct SM64PokeyObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64PokeyKind
    let bodyIndex: Int8
    let effects: SM64PokeyEffect
    let spawnedParts: [SM64ObjectID]
    let numAliveBodyParts: UInt8
    let scale: Float
    let markedForDeletion: Bool
}

struct SM64PokeySchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64PokeyObjectEffectRecord]
}

/// Owner-thread bridge for the Pokey parent and its five parent-relative body
/// parts. Body-part removal changes only copied parent counters/flags; the
/// scheduler owns list traversal and end-of-frame unload ordering.
final class SM64PokeyObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_706F6B
    static let defaultBodyBehaviorIdentity: UInt64 = 0x6268_765F_7062
    static let defaultModel: UInt32 = 0
    static let headModel: UInt32 = 0x54 // MODEL_POKEY_HEAD
    static let bodyModel: UInt32 = 0x55 // MODEL_POKEY_BODY_PART

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var parents: [SM64ObjectID: SM64PokeyState] = [:]
    private var bodies: [SM64ObjectID: SM64PokeyState] = [:]
    private var parentInputs: [SM64ObjectID: SM64PokeyParentTickInput] = [:]
    private var bodyInputs: [SM64ObjectID: SM64PokeyBodyTickInput] = [:]
    private var currentFrame: UInt64 = 0
    private(set) var effectLog: [SM64PokeyObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(parents.keys) + Array(bodies.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64PokeyState? {
        parents[id] ?? bodies[id]
    }

    @discardableResult
    func spawnPokey(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64PokeyObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64PokeyObjectBridge.defaultBehaviorIdentity
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
            preconditionFailure("newly spawned Pokey could not attach")
        }
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
        let state = SM64PokeyState(
            kind: .parent,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
        parents[id] = state
        parentInputs[id] = SM64PokeyParentTickInput()
        synchronizeParent(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setParentInput(_ input: SM64PokeyParentTickInput, for id: SM64ObjectID) -> Bool {
        guard parents[id] != nil else { return false }
        parentInputs[id] = input
        return true
    }

    @discardableResult
    func setBodyInput(_ input: SM64PokeyBodyTickInput, for id: SM64ObjectID) -> Bool {
        guard bodies[id] != nil else { return false }
        bodyInputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        parentInputs frameInputs: [SM64ObjectID: SM64PokeyParentTickInput] = [:],
        bodyInputs frameBodyInputs: [SM64ObjectID: SM64PokeyBodyTickInput] = [:]
    ) -> SM64PokeySchedulerTickResult {
        parentInputs = frameInputs
        bodyInputs = frameBodyInputs
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
        currentFrame = engineState.globals.frame &+ 1
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            parents.removeValue(forKey: id)
            bodies.removeValue(forKey: id)
            parentInputs.removeValue(forKey: id)
            bodyInputs.removeValue(forKey: id)
        }
        for id in Array(parents.keys) where engineState.objects.record(for: id) == nil {
            parents.removeValue(forKey: id)
            parentInputs.removeValue(forKey: id)
        }
        for id in Array(bodies.keys) where engineState.objects.record(for: id) == nil {
            bodies.removeValue(forKey: id)
            bodyInputs.removeValue(forKey: id)
        }
        return SM64PokeySchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if let parent = parents[id] {
            updateParent(id: id, state: parent, pool: pool)
        } else if let body = bodies[id] {
            updateBody(id: id, state: body, pool: pool)
        }
    }

    private func updateParent(id: SM64ObjectID, state: SM64PokeyState, pool: SM64ObjectPool) {
        guard var parent = parents[id], pool.record(for: id) != nil else { return }
        let previousAction = parent.action
        let result = SM64PokeyKernel.tickParent(
            parentInputs[id] ?? defaultParentInput(for: pool.record(for: id)),
            state: &parent
        )
        var spawnedParts: [SM64ObjectID] = []
        if result.effects.contains(.spawnParts) {
            spawnedParts = spawnBodyParts(parentID: id, parent: parent, pool: pool)
        } else if result.effects.contains(.replenishPart), parent.numAliveBodyParts > 0 {
            let index = Int(parent.numAliveBodyParts) - 1
            if let bodyID = try? pool.spawn(
                in: .generalActor,
                model: Self.bodyModel,
                behaviorIdentity: Self.defaultBodyBehaviorIdentity,
                parent: id
            ) {
                let body = SM64PokeyState(
                    kind: .bodyPart,
                    bodyIndex: Int8(index),
                    homeX: parent.positionX,
                    homeY: parent.positionY,
                    homeZ: parent.positionZ,
                    positionX: parent.positionX,
                    positionY: parent.positionY,
                    positionZ: parent.positionZ,
                    scale: 0
                )
                bodies[bodyID] = body
                synchronizeBody(id: bodyID, state: body, pool: pool)
                bodyInputs[bodyID] = defaultBodyInput(parent: parent)
                spawnedParts.append(bodyID)
            }
        }

        parents[id] = parent
        synchronizeParent(id: id, state: parent, pool: pool, previousAction: previousAction)
        if parent.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        effectLog.append(
            SM64PokeyObjectEffectRecord(
                objectID: id,
                kind: .parent,
                bodyIndex: -1,
                effects: result.effects,
                spawnedParts: spawnedParts,
                numAliveBodyParts: parent.numAliveBodyParts,
                scale: 1,
                markedForDeletion: parent.markedForDeletion
            )
        )
    }

    private func updateBody(id: SM64ObjectID, state: SM64PokeyState, pool: SM64ObjectPool) {
        guard var body = bodies[id], let record = pool.record(for: id),
              let parent = parents[record.parent] else { return }
        let parentID = record.parent
        let input = bodyInputs[id] ?? defaultBodyInput(parent: parent)
        let result = SM64PokeyKernel.tickBody(input, state: &body)
        bodies[id] = body
        if result.killedPart {
            var updatedParent = parent
            updatedParent.numAliveBodyParts = updatedParent.numAliveBodyParts > 0
                ? updatedParent.numAliveBodyParts - 1
                : 0
            updatedParent.aliveBodyPartFlags &= ~(1 << UInt8(max(0, Int(body.bodyIndex))))
            if result.killedHead { updatedParent.headWasKilled = true }
            parents[parentID] = updatedParent
            synchronizeParent(id: parentID, state: updatedParent, pool: pool, previousAction: updatedParent.action)
        }
        synchronizeBody(id: id, state: body, pool: pool)
        if body.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        effectLog.append(
            SM64PokeyObjectEffectRecord(
                objectID: id,
                kind: .bodyPart,
                bodyIndex: body.bodyIndex,
                effects: result.effects,
                spawnedParts: [],
                numAliveBodyParts: parent.numAliveBodyParts,
                scale: body.scale,
                markedForDeletion: body.markedForDeletion
            )
        )
    }

    private func spawnBodyParts(parentID: SM64ObjectID, parent: SM64PokeyState, pool: SM64ObjectPool) -> [SM64ObjectID] {
        var spawned: [SM64ObjectID] = []
        for index in 0..<5 {
            guard let bodyID = try? pool.spawn(
                in: .generalActor,
                model: index == 0 ? Self.headModel : Self.bodyModel,
                behaviorIdentity: Self.defaultBodyBehaviorIdentity,
                parent: parentID
            ) else { continue }
            let body = SM64PokeyState(
                kind: .bodyPart,
                bodyIndex: Int8(index),
                homeX: parent.positionX,
                homeY: parent.positionY,
                homeZ: parent.positionZ,
                positionX: parent.positionX,
                positionY: parent.positionY + Float(480 - index * 120),
                positionZ: parent.positionZ
            )
            bodies[bodyID] = body
            bodyInputs[bodyID] = defaultBodyInput(parent: parent)
            synchronizeBody(id: bodyID, state: body, pool: pool)
            spawned.append(bodyID)
        }
        return spawned
    }

    private func defaultParentInput(for record: SM64ObjectRecord?) -> SM64PokeyParentTickInput {
        guard let record else { return SM64PokeyParentTickInput() }
        return SM64PokeyParentTickInput(
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            moveFlags: record.moveFlags,
            animationNearEnd: record.animationState != 0
        )
    }

    private func defaultBodyInput(parent: SM64PokeyState) -> SM64PokeyBodyTickInput {
        SM64PokeyBodyTickInput(
            parentX: parent.positionX,
            parentY: parent.positionY,
            parentZ: parent.positionZ,
            parentAction: parent.action,
            parentAliveBodyPartFlags: parent.aliveBodyPartFlags,
            parentNumAliveBodyParts: parent.numAliveBodyParts,
            parentBottomBodyPartSize: parent.bottomBodyPartSize,
            parentHeadWasKilled: parent.headWasKilled,
            globalFrame: currentFrame
        )
    }

    private func synchronizeParent(id: SM64ObjectID, state: SM64PokeyState, pool: SM64ObjectPool, previousAction: SM64PokeyAction) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.forwardVelocity = state.forwardVelocity
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.behaviorParams = Int32(state.numAliveBodyParts)
            record.behaviorParams2ndByte = Int32(state.aliveBodyPartFlags)
            record.animationState = Int32(truncatingIfNeeded: state.animationState)
            record.interactionType = 0
        }
    }

    private func synchronizeBody(id: SM64ObjectID, state: SM64PokeyState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.scale = SM64ObjectVector3(x: state.scale * 3, y: state.scale * 3, z: state.scale * 3)
            record.action = Int32(state.action.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.behaviorParams2ndByte = Int32(state.bodyIndex)
            record.graphYOffset = state.scale * 22
            record.hitboxDownOffset = state.hitbox.downOffset
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.interactionType = state.markedForDeletion ? 0 : state.hitbox.interactType
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.numLootCoins = state.bodyIndex == 0 ? 1 : 0
        }
    }
}
