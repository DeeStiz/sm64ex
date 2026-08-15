import Foundation

struct SM64BooObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let effects: SM64BooEffect
    let action: SM64BooAction
    let opacity: Int16
    let markedForDeletion: Bool
}

struct SM64BooSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64BooObjectEffectRecord]
}

/// Owner-thread bridge for the common Ghost Hunt Boo behavior. The bridge
/// keeps the C behavior's hit/opacity state value-only while object records
/// retain stable transforms, collision fields, and deletion boundaries.
final class SM64BooObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626F_6F
    static let defaultModel: UInt32 = 0x54 // MODEL_BOO

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64BooState] = [:]
    private var inputs: [SM64ObjectID: SM64BooTickInput] = [:]
    private(set) var effectLog: [SM64BooObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) { self.scheduler = scheduler }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64BooState? { states[id] }

    @discardableResult
    func spawnBoo(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64BooObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64BooObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, model: model, behaviorIdentity: behaviorIdentity)
        guard attach(id, homeX: homeX, homeY: homeY, homeZ: homeZ, moveYaw: moveYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Boo could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64BooState(homeX: homeX, homeY: homeY, homeZ: homeZ, moveYaw: moveYaw)
        states[id] = state
        inputs[id] = SM64BooTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64BooTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64BooTickInput] = [:]
    ) -> SM64BooSchedulerTickResult {
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
        return SM64BooSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var boo = states[id], pool.record(for: id) != nil else { return }
        let previousAction = boo.action
        let input = inputs[id] ?? defaultInput(for: id, pool: pool)
        let result = SM64BooKernel.tick(input, state: &boo)
        states[id] = boo
        synchronizeRecord(id: id, state: boo, pool: pool, previousAction: previousAction)
        if boo.markedForDeletion { _ = pool.markForDeletion(id) }
        effectLog.append(
            SM64BooObjectEffectRecord(
                objectID: id,
                effects: result.effects,
                action: boo.action,
                opacity: boo.opacity,
                markedForDeletion: boo.markedForDeletion
            )
        )
    }

    private func defaultInput(for id: SM64ObjectID, pool: SM64ObjectPool) -> SM64BooTickInput {
        guard let record = pool.record(for: id) else { return SM64BooTickInput() }
        let dx = record.position.x - record.homePosition.x
        let dz = record.position.z - record.homePosition.z
        return SM64BooTickInput(
            activeInRoom: record.activeFlags & (1 << 3) == 0,
            distanceToMario: record.distanceToMario,
            lateralDistanceFromHome: (dx * dx + dz * dz).squareRoot(),
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            angleToHome: Int16(truncatingIfNeeded: record.angleToHome),
            marioFaceYaw: Int16(truncatingIfNeeded: record.faceAngles.yaw),
            marioMoveYaw: Int16(truncatingIfNeeded: record.moveAngles.yaw),
            marioY: record.position.y,
            marioInAir: record.moveFlags & (1 << 12) != 0,
            marioForwardVelocity: record.forwardVelocity,
            attackStatus: record.interactionStatus & (1 << 15) != 0 ? .attacked : .none,
            hitWall: record.moveFlags & 1 != 0,
            shouldStop: record.activeFlags & (1 << 3) != 0,
            randomValue: UInt32(truncatingIfNeeded: record.timer)
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64BooState,
        pool: SM64ObjectPool,
        previousAction: SM64BooAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position = SM64ObjectVector3(x: state.positionX, y: state.positionY, z: state.positionZ)
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.scale = SM64ObjectVector3(x: state.renderScaleX, y: state.renderScaleY, z: state.renderScaleZ)
            record.forwardVelocity = state.forwardVelocity
            record.velocity.y = state.velocityY
            record.gravity = state.gravity
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles = SM64ObjectAngles(pitch: Int32(state.facePitch), yaw: Int32(state.faceYaw), roll: Int32(state.faceRoll))
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.opacity = Int32(state.opacity)
            record.graphYOffset = 30
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? state.interactionType : 0
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.friction = 1_000
            record.buoyancy = 200
        }
    }
}
