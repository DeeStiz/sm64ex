import Foundation

struct SM64BullyObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let size: SM64BullySize
    let effects: SM64BullyEffect
    let action: SM64BullyAction
    let markedForDeletion: Bool
}

struct SM64BullySchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BullyObjectEffectRecord]
}

/// Owner-thread bridge for small and large Bully actors. The collision
/// response is a copied state/effect boundary; object records retain only
/// stable transforms, hitboxes, action timers, and deletion flags.
final class SM64BullyObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_62756C
    static let defaultModel: UInt32 = 0x6A // MODEL_BULLY

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64BullyState] = [:]
    private var inputs: [SM64ObjectID: SM64BullyTickInput] = [:]
    private(set) var effectLog: [SM64BullyObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64BullyState? {
        states[id]
    }

    @discardableResult
    func spawnBully(
        in engineState: SM64SwiftEngineState,
        size: SM64BullySize,
        subtype: SM64BullySubtype = .generic,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64BullyAction = .patrol,
        model: UInt32 = SM64BullyObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BullyObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            size: size,
            subtype: subtype,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            action: action,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bully could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        size: SM64BullySize,
        subtype: SM64BullySubtype = .generic,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64BullyAction = .patrol,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BullyState(
            size: size,
            subtype: subtype,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            action: action
        )
        states[id] = state
        inputs[id] = SM64BullyTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64BullyTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64BullyTickInput] = [:]
    ) -> SM64BullySchedulerTickResult {
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
        return SM64BullySchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var bully = states[id], let record = pool.record(for: id) else { return }
        let previousAction = bully.action
        let input = inputs[id] ?? defaultInput(for: record)
        let result = SM64BullyKernel.tick(input, state: &bully)
        states[id] = bully
        synchronizeRecord(id: id, state: bully, pool: pool, previousAction: previousAction)
        if bully.markedForDeletion {
            _ = pool.markForDeletion(id)
        }
        effectLog.append(
            SM64BullyObjectEffectRecord(
                objectID: id,
                size: bully.size,
                effects: result.effects,
                action: bully.action,
                markedForDeletion: bully.markedForDeletion
            )
        )
    }

    private func defaultInput(for record: SM64ObjectRecord) -> SM64BullyTickInput {
        let dx = record.position.x - record.homePosition.x
        let dz = record.position.z - record.homePosition.z
        return SM64BullyTickInput(
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            distanceFromHome: (dx * dx + dz * dz).squareRoot(),
            homeRadiusExceeded: record.distanceToMario > 1_000,
            interacted: record.interactionStatus != 0,
            marioCollisionAngle: Int16(truncatingIfNeeded: record.moveAngles.yaw),
            floorCollisionFlags: record.moveFlags,
            marioY: record.position.y
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BullyState,
        pool: SM64ObjectPool,
        previousAction: SM64BullyAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position.x = state.positionX
            record.position.y = state.positionY
            record.position.z = state.positionZ
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.faceYaw)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.behaviorParams2ndByte = Int32(state.size.rawValue)
            record.behaviorParams = Int32(state.subtype.rawValue)
            record.graphFlags = state.invisible ? record.graphFlags | 0x10 : record.graphFlags & ~0x10
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? 1 : 0
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
        }
    }
}
