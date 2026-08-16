import Foundation

struct SM64BowserBombObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64BowserBombKind
    let effects: SM64BowserBombEffect
    let spawnedChildren: [SM64ObjectID]
    let spawnedExplosionRequest: Bool
    let timer: UInt32
    let scale: Float
    let opacity: Int32
    let animationState: Int32
    let presentedEffects: [SM64OwnerThreadEffectIntent]
    let markedForDeletion: Bool
    let genericEffects: SM64ExplosionEffect?
    let genericBubbleCount: Int32
    let genericSpawnedSmoke: Bool
}

struct SM64BowserBombSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BowserBombObjectEffectRecord]
    let deliveries: [SM64OwnerThreadEffectDeliveryResult]
}

/// Owner-thread bridge for the Bowser bomb, flame explosion, smoke, and shared
/// generic explosion family. Generic Mario-hit routing is opt-in so callers
/// can qualify the new consumer without silently changing the historical
/// request-only route.
final class SM64BowserBombObjectBridge {
    static let bombModel: UInt32 = 0xB3 // MODEL_WATER_MINE
    static let flamesModel: UInt32 = 0x67 // MODEL_BOWSER_FLAMES
    static let smokeModel: UInt32 = 0x66 // MODEL_BOWSER_SMOKE
    static let bombBehaviorIdentity: UInt64 = 0x6268_765F_626F6D62
    static let explosionBehaviorIdentity: UInt64 = 0x6268_765F_626578
    static let smokeBehaviorIdentity: UInt64 = 0x6268_765F_626D73

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var bombs: [SM64ObjectID: SM64BowserBombState] = [:]
    private var bombInputs: [SM64ObjectID: SM64BowserBombTickInput] = [:]
    private var explosions: [SM64ObjectID: SM64BowserBombExplosionState] = [:]
    private var explosionInputs: [SM64ObjectID: SM64BowserBombExplosionTickInput] = [:]
    private var smokes: [SM64ObjectID: SM64BowserBombSmokeState] = [:]
    private var genericExplosions: [SM64ObjectID: SM64ExplosionState] = [:]
    private var genericExplosionInputs: [SM64ObjectID: SM64ExplosionTickInput] = [:]
    var routesGenericExplosionRequests: Bool
    private(set) var effectLog: [SM64BowserBombObjectEffectRecord] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter(),
        routesGenericExplosionRequests: Bool = false
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
        self.routesGenericExplosionRequests = routesGenericExplosionRequests
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(bombs.keys) + Array(explosions.keys) + Array(smokes.keys)
            + Array(genericExplosions.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func bombState(for id: SM64ObjectID) -> SM64BowserBombState? { bombs[id] }
    func explosionState(for id: SM64ObjectID) -> SM64BowserBombExplosionState? { explosions[id] }
    func smokeState(for id: SM64ObjectID) -> SM64BowserBombSmokeState? { smokes[id] }
    func genericExplosionState(for id: SM64ObjectID) -> SM64ExplosionState? {
        genericExplosions[id]
    }

    @discardableResult
    func setGenericExplosionState(
        _ state: SM64ExplosionState,
        for id: SM64ObjectID,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard genericExplosions[id] != nil, pool.record(for: id) != nil else { return false }
        genericExplosions[id] = state
        synchronizeGenericExplosion(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func spawnBomb(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64BowserBombObjectBridge.bombModel,
        behaviorIdentity: UInt64 = SM64BowserBombObjectBridge.bombBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attachBomb(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bowser bomb could not attach")
        }
        return id
    }

    @discardableResult
    func attachBomb(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BowserBombState()
        bombs[id] = state
        bombInputs[id] = SM64BowserBombTickInput()
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.homePosition = position
        }
        synchronizeBomb(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func setBombInput(_ input: SM64BowserBombTickInput, for id: SM64ObjectID) -> Bool {
        guard bombs[id] != nil else { return false }
        bombInputs[id] = input
        return true
    }

    @discardableResult
    func setExplosionInput(
        _ input: SM64BowserBombExplosionTickInput,
        for id: SM64ObjectID
    ) -> Bool {
        guard explosions[id] != nil else { return false }
        explosionInputs[id] = input
        return true
    }

    @discardableResult
    func setGenericExplosionInput(
        _ input: SM64ExplosionTickInput,
        for id: SM64ObjectID
    ) -> Bool {
        guard genericExplosions[id] != nil else { return false }
        genericExplosionInputs[id] = input
        return true
    }

    @discardableResult
    func spawnExplosion(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            model: Self.flamesModel,
            behaviorIdentity: Self.explosionBehaviorIdentity,
            parent: parent
        )
        guard attachExplosion(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bowser bomb explosion could not attach")
        }
        return id
    }

    @discardableResult
    func spawnGenericExplosion(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .destructive,
            model: SM64ExplosionKernel.model,
            behaviorIdentity: SM64ExplosionKernel.behaviorIdentity,
            parent: parent
        )
        guard attachGenericExplosion(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned generic explosion could not attach")
        }
        return id
    }

    @discardableResult
    func attachExplosion(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BowserBombExplosionState()
        explosions[id] = state
        explosionInputs[id] = SM64BowserBombExplosionTickInput()
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.homePosition = position
        }
        synchronizeExplosion(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func attachGenericExplosion(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64ExplosionState()
        genericExplosions[id] = state
        genericExplosionInputs[id] = SM64ExplosionTickInput()
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.homePosition = position
        }
        synchronizeGenericExplosion(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        bombInputs frameBombInputs: [SM64ObjectID: SM64BowserBombTickInput] = [:],
        explosionInputs frameExplosionInputs: [SM64ObjectID: SM64BowserBombExplosionTickInput] = [:],
        genericExplosionInputs frameGenericExplosionInputs: [SM64ObjectID: SM64ExplosionTickInput] = [:]
    ) -> SM64BowserBombSchedulerTickResult {
        bombInputs = frameBombInputs
        explosionInputs = frameExplosionInputs
        genericExplosionInputs = frameGenericExplosionInputs
        effectLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            bombs.removeValue(forKey: id)
            bombInputs.removeValue(forKey: id)
            explosions.removeValue(forKey: id)
            explosionInputs.removeValue(forKey: id)
            smokes.removeValue(forKey: id)
            genericExplosions.removeValue(forKey: id)
            genericExplosionInputs.removeValue(forKey: id)
        }
        for id in Array(bombs.keys) where engineState.objects.record(for: id) == nil {
            bombs.removeValue(forKey: id)
            bombInputs.removeValue(forKey: id)
        }
        for id in Array(explosions.keys) where engineState.objects.record(for: id) == nil {
            explosions.removeValue(forKey: id)
            explosionInputs.removeValue(forKey: id)
        }
        for id in Array(smokes.keys) where engineState.objects.record(for: id) == nil {
            smokes.removeValue(forKey: id)
        }
        for id in Array(genericExplosions.keys) where engineState.objects.record(for: id) == nil {
            genericExplosions.removeValue(forKey: id)
            genericExplosionInputs.removeValue(forKey: id)
        }
        return SM64BowserBombSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            deliveries: deliveryLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if bombs[id] != nil {
            updateBomb(id: id, pool: pool)
        } else if explosions[id] != nil {
            updateExplosion(id: id, pool: pool)
        } else if genericExplosions[id] != nil {
            updateGenericExplosion(id: id, pool: pool)
        } else if smokes[id] != nil {
            updateSmoke(id: id, pool: pool)
        }
    }

    private func updateBomb(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = bombs[id], let record = pool.record(for: id) else { return }
        let result = SM64BowserBombKernel.tickBomb(
            bombInputs[id] ?? SM64BowserBombTickInput(),
            state: &state
        )
        bombs[id] = state
        if result.effects.contains(.clearInteraction) {
            _ = pool.mutate(id) { object in
                object.interactionStatus &= ~SM64BowserBombKernel.interactedStatus
            }
        }
        var spawnedChildren: [SM64ObjectID] = []
        if result.effects.contains(.spawnExplosion), routesGenericExplosionRequests,
           let child = try? pool.spawn(
               in: .destructive,
               model: SM64ExplosionKernel.model,
               behaviorIdentity: SM64ExplosionKernel.behaviorIdentity,
               parent: id
           ) {
            genericExplosions[child] = SM64ExplosionState()
            genericExplosionInputs[child] = SM64ExplosionTickInput()
            synchronizeGenericExplosion(
                id: child,
                state: genericExplosions[child]!,
                pool: pool,
                position: record.position
            )
            spawnedChildren.append(child)
        }
        if result.effects.contains(.spawnFlames),
           let child = try? pool.spawn(
               in: .default,
               model: Self.flamesModel,
               behaviorIdentity: Self.explosionBehaviorIdentity,
               parent: id
           ) {
            explosions[child] = SM64BowserBombExplosionState()
            explosionInputs[child] = SM64BowserBombExplosionTickInput()
            synchronizeExplosion(
                id: child,
                state: explosions[child]!,
                pool: pool,
                position: record.position
            )
            spawnedChildren.append(child)
        }
        var presentedEffects: [SM64OwnerThreadEffectIntent] = []
        if result.effects.contains(.sound) {
            presentedEffects.append(effectRouter.enqueue(
                objectID: id,
                kind: .sound,
                value: SM64BowserBombKernel.explosionSound
            ))
        }
        if result.effects.contains(.cameraShake) {
            presentedEffects.append(effectRouter.enqueue(
                objectID: id,
                kind: .cameraShake,
                value: SM64BowserBombKernel.largeCameraShake
            ))
        }
        if state.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
        }
        if !effectRouter.pending.isEmpty {
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        synchronizeBomb(id: id, state: state, pool: pool)
        effectLog.append(
            SM64BowserBombObjectEffectRecord(
                objectID: id,
                kind: .bomb,
                effects: result.effects,
                spawnedChildren: spawnedChildren,
                spawnedExplosionRequest: result.effects.contains(.spawnExplosion),
                timer: state.timer,
                scale: 1,
                opacity: 255,
                animationState: -1,
                presentedEffects: presentedEffects,
                markedForDeletion: state.markedForDeletion,
                genericEffects: nil,
                genericBubbleCount: 0,
                genericSpawnedSmoke: false
            )
        )
    }

    private func updateExplosion(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = explosions[id], pool.record(for: id) != nil else { return }
        let result = SM64BowserBombKernel.tickExplosion(
            explosionInputs[id] ?? SM64BowserBombExplosionTickInput(),
            state: &state
        )
        explosions[id] = state
        var spawnedChildren: [SM64ObjectID] = []
        if let request = result.smokeSpawn,
           let child = try? pool.spawn(
               in: .default,
               model: Self.smokeModel,
               behaviorIdentity: Self.smokeBehaviorIdentity,
               parent: id
           ) {
            let parentPosition = pool.record(for: id)?.position ?? .zero
            let smoke = SM64BowserBombSmokeState(
                position: SM64ObjectVector3(
                    x: parentPosition.x + request.offset.x,
                    y: parentPosition.y + request.offset.y,
                    z: parentPosition.z + request.offset.z
                ),
                velocityY: request.velocityY
            )
            smokes[child] = smoke
            synchronizeSmoke(id: child, state: smoke, pool: pool)
            spawnedChildren.append(child)
        }
        if state.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        synchronizeExplosion(id: id, state: state, pool: pool)
        effectLog.append(
            SM64BowserBombObjectEffectRecord(
                objectID: id,
                kind: .explosion,
                effects: result.effects,
                spawnedChildren: spawnedChildren,
                spawnedExplosionRequest: false,
                timer: state.timer,
                scale: state.scale,
                opacity: 255,
                animationState: state.animationState,
                presentedEffects: [],
                markedForDeletion: state.markedForDeletion,
                genericEffects: nil,
                genericBubbleCount: 0,
                genericSpawnedSmoke: false
            )
        )
    }

    private func updateGenericExplosion(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = genericExplosions[id], pool.record(for: id) != nil else { return }
        let result = SM64ExplosionKernel.tick(
            genericExplosionInputs[id] ?? SM64ExplosionTickInput(),
            state: &state
        )
        genericExplosions[id] = state
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
        if state.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
        }
        if !effectRouter.pending.isEmpty {
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        synchronizeGenericExplosion(id: id, state: state, pool: pool)
        effectLog.append(
            SM64BowserBombObjectEffectRecord(
                objectID: id,
                kind: .genericExplosion,
                effects: [],
                spawnedChildren: [],
                spawnedExplosionRequest: false,
                timer: state.timer,
                scale: state.scale,
                opacity: state.opacity,
                animationState: state.animationState,
                presentedEffects: presentedEffects,
                markedForDeletion: state.markedForDeletion,
                genericEffects: result.effects,
                genericBubbleCount: result.bubbleCount,
                genericSpawnedSmoke: result.spawnedSmoke
            )
        )
    }

    private func updateSmoke(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var state = smokes[id], pool.record(for: id) != nil else { return }
        let result = SM64BowserBombKernel.tickSmoke(state: &state)
        smokes[id] = state
        if state.markedForDeletion {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }
        synchronizeSmoke(id: id, state: state, pool: pool)
        effectLog.append(
            SM64BowserBombObjectEffectRecord(
                objectID: id,
                kind: .smoke,
                effects: result.effects,
                spawnedChildren: [],
                spawnedExplosionRequest: false,
                timer: state.timer,
                scale: state.scale,
                opacity: state.opacity,
                animationState: state.animationState,
                presentedEffects: [],
                markedForDeletion: state.markedForDeletion,
                genericEffects: nil,
                genericBubbleCount: 0,
                genericSpawnedSmoke: false
            )
        )
    }

    private func synchronizeGenericExplosion(
        id: SM64ObjectID,
        state: SM64ExplosionState,
        pool: SM64ObjectPool,
        position: SM64ObjectVector3? = nil
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            if let position { record.position = position }
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.opacity = state.opacity
            record.animationState = state.animationState
            record.timer = Int32(truncatingIfNeeded: state.timer)
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

    private func synchronizeBomb(
        id: SM64ObjectID,
        state: SM64BowserBombState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.drawingDistance = state.visibilityDistance
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.hitboxRadius = SM64BowserBombKernel.bombHitboxRadius
            record.hitboxHeight = SM64BowserBombKernel.bombHitboxHeight
            record.hitboxDownOffset = SM64BowserBombKernel.bombHitboxDownOffset
            record.intangibleTimer = 0
            record.interactionType = 0
        }
    }

    private func synchronizeExplosion(
        id: SM64ObjectID,
        state: SM64BowserBombExplosionState,
        pool: SM64ObjectPool,
        position: SM64ObjectVector3? = nil
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            if let position { record.position = position }
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.graphYOffset = SM64BowserBombKernel.explosionGraphYOffset
            record.animationState = state.animationState
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.interactionType = 0
            record.intangibleTimer = 1
        }
    }

    private func synchronizeSmoke(
        id: SM64ObjectID,
        state: SM64BowserBombSmokeState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = state.position
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.graphYOffset = SM64BowserBombKernel.smokeGraphYOffset
            record.animationState = state.animationState
            record.opacity = state.opacity
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.interactionType = 0
            record.intangibleTimer = 1
        }
    }
}
