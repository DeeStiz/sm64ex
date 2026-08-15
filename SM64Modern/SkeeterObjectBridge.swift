import Foundation

struct SM64SkeeterObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let isWave: Bool
    let effects: SM64SkeeterEffect
    let action: SM64SkeeterAction
    let spawnedWaves: [SM64ObjectID]
    let scale: Float
    let animationState: UInt32
    let markedForDeletion: Bool
}

struct SM64SkeeterSchedulerTickResult: Equatable, Sendable {
    let scheduler: SM64ObjectSchedulerTickResult
    let effects: [SM64SkeeterObjectEffectRecord]
}

/// Owner-thread bridge for Skeeter water-surface actors and their four-wave
/// transient children. Parent links and wave offsets are stable value IDs;
/// the copied kernel never sees a C object pointer or list node.
final class SM64SkeeterObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_736B65
    static let defaultWaveBehaviorIdentity: UInt64 = 0x6268_765F_736B77
    static let defaultModel: UInt32 = 0x69 // MODEL_SKEETER
    static let defaultWaveModel: UInt32 = 0xA6 // MODEL_IDLE_WATER_WAVE

    private static let waveOffsets: [SM64ObjectVector3] = [
        SM64ObjectVector3(x: -382, y: 0, z: -66),
        SM64ObjectVector3(x: 130, y: 0, z: -66),
        SM64ObjectVector3(x: -180, y: 0, z: 130),
        SM64ObjectVector3(x: 180, y: 0, z: 130),
    ]

    private let scheduler: SM64ObjectScheduler
    private var states: [SM64ObjectID: SM64SkeeterState] = [:]
    private var waveStates: [SM64ObjectID: SM64SkeeterWaveState] = [:]
    private var inputs: [SM64ObjectID: SM64SkeeterTickInput] = [:]
    private var currentFrame: UInt64 = 0
    private(set) var effectLog: [SM64SkeeterObjectEffectRecord] = []

    init(scheduler: SM64ObjectScheduler = SM64ObjectScheduler()) {
        self.scheduler = scheduler
    }

    var registeredIDs: [SM64ObjectID] {
        (Array(states.keys) + Array(waveStates.keys)).sorted { lhs, rhs in
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.generation < rhs.generation
        }
    }

    func state(for id: SM64ObjectID) -> SM64SkeeterState? {
        states[id]
    }

    func waveState(for id: SM64ObjectID) -> SM64SkeeterWaveState? {
        waveStates[id]
    }

    @discardableResult
    func spawnSkeeter(
        in engineState: SM64SwiftEngineState,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        model: UInt32 = SM64SkeeterObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64SkeeterObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Skeeter could not attach")
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
        let state = SM64SkeeterState(
            homeX: homeX,
            homeY: homeY,
            homeZ: homeZ,
            moveYaw: moveYaw
        )
        states[id] = state
        inputs[id] = SM64SkeeterTickInput()
        synchronizeSkeeter(id: id, state: state, pool: pool, previousAction: state.action)
        return true
    }

    @discardableResult
    func setInput(_ input: SM64SkeeterTickInput, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        inputs[id] = input
        return true
    }

    @discardableResult
    func tick(
        state engineState: SM64SwiftEngineState,
        inputs frameInputs: [SM64ObjectID: SM64SkeeterTickInput] = [:]
    ) -> SM64SkeeterSchedulerTickResult {
        inputs = frameInputs
        effectLog.removeAll(keepingCapacity: true)
        currentFrame = engineState.globals.frame &+ 1
        let schedulerResult = scheduler.update(state: engineState) { [weak self] id, pool in
            self?.update(id: id, pool: pool)
        }
        for id in schedulerResult.unloaded {
            states.removeValue(forKey: id)
            waveStates.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        for id in Array(states.keys) where engineState.objects.record(for: id) == nil {
            states.removeValue(forKey: id)
            inputs.removeValue(forKey: id)
        }
        for id in Array(waveStates.keys) where engineState.objects.record(for: id) == nil {
            waveStates.removeValue(forKey: id)
        }
        return SM64SkeeterSchedulerTickResult(scheduler: schedulerResult, effects: effectLog)
    }

    private func update(id: SM64ObjectID, pool: SM64ObjectPool) {
        if var wave = waveStates[id], pool.record(for: id) != nil {
            wave.tick(globalFrame: currentFrame)
            waveStates[id] = wave
            synchronizeWave(id: id, state: wave, pool: pool)
            if wave.markedForDeletion { _ = pool.markForDeletion(id) }
            effectLog.append(
                SM64SkeeterObjectEffectRecord(
                    objectID: id,
                    isWave: true,
                    effects: [],
                    action: .idle,
                    spawnedWaves: [],
                    scale: wave.scale,
                    animationState: wave.animationState,
                    markedForDeletion: wave.markedForDeletion
                )
            )
            return
        }

        guard var skeeter = states[id], let record = pool.record(for: id) else { return }
        let previousAction = skeeter.action
        let input = inputs[id] ?? defaultInput(for: record)
        let result = SM64SkeeterKernel.tick(input, state: &skeeter)
        var spawnedWaves: [SM64ObjectID] = []

        if result.effects.contains(.spawnWaves) {
            for offset in Self.waveOffsets {
                guard let waveID = try? pool.spawn(
                    in: .generalActor,
                    model: Self.defaultWaveModel,
                    behaviorIdentity: Self.defaultWaveBehaviorIdentity,
                    parent: id
                ) else { continue }
                var wave = SM64SkeeterWaveState()
                wave.relativePosition = offset
                waveStates[waveID] = wave
                synchronizeWave(id: waveID, state: wave, pool: pool)
                spawnedWaves.append(waveID)
            }
        }

        states[id] = skeeter
        synchronizeSkeeter(id: id, state: skeeter, pool: pool, previousAction: previousAction)
        if skeeter.markedForDeletion { _ = pool.markForDeletion(id) }
        effectLog.append(
            SM64SkeeterObjectEffectRecord(
                objectID: id,
                isWave: false,
                effects: result.effects,
                action: skeeter.action,
                spawnedWaves: spawnedWaves,
                scale: 1,
                animationState: 0,
                markedForDeletion: skeeter.markedForDeletion
            )
        )
    }

    private func defaultInput(for record: SM64ObjectRecord) -> SM64SkeeterTickInput {
        SM64SkeeterTickInput(
            distanceToMario: record.distanceToMario,
            angleToMario: Int16(truncatingIfNeeded: record.angleToMario),
            moveFlags: record.moveFlags,
            animationNearEnd: record.animationState != 0,
            animationAtEnd: record.animationState < 0
        )
    }

    private func synchronizeSkeeter(
        id: SM64ObjectID,
        state: SM64SkeeterState,
        pool: SM64ObjectPool,
        previousAction: SM64SkeeterAction
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
            record.moveAngles.yaw = Int32(state.moveYaw)
            record.faceAngles.yaw = Int32(state.faceYaw)
            record.action = Int32(state.action.rawValue)
            record.previousAction = Int32(previousAction.rawValue)
            record.timer = Int32(truncatingIfNeeded: state.timer)
            record.moveFlags = state.moveFlags
            record.hitboxDownOffset = state.hitbox.downOffset
            record.hitboxRadius = state.hitbox.radius
            record.hitboxHeight = state.hitbox.height
            record.hurtboxRadius = state.hitbox.hurtboxRadius
            record.hurtboxHeight = state.hitbox.hurtboxHeight
            record.interactionType = state.hitbox.interactType
            record.damageOrCoinValue = Int32(state.hitbox.damageOrCoinValue)
            record.numLootCoins = Int32(state.hitbox.numLootCoins)
        }
    }

    private func synchronizeWave(id: SM64ObjectID, state: SM64SkeeterWaveState, pool: SM64ObjectPool) {
        _ = pool.mutate(id) { record in
            record.objectFlags |=
                SM64ObjectScheduler.objectFlagTransformRelativeToParent |
                SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
            record.parentRelativePosition = state.relativePosition
            record.scale = SM64ObjectVector3(x: state.scale, y: state.scale, z: state.scale)
            record.animationState = Int32(truncatingIfNeeded: state.animationState)
            record.interactionType = 0
        }
    }
}
