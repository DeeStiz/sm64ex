import Foundation

struct SM64TTC2DRotatorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TTC2DRotatorOutput
}

/// Owner-thread adapter for `bhvTTC2DRotator`. Random direction/timer draws
/// are explicit state so the hand and cog variants remain replayable.
final class SM64TTC2DRotatorObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_747232
    static let defaultModel: UInt32 = 0

    private struct State {
        let speedSetting: Int32
        let behaviorByte: Int32
        var minTimeUntilNextTurn: Int32
        var targetYaw: Int32
        var increment: Int16
        let speed: Int16
        var randomDirectionTimer: Int32
        let randomUsesSpeed: Bool
        let randomSpeedTimer: Int32
        let randomReverseTimer: Int32
        let randomMinTime: Int32
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TTC2DRotatorObjectEffectRecord] = []

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
    func spawnRotator(
        in engineState: SM64SwiftEngineState,
        faceYaw: Int16 = 0,
        behaviorByte: Int32 = 0,
        speedSetting: Int32 = 0,
        randomUsesSpeed: Bool = true,
        randomSpeedTimer: Int32 = 90,
        randomReverseTimer: Int32 = 30,
        randomMinTime: Int32 = 10,
        model: UInt32 = SM64TTC2DRotatorObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TTC2DRotatorObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            faceYaw: faceYaw,
            behaviorByte: behaviorByte,
            speedSetting: speedSetting,
            randomUsesSpeed: randomUsesSpeed,
            randomSpeedTimer: randomSpeedTimer,
            randomReverseTimer: randomReverseTimer,
            randomMinTime: randomMinTime,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned TTC 2D rotator could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        faceYaw: Int16 = 0,
        behaviorByte: Int32,
        speedSetting: Int32,
        randomUsesSpeed: Bool = true,
        randomSpeedTimer: Int32 = 90,
        randomReverseTimer: Int32 = 30,
        randomMinTime: Int32 = 10,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil,
              (0...1).contains(behaviorByte), (0...3).contains(speedSetting) else { return false }
        let initialization = SM64TTC2DRotatorBehavior.initialize(
            behaviorByte: behaviorByte,
            speedSetting: speedSetting,
            faceYaw: faceYaw
        )
        registered.insert(id)
        states[id] = State(
            speedSetting: speedSetting,
            behaviorByte: behaviorByte,
            minTimeUntilNextTurn: initialization.minTimeUntilNextTurn,
            targetYaw: initialization.targetYaw,
            increment: initialization.increment,
            speed: initialization.speed,
            randomDirectionTimer: 0,
            randomUsesSpeed: randomUsesSpeed,
            randomSpeedTimer: randomSpeedTimer,
            randomReverseTimer: randomReverseTimer,
            randomMinTime: randomMinTime
        )
        _ = pool.mutate(id) { record in
            record.faceAngles.yaw = Int32(faceYaw)
            record.moveAngles.yaw = Int32(faceYaw)
            record.behaviorParams2ndByte = behaviorByte
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64TTC2DRotatorObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              var rotatorState = states[id] else { return nil }
        let output = SM64TTC2DRotatorBehavior.update(
            SM64TTC2DRotatorInput(
                speedSetting: rotatorState.speedSetting,
                behaviorByte: rotatorState.behaviorByte,
                timer: record.timer,
                minTimeUntilNextTurn: rotatorState.minTimeUntilNextTurn,
                targetYaw: rotatorState.targetYaw,
                increment: rotatorState.increment,
                speed: rotatorState.speed,
                randomDirectionTimer: rotatorState.randomDirectionTimer,
                faceYaw: Int16(truncatingIfNeeded: record.faceAngles.yaw),
                randomUsesSpeed: rotatorState.randomUsesSpeed,
                randomSpeedTimer: rotatorState.randomSpeedTimer,
                randomReverseTimer: rotatorState.randomReverseTimer,
                randomMinTime: rotatorState.randomMinTime
            )
        )
        rotatorState.minTimeUntilNextTurn = output.minTimeUntilNextTurn
        rotatorState.targetYaw = output.targetYaw
        rotatorState.increment = output.increment
        rotatorState.randomDirectionTimer = output.randomDirectionTimer
        states[id] = rotatorState
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer == record.timer ? record.timer &+ 1 : output.timer
            next.faceAngles.yaw = Int32(output.faceYaw)
            next.angleVelocity.yaw = Int32(output.angleVelocityYaw)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TTC2DRotatorObjectEffectRecord(objectID: id, output: output)
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
