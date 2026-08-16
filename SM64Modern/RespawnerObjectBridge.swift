import Foundation

struct SM64RespawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let effects: SM64RespawnerEffect
    let spawnedObject: SM64ObjectID?
    let timer: UInt32
    let markedForDeletion: Bool
}

struct SM64RespawnerSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64RespawnerObjectEffectRecord]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for `bhvRespawner`. Allocation, behavior-parameter
/// transfer, and deactivation remain pool operations; the kernel never sees a
/// C object pointer or a mutable object-list node.
final class SM64RespawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_727370
    static let defaultModel: UInt32 = 0

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64RespawnerState] = [:]
    private var inputs: [SM64ObjectID: SM64RespawnerTickInput] = [:]
    private(set) var effectLog: [SM64RespawnerObjectEffectRecord] = []
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

    func state(for id: SM64ObjectID) -> SM64RespawnerState? { states[id] }

    @discardableResult
    func spawnRespawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        modelToRespawn: UInt32,
        behaviorToRespawn: UInt64,
        minSpawnDistance: Float,
        behaviorParams: Int32 = 0,
        model: UInt32 = SM64RespawnerObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64RespawnerObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            model: model,
            behaviorIdentity: behaviorIdentity,
            drawingDistance: 3_000
        )
        guard attach(
            id,
            position: position,
            modelToRespawn: modelToRespawn,
            behaviorToRespawn: behaviorToRespawn,
            minSpawnDistance: minSpawnDistance,
            behaviorParams: behaviorParams,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned respawner could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        modelToRespawn: UInt32,
        behaviorToRespawn: UInt64,
        minSpawnDistance: Float,
        behaviorParams: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil,
              minSpawnDistance.isFinite,
              minSpawnDistance >= 0 else { return false }
        states[id] = SM64RespawnerState(
            modelToRespawn: modelToRespawn,
            behaviorToRespawn: behaviorToRespawn,
            minSpawnDistance: minSpawnDistance,
            behaviorParams: behaviorParams
        )
        inputs[id] = SM64RespawnerTickInput()
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagBuildTransform
                | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.respawnInfoType = 1
            record.respawnInfoIdentity = behaviorToRespawn
        }
        return true
    }

    @discardableResult
    func setInput(_ input: SM64RespawnerTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64RespawnerTickInput] = [:]
    ) -> SM64RespawnerSchedulerTickResult {
        inputs = frameInputs
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        return SM64RespawnerSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var respawner = states[id], let record = pool.record(for: id) else { return }
        let result = SM64RespawnerKernel.tick(
            inputs[id] ?? SM64RespawnerTickInput(),
            state: &respawner
        )
        states[id] = respawner
        var spawnedObject: SM64ObjectID?
        if result.effects.contains(.spawnObject),
           let child = try? pool.spawn(
               in: .default,
               model: respawner.modelToRespawn,
               behaviorIdentity: respawner.behaviorToRespawn
           ) {
            _ = pool.mutate(child) { spawned in
                spawned.position = record.position
                spawned.homePosition = record.homePosition
                spawned.behaviorParams = respawner.behaviorParams
                spawned.objectFlags |= SM64ObjectScheduler.objectFlagBuildTransform
                    | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            }
            spawnedObject = child
        }
        if result.effects.contains(.markForDeletion) {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        effectLog.append(
            SM64RespawnerObjectEffectRecord(
                objectID: id,
                effects: result.effects,
                spawnedObject: spawnedObject,
                timer: respawner.timer,
                markedForDeletion: respawner.markedForDeletion
            )
        )
    }
}
