import Foundation

struct SM64SwoopObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let effects: SM64SwoopEffect
    let action: SM64SwoopAction
    let markedForDeletion: Bool
}

struct SM64SwoopSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64SwoopObjectEffectRecord]
}

/// Owner-thread bridge for the hitbox-bearing Swoop family. Collision and
/// room admission remain copied inputs; the bridge only mutates the stable
/// object record and preserves end-of-frame deletion ordering.
final class SM64SwoopObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_73776F
    static let defaultModel: UInt32 = 0x64 // MODEL_SWOOP

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64SwoopState] = [:]
    private var inputs: [SM64ObjectID: SM64SwoopTickInput] = [:]
    private(set) var effectLog: [SM64SwoopObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64SwoopState? {
        states[id]
    }

    @discardableResult
    func spawnSwoop(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        homeY: Float? = nil,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64SwoopObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64SwoopObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            positionY: positionY,
            homeY: homeY,
            moveYaw: moveYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Swoop could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        positionY: Float = 0,
        homeY: Float? = nil,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64SwoopState(positionY: positionY, homeY: homeY, moveYaw: moveYaw)
        states[id] = state
        inputs[id] = SM64SwoopTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64SwoopTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64SwoopTickInput] = [:]
    ) -> SM64SwoopSchedulerTickResult {
        inputs = frameInputs
        effectLog.removeAll(keepingCapacity: true)
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
        return SM64SwoopSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var swoop = states[id], let record = pool.record(for: id) else { return }
        let previousAction = swoop.action
        let input = inputs[id] ?? defaultInput(for: record)
        let result = SM64SwoopKernel.tick(input, state: &swoop)
        states[id] = swoop
        synchronizeRecord(id: id, state: swoop, pool: pool, previousAction: previousAction)
        if swoop.markedForDeletion {
            _ = pool.markForDeletion(id)
        }
        effectLog.append(
            SM64SwoopObjectEffectRecord(
                objectID: id,
                effects: result.effects,
                action: swoop.action,
                markedForDeletion: swoop.markedForDeletion
            )
        )
    }

    private func defaultInput(for record: SM64ObjectRecord) -> SM64SwoopTickInput {
        SM64SwoopTickInput(
            distanceToMario: record.distanceToMario,
            marioY: record.position.y,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            moveFlags: record.moveFlags
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64SwoopState,
        pool: SM64ObjectPool,
        previousAction: SM64SwoopAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.position.y = state.positionY
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.pitch = Int32(state.facePitch)
            record.faceAngles.roll = Int32(state.faceRoll)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.numLootCoins = Int32(state.hitbox.numLootCoins)
            record.interactionType = 1
        }
    }
}
