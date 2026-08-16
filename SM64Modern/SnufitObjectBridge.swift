import Foundation

struct SM64SnufitObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64SnufitObjectKind
    let action: SM64SnufitAction?
    let bulletAction: SM64SnufitBulletAction?
    let effects: SM64SnufitEffect
    let spawnedBullets: [SM64ObjectID]
    let markedForDeletion: Bool
}

enum SM64SnufitObjectKind: UInt8, Equatable, Sendable {
    case snufit = 0
    case bullet = 1
}

struct SM64SnufitSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64SnufitObjectEffectRecord]
}

/// Owner-thread bridge for the Snufit and bowling-ball family. A Snufit owns
/// the three-shot cadence; bullets are ordinary general-actor children and
/// unload at the scheduler boundary after a metal bounce, wall/ground hit, or
/// distance/room cull.
final class SM64SnufitObjectBridge {
    static let differentRoomFlag: UInt16 = 1 << 3 // ACTIVE_FLAG_IN_DIFFERENT_ROOM
    static let defaultSnufitBehaviorIdentity: UInt64 = 0x6268_765F_736E66
    static let defaultBulletBehaviorIdentity: UInt64 = 0x6268_765F_736E62
    static let snufitModel: UInt32 = 0xCE // MODEL_SNUFIT
    static let bulletModel: UInt32 = 0xB4 // MODEL_BOWLING_BALL

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var snufits: [SM64ObjectID: SM64SnufitState] = [:]
    private var bullets: [SM64ObjectID: SM64SnufitBulletState] = [:]
    private var snufitInputs: [SM64ObjectID: SM64SnufitTickInput] = [:]
    private var bulletInputs: [SM64ObjectID: SM64SnufitBulletTickInput] = [:]
    private(set) var effectLog: [SM64SnufitObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(snufits.keys) + Array(bullets.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func snufitState(for id: SM64ObjectID) -> SM64SnufitState? { snufits[id] }
    func bulletState(for id: SM64ObjectID) -> SM64SnufitBulletState? { bullets[id] }

    @discardableResult
    func spawnSnufit(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64SnufitObjectBridge.snufitModel,
        behaviorIdentity: UInt64 = SM64SnufitObjectBridge.defaultSnufitBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attachSnufit(
            id,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            moveYaw: moveYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Snufit could not attach")
        }
        return id
    }

    @discardableResult
    func attachSnufit(
        _ id: SM64ObjectID,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64SnufitState(
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            moveYaw: moveYaw
        )
        snufits[id] = state
        snufitInputs[id] = SM64SnufitTickInput()
        synchronizeSnufit(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func spawnBullet(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0,
        movePitch: Int16 = 0,
        parent: SM64ObjectID? = nil,
        model: UInt32 = SM64SnufitObjectBridge.bulletModel,
        behaviorIdentity: UInt64 = SM64SnufitObjectBridge.defaultBulletBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard attachBullet(
            id,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            moveYaw: moveYaw,
            movePitch: movePitch,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Snufit bullet could not attach")
        }
        return id
    }

    @discardableResult
    func attachBullet(
        _ id: SM64ObjectID,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0,
        movePitch: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let bullet = SM64SnufitBulletState(
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ,
            moveYaw: moveYaw,
            movePitch: movePitch
        )
        bullets[id] = bullet
        bulletInputs[id] = SM64SnufitBulletTickInput()
        synchronizeBullet(id: id, state: bullet, pool: pool)
        return true
    }

    @discardableResult
    func setSnufitInput(_ input: SM64SnufitTickInput, for id: SM64ObjectID) -> Bool {
        guard snufits[id] != nil else { return false }
        snufitInputs[id] = input
        return true
    }

    @discardableResult
    func setBulletInput(_ input: SM64SnufitBulletTickInput, for id: SM64ObjectID) -> Bool {
        guard bullets[id] != nil else { return false }
        bulletInputs[id] = input
        return true
    }

    /// Clears per-tick owner-thread effects before an external shared
    /// dispatcher invokes `updateInline` for each Snufit or bullet identity.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    /// Advances one Snufit-family callback without starting a nested scheduler
    /// pass. The enclosing dispatcher remains authoritative for list order.
    @discardableResult
    func updateInline(_ id: SM64ObjectID, pool: SM64ObjectPool) -> Bool {
        guard (snufits[id] != nil || bullets[id] != nil), pool.record(for: id) != nil else {
            return false
        }
        update(id: id, pool: pool)
        return true
    }

    /// Removes a Snufit or bullet shadow after scheduler unload or reset.
    func remove(_ id: SM64ObjectID) {
        snufits.removeValue(forKey: id)
        bullets.removeValue(forKey: id)
        snufitInputs.removeValue(forKey: id)
        bulletInputs.removeValue(forKey: id)
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        snufitInputs frameSnufitInputs: [SM64ObjectID: SM64SnufitTickInput] = [:],
        bulletInputs frameBulletInputs: [SM64ObjectID: SM64SnufitBulletTickInput] = [:]
    ) -> SM64SnufitSchedulerTickResult {
        snufitInputs = frameSnufitInputs
        bulletInputs = frameBulletInputs
        beginExternalTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            _ = self?.updateInline(id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            remove(id)
        }
        for id in registeredIDs where engineState.objects.record(for: id) == nil {
            remove(id)
        }
        return SM64SnufitSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if var state = snufits[id], pool.record(for: id) != nil {
            let input = snufitInputs[id] ?? defaultSnufitInput(for: id, pool: pool)
            let result = SM64SnufitKernel.tick(input, state: &state)
            var spawned: [SM64ObjectID] = []
            if result.effects.contains(.spawnBullet), state.bullets > 0,
               let child = try? pool.spawn(
                   in: .generalActor,
                   model: Self.bulletModel,
                   behaviorIdentity: Self.defaultBulletBehaviorIdentity,
                   parent: id
               ) {
                let yaw = state.moveYaw
                let pitch = state.movePitch
                let childState = SM64SnufitBulletState(
                    // spawn_object_relative(0, 0, -20, 40, ...): the
                    // scheduler's parent transform owns the later local
                    // placement; these values are the initial world snapshot.
                    positionX: state.positionX,
                    positionY: state.positionY - 20,
                    positionZ: state.positionZ + 40,
                    moveYaw: yaw,
                    movePitch: pitch
                )
                bullets[child] = childState
                bulletInputs[child] = SM64SnufitBulletTickInput()
                synchronizeBullet(id: child, state: childState, pool: pool)
                spawned.append(child)
            }
            snufits[id] = state
            synchronizeSnufit(id: id, state: state, pool: pool)
            effectLog.append(
                SM64SnufitObjectEffectRecord(
                    objectID: id,
                    kind: .snufit,
                    action: state.action,
                    bulletAction: nil,
                    effects: result.effects,
                    spawnedBullets: spawned,
                    markedForDeletion: state.markedForDeletion
                )
            )
            return
        }

        guard var state = bullets[id], let record = pool.record(for: id) else { return }
        let input = bulletInputs[id] ?? defaultBulletInput(for: record)
        let result = SM64SnufitKernel.tickBullet(input, state: &state)
        if state.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        bullets[id] = state
        synchronizeBullet(id: id, state: state, pool: pool)
        effectLog.append(
            SM64SnufitObjectEffectRecord(
                objectID: id,
                kind: .bullet,
                action: nil,
                bulletAction: state.action,
                effects: result.effects,
                spawnedBullets: [],
                markedForDeletion: state.markedForDeletion
            )
        )
    }

    private func defaultSnufitInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64SnufitTickInput {
        guard let record = pool.record(for: id) else { return SM64SnufitTickInput() }
        return SM64SnufitTickInput(
            activeInRoom: record.activeFlags & Self.differentRoomFlag == 0,
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            globalTimer: UInt32(truncatingIfNeeded: record.timer)
        )
    }

    private func defaultBulletInput(for record: SM64ObjectRecord) -> SM64SnufitBulletTickInput {
        SM64SnufitBulletTickInput(
            differentRoom: record.activeFlags & Self.differentRoomFlag != 0,
            distanceToMario: record.distanceToMario,
            moveFlags: record.moveFlags,
            hitWallOrGround: record.moveFlags & (SM64SnufitKernel.hitWallFlag | SM64SnufitKernel.onGroundMask) != 0
        )
    }

    private func synchronizeSnufit(id: SM64ObjectID, state: SM64SnufitState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.moveAngles.pitch = Int32(state.movePitch)
            record.faceAngles.pitch = Int32(state.facePitch)
            record.action = Int32(state.action.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
        }
    }

    private func synchronizeBullet(id: SM64ObjectID, state: SM64SnufitBulletState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            if record.parent != record.id {
                record.objectFlags |= SM64ObjectScheduler.objectFlagTransformRelativeToParent
                record.parentRelativePosition = SM64ObjectVector3(x: 0, y: -20, z: 40)
            } else {
                record.objectFlags &= ~SM64ObjectScheduler.objectFlagTransformRelativeToParent
            }
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.moveAngles.pitch = Int32(state.movePitch)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.action = Int32(state.action.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.intangibleTimer = state.intangible ? 1 : -1
            record.interactionType = state.intangible ? 0 : state.hitbox.interactType
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.hitboxDownOffset = state.hitbox.downOffset
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
        }
    }
}
