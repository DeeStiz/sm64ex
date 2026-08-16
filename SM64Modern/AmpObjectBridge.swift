import Foundation

struct SM64AmpObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64AmpKind
    let effects: SM64AmpEffect
    let action: SM64AmpAction
    let tangible: Bool
    let invisible: Bool
}

struct SM64AmpSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64AmpObjectEffectRecord]
}

/// Owner-thread bridge for the homing, circling, and fixed Amp families. The
/// copied kernel owns behavior state; object records carry only stable values
/// needed by collision, transform, and renderer snapshots.
final class SM64AmpObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_616D70
    static let defaultModel: UInt32 = 0xC2 // MODEL_AMP

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64AmpState] = [:]
    private var inputs: [SM64ObjectID: SM64AmpTickInput] = [:]
    private(set) var effectLog: [SM64AmpObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64AmpState? {
        states[id]
    }

    func contains(_ id: SM64ObjectID) -> Bool {
        states[id] != nil
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        input: SM64AmpTickInput? = nil,
        pool: SM64ObjectPool
    ) -> SM64AmpObjectEffectRecord? {
        guard states[id] != nil else { return nil }
        if let input { inputs[id] = input }
        let count = effectLog.count
        update(id: id, pool: pool)
        return effectLog.count > count ? effectLog.last : nil
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        inputs.removeValue(forKey: id)
    }

    @discardableResult
    func spawnAmp(
        in engineState: SM64SwiftEngineState,
        kind: SM64AmpKind,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        rotationRadius: Float = 0,
        initialMoveYaw: Int16 = 0,
        initialPhase: Int32 = 0,
        model: UInt32 = SM64AmpObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64AmpObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            kind: kind,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            rotationRadius: rotationRadius,
            initialMoveYaw: initialMoveYaw,
            initialPhase: initialPhase,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Amp could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64AmpKind,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        rotationRadius: Float = 0,
        initialMoveYaw: Int16 = 0,
        initialPhase: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        let state = SM64AmpState(
            kind: kind,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            rotationRadius: rotationRadius,
            initialMoveYaw: initialMoveYaw,
            initialPhase: initialPhase
        )
        states[id] = state
        inputs[id] = SM64AmpTickInput()
        synchronizeRecord(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64AmpTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64AmpTickInput] = [:]
    ) -> SM64AmpSchedulerTickResult {
        inputs = frameInputs
        beginExternalTick()
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            _ = self?.updateInline(id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            remove(id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            remove(id)
        }
        return SM64AmpSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        guard var amp = states[id], let record = pool.record(for: id) else { return }
        let previousAction = amp.action
        let input = inputs[id] ?? defaultInput(for: record)
        let result = SM64AmpKernel.tick(input, state: &amp)
        states[id] = amp
        synchronizeRecord(id: id, state: amp, pool: pool, previousAction: previousAction)
        effectLog.append(
            SM64AmpObjectEffectRecord(
                objectID: id,
                kind: amp.kind,
                effects: result.effects,
                action: amp.action,
                tangible: amp.tangible,
                invisible: amp.invisible
            )
        )
    }

    private func defaultInput(for record: SM64ObjectRecord) -> SM64AmpTickInput {
        SM64AmpTickInput(
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            marioHeadY: record.position.y + 150,
            verticalAngleToMario: Int16(truncatingIfNeeded: record.faceAngles.pitch),
            cameraTargetYaw: Int16(truncatingIfNeeded: record.faceAngles.yaw),
            homeRadiusExceeded: record.distanceToMario > 1_500,
            interacted: record.interactionStatus != 0
        )
    }

    private func synchronizeRecord(
        id: SM64ObjectID,
        state: SM64AmpState,
        pool: SM64ObjectPool,
        previousAction: SM64AmpAction
    ) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagBuildTransform |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.position.x = state.positionX
            record.position.y = state.positionY
            record.position.z = state.positionZ
            record.homePosition = SM64ObjectVector3(x: state.homeX, y: state.homeY, z: state.homeZ)
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.forwardVelocity = state.forwardVelocity
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.faceYaw)
            record.faceAngles.pitch = Int32(state.facePitch)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.animationState = state.animationState
            record.graphFlags = state.invisible ? record.graphFlags | 0x10 : record.graphFlags & ~0x10
            record.intangibleTimer = state.tangible ? -1 : 1
            record.interactionType = state.tangible ? 1 : 0
            record.hitboxDownOffset = state.hitbox.downOffset
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.health = Int32(state.hitbox.health)
            record.numLootCoins = Int32(state.hitbox.numLootCoins)
        }
    }
}
