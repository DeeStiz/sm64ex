import Foundation

struct SM64SpinyObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let effects: SM64SpinyEffect
    let attackHandler: SM64SpinyAttackHandler
    let action: SM64SpinyAction
}

struct SM64SpinySchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64SpinyObjectEffectRecord]
}

/// Scheduler adapter for the Lakitu-spawned Spiny family. The parent object
/// and collision resolver remain owner-thread inputs; the Spiny kernel only
/// receives copied values and returns copied effect intents.
final class SM64SpinyObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7370_696E

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64SpinyState] = [:]
    private var inputs: [SM64ObjectID: SM64SpinyTickInput] = [:]
    private(set) var effectLog: [SM64SpinyObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    func state(for id: SM64ObjectID) -> SM64SpinyState? {
        states[id]
    }

    @discardableResult
    func spawnSpiny(
        in engineState: SM64SwiftEngineState,
        action: SM64SpinyAction = .walk,
        objectList: SM64ObjectList = .generalActor,
        parent: SM64ObjectID? = nil,
        behaviorIdentity: UInt64 = SM64SpinyObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: objectList,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard attach(id, action: action, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Spiny could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        action: SM64SpinyAction = .walk,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64SpinyState(action: action)
        states[id] = state
        inputs[id] = SM64SpinyTickInput()
        synchronizeRecord(id: id, state: state, pool: pool)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64SpinyTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64SpinyTickInput] = [:]
    ) -> SM64SpinySchedulerTickResult {
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

        return SM64SpinySchedulerTickResult(
            scheduler: schedulerResult,
            effects: effectLog
        )
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var spiny = states[id], let record = pool.record(for: id) else { return }
        var input = inputs[id] ?? SM64SpinyTickInput()
        if record.parent != id, let parent = pool.record(for: record.parent) {
            input.hasParent = true
            input.parentPreviousObjectExists = parent.previousObject != nil
            input.parentForwardVelocity = parent.forwardVelocity
            input.parentMoveAngleYaw = Int16(truncatingIfNeeded: parent.moveAngles.yaw)
            input.parentFaceAngleYaw = Int16(truncatingIfNeeded: parent.faceAngles.yaw)
        }

        let result = SM64SpinyKernel.tick(input, state: &spiny)
        states[id] = spiny
        synchronizeRecord(id: id, state: spiny, pool: pool)
        if spiny.markedForDeletion {
            _ = pool.markForDeletion(id)
        }
        effectLog.append(
            SM64SpinyObjectEffectRecord(
                objectID: id,
                effects: result.effects,
                attackHandler: result.attackHandler,
                action: result.state.action
            )
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64SpinyState,
        pool: SM64ObjectPool
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.numLootCoins = Int32(state.hitbox.numLootCoins)
            record.graphYOffset = state.graphYOffset
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveAngleYaw)
            record.faceAngles.yaw = Int32(state.faceAngleYaw)
            record.faceAngles.pitch = Int32(state.faceAnglePitch)
            record.action = Int32(state.action.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.moveFlags = state.moveFlags
            record.interactionType = state.action == .walk ? 0 : 1
        }
    }
}
