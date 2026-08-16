import Foundation

/// A scheduler-facing effect record. The kernel returns value-only effect
/// bits; this record adds the object identity and the small amount of
/// owner-thread context required by audio, particles, coins, and respawn.
struct SM64GoombaObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let effects: SM64GoombaEffect
    let attackHandler: SM64GoombaAttackHandler
    let attackDropsBlueCoin: Bool
    let action: SM64GoombaAction
    let deathSound: SM64GoombaDeathSound
    let numLootCoins: UInt8
    let respawnMarked: Bool
}

struct SM64GoombaRespawnRequest: Equatable, Sendable {
    let sourceID: SM64ObjectID
    let parentID: SM64ObjectID?
    let tripletFlag: UInt8?
    let parentMask: UInt32
    let respawnBit: UInt8
}

enum SM64GoombaTripletSpawnerAction: UInt8, Equatable, Sendable {
    case unloaded = 0
    case loaded = 1
}

struct SM64GoombaTripletSpawnerState: Equatable, Sendable {
    let size: SM64GoombaSize
    let extraGoombas: UInt8
    var action: SM64GoombaTripletSpawnerAction = .unloaded
    var deadFlags: UInt32 = 0
}

struct SM64GoombaSpawnerTickInput: Equatable, Sendable {
    var distanceToMario: Float

    init(distanceToMario: Float = 10_000) {
        self.distanceToMario = distanceToMario
    }
}

struct SM64GoombaSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64GoombaObjectEffectRecord]
    let respawnRequests: [SM64GoombaRespawnRequest]
}

