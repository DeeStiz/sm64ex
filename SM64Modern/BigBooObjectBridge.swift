import Foundation

struct SM64BigBooObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let variant: SM64BigBooVariant
    let action: SM64BigBooAction
    let effects: SM64BigBooEffect
    let health: Int16
    let starPosition: SM64ObjectVector3?
    let spawnedChildren: [SM64ObjectID]
    let presentedEffects: [SM64OwnerThreadEffectIntent]
}

struct SM64BigBooSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BigBooObjectEffectRecord]
}

/// Owner-thread bridge for the source Big Boo variants. The value kernel owns
/// action/health state; this seam owns generation-safe records, optional
/// reward/bridge creation, shared presentation delivery, and retirement.
final class SM64BigBooObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626967
    static let defaultModel: UInt32 = 0x54 // MODEL_BOO
    static let staircaseModel: UInt32 = 0x35 // MODEL_BBH_STAIRCASE_STEP
    static let staircaseBehaviorIdentity: UInt64 = 0x6268_765F_627264
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let starBehaviorIdentity: UInt64 = 0x6268_765F_73746E
    static let defaultWallHitboxRadius: Float = 30

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64BigBooState] = [:]
    private var inputs: [SM64ObjectID: SM64BigBooTickInput] = [:]
    private(set) var effectLog: [SM64BigBooObjectEffectRecord] = []
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

    func state(for id: SM64ObjectID) -> SM64BigBooState? { states[id] }

    @discardableResult
    func setState(_ state: SM64BigBooState, for id: SM64ObjectID, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        guard states[id] != nil else { return false }
        states[id] = state
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func spawnBigBoo(
        in engineState: SM64SwiftEngineState,
        variant: SM64BigBooVariant = .ghostHunt,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64BigBooAction = .initialize,
        model: UInt32 = SM64BigBooObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BigBooObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            variant: variant,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            action: action,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Big Boo could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        variant: SM64BigBooVariant = .ghostHunt,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64BigBooAction = .initialize,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        var state = SM64BigBooState(
            variant: variant,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
        state.action = action
        states[id] = state
        inputs[id] = SM64BigBooTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64BigBooTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64BigBooTickInput] = [:],
        presentBossEffects: Bool = false,
        spawnRewardStar: Bool = false,
        spawnBridgeChildren: Bool = false
    ) -> SM64BigBooSchedulerTickResult {
        inputs = frameInputs
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(
                id: id,
                pool: pool,
                presentBossEffects: presentBossEffects,
                spawnRewardStar: spawnRewardStar,
                spawnBridgeChildren: spawnBridgeChildren
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
        return SM64BigBooSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(
        id: SM64ObjectID,
        pool: SM64ObjectPool,
        presentBossEffects: Bool,
        spawnRewardStar: Bool,
        spawnBridgeChildren: Bool
    ) {
        guard var boo = states[id], pool.record(for: id) != nil else { return }
        let previousAction = boo.action
        let input = inputs[id] ?? defaultInput(for: id, pool: pool)
        let result = SM64BigBooKernel.tick(input, state: &boo)
        states[id] = boo
        synchronizeRecord(id: id, state: boo, pool: pool, previousAction: previousAction)

        var spawnedChildren: [SM64ObjectID] = []
        if spawnRewardStar,
           let starPosition = result.starPosition,
           let star = try? pool.spawn(
               in: .level,
               model: Self.starModel,
               behaviorIdentity: Self.starBehaviorIdentity,
               parent: id
           ) {
            _ = pool.mutate(star) { record in
                record.objectFlags |=
                    SM64ObjectScheduler.objectFlagBuildTransform |
                    SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                record.position = starPosition
                record.homePosition = starPosition
            }
            spawnedChildren.append(star)
        }
        if spawnBridgeChildren, result.effects.contains(.spawnBridge) {
            let positions = [
                SM64ObjectVector3(x: 973, y: 0, z: 717),
                SM64ObjectVector3(x: 973, y: 0, z: 517),
                SM64ObjectVector3(x: 973, y: 0, z: 917)
            ]
            for position in positions {
                guard let child = try? pool.spawn(
                    in: .level,
                    model: Self.staircaseModel,
                    behaviorIdentity: Self.staircaseBehaviorIdentity,
                    parent: id
                ) else { break }
                _ = pool.mutate(child) { record in
                    record.objectFlags |=
                        SM64ObjectScheduler.objectFlagBuildTransform |
                        SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                    record.position = position
                    record.homePosition = position
                }
                spawnedChildren.append(child)
            }
        }
        if presentBossEffects {
            if result.effects.contains(.sound) {
                effectRouter.enqueue(objectID: id, kind: .sound)
            }
            if result.effects.contains(.mist) {
                effectRouter.enqueue(objectID: id, kind: .particle, value: 1)
            }
            if result.effects.contains(.shake) {
                effectRouter.enqueue(objectID: id, kind: .cameraShake, value: 1)
            }
            if result.effects.contains(.star) {
                effectRouter.enqueue(objectID: id, kind: .star, value: 1)
            }
        }
        if boo.markedForDeletion || result.effects.contains(.markForDeletion) {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)
        effectLog.append(
            SM64BigBooObjectEffectRecord(
                objectID: id,
                variant: boo.variant,
                action: boo.action,
                effects: result.effects,
                health: boo.health,
                starPosition: result.starPosition,
                spawnedChildren: spawnedChildren,
                presentedEffects: delivery.presented
            )
        )
    }

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64BigBooTickInput {
        guard let record = pool.record(for: id) else { return SM64BigBooTickInput() }
        let dx = record.position.x - record.homePosition.x
        let dz = record.position.z - record.homePosition.z
        return SM64BigBooTickInput(
            activeInRoom: record.activeFlags & (1 << 3) == 0,
            distanceToMario: record.distanceToMario,
            lateralDistanceFromHome: (dx * dx + dz * dz).squareRoot(),
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            angleToHome: Int16(truncatingIfNeeded: record.angleToHome),
            marioFaceYaw: Int16(truncatingIfNeeded: record.faceAngles.yaw),
            marioMoveYaw: Int16(truncatingIfNeeded: record.moveAngles.yaw),
            marioY: record.position.y,
            marioInAir: record.moveFlags & (1 << 12) != 0,
            attackStatus: record.interactionStatus & (1 << 15) != 0 ? .attacked : .none,
            hitWall: record.moveFlags & (1 << 9) != 0,
            shouldStop: record.activeFlags & (1 << 3) != 0,
            randomValue: UInt32(truncatingIfNeeded: record.timer)
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BigBooState,
        pool: SM64ObjectPool,
        previousAction: SM64BigBooAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.scale = SM64ObjectVector3(x: state.renderScaleX, y: state.renderScaleY, z: state.renderScaleZ)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.gravity = state.gravity
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles = SM64ObjectAngles(
                pitch: 0,
                yaw: Int32(state.faceYaw),
                roll: Int32(state.faceRoll)
            )
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.opacity = Int32(state.opacity)
            record.graphYOffset = state.baseScale * 60
            record.graphFlags = state.hidden
                ? record.graphFlags | 0x10
                : record.graphFlags & ~0x10
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? state.interactionType : 0
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.health = Int32(state.health)
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.wallHitboxRadius = Self.defaultWallHitboxRadius
            record.gravity = state.gravity
            record.buoyancy = 2
            record.dragStrength = 10
            record.friction = 10
        }
    }
}
