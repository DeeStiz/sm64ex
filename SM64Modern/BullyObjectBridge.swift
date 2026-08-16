import Foundation

struct SM64BullyObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let size: SM64BullySize
    let effects: SM64BullyEffect
    let action: SM64BullyAction
    let markedForDeletion: Bool
    let coinPosition: SM64ObjectVector3?
    let starPosition: SM64ObjectVector3?
    let bridgePosition: SM64ObjectVector3?
    let spawnedChildren: [SM64ObjectID]
    let presentedEffects: [SM64OwnerThreadEffectIntent]
    let collision: SM64BullyCollisionResult?
    let movement: SM64BullyMovementResult?
}

struct SM64BullySchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BullyObjectEffectRecord]
}

/// Owner-thread bridge for small and large Bully actors. The collision
/// response is a copied state/effect boundary; object records retain only
/// stable transforms, hitboxes, action timers, and deletion flags.
final class SM64BullyObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_62756C
    static let defaultModel: UInt32 = 0x6A // MODEL_BULLY
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let starBehaviorIdentity: UInt64 = 0x6268_765F_73746E
    static let bridgeModel: UInt32 = 0
    static let bridgeBehaviorIdentity: UInt64 = 0x6268_765F_6C6C62
    static let coinModel: UInt32 = SM64OwnerThreadEffectRouter.coinModel
    static let coinBehaviorIdentity: UInt64 = SM64OwnerThreadEffectRouter.coinBehaviorIdentity
    static let defaultWallHitboxRadius: Float = SM64BullyCollision.wallHitboxRadius

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64BullyState] = [:]
    private var inputs: [SM64ObjectID: SM64BullyTickInput] = [:]
    private var minionParents: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64BullyObjectEffectRecord] = []
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

    func state(for id: SM64ObjectID) -> SM64BullyState? {
        states[id]
    }

    func minionIDs(for parentID: SM64ObjectID) -> [SM64ObjectID] {
        minionParents.compactMap { child, parent in
            parent == parentID ? child : nil
        }.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    @discardableResult
    func setState(_ state: SM64BullyState, for id: SM64ObjectID, in pool: SM64ObjectPool) -> Bool {
        guard states[id] != nil, pool.record(for: id) != nil else { return false }
        states[id] = state
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func spawnBully(
        in engineState: SM64SwiftEngineState,
        size: SM64BullySize,
        subtype: SM64BullySubtype = .generic,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64BullyAction = .patrol,
        model: UInt32 = SM64BullyObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BullyObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            size: size,
            subtype: subtype,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            action: action,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bully could not attach")
        }
        return id
    }

    @discardableResult
    func spawnBigBullyWithMinions(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 3_700,
        homeY: Float = 600,
        homeZ: Float = -5_500
    ) throws -> SM64ObjectID {
        let parentID = try spawnBully(
            in: engineState,
            size: .big,
            subtype: .generic,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            action: .inactive
        )
        let minionPositions = [
            SM64ObjectVector3(x: 4_454, y: 307, z: -5_426),
            SM64ObjectVector3(x: 3_840, y: 307, z: -6_041),
            SM64ObjectVector3(x: 3_226, y: 307, z: -5_426)
        ]
        for position in minionPositions {
            let childID = try spawnBully(
                in: engineState,
                size: .small,
                subtype: .minion,
                homeX: position.x,
                homeY: position.y,
                homeZ: position.z
            )
            minionParents[childID] = parentID
        }
        return parentID
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        size: SM64BullySize,
        subtype: SM64BullySubtype = .generic,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64BullyAction = .patrol,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BullyState(
            size: size,
            subtype: subtype,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            action: action
        )
        states[id] = state
        inputs[id] = SM64BullyTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64BullyTickInput, for id: SM64ObjectID) -> Bool {
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

    /// Updates one Bully parent/minion without nesting another scheduler pass.
    @discardableResult
    func updateInline(_ id: SM64ObjectID, pool: SM64ObjectPool) -> Bool {
        guard states[id] != nil, pool.record(for: id) != nil else { return false }
        update(
            id: id,
            pool: pool,
            collisionWorld: nil,
            advanceMovement: false,
            presentEffects: false,
            spawnRewards: false,
            spawnBridge: false
        )
        return true
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        inputs.removeValue(forKey: id)
        minionParents.removeValue(forKey: id)
        let childIDs = minionParents.compactMap { child, parent in parent == id ? child : nil }
        for child in childIDs { minionParents.removeValue(forKey: child) }
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64BullyTickInput] = [:],
        collisionWorld: SM64SurfaceCollisionWorld? = nil,
        advanceMovement: Bool = false,
        presentEffects: Bool = false,
        spawnRewards: Bool = false,
        spawnBridge: Bool = false
    ) -> SM64BullySchedulerTickResult {
        inputs = frameInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(
                id: id,
                pool: pool,
                collisionWorld: collisionWorld,
                advanceMovement: advanceMovement,
                presentEffects: presentEffects,
                spawnRewards: spawnRewards,
                spawnBridge: spawnBridge
            )
        }
        for id in schedulerResult.unloaded {
            remove(id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            remove(id)
        }
        return SM64BullySchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(
        id: SM64ObjectID,
        pool: SM64ObjectPool,
        collisionWorld: SM64SurfaceCollisionWorld?,
        advanceMovement: Bool,
        presentEffects: Bool,
        spawnRewards: Bool,
        spawnBridge: Bool
    ) {
        guard var bully = states[id], let record = pool.record(for: id) else { return }
        let previousAction = bully.action
        let physicsEnabled = advanceMovement
            && collisionWorld != nil
            && bully.action != .inactive
            && bully.action != .lavaDeath
            && bully.action != .deathPlaneDeath
        let collision = physicsEnabled
            ? collisionWorld.flatMap { world in
                SM64BullyCollision.resolve(
                    SM64BullyCollisionInput(
                        position: record.position,
                        moveYaw: bully.moveYaw,
                        wallHitboxRadius: record.wallHitboxRadius,
                        previousMoveFlags: record.moveFlags,
                        world: world
                    )
                )
            }
            : nil
        var input = inputs[id] ?? defaultInput(for: record)
        if bully.size == .big, bully.action == .inactive {
            input.minionCount = bully.knockbackCounter
        }
        input.movementHandledExternally = physicsEnabled
        let result = SM64BullyKernel.tick(input, state: &bully)
        if bully.subtype == .minion,
           result.effects.contains(.markForDeletion),
           let parentID = minionParents[id],
           var parent = states[parentID] {
            parent.knockbackCounter = min(parent.knockbackCounter &+ 1, 3)
            states[parentID] = parent
        }
        let movement: SM64BullyMovementResult?
        if physicsEnabled, let world = collisionWorld {
            let basePosition = collision?.position ?? record.position
            let actionPosition = SM64ObjectVector3(
                x: basePosition.x,
                y: bully.positionY,
                z: basePosition.z
            )
            let candidatePosition = SM64ObjectVector3(
                x: actionPosition.x
                    + SM64CanonicalTrig.sins(bully.moveYaw) * bully.forwardVelocity,
                y: actionPosition.y,
                z: actionPosition.z
                    + SM64CanonicalTrig.coss(bully.moveYaw) * bully.forwardVelocity
            )
            let floor = collision ?? SM64BullyCollision.resolve(
                SM64BullyCollisionInput(
                    position: actionPosition,
                    moveYaw: bully.moveYaw,
                    wallHitboxRadius: record.wallHitboxRadius,
                    previousMoveFlags: record.moveFlags,
                    world: world
                )
            )
            let intendedFloor = world.findFloor(
                x: candidatePosition.x,
                y: candidatePosition.y,
                z: candidatePosition.z
            )
            let intendedRoom: Int8 = intendedFloor.surfaceID.flatMap {
                world.surface(withID: $0)?.room
            } ?? 0
            movement = SM64BullyCollision.move(
                SM64BullyMovementInput(
                    startPosition: actionPosition,
                    candidatePosition: candidatePosition,
                    velocityY: bully.velocityY,
                    forwardVelocity: bully.forwardVelocity,
                    moveYaw: bully.moveYaw,
                    floorHeight: floor?.floorHeight ?? record.floorHeight,
                    floorRoom: floor?.floorRoom ?? Int8(truncatingIfNeeded: record.floorRoom),
                    objectRoom: Int8(truncatingIfNeeded: record.room),
                    floorNormalX: floor?.floorNormalX ?? 0,
                    floorNormalY: floor?.floorNormalY ?? 1,
                    floorNormalZ: floor?.floorNormalZ ?? 0,
                    moveFlags: floor?.moveFlags ?? record.moveFlags,
                    collisionFlags: floor?.collisionFlags ?? 0,
                    gravity: bully.size == .small
                        ? SM64BullyCollision.smallGravity
                        : SM64BullyCollision.bigGravity,
                    friction: bully.size == .small
                        ? SM64BullyCollision.smallFriction
                        : SM64BullyCollision.bigFriction,
                    buoyancy: SM64BullyCollision.buoyancy,
                    intendedFloorHeight: intendedFloor.height,
                    intendedFloorNormalY: intendedFloor.normalY ?? 0,
                    intendedFloorRoom: intendedRoom,
                    intendedFloorExists: intendedFloor.surfaceID != nil,
                    waterLevel: world.findWaterLevel(
                        x: candidatePosition.x,
                        z: candidatePosition.z
                    )
                )
            )
        } else {
            movement = nil
        }
        if let movement {
            bully.positionX = movement.position.x
            bully.positionY = movement.position.y
            bully.positionZ = movement.position.z
            bully.velocityY = movement.velocity.y
            bully.forwardVelocity = movement.forwardVelocity
            bully.collisionFlag = movement.collisionFlags
        }
        states[id] = bully
        synchronizeRecord(
            id: id,
            state: bully,
            pool: pool,
            previousAction: previousAction,
            collision: collision,
            movement: movement
        )
        var spawnedChildren: [SM64ObjectID] = []
        if spawnRewards, let coinPosition = result.coinPosition,
           let coin = try? pool.spawn(
               in: .unimportant,
               model: Self.coinModel,
               behaviorIdentity: Self.coinBehaviorIdentity,
               parent: id
           ) {
            _ = pool.mutate(coin) { record in
                record.objectFlags |=
                    SM64ObjectScheduler.objectFlagBuildTransform |
                    SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                record.position = coinPosition
                record.homePosition = coinPosition
                record.forwardVelocity = 10
            }
            spawnedChildren.append(coin)
        }
        if spawnRewards, let starPosition = result.starPosition,
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
        if spawnBridge, let bridgePosition = result.bridgePosition,
           let bridge = try? pool.spawn(
               in: .level,
               model: Self.bridgeModel,
               behaviorIdentity: Self.bridgeBehaviorIdentity,
               parent: id
           ) {
            _ = pool.mutate(bridge) { record in
                record.objectFlags |=
                    SM64ObjectScheduler.objectFlagBuildTransform |
                    SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                record.position = bridgePosition
                record.homePosition = bridgePosition
            }
            spawnedChildren.append(bridge)
        }
        if presentEffects {
            if result.effects.contains(.sound) || result.effects.contains(.coin) {
                effectRouter.enqueue(objectID: id, kind: .sound)
            }
            if result.effects.contains(.mist) {
                effectRouter.enqueue(objectID: id, kind: .particle, value: 1)
            }
            if result.effects.contains(.cameraShake) {
                effectRouter.enqueue(objectID: id, kind: .cameraShake, value: 1)
            }
            if result.effects.contains(.star) {
                effectRouter.enqueue(objectID: id, kind: .star, value: 1)
            }
            if result.effects.contains(.music) {
                effectRouter.enqueue(objectID: id, kind: .music, value: 1)
            }
        }
        if bully.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)
        effectLog.append(
            SM64BullyObjectEffectRecord(
                objectID: id,
                size: bully.size,
                effects: result.effects,
                action: bully.action,
                markedForDeletion: bully.markedForDeletion,
                coinPosition: result.coinPosition,
                starPosition: result.starPosition,
                bridgePosition: result.bridgePosition,
                spawnedChildren: spawnedChildren,
                presentedEffects: delivery.presented,
                collision: collision,
                movement: movement
            )
        )
    }

    private func defaultInput(for record: SM64ObjectRecord) -> SM64BullyTickInput {
        let dx = record.position.x - record.homePosition.x
        let dz = record.position.z - record.homePosition.z
        return SM64BullyTickInput(
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            distanceFromHome: (dx * dx + dz * dz).squareRoot(),
            homeRadiusExceeded: record.distanceToMario > 1_000,
            interacted: record.interactionStatus != 0,
            marioCollisionAngle: Int16(truncatingIfNeeded: record.moveAngles.yaw),
            floorCollisionFlags: record.moveFlags,
            marioY: record.position.y
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BullyState,
        pool: SM64ObjectPool,
        previousAction: SM64BullyAction,
        collision: SM64BullyCollisionResult? = nil,
        movement: SM64BullyMovementResult? = nil
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position.x = state.positionX
            record.position.y = state.positionY
            record.position.z = state.positionZ
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.faceYaw)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.behaviorParams2ndByte = Int32(state.size.rawValue)
            record.behaviorParams = Int32(state.subtype.rawValue)
            record.graphFlags = state.invisible ? record.graphFlags | 0x10 : record.graphFlags & ~0x10
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? 1 : 0
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.wallHitboxRadius = Self.defaultWallHitboxRadius
            record.gravity = state.size == .small
                ? SM64BullyCollision.smallGravity
                : SM64BullyCollision.bigGravity
            record.buoyancy = SM64BullyCollision.buoyancy
            if let collision {
                record.floorHeight = collision.floorHeight
                record.floorType = collision.floorType
                record.floorRoom = Int16(collision.floorRoom)
                record.moveFlags = collision.moveFlags
            }
            if let movement {
                record.position = movement.position
                record.velocity = movement.velocity
                record.forwardVelocity = movement.forwardVelocity
                record.moveFlags = movement.moveFlags
            } else {
                record.velocity.y = state.velocityY
            }
        }
    }
}
