import Foundation

struct SM64ExplosionObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let effects: SM64ExplosionEffect
    let bubbleCount: Int32
    let spawnedSmoke: Bool
    let timer: UInt32
    let scale: Float
    let opacity: Int32
    let animationState: Int32
    let presentedEffects: [SM64OwnerThreadEffectIntent]
    let markedForDeletion: Bool
}

struct SM64ExplosionSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64ExplosionObjectEffectRecord]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for `bhvExplosion`. Water bubbles and ground smoke are
/// retained as typed child requests until their shared behaviors migrate.
final class SM64ExplosionObjectBridge {
    static let defaultModel: UInt32 = SM64ExplosionKernel.model
    static let defaultBehaviorIdentity: UInt64 = SM64ExplosionKernel.behaviorIdentity

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64ExplosionState] = [:]
    private var inputs: [SM64ObjectID: SM64ExplosionTickInput] = [:]
    private(set) var effectLog: [SM64ExplosionObjectEffectRecord] = []
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

    func state(for id: SM64ObjectID) -> SM64ExplosionState? { states[id] }

    @discardableResult
    func setState(
        _ state: SM64ExplosionState,
        for id: SM64ObjectID,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard states[id] != nil, pool.record(for: id) != nil else { return false }
        states[id] = state
        synchronizeRecord(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func spawnExplosion(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64ExplosionObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64ExplosionObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .destructive,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned explosion could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64ExplosionState()
        states[id] = state
        inputs[id] = SM64ExplosionTickInput()
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.homePosition = position
        }
        synchronizeRecord(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64ExplosionTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64ExplosionTickInput] = [:]
    ) -> SM64ExplosionSchedulerTickResult {
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
        return SM64ExplosionSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var explosion = states[id], let record = pool.record(for: id) else { return }
        let result = SM64ExplosionKernel.tick(
            inputs[id] ?? SM64ExplosionTickInput(),
            state: &explosion
        )
        states[id] = explosion
        var presentedEffects: [SM64OwnerThreadEffectIntent] = []
        if result.effects.contains(.sound) {
            presentedEffects.append(effectRouter.enqueue(
                objectID: id,
                kind: .sound,
                value: SM64ExplosionKernel.soundValue
            ))
        }
        if result.effects.contains(.cameraShake) {
            presentedEffects.append(effectRouter.enqueue(
                objectID: id,
                kind: .cameraShake,
                value: SM64ExplosionKernel.environmentalShake
            ))
        }
        if explosion.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
        }
        if !effectRouter.pending.isEmpty {
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        synchronizeRecord(id: id, state: explosion, pool: pool)
        effectLog.append(
            SM64ExplosionObjectEffectRecord(
                objectID: id,
                effects: result.effects,
                bubbleCount: result.bubbleCount,
                spawnedSmoke: result.spawnedSmoke,
                timer: explosion.timer,
                scale: explosion.scale,
                opacity: explosion.opacity,
                animationState: explosion.animationState,
                presentedEffects: presentedEffects,
                markedForDeletion: explosion.markedForDeletion
            )
        )
        _ = record
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64ExplosionState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.opacity = state.opacity
            record.animationState = state.animationState
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.graphYOffset = 0
            record.hitboxRadius = SM64ExplosionKernel.hitboxRadius
            record.hitboxHeight = SM64ExplosionKernel.hitboxHeight
            record.hitboxDownOffset = SM64ExplosionKernel.hitboxDownOffset
            record.damageOrCoinValue = SM64ExplosionKernel.damageOrCoinValue
            record.interactionType = state.markedForDeletion
                ? 0
                : SM64ExplosionKernel.interactionType
            record.intangibleTimer = 0
        }
    }
}
