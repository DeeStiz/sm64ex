import Foundation

struct SM64MoneybagObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: Bool // false = moneybag, true = hidden coin
    let action: UInt8
    let effects: SM64MoneybagEffect
    let spawnedChildren: [SM64ObjectID]
    let markedForDeletion: Bool
}

struct SM64MoneybagSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64MoneybagObjectEffectRecord]
}

/// Owner-thread bridge for the Moneybag actor and its level-list hidden coin.
/// The coin placeholder persists until its transform callback; loot and mist
/// are transient unimportant children and are unloaded at the scheduler edge.
final class SM64MoneybagObjectBridge {
    static let moneybagModel: UInt32 = 0x66 // MODEL_MONEYBAG
    static let hiddenCoinModel: UInt32 = 0x74 // MODEL_YELLOW_COIN
    static let coinModel: UInt32 = 0x74 // MODEL_YELLOW_COIN
    static let mistModel: UInt32 = 0x8E // MODEL_MIST
    static let moneybagBehaviorIdentity: UInt64 = 0x6268_765F_6D6F_6E
    static let hiddenBehaviorIdentity: UInt64 = 0x6268_765F_686964

    private let scheduler: SM64ObjectScheduler
    private var moneybags: [SM64ObjectID: SM64MoneybagState] = [:]
    private var hiddenCoins: [SM64ObjectID: SM64MoneybagHiddenState] = [:]
    private var inputs: [SM64ObjectID: SM64MoneybagTickInput] = [:]
    private var hiddenInputs: [SM64ObjectID: SM64MoneybagHiddenTickInput] = [:]
    private(set) var effectLog: [SM64MoneybagObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) { self.scheduler = scheduler }

