import Foundation

enum SM64EyerokObjectKind: UInt8, Equatable, Sendable {
    case boss = 0
    case hand = 1
}

struct SM64EyerokObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let parentID: SM64ObjectID?
    let kind: SM64EyerokObjectKind
    let side: Int8
    let bossAction: SM64EyerokBossAction?
    let handAction: SM64EyerokHandAction?
    let bossEffects: SM64EyerokBossEffect
    let handEffects: SM64EyerokHandEffect
    let starPosition: SM64ObjectVector3?
    let collision: SM64EyerokHandCollisionResult?
    let movement: SM64EyerokHandMovementResult?
    let spawnedChildren: [SM64ObjectID]
    let presentedEffects: [SM64OwnerThreadEffectIntent]
}

struct SM64EyerokSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64EyerokObjectEffectRecord]
}

/// Owner-thread bridge for the Eyerok boss and its two generation-safe hands.
/// The boss/hand kernels remain value-only; this seam owns parent identity,
/// child creation, object-record synchronization, and typed presentation
/// delivery. Surface collision and standard movement are intentionally a
/// later opt-in input, matching the other migrated actor bridges.
final class SM64EyerokObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_5F65_7972
    static let handBehaviorIdentity: UInt64 = 0x6268_5F68_6E64
    static let bossModel: UInt32 = 0
    static let starModel: UInt32 = 0x7A // MODEL_STAR
    static let starBehaviorIdentity: UInt64 = 0x6268_765F_73746E
    static let handHitboxInteractType: UInt32 = 1 << 15 // INTERACT_BOUNCE_TOP
    static let defaultWallHitboxRadius: Float = SM64EyerokHandCollision.wallHitboxRadius
    static let handHitboxRadius: Float = 150
    static let handHitboxHeight: Float = 100
    static let handHurtboxRadius: Float = 1
    static let handHurtboxHeight: Float = 1

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var bossStates: [SM64ObjectID: SM64EyerokBossState] = [:]
    private var bossInputs: [SM64ObjectID: SM64EyerokBossInput] = [:]
    private var handStates: [SM64ObjectID: SM64EyerokHandState] = [:]
    private var handInputs: [SM64ObjectID: SM64EyerokHandInput] = [:]
    private var handParents: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64EyerokObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredBossIDs: [SM64ObjectID] { sortedIDs(bossStates.keys) }
    var registeredHandIDs: [SM64ObjectID] { sortedIDs(handStates.keys) }

    func bossState(for id: SM64ObjectID) -> SM64EyerokBossState? { bossStates[id] }
    func handState(for id: SM64ObjectID) -> SM64EyerokHandState? { handStates[id] }
    func parentID(for handID: SM64ObjectID) -> SM64ObjectID? { handParents[handID] }

    @discardableResult
    func spawnBoss(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        action: SM64EyerokBossAction = .sleep,
        model: UInt32 = SM64EyerokObjectBridge.bossModel,
        behaviorIdentity: UInt64 = SM64EyerokObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attachBoss(
            id,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            action: action,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Eyerok boss could not attach")
        }
        return id
    }

    @discardableResult
    func attachBoss(
        _ id: SM64ObjectID,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        action: SM64EyerokBossAction = .sleep,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        var state = SM64EyerokBossState(homeX: homeX, homeY: homeY, homeZ: homeZ)
        state.action = action
        bossStates[id] = state
        bossInputs[id] = SM64EyerokBossInput()
        synchronizeBossRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setBossState(
        _ state: SM64EyerokBossState,
        for id: SM64ObjectID,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard bossStates[id] != nil, pool.record(for: id) != nil else { return false }
        bossStates[id] = state
        synchronizeBossRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setBossInput(_ input: SM64EyerokBossInput, for id: SM64ObjectID) -> Bool {
        guard bossStates[id] != nil else { return false }
        bossInputs[id] = input
        return true
    }

    @discardableResult
    func setHandState(
        _ state: SM64EyerokHandState,
        for id: SM64ObjectID,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard handStates[id] != nil, pool.record(for: id) != nil else { return false }
        handStates[id] = state
        synchronizeHandRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setHandInput(_ input: SM64EyerokHandInput, for id: SM64ObjectID) -> Bool {
        guard handStates[id] != nil else { return false }
        handInputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        bossInputs frameBossInputs: [SM64ObjectID: SM64EyerokBossInput] = [:],
        handInputs frameHandInputs: [SM64ObjectID: SM64EyerokHandInput] = [:],
        collisionWorld: SM64SurfaceCollisionWorld? = nil,
        advanceMovement: Bool = false,
        presentEffects: Bool = false,
        spawnRewardStar: Bool = false
    ) -> SM64EyerokSchedulerTickResult {
        bossInputs = frameBossInputs
        handInputs = frameHandInputs
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            guard let self else { return }
            if self.bossStates[id] != nil {
                self.updateBoss(
                    id: id,
                    pool: pool,
                    presentEffects: presentEffects,
                    spawnRewardStar: spawnRewardStar
                )
            } else if self.handStates[id] != nil {
                self.updateHand(
                    id: id,
                    pool: pool,
                    collisionWorld: collisionWorld,
                    advanceMovement: advanceMovement,
                    presentEffects: presentEffects
                )
            }
        }

        for id in schedulerResult.unloaded {
            bossStates.removeValue(forKey: id)
            bossInputs.removeValue(forKey: id)
            handStates.removeValue(forKey: id)
            handInputs.removeValue(forKey: id)
            handParents.removeValue(forKey: id)
        }
        for id in Array(bossStates.keys) where engineState.objects.record(for: id) == nil {
            bossStates.removeValue(forKey: id)
            bossInputs.removeValue(forKey: id)
        }
        for id in Array(handStates.keys) where engineState.objects.record(for: id) == nil {
            handStates.removeValue(forKey: id)
            handInputs.removeValue(forKey: id)
            handParents.removeValue(forKey: id)
        }
        for id in Array(handStates.keys) where handParents[id].flatMap({ bossStates[$0] }) == nil {
            handStates.removeValue(forKey: id)
            handInputs.removeValue(forKey: id)
            handParents.removeValue(forKey: id)
        }

        return SM64EyerokSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func updateBoss(
        id: SM64ObjectID,
        pool: SM64ObjectPool,
        presentEffects: Bool,
        spawnRewardStar: Bool
    ) {
        guard var boss = bossStates[id], pool.record(for: id) != nil else { return }
        let previousAction = boss.action
        let input = bossInputs[id] ?? defaultBossInput(for: id, pool: pool)
        let result = SM64EyerokBossKernel.tick(input, state: &boss)
        bossStates[id] = boss
        synchronizeBossRecord(id: id, state: boss, pool: pool, previousAction: previousAction)

        var spawnedChildren: [SM64ObjectID] = []
        if result.effects.contains(.spawnHands), handIDs(for: id).isEmpty {
            for spawn in result.spawnedHands {
                guard let handID = try? pool.spawn(
                    in: .generalActor,
                    model: spawn.model,
                    behaviorIdentity: Self.handBehaviorIdentity,
                    parent: id
                ) else { break }
                var hand = SM64EyerokHandState(
                    side: spawn.side,
                    homeX: spawn.position.x,
                    homeY: spawn.position.y,
                    homeZ: spawn.position.z,
                    positionX: spawn.position.x,
                    positionY: spawn.position.y,
                    positionZ: spawn.position.z,
                    faceYaw: spawn.faceYaw
                )
                hand.action = .sleep
                handStates[handID] = hand
                handInputs[handID] = SM64EyerokHandInput()
                handParents[handID] = id
                synchronizeHandRecord(id: handID, state: hand, pool: pool, previousAction: hand.action)
                spawnedChildren.append(handID)
            }
        }
        if spawnRewardStar, let starPosition = result.starPosition,
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

        if presentEffects { enqueueBossEffects(id: id, result: result) }
        if result.effects.contains(.markForDeletion) {
            for handID in handIDs(for: id) {
                effectRouter.enqueue(objectID: handID, kind: .markForDeletion)
            }
        }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)
        effectLog.append(
            SM64EyerokObjectEffectRecord(
                objectID: id,
                parentID: nil,
                kind: .boss,
                side: 0,
                bossAction: boss.action,
                handAction: nil,
                bossEffects: result.effects,
                handEffects: [],
                starPosition: result.starPosition,
                collision: nil,
                movement: nil,
                spawnedChildren: spawnedChildren,
                presentedEffects: delivery.presented
            )
        )
    }

    private func updateHand(
        id: SM64ObjectID,
        pool: SM64ObjectPool,
        collisionWorld: SM64SurfaceCollisionWorld?,
        advanceMovement: Bool,
        presentEffects: Bool
    ) {
        guard var hand = handStates[id], let parentID = handParents[id],
              var boss = bossStates[parentID], let record = pool.record(for: id) else { return }
        let previousAction = hand.action
        let physicsEnabled = advanceMovement && collisionWorld != nil && hand.action != .sleep
        let collision = physicsEnabled
            ? collisionWorld.flatMap { world in
                SM64EyerokHandCollision.resolve(
                    SM64EyerokHandCollisionInput(
                        position: record.position,
                        moveYaw: hand.moveYaw,
                        forwardVelocity: hand.forwardVelocity,
                        wallHitboxRadius: record.wallHitboxRadius,
                        previousMoveFlags: record.moveFlags,
                        world: world
                    )
                )
            }
            : nil
        var input = handInputs[id] ?? defaultHandInput(for: id, pool: pool)
        if let collision {
            input.onGround = collision.moveFlags & SM64EyerokHandCollision.onGround != 0
            input.hitEdge = input.hitEdge || collision.moveFlags & SM64EyerokHandCollision.hitEdge != 0
            input.hitWall = input.hitWall || collision.hitWall
        }
        input.parentAction = boss.action
        input.parentNumHands = boss.numHands
        input.parentActiveHand = boss.activeHand
        input.parentBusyHand = boss.busyHand
        input.parentHandSelectionPhase = boss.handSelectionPhase
        input.parentHandSelectionDirection = boss.handSelectionDirection
        input.parentHandBlend = boss.handBlend
        input.parentHandTargetZ = boss.handTargetZ
        input.parentPositionX = boss.positionX
        input.parentPositionZ = boss.positionZ

        let result = SM64EyerokHandKernel.tick(input, state: &hand)
        let movement: SM64EyerokHandMovementResult?
        if physicsEnabled, let world = collisionWorld {
            let basePosition = collision?.position ?? record.position
            let actionPosition = SM64ObjectVector3(
                x: basePosition.x,
                y: hand.positionY,
                z: basePosition.z
            )
            let candidatePosition = SM64ObjectVector3(
                x: actionPosition.x
                    + SM64CanonicalTrig.sins(hand.moveYaw) * hand.forwardVelocity,
                y: actionPosition.y,
                z: actionPosition.z
                    + SM64CanonicalTrig.coss(hand.moveYaw) * hand.forwardVelocity
            )
            let floor = collision ?? SM64EyerokHandCollision.resolve(
                SM64EyerokHandCollisionInput(
                    position: actionPosition,
                    moveYaw: hand.moveYaw,
                    forwardVelocity: hand.forwardVelocity,
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
            movement = SM64EyerokHandCollision.move(
                SM64EyerokHandMovementInput(
                    startPosition: actionPosition,
                    candidatePosition: candidatePosition,
                    velocityY: hand.velocityY,
                    forwardVelocity: hand.forwardVelocity,
                    moveYaw: hand.moveYaw,
                    floorHeight: floor?.floorHeight ?? record.floorHeight,
                    floorRoom: floor?.floorRoom ?? Int8(truncatingIfNeeded: record.floorRoom),
                    objectRoom: Int8(truncatingIfNeeded: record.room),
                    moveFlags: floor?.moveFlags ?? record.moveFlags,
                    gravity: hand.gravity,
                    bounciness: SM64EyerokHandCollision.bounciness,
                    dragStrength: SM64EyerokHandCollision.dragStrength,
                    buoyancy: SM64EyerokHandCollision.buoyancy,
                    nativeStepScale: 1,
                    intendedFloorHeight: intendedFloor.height,
                    intendedFloorNormalY: intendedFloor.normalY ?? 0,
                    intendedFloorRoom: intendedRoom,
                    intendedFloorExists: intendedFloor.surfaceID != nil,
                    waterLevel: world.findWaterLevel(
                        x: candidatePosition.x,
                        z: candidatePosition.z
                    ),
                    activeFarAway: false
                )
            )
        } else {
            movement = nil
        }
        if let movement {
            hand.positionX = movement.position.x
            hand.positionY = movement.position.y
            hand.positionZ = movement.position.z
            hand.velocityY = movement.velocity.y
            hand.forwardVelocity = movement.forwardVelocity
            hand.moveFlags = movement.moveFlags
        }
        boss.numHands = result.parentNumHands
        boss.activeHand = result.parentActiveHand
        boss.busyHand = result.parentBusyHand
        bossStates[parentID] = boss
        handStates[id] = hand
        synchronizeBossRecord(id: parentID, state: boss, pool: pool, previousAction: boss.action)
        synchronizeHandRecord(
            id: id,
            state: hand,
            pool: pool,
            previousAction: previousAction,
            collision: collision,
            movement: movement
        )

        if presentEffects { enqueueHandEffects(id: id, result: result) }
        let delivery = effectRouter.deliver(to: pool)
        deliveryLog.append(delivery)
        effectLog.append(
            SM64EyerokObjectEffectRecord(
                objectID: id,
                parentID: parentID,
                kind: .hand,
                side: hand.side,
                bossAction: nil,
                handAction: hand.action,
                bossEffects: [],
                handEffects: result.effects,
                starPosition: nil,
                collision: collision,
                movement: movement,
                spawnedChildren: [],
                presentedEffects: delivery.presented
            )
        )
    }

    private func enqueueBossEffects(id: SM64ObjectID, result: SM64EyerokBossTickResult) {
        if result.effects.contains(.explodeSound) { effectRouter.enqueue(objectID: id, kind: .sound) }
        if result.effects.contains(.bossMusic) { effectRouter.enqueue(objectID: id, kind: .music, value: 1) }
        if result.effects.contains(.dialog) {
            effectRouter.enqueue(objectID: id, kind: .dialog, value: result.dialogID)
        }
        if result.effects.contains(.star) { effectRouter.enqueue(objectID: id, kind: .star, value: 1) }
        if result.effects.contains(.stopBossMusic) { effectRouter.enqueue(objectID: id, kind: .music, value: 0) }
        if result.effects.contains(.markForDeletion) {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
        }
    }

    private func enqueueHandEffects(id: SM64ObjectID, result: SM64EyerokHandTickResult) {
        if result.effects.contains(.shortSound) || result.effects.contains(.showEyeSound)
            || result.effects.contains(.poundSound) || result.effects.contains(.soundSpawner) {
            effectRouter.enqueue(objectID: id, kind: .sound)
        }
        if result.effects.contains(.cameraShake) || result.effects.contains(.deathPound) {
            effectRouter.enqueue(objectID: id, kind: .cameraShake, value: 1)
        }
        if result.effects.contains(.mist) { effectRouter.enqueue(objectID: id, kind: .particle, value: 1) }
        if result.effects.contains(.explodeCoins) {
            effectRouter.enqueue(objectID: id, kind: .particle, value: 2)
        }
    }

    private func defaultBossInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64EyerokBossInput {
        guard let record = pool.record(for: id) else { return SM64EyerokBossInput() }
        return SM64EyerokBossInput(
            distanceToMario: record.distanceToMario,
            marioRelativeZ: record.distanceToMario,
            marioPositionZ: record.position.z,
            marioReadyToSpeak: record.dialogState != 0,
            dialogComplete: record.dialogResponse != 0,
            randomLowBit: record.timer & 1 != 0
        )
    }

    private func defaultHandInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64EyerokHandInput {
        guard let record = pool.record(for: id) else { return SM64EyerokHandInput() }
        return SM64EyerokHandInput(
            marioRelativeZ: record.distanceToMario,
            marioPositionX: record.position.x,
            marioPositionY: record.position.y,
            marioPositionZ: record.position.z,
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            angleToHome: Int16(truncatingIfNeeded: record.angleToHome),
            randomLowBit: record.timer & 1 != 0,
            randomLinearOffset: 20 + Int32(record.timer % 31),
            animationEnded: record.animationState != 0,
            animationFrameOne: record.animationState == 1,
            animationNearEnd: record.animationState != 0,
            receivedAttack: record.interactionStatus & (1 << 15) != 0,
            onGround: record.moveFlags & (1 << 1) != 0,
            hitEdge: record.moveFlags & (1 << 10) != 0,
            hitWall: record.moveFlags & (1 << 9) != 0
        )
    }

    private func synchronizeBossRecord(
        id: SM64ObjectID,
        state: SM64EyerokBossState,
        pool: SM64ObjectPool,
        previousAction: SM64EyerokBossAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.faceAngles.yaw = Int32(state.faceYaw)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.subAction = state.subAction
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.health = state.numHands
            record.behaviorParams = state.handSelectionCounter
            record.behaviorParams2ndByte = state.numHands
        }
    }

    private func synchronizeHandRecord(
        id: SM64ObjectID,
        state: SM64EyerokHandState,
        pool: SM64ObjectPool,
        previousAction: SM64EyerokHandAction,
        collision: SM64EyerokHandCollisionResult? = nil,
        movement: SM64EyerokHandMovementResult? = nil
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.scale = SM64ObjectVector3(x: state.renderScale, y: state.renderScale, z: state.renderScale)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.gravity = state.gravity
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.faceYaw)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.behaviorParams2ndByte = Int32(state.side)
            record.animationState = Int32(state.animState)
            record.health = Int32(state.health)
            record.intangibleTimer = state.collisionMode == 3 ? -1 : 1
            record.interactionType = state.collisionMode == 3 ? Self.handHitboxInteractType : 0
            record.hitboxRadius = Self.handHitboxRadius
            record.hitboxHeight = Self.handHitboxHeight
            record.hurtboxRadius = Self.handHurtboxRadius
            record.hurtboxHeight = Self.handHurtboxHeight
            record.floorType = Int16(truncatingIfNeeded: state.collisionMode)
            record.wallHitboxRadius = Self.defaultWallHitboxRadius
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

    private func handIDs(for parentID: SM64ObjectID) -> [SM64ObjectID] {
        sortedIDs(handParents.compactMap { $0.value == parentID ? $0.key : nil })
    }

    private func sortedIDs<S: Sequence>(_ ids: S) -> [SM64ObjectID] where S.Element == SM64ObjectID {
        ids.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }
}
