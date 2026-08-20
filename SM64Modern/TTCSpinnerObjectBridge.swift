import Foundation

struct SM64TTCSpinnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TTCSpinnerOutput
}

/// Owner-thread adapter for `bhvTTCSpinner`. The value kernel owns speed,
/// direction-change, pause, and pitch wrapping decisions; this bridge owns
/// copied random-direction state and the render-facing object record.
final class SM64TTCSpinnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7473_70
    static let defaultModel: UInt32 = 0

    private struct State {
        let speedSetting: Int32
        var direction: Int32
        var changeDirectionTimer: Int32
        let randomDirection: Int32
        let randomChangeDirectionTimer: Int32
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TTCSpinnerObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnSpinner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        facePitch: Int16 = 0,
        speedSetting: Int32 = 0,
        direction: Int32 = 1,
        changeDirectionTimer: Int32 = 20,
        randomDirection: Int32 = -1,
        randomChangeDirectionTimer: Int32 = 30,
        model: UInt32 = SM64TTCSpinnerObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TTCSpinnerObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            position: position,
            facePitch: facePitch,
            speedSetting: speedSetting,
            direction: direction,
            changeDirectionTimer: changeDirectionTimer,
            randomDirection: randomDirection,
            randomChangeDirectionTimer: randomChangeDirectionTimer,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned TTC spinner could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        facePitch: Int16 = 0,
        speedSetting: Int32,
        direction: Int32 = 1,
        changeDirectionTimer: Int32 = 20,
        randomDirection: Int32 = -1,
        randomChangeDirectionTimer: Int32 = 30,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, (0...3).contains(speedSetting), abs(direction) <= 1 else {
            return false
        }
        registered.insert(id)
        states[id] = State(
            speedSetting: speedSetting,
            direction: direction,
            changeDirectionTimer: changeDirectionTimer,
            randomDirection: randomDirection,
            randomChangeDirectionTimer: randomChangeDirectionTimer
        )
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.pitch = Int32(facePitch)
            record.timer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64TTCSpinnerObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              var spinnerState = states[id] else { return nil }
        let output = SM64TTCSpinnerBehavior.update(
            SM64TTCSpinnerInput(
                speedSetting: spinnerState.speedSetting,
                timer: record.timer,
                changeDirectionTimer: spinnerState.changeDirectionTimer,
                direction: spinnerState.direction,
                facePitch: Int16(truncatingIfNeeded: record.faceAngles.pitch),
                randomDirection: spinnerState.randomDirection,
                randomChangeDirectionTimer: spinnerState.randomChangeDirectionTimer
            )
        )
        spinnerState.direction = output.direction
        spinnerState.changeDirectionTimer = output.changeDirectionTimer
        states[id] = spinnerState
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer == record.timer ? record.timer &+ 1 : output.timer
            next.faceAngles.pitch = Int32(output.facePitch)
            next.angleVelocity.pitch = Int32(output.angleVelocityPitch)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TTCSpinnerObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        states.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