    var registeredIDs: [SM64ObjectID] {
        (Array(moneybags.keys) + Array(hiddenCoins.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64MoneybagState? { moneybags[id] }
    func hiddenState(for id: SM64ObjectID) -> SM64MoneybagHiddenState? { hiddenCoins[id] }

    @discardableResult
    func spawnMoneybag(
        in engineState: SM64SwiftEngineState,
        action: SM64MoneybagAction = .appear,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: Self.moneybagModel,
            behaviorIdentity: Self.moneybagBehaviorIdentity
        )
        guard attachMoneybag(
            id, action: action, positionX: positionX, positionY: positionY,
            positionZ: positionZ, floorHeight: floorHeight, moveYaw: moveYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Moneybag could not attach")
        }
        return id
    }

    @discardableResult
    func attachMoneybag(
        _ id: SM64ObjectID,
        action: SM64MoneybagAction = .appear,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64MoneybagState(
            action: action, positionX: positionX, positionY: positionY,
            positionZ: positionZ, floorHeight: floorHeight, moveYaw: moveYaw
        )
        moneybags[id] = state
        inputs[id] = SM64MoneybagTickInput()
        synchronizeMoneybag(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func spawnHiddenCoin(
        in engineState: SM64SwiftEngineState,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: Self.hiddenCoinModel,
            behaviorIdentity: Self.hiddenBehaviorIdentity
        )
        guard attachHiddenCoin(id, positionX: positionX, positionY: positionY, positionZ: positionZ, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned hidden Moneybag coin could not attach")
        }
        return id
    }

    @discardableResult
    func attachHiddenCoin(
        _ id: SM64ObjectID,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        var state = SM64MoneybagHiddenState()
        state.positionX = positionX; state.positionY = positionY; state.positionZ = positionZ
        hiddenCoins[id] = state
        hiddenInputs[id] = SM64MoneybagHiddenTickInput()
        synchronizeHiddenCoin(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64MoneybagTickInput, for id: SM64ObjectID) -> Bool {
        guard moneybags[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func setHiddenInput(_ input: SM64MoneybagHiddenTickInput, for id: SM64ObjectID) -> Bool {
        guard hiddenCoins[id] != nil else { return false }
        hiddenInputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64MoneybagTickInput] = [:],
        hiddenInputs frameHiddenInputs: [SM64ObjectID: SM64MoneybagHiddenTickInput] = [:]
    ) -> SM64MoneybagSchedulerTickResult {
        inputs = frameInputs; hiddenInputs = frameHiddenInputs
        effectLog.removeAll(keepingCapacity: true)
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            moneybags.removeValue(forKey: id); inputs.removeValue(forKey: id)
            hiddenCoins.removeValue(forKey: id); hiddenInputs.removeValue(forKey: id)
        }
        for id in Array(moneybags.keys) where engineState.objects.record(for: id) == nil {
            moneybags.removeValue(forKey: id); inputs.removeValue(forKey: id)
        }
        for id in Array(hiddenCoins.keys) where engineState.objects.record(for: id) == nil {
            hiddenCoins.removeValue(forKey: id); hiddenInputs.removeValue(forKey: id)
        }
        return SM64MoneybagSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if let state = moneybags[id] {
            updateMoneybag(id: id, state: state, pool: pool)
        } else if let state = hiddenCoins[id] {
            updateHiddenCoin(id: id, state: state, pool: pool)
        }
    }

    private func updateMoneybag(id: SM64ObjectID, state initial: SM64MoneybagState, pool: SM64ObjectPool) {
        var state = initial
        let input = inputs[id] ?? defaultInput(for: id, pool: pool)
        let result = SM64MoneybagKernel.tick(input, state: &state)
        moneybags[id] = state
        synchronizeMoneybag(id: id, state: state, pool: pool)
        var children: [SM64ObjectID] = []
        if result.effects.contains(.hiddenSpawn),
           let child = try? pool.spawn(in: .level, model: Self.hiddenCoinModel, behaviorIdentity: Self.hiddenBehaviorIdentity) {
            var hidden = SM64MoneybagHiddenState()
            hidden.positionX = state.positionX; hidden.positionY = state.positionY; hidden.positionZ = state.positionZ
            hiddenCoins[child] = hidden; hiddenInputs[child] = SM64MoneybagHiddenTickInput()
            synchronizeHiddenCoin(id: child, state: hidden, pool: pool)
            children.append(child)
        }
        if result.effects.contains(.coins) {
            for _ in 0..<5 {
                if let child = spawnTransient(model: Self.coinModel, behaviorIdentity: 0x6268_765F_636F69, parent: id, pool: pool) { children.append(child) }
            }
        } else if result.effects.contains(.coin),
                  let child = spawnTransient(model: Self.coinModel, behaviorIdentity: 0x6268_765F_636F69, parent: id, pool: pool) {
            children.append(child)
        }
        if result.effects.contains(.mist),
           let child = spawnTransient(model: Self.mistModel, behaviorIdentity: 0x6268_765F_6D6973, parent: id, pool: pool) { children.append(child) }
        if state.markedForDeletion { _ = pool.markForDeletion(id) }
        effectLog.append(SM64MoneybagObjectEffectRecord(objectID: id, kind: false, action: state.action.rawValue, effects: result.effects, spawnedChildren: children, markedForDeletion: state.markedForDeletion))
    }

    private func updateHiddenCoin(id: SM64ObjectID, state initial: SM64MoneybagHiddenState, pool: SM64ObjectPool) {
        var state = initial
        let result = SM64MoneybagKernel.tickHidden(hiddenInputs[id] ?? SM64MoneybagHiddenTickInput(), state: &state)
        hiddenCoins[id] = state
        synchronizeHiddenCoin(id: id, state: state, pool: pool)
        var children: [SM64ObjectID] = []
        if result.effects.contains(.hiddenSpawn),
           let child = try? pool.spawn(in: .generalActor, model: Self.moneybagModel, behaviorIdentity: Self.moneybagBehaviorIdentity) {
            let moneybag = SM64MoneybagState(action: .appear, positionX: state.positionX, positionY: state.positionY, positionZ: state.positionZ, floorHeight: state.positionY)
            moneybags[child] = moneybag; inputs[child] = SM64MoneybagTickInput()
            synchronizeMoneybag(id: child, state: moneybag, pool: pool)
            children.append(child)
        }
        effectLog.append(SM64MoneybagObjectEffectRecord(objectID: id, kind: true, action: state.action.rawValue, effects: result.effects, spawnedChildren: children, markedForDeletion: false))
    }

    private func spawnTransient(model: UInt32, behaviorIdentity: UInt64, parent: SM64ObjectID, pool: SM64ObjectPool) -> SM64ObjectID? {
        guard let child = try? pool.spawn(in: .unimportant, model: model, behaviorIdentity: behaviorIdentity, parent: parent) else { return nil }
        _ = pool.markForDeletion(child)
        return child
    }

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64MoneybagTickInput {
        guard let record = pool.record(for: id) else { return SM64MoneybagTickInput() }
        let dx = record.position.x - record.homePosition.x, dz = record.position.z - record.homePosition.z
        return SM64MoneybagTickInput(
            distanceToMario: record.distanceToMario,
            homeDistanceToMario: record.distanceToMario,
            closeToHome: (dx * dx + dz * dz).squareRoot() < 100,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            angleToHome: Int16(truncatingIfNeeded: record.angleToHome),
            interacted: record.interactionStatus & (1 << 15) != 0,
            attackedMario: record.interactionStatus & (1 << 13) != 0,
            wasAttacked: record.interactionStatus & (1 << 14) != 0,
            collisionFlags: record.moveFlags,
            animationFrame: Int16(truncatingIfNeeded: record.animationState),
            nearAnimationEnd: record.animationState != 0
        )
    }

    private func synchronizeMoneybag(id: SM64ObjectID, state: SM64MoneybagState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagBuildTransform | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.forwardVelocity = state.forwardVelocity; record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw); record.faceAngles.yaw = Int32(state.moveYaw)
            record.action = Int32(state.action.rawValue); record.subAction = Int32(state.jumpState.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer); record.opacity = state.opacity
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? state.hitbox.interactType : 0
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue); record.health = Int32(state.hitbox.health)
            record.hitboxRadius = state.hitbox.radius; record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius; record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.gravity = 3; record.friction = 1; record.buoyancy = 2
        }
    }

    private func synchronizeHiddenCoin(id: SM64ObjectID, state: SM64MoneybagHiddenState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.action = Int32(state.action.rawValue); record.timer = Int32(truncatingIfNeeded: state.timer)
            record.interactionType = state.hitbox.interactType; record.intangibleTimer = 0
            record.hitboxRadius = 110; record.hitboxHeight = 100; record.graphYOffset = 27
        }
    }
}
