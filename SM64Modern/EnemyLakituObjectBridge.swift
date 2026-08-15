import Foundation

/// Owner-thread effect record for the Enemy Lakitu behavior. The optional
/// child identity is the only allocation result that crosses this boundary;
/// all movement and animation decisions remain value-only kernel output.
struct SM64EnemyLakituObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let effects: SM64EnemyLakituEffect
    let action: SM64EnemyLakituAction
    let subAction: SM64EnemyLakituSubAction
    let numSpinies: UInt8
    let spawnedSpiny: SM64ObjectID?
}

struct SM64EnemyLakituSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let lakituEffects: [SM64EnemyLakituObjectEffectRecord]
    let spinyEffects: [SM64SpinyObjectEffectRecord]
}

/// Composite owner-thread bridge for `bhvEnemyLakitu` and the Spiny objects it
/// allocates. Lakitu lives in the spawner list, so a newly allocated Spiny is
/// appended to the live general-actor list and receives the same frame's
/// callback after the player list, matching the C object-list traversal.
final class SM64EnemyLakituObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6C616B
    static let defaultSpinyModel: UInt32 = 0x55 // MODEL_SPINY_BALL
    static let defaultLakituModel: UInt32 = 0x54 // MODEL_ENEMY_LAKITU

    private let scheduler: SM64ObjectScheduler
    private let spinyBridge: SM64SpinyObjectBridge
    private var states: [SM64ObjectID: SM64EnemyLakituState] = [:]
    private var inputs: [SM64ObjectID: SM64EnemyLakituTickInput] = [:]
    private(set) var effectLog: [SM64EnemyLakituObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
        self.spinyBridge = SM64SpinyObjectBridge(scheduler: scheduler)
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    var spinyIDs: [SM64ObjectID] {
        spinyBridge.registeredIDs
    }

    func state(for id: SM64ObjectID) -> SM64EnemyLakituState? {
        states[id]
    }

    func spinyState(for id: SM64ObjectID) -> SM64SpinyState? {
        spinyBridge.state(for: id)
    }

    /// Allocates a Lakitu in the spawner list and attaches its copied-POD
    /// shadow. The parent/previous-object relationship is established only
    /// after the kernel emits a spawn event during a scheduler callback.
    @discardableResult
    func spawnLakitu(
        in engineState: SM64SwiftEngineState,
        model: UInt32 = SM64EnemyLakituObjectBridge.defaultLakituModel,
        behaviorIdentity: UInt64 = SM64EnemyLakituObjectBridge.defaultBehaviorIdentity,
        drawingDistance: Float = 4_000
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .spawner,
            model: model,
            behaviorIdentity: behaviorIdentity,
            drawingDistance: drawingDistance
        )
        guard attach(id, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Enemy Lakitu could not attach")
        }
        return id
    }

    /// Attaches the behavior shadow to an object allocated by an existing
    /// object loader. This keeps allocation authority and behavior authority
    /// independently replaceable during the migration.
    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        in pool: SM64ObjectPool,
        state: SM64EnemyLakituState = SM64EnemyLakituState()
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = state
        inputs[id] = SM64EnemyLakituTickInput()
        synchronizeRecord(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64EnemyLakituTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func setSpinyInput(_ input: SM64SpinyTickInput, for id: SM64ObjectID) -> Bool {
        spinyBridge.setInput(input, for: id)
    }

    /// Runs one owner-thread scheduler pass for Lakitu and its live Spiny
    /// children. Child allocation and parent-link mutation happen inside the
    /// Lakitu callback, before traversal reaches the appended actor list.
    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64EnemyLakituTickInput] = [:],
        spinyInputs: [SM64ObjectID: SM64SpinyTickInput] = [:]
    ) -> SM64EnemyLakituSchedulerTickResult {
        inputs = frameInputs
        for (id, input) in spinyInputs {
            _ = spinyBridge.setInput(input, for: id)
        }
        effectLog.removeAll(keepingCapacity: true)
        spinyBridge.resetEffectLog()

        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            guard let self else { return }
            if self.states[id] != nil {
                self.updateLakitu(id: id, pool: pool)
            } else if self.spinyBridge.contains(id) {
                self.spinyBridge.update(id: id, pool: pool)
            }
        }

        // A Spiny can decrement its Lakitu's count while the Lakitu callback
        // has already run. Apply that owner-thread bookkeeping after the live
        // callback sequence but before snapshots leave the engine thread.
        for effect in spinyBridge.effectLog {
            apply(spinyEffect: effect, pool: engineState.objects)
        }

        let spinyEffects = spinyBridge.effectLog
        for id in schedulerResult.unloaded {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        spinyBridge.prune(unloaded: schedulerResult.unloaded, pool: engineState.objects)

        return SM64EnemyLakituSchedulerTickResult(
            scheduler: schedulerResult,
            lakituEffects: effectLog,
            spinyEffects: spinyEffects
        )
    }

    private func updateLakitu(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var lakitu = states[id], let record = pool.record(for: id) else { return }
        let input = inputs[id] ?? defaultInput(for: record)
        let result = SM64EnemyLakituKernel.tick(input, state: &lakitu)
        var spawnedSpiny: SM64ObjectID?

        if result.effects.contains(.spawnSpiny) {
            spawnedSpiny = spinyBridge.spawnSpiny(
                in: pool,
                action: .heldByLakitu,
                objectList: .generalActor,
                parent: id,
                model: Self.defaultSpinyModel,
                drawingDistance: 4_000
            )
            if let spawnedSpiny {
                _ = pool.setPreviousObject(id, previous: spawnedSpiny)
            } else {
                // Allocation failure is an explicit owner-thread event: do not
                // leave the kernel shadow claiming a child that does not exist.
                lakitu.numSpinies = lakitu.numSpinies > 0 ? lakitu.numSpinies - 1 : 0
                lakitu.previousSpinyAttached = false
                lakitu.subAction = .noSpiny
                lakitu.spinyCooldown = 0
            }
        }

        if result.effects.contains(.clearPreviousSpiny) || result.effects.contains(.attacked) {
            _ = pool.setPreviousObject(id, previous: nil)
        }

        states[id] = lakitu
        synchronizeRecord(id: id, state: lakitu, pool: pool)
        effectLog.append(
            SM64EnemyLakituObjectEffectRecord(
                objectID: id,
                effects: result.effects,
                action: lakitu.action,
                subAction: lakitu.subAction,
                numSpinies: lakitu.numSpinies,
                spawnedSpiny: spawnedSpiny
            )
        )
    }

    private func apply(spinyEffect: SM64SpinyObjectEffectRecord, pool: SM64ObjectPool) {
        guard spinyEffect.effects.contains(.decrementParentCount)
                || spinyEffect.effects.contains(.markForDeletion),
              let parentID = spinyEffect.parentID,
              var parent = states[parentID]
        else { return }

        if parent.numSpinies > 0 {
            parent.numSpinies -= 1
        }
        if pool.record(for: parentID)?.previousObject == spinyEffect.objectID {
            parent.previousSpinyAttached = false
            _ = pool.setPreviousObject(parentID, previous: nil)
        }
        states[parentID] = parent
        synchronizeRecord(id: parentID, state: parent, pool: pool)
    }

    private func defaultInput(for record: SM64ObjectRecord) -> SM64EnemyLakituTickInput {
        SM64EnemyLakituTickInput(
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            marioForwardVelocity: record.forwardVelocity,
            lakituY: record.position.y,
            marioY: record.position.y,
            drawingDistance: record.drawingDistance
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64EnemyLakituState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.hitboxRadius = 50
            record.hitboxHeight = 50
            record.hurtboxRadius = 40
            record.hurtboxHeight = 50
            record.damageOrCoinValue = 2
            record.numLootCoins = 5
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.faceYaw)
            record.action = Int32(state.action.rawValue)
            record.subAction = Int32(state.subAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.behaviorParams2ndByte = Int32(state.numSpinies)
            record.interactionType = 1
        }
    }
}