/// Owner-thread adapter for the copied-POD Goomba kernel.
///
/// The C-shaped scheduler still owns object-list traversal, time-stop
/// admission, current-object selection, object counters, and end-of-frame
/// unloading. This adapter only supplies a Goomba's collision/attack input,
/// copies the kernel result back to its object record, and records effects in
/// the exact callback order. No C object pointer or reference escapes this
/// boundary.
final class SM64GoombaObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_676F_6F6D
    static let defaultTripletSpawnerBehaviorIdentity: UInt64 = 0x6268_765F_7472_6970

    private let scheduler: SM64ObjectScheduler
    private let effectRouter: SM64OwnerThreadEffectRouter
    private var states: [SM64ObjectID: SM64GoombaState] = [:]
    private var inputs: [SM64ObjectID: SM64GoombaTickInput] = [:]
    private var spawners: [SM64ObjectID: SM64GoombaTripletSpawnerState] = [:]
    private var spawnerInputs: [SM64ObjectID: SM64GoombaSpawnerTickInput] = [:]
    private var memberships: [SM64ObjectID: (parent: SM64ObjectID, tripletFlag: UInt8)] = [:]
    private(set) var effectLog: [SM64GoombaObjectEffectRecord] = []
    private(set) var respawnRequests: [SM64GoombaRespawnRequest] = []
    private(set) var deliveryLog: [SM64OwnerThreadEffectDeliveryResult] = []

    init(
        scheduler: SM64ObjectScheduler = SM64ObjectScheduler(),
        effectRouter: SM64OwnerThreadEffectRouter = SM64OwnerThreadEffectRouter()
    ) {
        self.scheduler = scheduler
        self.effectRouter = effectRouter
    }

    var registeredIDs: [SM64ObjectID] {
        Set(states.keys).union(spawners.keys).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64GoombaState? {
        states[id]
    }

    func spawnerState(for id: SM64ObjectID) -> SM64GoombaTripletSpawnerState? {
        spawners[id]
    }

    func goombaIDs(parent: SM64ObjectID) -> [SM64ObjectID] {
        memberships.compactMap { id, membership in
            membership.parent == parent ? id : nil
        }.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    /// Spawns and attaches a Goomba on the engine owner thread.
    @discardableResult
    func spawnGoomba(
        in engineState: SM64SwiftEngineState,
        objectList: SM64ObjectList = .generalActor,
        size: SM64GoombaSize = .regular,
        moveAngleYaw: Int16 = 0,
        model: UInt32 = 0,
        behaviorIdentity: UInt64 = SM64GoombaObjectBridge.defaultBehaviorIdentity,
        parent: SM64ObjectID? = nil,
        tripletFlag: UInt8? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: objectList,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent,
            drawingDistance: SM64GoombaState(size: size).drawDistance
        )
        guard attach(
            id,
            size: size,
            moveAngleYaw: moveAngleYaw,
            in: engineState.objects,
            parent: parent,
            tripletFlag: tripletFlag
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Goomba could not attach")
        }
        return id
    }

    /// Spawns a C-shaped triplet spawner. Children are created from the
    /// scheduler callback, so they append to the live general-actor list and
    /// are eligible for the same frame's later callback pass.
    @discardableResult
    func spawnTripletSpawner(
        in engineState: SM64SwiftEngineState,
        size: SM64GoombaSize = .regular,
        extraGoombas: UInt8 = 0,
        model: UInt32 = 0,
        behaviorIdentity: UInt64 = SM64GoombaObjectBridge.defaultTripletSpawnerBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .spawner,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        let spawner = SM64GoombaTripletSpawnerState(
            size: size,
            extraGoombas: extraGoombas
        )
        spawners[id] = spawner
        spawnerInputs[id] = SM64GoombaSpawnerTickInput()
        synchronizeSpawnerRecord(id: id, state: spawner, pool: engineState.objects)
        return id
    }

    /// Attaches a Goomba shadow to an existing object record. This is useful
    /// when a C spawner remains authoritative for allocation but Swift owns
    /// the behavior callback for a qualified object identity.
    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        size: SM64GoombaSize,
        moveAngleYaw: Int16 = 0,
        in pool: SM64ObjectPool,
        parent: SM64ObjectID? = nil,
        tripletFlag: UInt8? = nil
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        if let parent, pool.record(for: parent) == nil { return false }
        let state = SM64GoombaState(size: size, moveAngleYaw: moveAngleYaw)
        states[id] = state
        inputs[id] = SM64GoombaTickInput()
        if let parent, let tripletFlag {
            memberships[id] = (parent: parent, tripletFlag: tripletFlag)
        }
        _ = pool.mutate(id) { record in
            if let tripletFlag {
                record.behaviorParams2ndByte = Int32(size.rawValue | (tripletFlag & 0xFC))
            }
        }
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func detach(_ id: SM64ObjectID, from pool: SM64ObjectPool? = nil) -> Bool {
        let removed = registeredIDs.contains(id)
        remove(id)
        if let pool, pool.record(for: id) != nil {
            _ = pool.despawn(id)
        }
        return removed
    }

    /// Clears per-tick owner-thread effects before an external shared
    /// dispatcher invokes `updateInline` for each live Goomba identity.
    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
        respawnRequests.removeAll(keepingCapacity: true)
        deliveryLog.removeAll(keepingCapacity: true)
        effectRouter.beginTick()
    }

    /// Advances exactly one Goomba or triplet-spawner callback without
    /// starting a nested scheduler traversal. The shared behavior dispatcher
    /// owns list order and frame bookkeeping.
    @discardableResult
    func updateInline(_ id: SM64ObjectID, pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        update(id: id, pool: pool)
        return true
    }

    /// Drops the owner-thread shadow for an unloaded or externally retired
    /// object without touching the scheduler's object pool.
    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        inputs.removeValue(forKey: id)
        memberships.removeValue(forKey: id)
        spawners.removeValue(forKey: id)
        spawnerInputs.removeValue(forKey: id)
    }

    @discardableResult
    func setInput(_ input: SM64GoombaTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func setSpawnerInput(_ input: SM64GoombaSpawnerTickInput, for id: SM64ObjectID) -> Bool {
        guard spawners[id] != nil else { return false }
        spawnerInputs[id] = input
        return true
    }

    /// Advances the shared owner-thread scheduler and returns the Goomba
    /// effects in callback order. Inputs are replaced as a frame snapshot;
    /// omitted registered objects receive the C-shaped zero/default input.
    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64GoombaTickInput] = [:],
        spawnerInputs frameSpawnerInputs: [SM64ObjectID: SM64GoombaSpawnerTickInput] = [:]
    ) -> SM64GoombaSchedulerTickResult {
        inputs = frameInputs
        spawnerInputs = frameSpawnerInputs
        beginExternalTick()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }

        // Unloading is the scheduler's responsibility. Removing the shadow at
        // this point keeps a later slot reuse from inheriting old behavior.
        for id in schedulerResult.unloaded {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
            memberships.removeValue(forKey: id)
            spawners.removeValue(forKey: id)
            spawnerInputs.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
            memberships.removeValue(forKey: id)
        }
        for id in Array(spawners.keys) where engineState.objects.record(for: id) == nil {
            spawners.removeValue(forKey: id)
            spawnerInputs.removeValue(forKey: id)
        }

        return SM64GoombaSchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog,
            respawnRequests: respawnRequests
        )
    }

    /// Collision/interaction entry point. The raw C interaction bitfield is
    /// decoded before the scheduler callback; behavior code receives only the
    /// copied motion and attack POD values.
    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        collisionInputs: [SM64ObjectID: SM64GoombaCollisionSnapshot],
        spawnerInputs frameSpawnerInputs: [SM64ObjectID: SM64GoombaSpawnerTickInput] = [:]
    ) -> SM64GoombaSchedulerTickResult {
        let frameInputs = collisionInputs.mapValues(SM64GoombaCollisionKernel.input(from:))
        return tick(
            state: engineState,
            inputs: frameInputs,
            spawnerInputs: frameSpawnerInputs
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if let spawner = spawners[id] {
            updateSpawner(id: id, state: spawner, pool: pool)
            return
        }
        guard var goomba = states[id], pool.record(for: id) != nil else { return }
        let previousAction = goomba.action
        let input = inputs[id] ?? SM64GoombaTickInput()
        let result = SM64GoombaKernel.tick(input, state: &goomba)
        states[id] = goomba

        synchronizeRecord(
            id: id,
            state: goomba,
            pool: pool,
            previousAction: previousAction
        )
        if goomba.markedForDeletion {
            recordRespawn(for: id, state: goomba, pool: pool)
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }

        if let membership = memberships[id],
           let parent = pool.record(for: membership.parent),
           parent.action == Int32(SM64GoombaTripletSpawnerAction.unloaded.rawValue) {
            effectRouter.enqueue(objectID: id, kind: .markForDeletion)
            deliveryLog.append(effectRouter.deliver(to: pool))
        }

        effectLog.append(
            SM64GoombaObjectEffectRecord(
                objectID: id,
                effects: result.effects,
                attackHandler: result.attackHandler,
                attackDropsBlueCoin: result.attackDropsBlueCoin,
                action: goomba.action,
                deathSound: goomba.deathSound,
                numLootCoins: goomba.numLootCoins,
                respawnMarked: goomba.respawnMarked
            )
        )
    }

    private func updateSpawner(
        id: SM64ObjectID,
        state initialState: SM64GoombaTripletSpawnerState,
        pool: SM64ObjectPool
    ) {
        var state = initialState
        let input = spawnerInputs[id] ?? SM64GoombaSpawnerTickInput()
        let parentRecord = pool.record(for: id)
        state.deadFlags = UInt32(bitPattern: parentRecord?.behaviorParams ?? 0)

        if state.action == .unloaded {
            if input.distanceToMario < 3_000 {
                let count = Int(state.extraGoombas) + 3
                let dAngle = max(1, 0x10000 / count)
                var angle = 0
                var goombaFlag: UInt32 = 1 << 8
                while angle < 0xFFFF {
                    let parentFlag = goombaFlag
                    let tripletFlag = UInt8(truncatingIfNeeded: parentFlag >> 6)
                    if state.deadFlags & parentFlag == 0,
                       let child = spawnTripletChild(
                           parent: id,
                           state: state,
                           tripletFlag: tripletFlag,
                           angle: Int16(truncatingIfNeeded: angle),
                           pool: pool
                       ) {
                        let parentPosition = pool.record(for: id)?.position ?? .zero
                        _ = pool.mutate(child) { record in
                            record.position.x = parentPosition.x + 500 * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: angle))
                            record.position.y = parentPosition.y
                            record.position.z = parentPosition.z + 500 * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: angle))
                        }
                    }
                    angle += dAngle
                    goombaFlag &<<= 1
                }
                state.action = .loaded
            }
        } else if input.distanceToMario > 4_000 {
            state.action = .unloaded
        }

        spawners[id] = state
        synchronizeSpawnerRecord(id: id, state: state, pool: pool)
    }

    private func spawnTripletChild(
        parent: SM64ObjectID,
        state: SM64GoombaTripletSpawnerState,
        tripletFlag: UInt8,
        angle: Int16,
        pool: SM64ObjectPool
    ) -> SM64ObjectID? {
        guard let child = try? pool.spawn(
            in: .generalActor,
            model: 0,
            behaviorIdentity: Self.defaultBehaviorIdentity,
            parent: parent,
            drawingDistance: SM64GoombaState(size: state.size).drawDistance
        ) else { return nil }
        guard attach(
            child,
            size: state.size,
            moveAngleYaw: angle,
            in: pool,
            parent: parent,
            tripletFlag: tripletFlag
        ) else {
            _ = pool.despawn(child)
            return nil
        }
        return child
    }

    private func recordRespawn(
        for id: SM64ObjectID,
        state: SM64GoombaState,
        pool: SM64ObjectPool
    ) {
        guard state.respawnMarked else { return }
        let membership = memberships[id]
        let parentMask = membership.map { UInt32($0.tripletFlag & 0xFC) << 6 } ?? 0
        let respawnBit = membership.map { ($0.tripletFlag & 0xFC) >> 2 } ?? 0
        if let membership, pool.record(for: membership.parent) != nil {
            _ = pool.mutate(membership.parent) { record in
                record.behaviorParams |= Int32(bitPattern: parentMask)
                record.respawnInfoType = 1
                record.respawnInfoIdentity = UInt64(respawnBit)
            }
            if var spawner = spawners[membership.parent] {
                spawner.deadFlags |= parentMask
                spawners[membership.parent] = spawner
            }
        }
        respawnRequests.append(
            SM64GoombaRespawnRequest(
                sourceID: id,
                parentID: membership?.parent,
                tripletFlag: membership?.tripletFlag,
                parentMask: parentMask,
                respawnBit: respawnBit
            )
        )
    }

    private func synchronizeSpawnerRecord(
        id: SM64ObjectID,
        state: SM64GoombaTripletSpawnerState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.action = Int32(state.action.rawValue)
            record.behaviorParams2ndByte = Int32(
                state.size.rawValue | ((state.extraGoombas & 0x3F) << 2)
            )
            record.behaviorParams = Int32(bitPattern: state.deadFlags)
        }
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64GoombaState,
        pool: SM64ObjectPool,
        previousAction: SM64GoombaAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.scale = SM64ObjectVector3(
                x: state.scale,
                y: state.scale,
                z: state.scale
            )
            record.gravity = state.gravity
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.drawingDistance = state.drawDistance
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveAngleYaw)
            record.faceAngles.yaw = Int32(state.moveAngleYaw)
            record.animationState = Int32(state.animationState)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.health = Int32(state.health)
            record.numLootCoins = Int32(state.numLootCoins)
            record.respawnInfoType = state.respawnMarked ? 1 : 0
        }
    }
}
