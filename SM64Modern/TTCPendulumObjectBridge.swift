import Foundation

struct SM64TTCPendulumObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TTCPendulumOutput
}

/// Owner-thread adapter for `bhvTTCPendulum`. The value kernel owns the
/// acceleration/delay/sound-timer oscillator; this bridge owns copied state,
/// level-list lifetime, and render-facing roll mutation.
final class SM64TTCPendulumObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_747065
    static let defaultModel: UInt32 = 0

    private struct State {
        let speedSetting: Int32
        var angle: Float
        var angleVelocity: Float
        var angleAcceleration: Float
        var accelerationDirection: Float
        var delay: Int32
        var soundTimer: Int32
        let randomAccelerationUses13: Bool
        let randomDelayIsEven: Bool
        let randomDelay: Int32
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TTCPendulumObjectEffectRecord] = []

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
    func spawnPendulum(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        speedSetting: Int32 = 0,
        randomAccelerationUses13: Bool = true,
        randomDelayIsEven: Bool = false,
        randomDelay: Int32 = 7,
        model: UInt32 = SM64TTCPendulumObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TTCPendulumObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            position: position,
            speedSetting: speedSetting,
            randomAccelerationUses13: randomAccelerationUses13,
            randomDelayIsEven: randomDelayIsEven,
            randomDelay: randomDelay,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned TTC pendulum could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        speedSetting: Int32,
        randomAccelerationUses13: Bool = true,
        randomDelayIsEven: Bool = false,
        randomDelay: Int32 = 7,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, (0...3).contains(speedSetting) else { return false }
        let initialization = SM64TTCPendulumBehavior.initialize(speedSetting: speedSetting)
        registered.insert(id)
        states[id] = State(
            speedSetting: speedSetting,
            angle: initialization.angle,
            angleVelocity: 0,
            angleAcceleration: initialization.angleAcceleration,
            accelerationDirection: 1,
            delay: 0,
            soundTimer: 0,
            randomAccelerationUses13: randomAccelerationUses13,
            randomDelayIsEven: randomDelayIsEven,
            randomDelay: randomDelay
        )
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.roll = Int32(initialization.angle)
            record.angleVelocity.roll = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64TTCPendulumObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              var pendulumState = states[id] else { return nil }
        let output = SM64TTCPendulumBehavior.update(
            SM64TTCPendulumInput(
                speedSetting: pendulumState.speedSetting,
                angle: pendulumState.angle,
                angleVelocity: pendulumState.angleVelocity,
                angleAcceleration: pendulumState.angleAcceleration,
                accelerationDirection: pendulumState.accelerationDirection,
                delay: pendulumState.delay,
                soundTimer: pendulumState.soundTimer,
                randomAccelerationUses13: pendulumState.randomAccelerationUses13,
                randomDelayIsEven: pendulumState.randomDelayIsEven,
                randomDelay: pendulumState.randomDelay
            )
        )
        pendulumState.angle = output.angle
        pendulumState.angleVelocity = output.angleVelocity
        pendulumState.angleAcceleration = output.angleAcceleration
        pendulumState.accelerationDirection = output.accelerationDirection
        pendulumState.delay = output.delay
        pendulumState.soundTimer = output.soundTimer
        states[id] = pendulumState
        _ = engineState.objects.mutate(id) { next in
            next.angleVelocity.roll = output.faceRoll - record.faceAngles.roll
            next.faceAngles.roll = output.faceRoll
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TTCPendulumObjectEffectRecord(objectID: id, output: output)
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
