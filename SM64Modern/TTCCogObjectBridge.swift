import Foundation

struct SM64TTCCogObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TTCCogOutput
}

/// Owner-thread adapter for `bhvTTCCog`. The value kernel owns speed/target
/// approach and yaw wrapping; the bridge owns shape/direction initialization,
/// explicit random decisions, and level-list yaw mutation.
final class SM64TTCCogObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_636F67
    static let defaultModel: UInt32 = 0

    private struct State {
        let speedSetting: Int32
        let direction: Int32
        var speed: Float
        var targetSpeed: Float
        let randomTargetSpeed: Float
        let randomApproachReached: Bool
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TTCCogObjectEffectRecord] = []

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
    func spawnCog(
        in engineState: SM64SwiftEngineState,
        faceYaw: Int16 = 0,
        behaviorByte: UInt8 = 0,
        speedSetting: Int32 = 0,
        initialSpeed: Float = 0,
        targetSpeed: Float = 0,
        randomTargetSpeed: Float = 0,
        randomApproachReached: Bool = false,
        model: UInt32 = SM64TTCCogObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TTCCogObjectBridge.defaultBehaviorIdentity
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
            initialSpeed: initialSpeed,
            targetSpeed: targetSpeed,
            randomTargetSpeed: randomTargetSpeed,
            randomApproachReached: randomApproachReached,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned TTC cog could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        faceYaw: Int16 = 0,
        behaviorByte: UInt8,
        speedSetting: Int32,
        initialSpeed: Float = 0,
        targetSpeed: Float = 0,
        randomTargetSpeed: Float = 0,
        randomApproachReached: Bool = false,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil,
              (0...3).contains(speedSetting), initialSpeed.isFinite,
              targetSpeed.isFinite, randomTargetSpeed.isFinite else { return false }
        let direction: Int32 = behaviorByte & 1 == 0 ? 1 : -1
        registered.insert(id)
        states[id] = State(
            speedSetting: speedSetting,
            direction: direction,
            speed: initialSpeed,
            targetSpeed: targetSpeed,
            randomTargetSpeed: randomTargetSpeed,
            randomApproachReached: randomApproachReached
        )
        _ = pool.mutate(id) { record in
            record.faceAngles.yaw = Int32(faceYaw)
            record.moveAngles.yaw = Int32(faceYaw)
            record.behaviorParams2ndByte = Int32(behaviorByte)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64TTCCogObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              var cogState = states[id] else { return nil }
        let output = SM64TTCCogBehavior.update(
            SM64TTCCogInput(
                speedSetting: cogState.speedSetting,
                direction: cogState.direction,
                speed: cogState.speed,
                targetSpeed: cogState.targetSpeed,
                faceYaw: Int16(truncatingIfNeeded: record.faceAngles.yaw),
                randomTargetSpeed: cogState.randomTargetSpeed,
                randomApproachReached: cogState.randomApproachReached
            )
        )
        cogState.speed = output.speed
        cogState.targetSpeed = output.targetSpeed
        states[id] = cogState
        _ = engineState.objects.mutate(id) { next in
            next.faceAngles.yaw = Int32(output.faceYaw)
            next.angleVelocity.yaw = Int32(output.angleVelocityYaw)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TTCCogObjectEffectRecord(objectID: id, output: output)
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
