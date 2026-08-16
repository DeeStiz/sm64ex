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
    let spawnedChildren: [SM64ObjectID]
}

struct SM64ExplosionSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64ExplosionObjectEffectRecord]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for `bhvExplosion` and its water-bubble/ground-smoke
/// children. Random placement/rates remain explicit value inputs.
final class SM64ExplosionObjectBridge {
    static let defaultModel: UInt32 = SM64ExplosionKernel.model
    static let defaultBehaviorIdentity: UInt64 = SM64ExplosionKernel.behaviorIdentity
    static let bubbleModel: UInt32 = 0xA4 // MODEL_WHITE_PARTICLE_SMALL
    static let bubbleBehaviorIdentity: UInt64 = 0x6268_765F_627562
    static let groundSmokeModel: UInt32 = 0x96 // MODEL_SMOKE
    static let groundSmokeBehaviorIdentity: UInt64 = 0x6268_765F_64656D

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64ExplosionState] = [:]
    private var inputs: [SM64ObjectID: SM64ExplosionTickInput] = [:]
    private var bubbles: [SM64ObjectID: SM64ExplosionBubbleState] = [:]
    private var bubbleInputs: [SM64ObjectID: SM64ExplosionBubbleTickInput] = [:]
    private var groundSmokes: [SM64ObjectID: SM64ExplosionGroundSmokeState] = [:]
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
        (Array(states.keys) + Array(bubbles.keys) + Array(groundSmokes.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64ExplosionState? { states[id] }
    func bubbleState(for id: SM64ObjectID) -> SM64ExplosionBubbleState? { bubbles[id] }
    func groundSmokeState(for id: SM64ObjectID) -> SM64ExplosionGroundSmokeState? {
        groundSmokes[id]
    }

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
            bubbles.removeValue(forKey: id)
            bubbleInputs.removeValue(forKey: id)
            groundSmokes.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        for id in Array(bubbles.keys) where engineState.objects.record(for: id) == nil {
            bubbles.removeValue(forKey: id)
            bubbleInputs.removeValue(forKey: id)
        }
        for id in Array(groundSmokes.keys) where engineState.objects.record(for: id) == nil {
            groundSmokes.removeValue(forKey: id)
        }
        return SM64ExplosionSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if states[id] != nil {
            updateExplosion(id: id, pool: pool)
        } else if bubbles[id] != nil {
            updateBubble(id: id, pool: pool)
        } else if groundSmokes[id] != nil {
            updateGroundSmoke(id: id, pool: pool)
        }
    }

    private func updateExplosion(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var explosion = states[id], let record = pool.record(for: id) else { return }
        let input = inputs[id] ?? SM64ExplosionTickInput()
        let result = SM64ExplosionKernel.tick(
            input,
            state: &explosion
        )
        states[id] = explosion
        var spawnedChildren: [SM64ObjectID] = []
        if result.effects.contains(.spawnBubbles) {
            let seeds = Self.bubbleSeeds(input: input, count: Int(result.bubbleCount))
            for seed in seeds {
                guard let child = try? pool.spawn(
                    in: .default,
                    model: Self.bubbleModel,
                    behaviorIdentity: Self.bubbleBehaviorIdentity,
                    parent: id
                ) else { continue }
                bubbles[child] = SM64ExplosionChildrenKernel.makeBubble(
                    parentPosition: record.position,
                    input: seed
                )
                bubbleInputs[child] = SM64ExplosionBubbleTickInput(
                    waterLevel: input.bubbleWaterLevel
                )
                synchronizeBubble(id: child, state: bubbles[child]!, pool: pool)
                spawnedChildren.append(child)
            }
        } else if result.effects.contains(.spawnSmoke),
                  let child = try? pool.spawn(
                      in: .unimportant,
                      model: Self.groundSmokeModel,
                      behaviorIdentity: Self.groundSmokeBehaviorIdentity,
                      parent: id
                  ) {
            groundSmokes[child] = SM64ExplosionChildrenKernel.makeGroundSmoke(
                parentPosition: record.position
            )
            synchronizeGroundSmoke(id: child, state: groundSmokes[child]!, pool: pool)
            spawnedChildren.append(child)
        }
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
                markedForDeletion: explosion.markedForDeletion,
                spawnedChildren: spawnedChildren
            )
        )
        _ = record
    }

    private func updateBubble(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var bubble = bubbles[id], pool.record(for: id) != nil else { return }
        let result = SM64ExplosionChildrenKernel.tickBubble(
            bubbleInputs[id] ?? SM64ExplosionBubbleTickInput(),
            state: &bubble
        )
        bubbles[id] = bubble
        if bubble.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        synchronizeBubble(id: id, state: bubble, pool: pool)
        effectLog.append(
            SM64ExplosionObjectEffectRecord(
                objectID: id,
                effects: [],
                bubbleCount: 0,
                spawnedSmoke: false,
                timer: bubble.timer,
                scale: bubble.scale.x,
                opacity: 255,
                animationState: bubble.animationState,
                presentedEffects: [],
                markedForDeletion: bubble.markedForDeletion,
                spawnedChildren: []
            )
        )
    }

    private func updateGroundSmoke(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var smoke = groundSmokes[id], pool.record(for: id) != nil else { return }
        let result = SM64ExplosionChildrenKernel.tickGroundSmoke(state: &smoke)
        groundSmokes[id] = smoke
        if smoke.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        synchronizeGroundSmoke(id: id, state: smoke, pool: pool)
        effectLog.append(
            SM64ExplosionObjectEffectRecord(
                objectID: id,
                effects: [],
                bubbleCount: 0,
                spawnedSmoke: false,
                timer: smoke.timer,
                scale: smoke.scale,
                opacity: 255,
                animationState: smoke.animationState,
                presentedEffects: [],
                markedForDeletion: smoke.markedForDeletion,
                spawnedChildren: []
            )
        )
        _ = result
    }

    private static func bubbleSeeds(
        input: SM64ExplosionTickInput,
        count: Int
    ) -> [SM64ExplosionBubbleSpawnInput] {
        guard count > 0 else { return [] }
        if input.bubbleSpawns.count >= count {
            return Array(input.bubbleSpawns.prefix(count))
        }
        var seeds = input.bubbleSpawns
        while seeds.count < count {
            let index = seeds.count
            let column = index % 8
            let row = index / 8
            seeds.append(
                SM64ExplosionBubbleSpawnInput(
                    positionOffset: SM64ObjectVector3(
                        x: Float(column - 4) * 8,
                        y: Float(row - 2) * 6,
                        z: Float((index % 5) - 2) * 8
                    ),
                    expansionRateX: 0x800 + Int32(index * 17),
                    expansionRateY: 0x800 + Int32(index * 23),
                    initialTimer: UInt32(index % 10),
                    velocityY: 4 + Float(index % 4)
                )
            )
        }
        return seeds
    }

    private func synchronizeBubble(
        id: SM64ObjectID,
        state: SM64ExplosionBubbleState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = state.position
            record.scale = state.scale
            record.animationState = state.animationState
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.interactionType = 0
            record.intangibleTimer = 1
        }
    }

    private func synchronizeGroundSmoke(
        id: SM64ObjectID,
        state: SM64ExplosionGroundSmokeState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = state.position
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.animationState = state.animationState
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.interactionType = 0
            record.intangibleTimer = 1
        }
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
