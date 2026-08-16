import Foundation

enum SM64ChainChompReleaseObjectKind: UInt8, Equatable, Sendable {
    case woodenPost = 0
    case gate = 1
}

/// Common owner-thread delivery bits for the post and gate value kernels. The
/// renderer, audio, progression, and collision owners consume this stable
/// record rather than reaching into a C object pointer.
struct SM64ChainChompReleaseObjectEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let poundSound = Self(rawValue: 1 << 0)
    static let updatePosition = Self(rawValue: 1 << 1)
    static let releaseChain = Self(rawValue: 1 << 2)
    static let spawnCoins = Self(rawValue: 1 << 3)
    static let setRespawnBit = Self(rawValue: 1 << 4)
    static let wallExplosionSound = Self(rawValue: 1 << 5)
    static let cameraShake = Self(rawValue: 1 << 6)
    static let mist = Self(rawValue: 1 << 7)
    static let breakParticles = Self(rawValue: 1 << 8)
    static let markForDeletion = Self(rawValue: 1 << 9)
}

struct SM64ChainChompReleaseObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64ChainChompReleaseObjectKind
    let effects: SM64ChainChompReleaseObjectEffect
    let spawnedCoins: UInt8
    let markedForDeletion: Bool
}

struct SM64ChainChompReleaseSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64ChainChompReleaseObjectEffectRecord]
    let releaseRequests: [SM64ObjectID]
}

