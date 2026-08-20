import Foundation

enum SM64FlyGuyObjectKind: UInt8, Equatable, Sendable {
    case flyGuy = 0
    case flame = 1
}

struct SM64FlyGuyObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64FlyGuyObjectKind
    let effects: SM64FlyGuyEffect
    let action: SM64FlyGuyAction?
    let spawnedChildren: [SM64ObjectID]
    let markedForDeletion: Bool
}

struct SM64FlyGuySchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64FlyGuyObjectEffectRecord]
}

/// Owner-thread bridge for Fly Guy and its transient unimportant flame child.
final class SM64FlyGuyObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_666C79
    static let flameBehaviorIdentity: UInt64 = 0x6268_765F_666C6D
    static let defaultModel: UInt32 = 0xDC // MODEL_FLYGUY
    static let flameModel: UInt32 = 0xCB // MODEL_RED_FLAME_SHADOW

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64FlyGuyState] = [:]
    private var flames: [SM64ObjectID: SM64FlyGuyFlameState] = [:]
    private var parentForFlame: [SM64ObjectID: SM64ObjectID] = [:]
    private var inputs: [SM64ObjectID: SM64FlyGuyTickInput] = [:]
    private(set) var effectLog: [SM64FlyGuyObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(states.keys) + Array(flames.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64FlyGuyState? { states[id] }
    func flameState(for id: SM64ObjectID) -> SM64FlyGuyFlameState? { flames[id] }

    func contains(_ id: SM64ObjectID) -> Bool {
        states[id] != nil || flames[id] != nil
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        input: SM64FlyGuyTickInput? = nil,
        pool: SM64ObjectPool
    ) -> SM64FlyGuyObjectEffectRecord? {
        guard contains(id) else { return nil }
        if let input, states[id] != nil { inputs[id] = input }
        let count = effectLog.count
        update(id: id, pool: pool)
        return effectLog.count > count ? effectLog.last : nil
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        flames.removeValue(forKey: id)
        parentForFlame.removeValue(forKey: id)
        inputs.removeValue(forKey: id)
    }

    @discardableResult
    func spawnFlyGuy(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64FlyGuyObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64FlyGuyObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, model: model, behaviorIdentity: behaviorIdentity)
        guard attach(id, homeX: homeX, homeY: homeY, homeZ: homeZ, moveYaw: moveYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Fly Guy could not attach")
        }
        return id
    }

    @discardableResult
    func spawnFlame(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            behaviorIdentity: Self.flameBehaviorIdentity,
            parent: parent
        )
        var flame = SM64FlyGuyFlameState()
        flame.positionX = position.x
        flame.positionY = position.y
        flame.positionZ = position.z
        flames[id] = flame
        parentForFlame[id] = parent ?? id
        synchronizeFlame(id: id, state: flame, pool: engineState.objects)
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
        let state = SM64FlyGuyState(homeX: homeX, homeY: homeY, homeZ: homeZ, moveYaw: moveYaw)
        states[id] = state
        inputs[id] = SM64FlyGuyTickInput()
        synchronizeRecord(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64FlyGuyTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64FlyGuyTickInput] = [:]
    ) -> SM64FlyGuySchedulerTickResult {
        inputs = frameInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            _ = self?.updateInline(id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            remove(id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            remove(id)
        }
        for id in Array(flames.keys) where engineState.objects.record(for: id) == nil {
            remove(id)
        }
        return SM64FlyGuySchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if var flyGuy = states[id], pool.record(for: id) != nil {
            let input = inputs[id] ?? defaultInput(for: id, pool: pool)
            let result = SM64FlyGuyKernel.tick(input, state: &flyGuy)
            states[id] = flyGuy
            synchronizeRecord(id: id, state: flyGuy, pool: pool)
            var children: [SM64ObjectID] = []
            if result.effects.contains(.spitFire),
               let flame = try? pool.spawn(
                   in: .unimportant,
                   model: Self.flameModel,
                   behaviorIdentity: Self.flameBehaviorIdentity,
                   parent: id
               ) {
                flames[flame] = SM64FlyGuyFlameState()
                parentForFlame[flame] = id
                synchronizeFlame(id: flame, state: flames[flame]!, pool: pool)
                children.append(flame)
            }
            effectLog.append(
                SM64FlyGuyObjectEffectRecord(
                    objectID: id,
                    kind: .flyGuy,
                    effects: result.effects,
                    action: flyGuy.action,
                    spawnedChildren: children,
                    markedForDeletion: flyGuy.markedForDeletion
                )
            )
            return
        }

        guard var flame = flames[id],
              let parentID = parentForFlame[id],
              let parent = states[parentID],
              pool.record(for: id) != nil else { return }
        let result = SM64FlyGuyKernel.tickFlame(parent: parent, state: &flame)
        flames[id] = flame
        synchronizeFlame(id: id, state: flame, pool: pool)
        if flame.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        effectLog.append(
            SM64FlyGuyObjectEffectRecord(
                objectID: id,
                kind: .flame,
                effects: result.effects,
                action: nil,
                spawnedChildren: [],
                markedForDeletion: flame.markedForDeletion
            )
        )
    }

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64FlyGuyTickInput {
        guard let record = pool.record(for: id) else { return SM64FlyGuyTickInput() }
        let dx = record.position.x - record.homePosition.x
        let dz = record.position.z - record.homePosition.z
        return SM64FlyGuyTickInput(
            activeInRoom: record.activeFlags & (1 << 3) == 0,
            distanceToMario: record.distanceToMario,
            distanceFromHome: (dx * dx + dz * dz).squareRoot(),
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            marioY: record.position.y,
            behaviorShootsFire: record.behaviorParams2ndByte != 0,
            randomValue: UInt32(truncatingIfNeeded: record.timer),
            moveFlags: record.moveFlags
        )
    }

    private func synchronizeRecord(id: SM64ObjectID, state: SM64FlyGuyState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles = SM64ObjectAngles(pitch: Int32(state.facePitch), yaw: Int32(state.faceYaw), roll: Int32(state.faceRoll))
            record.action = Int32(state.action.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.animationState = 0
            record.graphYOffset = 30
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.interactionSubtype = 1 << 5 // INT_SUBTYPE_TWIRL_BOUNCE
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.numLootCoins = Int32(state.hitbox.numLootCoins)
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.friction = 1000
            record.buoyancy = 600
        }
    }

    private func synchronizeFlame(id: SM64ObjectID, state: SM64FlyGuyFlameState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.timer = Int32(truncatingIfNeeded: state.timer)
        }
    }
}
