import Foundation

enum SM64BouncingFireballObjectKind: UInt8, Equatable, Sendable {
    case fireball = 0
    case flame = 1
}

struct SM64BouncingFireballObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64BouncingFireballObjectKind
    let action: UInt8
    let effects: SM64BouncingFireballEffect
    let spawnedChildren: [SM64ObjectID]
    let flameScale: Float
    let markedForDeletion: Bool
}

struct SM64BouncingFireballSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BouncingFireballObjectEffectRecord]
}

/// Owner-thread bridge for `bhvBouncingFireball` and its transient
/// `bhvBouncingFireballFlame` children. The parent remains a value kernel;
/// child allocation and end-of-frame deletion stay in the pool owner.
final class SM64BouncingFireballObjectBridge {
    static let fireballModel: UInt32 = 0
    static let flameModel: UInt32 = 0x90 // MODEL_RED_FLAME
    static let fireballBehaviorIdentity: UInt64 = 0x6268_765F_62666972
    static let flameBehaviorIdentity: UInt64 = 0x6268_765F_62666C6D

    private let scheduler: SM64ObjectScheduler
    private var fireballStates: [SM64ObjectID: SM64BouncingFireballState] = [:]
    private var fireballInputs: [SM64ObjectID: SM64BouncingFireballTickInput] = [:]
    private var flameStates: [SM64ObjectID: SM64BouncingFireballFlameState] = [:]
    private var flameInputs: [SM64ObjectID: SM64BouncingFireballFlameTickInput] = [:]
    private(set) var effectLog: [SM64BouncingFireballObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) { self.scheduler = scheduler }

    var registeredIDs: [SM64ObjectID] {
        (Array(fireballStates.keys) + Array(flameStates.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64BouncingFireballState? { fireballStates[id] }
    func flameState(for id: SM64ObjectID) -> SM64BouncingFireballFlameState? { flameStates[id] }

    @discardableResult
    func spawnFireball(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        behaviorIdentity: UInt64 = SM64BouncingFireballObjectBridge.fireballBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            model: Self.fireballModel,
            behaviorIdentity: behaviorIdentity
        )
        guard attachFireball(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned bouncing fireball could not attach")
        }
        return id
    }

    @discardableResult
    func attachFireball(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        fireballStates[id] = SM64BouncingFireballState()
        fireballInputs[id] = SM64BouncingFireballTickInput()
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = position
        }
        return true
    }

    @discardableResult
    func setInput(_ input: SM64BouncingFireballTickInput, for id: SM64ObjectID) -> Bool {
        guard fireballStates[id] != nil else { return false }
        fireballInputs[id] = input
        return true
    }

    @discardableResult
    func setFlameInput(_ input: SM64BouncingFireballFlameTickInput, for id: SM64ObjectID) -> Bool {
        guard flameStates[id] != nil else { return false }
        flameInputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64BouncingFireballTickInput] = [:],
        flameInputs frameFlameInputs: [SM64ObjectID: SM64BouncingFireballFlameTickInput] = [:]
    ) -> SM64BouncingFireballSchedulerTickResult {
        for (id, input) in frameInputs { fireballInputs[id] = input }
        for (id, input) in frameFlameInputs { flameInputs[id] = input }
        effectLog.removeAll(keepingCapacity: true)
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            guard let self else { return }
            if self.fireballStates[id] != nil {
                self.updateFireball(id: id, pool: pool)
            } else if self.flameStates[id] != nil {
                self.updateFlame(id: id, pool: pool)
            }
        }
        for id in schedulerResult.unloaded {
            fireballStates.removeValue(forKey: id)
            fireballInputs.removeValue(forKey: id)
            flameStates.removeValue(forKey: id)
            flameInputs.removeValue(forKey: id)
        }
        return SM64BouncingFireballSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func updateFireball(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var fireball = fireballStates[id], pool.record(for: id) != nil else { return }
        let result = SM64BouncingFireballKernel.tick(fireballInputs[id] ?? SM64BouncingFireballTickInput(), state: &fireball)
        fireballStates[id] = fireball
        _ = pool.mutate(id) { record in
            record.action = Int32(fireball.action.rawValue)
            record.timer = Int32(truncatingIfNeeded: fireball.timer)
            record.velocity.y = fireball.velocityY
            record.forwardVelocity = fireball.forwardVelocity
            record.animationState = Int32(fireball.animState)
            record.interactionType = fireball.tangible ? 1 : 0
        }

        var spawned: [SM64ObjectID] = []
        if result.effects.contains(.spawnFlame), let child = try? pool.spawn(
            in: .generalActor,
            model: Self.flameModel,
            behaviorIdentity: Self.flameBehaviorIdentity,
            parent: id
        ) {
            flameStates[child] = SM64BouncingFireballFlameState()
            flameInputs[child] = SM64BouncingFireballFlameTickInput()
            let parentPosition = pool.record(for: id)?.position ?? .zero
            _ = pool.mutate(child) { record in
                record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                record.position = parentPosition
                record.scale = SM64ObjectVector3(
                    x: result.flameScale ?? 0.5,
                    y: result.flameScale ?? 0.5,
                    z: result.flameScale ?? 0.5
                )
                record.interactionType = fireball.tangible ? 1 : 0
            }
            spawned.append(child)
        }
        if fireball.markedForDeletion { _ = pool.markForDeletion(id) }
        effectLog.append(
            SM64BouncingFireballObjectEffectRecord(
                objectID: id,
                kind: .fireball,
                action: fireball.action.rawValue,
                effects: result.effects,
                spawnedChildren: spawned,
                flameScale: result.flameScale ?? 0,
                markedForDeletion: fireball.markedForDeletion
            )
        )
    }

    private func updateFlame(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var flame = flameStates[id], pool.record(for: id) != nil else { return }
        let result = SM64BouncingFireballFlameKernel.tick(flameInputs[id] ?? SM64BouncingFireballFlameTickInput(), state: &flame)
        flameStates[id] = flame
        _ = pool.mutate(id) { record in
            record.action = Int32(flame.action.rawValue)
            record.timer = Int32(truncatingIfNeeded: flame.timer)
            record.velocity.y = flame.velocityY
            record.forwardVelocity = flame.forwardVelocity
            record.interactionType = flame.markedForDeletion ? 0 : 1
        }
        if flame.markedForDeletion { _ = pool.markForDeletion(id) }
        effectLog.append(
            SM64BouncingFireballObjectEffectRecord(
                objectID: id,
                kind: .flame,
                action: flame.action.rawValue,
                effects: result.effects,
                spawnedChildren: [],
                flameScale: pool.record(for: id)?.scale.x ?? 0,
                markedForDeletion: flame.markedForDeletion
            )
        )
    }
}