/// Owner-thread bridge for the course-level Chain Chomp post and gate. It is
/// intentionally separate from the parent/segment bridge so the source's
/// processing order (surface post, surface gate, actor parent, chain parts)
/// can be composed explicitly by the future whole-level actor scheduler.
final class SM64ChainChompReleaseObjectBridge {
    static let postModel: UInt32 = 0x6B // MODEL_WOODEN_POST
    static let gateModel: UInt32 = 0x36 // MODEL_BOB_CHAIN_CHOMP_GATE
    static let postBehaviorIdentity: UInt64 = 0x6268_765F_7770_7374
    static let gateBehaviorIdentity: UInt64 = 0x6268_765F_6761_7465
    static let postCollisionIdentity: UInt64 = 0x706F_756E_6461_626C // "poundabl"
    static let gateCollisionIdentity: UInt64 = 0x6368_6F6D_705F_6761 // "chomp_ga"

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var postStates: [SM64ObjectID: SM64ChainChompPostState] = [:]
    private var postInputs: [SM64ObjectID: SM64ChainChompPostTickInput] = [:]
    private var postParents: [SM64ObjectID: SM64ObjectID] = [:]
    private var gateStates: [SM64ObjectID: SM64ChainChompGateState] = [:]
    private var gateInputs: [SM64ObjectID: Bool] = [:]
    private var gateParents: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64ChainChompReleaseObjectEffectRecord] = []
    private(set) var releaseRequestLog: [SM64ObjectID] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(postStates.keys) + Array(gateStates.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64ChainChompPostState? { postStates[id] }
    func gateState(for id: SM64ObjectID) -> SM64ChainChompGateState? { gateStates[id] }

    @discardableResult
    func spawnWoodenPost(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        homeY: Float = 0,
        behaviorIdentity: UInt64 = SM64ChainChompReleaseObjectBridge.postBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            model: Self.postModel,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard attachWoodenPost(id, parent: parent, homeY: homeY, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned wooden post could not attach")
        }
        return id
    }

    @discardableResult
    func spawnGate(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        behaviorIdentity: UInt64 = SM64ChainChompReleaseObjectBridge.gateBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            model: Self.gateModel,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard attachGate(id, parent: parent, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Chain Chomp gate could not attach")
        }
        return id
    }

    @discardableResult
    func attachWoodenPost(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        homeY: Float = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        postStates[id] = SM64ChainChompPostState(homeY: homeY)
        postInputs[id] = SM64ChainChompPostTickInput()
        postParents[id] = parent
        synchronizePost(id: id, pool: pool)
        return true
    }

    @discardableResult
    func attachGate(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        gateStates[id] = SM64ChainChompGateState()
        gateInputs[id] = false
        gateParents[id] = parent
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagBuildTransform
                | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
            record.collisionDataIdentity = Self.gateCollisionIdentity
        }
        return true
    }

    @discardableResult
    func setPostInput(_ input: SM64ChainChompPostTickInput, for id: SM64ObjectID) -> Bool {
        guard postStates[id] != nil else { return false }
        postInputs[id] = input
        return true
    }

    @discardableResult
    func setGateHit(_ hitGate: Bool, for id: SM64ObjectID) -> Bool {
        guard gateStates[id] != nil else { return false }
        gateInputs[id] = hitGate
        return true
    }

    /// Clears per-tick effects before a shared scheduler pass.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        releaseRequestLog.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    /// Advances one surface post or gate without nesting a scheduler
    /// traversal. The enclosing dispatcher remains list-order authority.
    @discardableResult
    func updateInline(_ id: SM64ObjectID, pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil,
              postStates[id] != nil || gateStates[id] != nil else { return false }
        if postStates[id] != nil {
            updatePost(id: id, pool: pool)
        } else {
            updateGate(id: id, pool: pool)
        }
        return true
    }

    /// Completes a shared dispatcher pass: derive parent release requests and
    /// apply the typed surface effects through the common owner sink.
    func finalizeExternalTick(pool: SM64ObjectPool) {
        releaseRequestLog = effectLog.compactMap { effect in
            effect.kind == .woodenPost && effect.effects.contains(.releaseChain)
                ? postParents[effect.objectID] : nil
        }
        effectRouter.enqueue(effectLog)
        let delivery = effectRouter.deliver(to: pool)
        if !delivery.delivered.isEmpty || !delivery.presented.isEmpty
            || !delivery.spawned.isEmpty || !delivery.deleted.isEmpty || !delivery.rejected.isEmpty {
            deliveryLog.append(delivery)
        }
    }

    /// Removes a surface child shadow after scheduler unload or reset.
    func remove(_ id: SM64ObjectID) {
        postStates.removeValue(forKey: id)
        postInputs.removeValue(forKey: id)
        postParents.removeValue(forKey: id)
        gateStates.removeValue(forKey: id)
        gateInputs.removeValue(forKey: id)
        gateParents.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil {
            remove(id)
        }
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        postInputs framePostInputs: [SM64ObjectID: SM64ChainChompPostTickInput] = [:],
        gateHits frameGateHits: [SM64ObjectID: Bool] = [:]
    ) -> SM64ChainChompReleaseSchedulerTickResult {
        for (id, input) in framePostInputs { postInputs[id] = input }
        for (id, hit) in frameGateHits { gateInputs[id] = hit }
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            guard let self else { return }
            if self.postStates[id] != nil {
                self.updatePost(id: id, pool: pool)
            } else if self.gateStates[id] != nil {
                self.updateGate(id: id, pool: pool)
            }
        }

        finalizeExternalTick(pool: engineState.objects)
        pruneExternal(unloaded: schedulerResult.unloaded, pool: engineState.objects)
        return SM64ChainChompReleaseSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            releaseRequests: releaseRequestLog
        )
    }

    private func updatePost(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var post = postStates[id], pool.record(for: id) != nil else { return }
        let result = SM64ChainChompPostKernel.tick(postInputs[id] ?? SM64ChainChompPostTickInput(), state: &post)
        postStates[id] = post
        synchronizePost(id: id, pool: pool)
        let effects = map(post: result.effects)
        effectLog.append(
            SM64ChainChompReleaseObjectEffectRecord(
                objectID: id,
                kind: .woodenPost,
                effects: effects,
                spawnedCoins: result.effects.contains(.spawnCoins) ? 5 : 0,
                markedForDeletion: false
            )
        )
    }

    private func updateGate(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var gate = gateStates[id], pool.record(for: id) != nil else { return }
        let result = SM64ChainChompGateKernel.tick(hitGate: gateInputs[id] ?? false, state: &gate)
        gateStates[id] = gate
        effectLog.append(
            SM64ChainChompReleaseObjectEffectRecord(
                objectID: id,
                kind: .gate,
                effects: map(gate: result.effects),
                spawnedCoins: 0,
                markedForDeletion: result.state.markedForDeletion
            )
        )
    }

    private func synchronizePost(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard let post = postStates[id] else { return }
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagBuildTransform
                | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position.y = post.positionY
            record.homePosition.y = post.homeY
            record.collisionDataIdentity = Self.postCollisionIdentity
            record.numLootCoins = Int32(post.numLootCoins)
            record.behaviorParams = post.respawnInfoBits == 0 ? record.behaviorParams : record.behaviorParams | (Int32(post.respawnInfoBits) << 8)
        }
    }

    private func map(post effects: SM64ChainChompPostEffect) -> SM64ChainChompReleaseObjectEffect {
        var mapped: SM64ChainChompReleaseObjectEffect = []
        if effects.contains(.poundSound) { mapped.insert(.poundSound) }
        if effects.contains(.updatePosition) { mapped.insert(.updatePosition) }
        if effects.contains(.releaseChain) { mapped.insert(.releaseChain) }
        if effects.contains(.spawnCoins) { mapped.insert(.spawnCoins) }
        if effects.contains(.setRespawnBit) { mapped.insert(.setRespawnBit) }
        return mapped
    }

    private func map(gate effects: SM64ChainChompGateEffect) -> SM64ChainChompReleaseObjectEffect {
        var mapped: SM64ChainChompReleaseObjectEffect = []
        if effects.contains(.wallExplosionSound) { mapped.insert(.wallExplosionSound) }
        if effects.contains(.cameraShake) { mapped.insert(.cameraShake) }
        if effects.contains(.mist) { mapped.insert(.mist) }
        if effects.contains(.breakParticles) { mapped.insert(.breakParticles) }
        if effects.contains(.markForDeletion) { mapped.insert(.markForDeletion) }
        return mapped
    }
}
