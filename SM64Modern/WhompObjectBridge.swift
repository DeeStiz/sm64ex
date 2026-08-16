import Foundation

struct SM64WhompObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let size: SM64WhompSize
    let action: SM64WhompAction
    let effects: SM64WhompEffect
    let health: Int16
    let markedForDeletion: Bool
    let spawnedChildren: [SM64ObjectID]
    let presentedEffects: [SM64OwnerThreadEffectIntent]
}

struct SM64WhompSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64WhompObjectEffectRecord]
}

/// Owner-thread bridge for the surface-list Whomp and King Whomp actors.
/// Value-state transitions produce effect intents; the scheduler remains the
/// authority for list order, collision counters, transforms, and unload.
final class SM64WhompObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_77686D
    static let defaultModel: UInt32 = 0x67 // MODEL_WHOMP
    static let bossCameraModeValue: Int32 = 11 // CAMERA_MODE_BOSS_FIGHT
    static let kingWhompDeathSoundValue: Int32 = Int32(bitPattern: 0x5147_C081)
    static let whompLowPrioritySoundValue: Int32 = Int32(bitPattern: 0x5016_8081)
    static let thwompSoundValue: Int32 = Int32(bitPattern: 0x500C_00A0)
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let starBehaviorIdentity: UInt64 = 0x6268_765F_73746E
    static let kingWhompStarPosition = SM64ObjectVector3(x: 180, y: 3_880, z: 340)

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64WhompState] = [:]
    private var inputs: [SM64ObjectID: SM64WhompTickInput] = [:]
    private(set) var effectLog: [SM64WhompObjectEffectRecord] = []
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

    func state(for id: SM64ObjectID) -> SM64WhompState? { states[id] }

    @discardableResult
    func spawnWhomp(
        in engineState: SM64SwiftEngineState,
        size: SM64WhompSize = .normal,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64WhompAction = .initialize,
        model: UInt32 = SM64WhompObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64WhompObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            size: size,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            action: action,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Whomp could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        size: SM64WhompSize = .normal,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64WhompAction = .initialize,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        var state = SM64WhompState(
            size: size,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
        state.action = action
        states[id] = state
        inputs[id] = SM64WhompTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64WhompTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64WhompTickInput] = [:],
        presentBossEffects: Bool = false,
        spawnRewardStar: Bool = false
    ) -> SM64WhompSchedulerTickResult {
        inputs = frameInputs
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(
                id: id,
                pool: pool,
                presentBossEffects: presentBossEffects,
                spawnRewardStar: spawnRewardStar
            )
        }
        for id in schedulerResult.unloaded {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        return SM64WhompSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(
        id: SM64ObjectID,
        pool: SM64ObjectPool,
        presentBossEffects: Bool,
        spawnRewardStar: Bool
    ) {
        guard var whomp = states[id], pool.record(for: id) != nil else { return }
        let previousAction = whomp.action
        let input = inputs[id] ?? defaultInput(for: id, pool: pool)
        let result = SM64WhompKernel.tick(input, state: &whomp)
        states[id] = whomp
        synchronizeRecord(id: id, state: whomp, pool: pool, previousAction: previousAction)
        var spawnedChildren: [SM64ObjectID] = []
        if spawnRewardStar,
           whomp.size == .king,
           result.effects.contains(.star),
           let star = try? pool.spawn(
               in: .level,
               model: Self.starModel,
               behaviorIdentity: Self.starBehaviorIdentity,
               parent: id
           ) {
            _ = pool.mutate(star) { starRecord in
                starRecord.objectFlags |=
                    SM64ObjectScheduler.objectFlagBuildTransform |
                    SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                starRecord.position = Self.kingWhompStarPosition
                starRecord.homePosition = Self.kingWhompStarPosition
                starRecord.behaviorParams2ndByte = 0
            }
            spawnedChildren.append(star)
        }
        if presentBossEffects {
            if result.effects.contains(.deathSound) {
                effectRouter.enqueue(
                    objectID: id,
                    kind: .sound,
                    value: Self.kingWhompDeathSoundValue
                )
            }
            if result.effects.contains(.landSound) {
                effectRouter.enqueue(
                    objectID: id,
                    kind: .sound,
                    value: Self.whompLowPrioritySoundValue
                )
            }
            if result.effects.contains(.soundSpawner) {
                effectRouter.enqueue(
                    objectID: id,
                    kind: .sound,
                    value: Self.thwompSoundValue,
                    auxiliary: 1
                )
            }
            if result.effects.contains(.bossMusic) {
                effectRouter.enqueue(objectID: id, kind: .music, value: 1)
            }
            if result.effects.contains(.cameraFocus) {
                effectRouter.enqueue(
                    objectID: id,
                    kind: .cameraFocus,
                    value: Self.bossCameraModeValue
                )
            }
            if result.effects.contains(.mist) {
                effectRouter.enqueue(objectID: id, kind: .particle, value: 1)
            }
            if result.effects.contains(.triangleBreak) {
                effectRouter.enqueue(objectID: id, kind: .particle, value: 2)
            }
            if result.effects.contains(.shake) {
                effectRouter.enqueue(objectID: id, kind: .cameraShake, value: 1)
            }
            if result.effects.contains(.star) {
                effectRouter.enqueue(objectID: id, kind: .star, value: 1)
            }
            if result.effects.contains(.stopBossMusic) {
                effectRouter.enqueue(objectID: id, kind: .music, value: 0)
            }
        }
        if whomp.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)
        effectLog.append(
            SM64WhompObjectEffectRecord(
                objectID: id,
                size: whomp.size,
                action: whomp.action,
                effects: result.effects,
                health: whomp.health,
                markedForDeletion: whomp.markedForDeletion,
                spawnedChildren: spawnedChildren,
                presentedEffects: delivery.presented
            )
        )
    }

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64WhompTickInput {
        guard let record = pool.record(for: id) else { return SM64WhompTickInput() }
        let dx = record.position.x - record.homePosition.x
        let dz = record.position.z - record.homePosition.z
        return SM64WhompTickInput(
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            lateralDistanceHome: (dx * dx + dz * dz).squareRoot(),
            marioFarBelow: record.position.y - record.homePosition.y < -1_000,
            marioGroundPound: record.interactionStatus & (1 << 13) != 0,
            marioOnPlatform: record.platform == id,
            landed: record.moveFlags & 1 != 0,
            onGround: record.moveFlags & 1 != 0,
            animationNearEnd: record.animationState != 0,
            marioSquished: record.action == 0x17,
            dialogComplete: record.dialogState != 0
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64WhompState,
        pool: SM64ObjectPool,
        previousAction: SM64WhompAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.pitch = Int32(state.facePitch)
            record.angleVelocity.pitch = Int32(state.angleVelocityPitch)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.subAction = state.subAction
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.behaviorParams2ndByte = Int32(state.size.rawValue)
            record.health = Int32(state.health)
            record.numLootCoins = state.size == .normal ? 5 : 0
            record.scale = state.size == .king ? .init(x: 2, y: 2, z: 2) : .one
            record.graphFlags = state.hidden ? record.graphFlags | 0x10 : record.graphFlags & ~0x10
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.wallHitboxRadius = 0
            record.gravity = -400
            record.buoyancy = 200
        }
    }
}
