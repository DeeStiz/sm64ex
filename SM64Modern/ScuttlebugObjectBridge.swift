import Foundation

enum SM64ScuttlebugObjectKind: UInt8, Equatable, Sendable {
    case scuttlebug = 0
    case spawner = 1
}

struct SM64ScuttlebugObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64ScuttlebugObjectKind
    let effects: SM64ScuttlebugEffect
    let action: SM64ScuttlebugSubAction?
    let spawnedChild: SM64ObjectID?
    let markedForDeletion: Bool
}

struct SM64ScuttlebugSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64ScuttlebugObjectEffectRecord]
}

/// Owner-thread bridge for the Scuttlebug proximity spawner and its child.
/// Spawned bugs are inserted in the general-actor list and remain owned by
/// stable IDs; deletion/re-arm happens at the scheduler boundary.
final class SM64ScuttlebugObjectBridge {
    static let differentRoomFlag: UInt16 = 1 << 3
    static let defaultSpawnerBehaviorIdentity: UInt64 = 0x6268_765F_736273
    static let defaultBugBehaviorIdentity: UInt64 = 0x6268_765F_736275
    static let spawnerModel: UInt32 = 0
    static let bugModel: UInt32 = 0x65 // MODEL_SCUTTLEBUG

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var bugs: [SM64ObjectID: SM64ScuttlebugState] = [:]
    private var spawners: [SM64ObjectID: SM64ScuttlebugSpawnerState] = [:]
    private var bugInputs: [SM64ObjectID: SM64ScuttlebugTickInput] = [:]
    private var spawnerInputs: [SM64ObjectID: SM64ScuttlebugSpawnerTickInput] = [:]
    private(set) var effectLog: [SM64ScuttlebugObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(bugs.keys) + Array(spawners.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func bugState(for id: SM64ObjectID) -> SM64ScuttlebugState? { bugs[id] }
    func spawnerState(for id: SM64ObjectID) -> SM64ScuttlebugSpawnerState? { spawners[id] }

    @discardableResult
    func spawnSpawner(
        in engineState: SM64SwiftEngineState,
        model: UInt32 = SM64ScuttlebugObjectBridge.spawnerModel,
        behaviorIdentity: UInt64 = SM64ScuttlebugObjectBridge.defaultSpawnerBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .spawner, model: model, behaviorIdentity: behaviorIdentity)
        guard attachSpawner(id, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Scuttlebug spawner could not attach")
        }
        return id
    }

    @discardableResult
    func attachSpawner(_ id: SM64ObjectID, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64ScuttlebugSpawnerState()
        spawners[id] = state
        spawnerInputs[id] = SM64ScuttlebugSpawnerTickInput()
        synchronizeSpawner(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func spawnBug(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        forwardVelocity: Float = 30,
        velocityY: Float = 80,
        parent: SM64ObjectID? = nil,
        model: UInt32 = SM64ScuttlebugObjectBridge.bugModel,
        behaviorIdentity: UInt64 = SM64ScuttlebugObjectBridge.defaultBugBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard attachBug(
            id,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Scuttlebug could not attach")
        }
        return id
    }

    @discardableResult
    func attachBug(
        _ id: SM64ObjectID,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        forwardVelocity: Float = 0,
        velocityY: Float = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        var state = SM64ScuttlebugState(homeX: homeX, homeY: homeY, homeZ: homeZ, moveYaw: moveYaw)
        state.forwardVelocity = forwardVelocity
        state.velocityY = velocityY
        bugs[id] = state
        bugInputs[id] = SM64ScuttlebugTickInput()
        synchronizeBug(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func setBugInput(_ input: SM64ScuttlebugTickInput, for id: SM64ObjectID) -> Bool {
        guard bugs[id] != nil else { return false }
        bugInputs[id] = input
        return true
    }

    @discardableResult
    func setSpawnerInput(_ input: SM64ScuttlebugSpawnerTickInput, for id: SM64ObjectID) -> Bool {
        guard spawners[id] != nil else { return false }
        spawnerInputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        bugInputs frameBugInputs: [SM64ObjectID: SM64ScuttlebugTickInput] = [:],
        spawnerInputs frameSpawnerInputs: [SM64ObjectID: SM64ScuttlebugSpawnerTickInput] = [:]
    ) -> SM64ScuttlebugSchedulerTickResult {
        bugInputs = frameBugInputs
        spawnerInputs = frameSpawnerInputs
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            bugs.removeValue(forKey: id)
            spawners.removeValue(forKey: id)
            bugInputs.removeValue(forKey: id)
            spawnerInputs.removeValue(forKey: id)
        }
        for id in registeredIDs where engineState.objects.record(for: id) == nil {
            bugs.removeValue(forKey: id)
            spawners.removeValue(forKey: id)
            bugInputs.removeValue(forKey: id)
            spawnerInputs.removeValue(forKey: id)
        }
        return SM64ScuttlebugSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if var spawner = spawners[id], pool.record(for: id) != nil {
            let input = spawnerInputs[id] ?? SM64ScuttlebugSpawnerTickInput()
            let result = SM64ScuttlebugKernel.tickSpawner(input, state: &spawner)
            var child: SM64ObjectID?
            if result.effects.contains(.spawnScuttlebug),
               let spawned = try? pool.spawn(
                   in: .generalActor,
                   model: Self.bugModel,
                   behaviorIdentity: Self.defaultBugBehaviorIdentity,
                   parent: id
               ) {
                let bug = SM64ScuttlebugState()
                bugs[spawned] = bug
                bugInputs[spawned] = SM64ScuttlebugTickInput()
                synchronizeBug(id: spawned, state: bug, pool: pool)
                child = spawned
            }
            spawners[id] = spawner
            synchronizeSpawner(id: id, state: spawner, pool: pool)
            effectLog.append(
                SM64ScuttlebugObjectEffectRecord(
                    objectID: id,
                    kind: .spawner,
                    effects: result.effects,
                    action: nil,
                    spawnedChild: child,
                    markedForDeletion: spawner.markedForDeletion
                )
            )
            return
        }

        guard var bug = bugs[id], let record = pool.record(for: id) else { return }
        let input = bugInputs[id] ?? defaultBugInput(for: record)
        let result = SM64ScuttlebugKernel.tick(input, state: &bug)
        bugs[id] = bug
        synchronizeBug(id: id, state: bug, pool: pool)
        if bug.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        effectLog.append(
            SM64ScuttlebugObjectEffectRecord(
                objectID: id,
                kind: .scuttlebug,
                effects: result.effects,
                action: bug.subAction,
                spawnedChild: nil,
                markedForDeletion: bug.markedForDeletion
            )
        )
    }

    private func defaultBugInput(for record: SM64ObjectRecord) -> SM64ScuttlebugTickInput {
        SM64ScuttlebugTickInput(
            moveFlags: record.moveFlags,
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            animationNearEnd: record.animationState != 0,
            animationAtEnd: record.animationState < 0,
            attacked: record.interactionStatus != 0
        )
    }

    private func synchronizeSpawner(id: SM64ObjectID, state: SM64ScuttlebugSpawnerState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.action = Int32(state.action)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.interactionType = 0
        }
    }

    private func synchronizeBug(id: SM64ObjectID, state: SM64ScuttlebugState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.moveYaw)
            record.action = Int32(state.subAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.moveFlags = state.moveFlags
            record.animationState = Int32(truncatingIfNeeded: state.animationState)
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.numLootCoins = Int32(state.hitbox.numLootCoins)
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
        }
    }
}
