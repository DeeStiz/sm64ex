import Foundation

struct SM64TTCMovingBarObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TTCMovingBarOutput
}

/// Owner-thread adapter for `bhvTTCMovingBar`. The value kernel owns the
/// action machine; this bridge owns initialized delay/offset state, authored
/// speed settings, home-relative position projection, and record mutation.
final class SM64TTCMovingBarObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_746D_62
    static let defaultModel: UInt32 = 0

    private struct State {
        var speedSetting: Int32
        var delay: Int32
        var stoppedTimer: Int32
        var offset: Float
        var speed: Float
        let randomDelay: Int32
        let randomPauseSelected: Bool
        let randomPauseTimer: Int32
        let randomFakeout: Bool
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TTCMovingBarObjectEffectRecord] = []

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
    func spawnMovingBar(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        speedSetting: Int32 = 0,
        behaviorByte: Int32 = 0,
        randomDelay: Int32 = 12,
        randomPauseSelected: Bool = false,
        randomPauseTimer: Int32 = 0,
        randomFakeout: Bool = false,
        model: UInt32 = SM64TTCMovingBarObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TTCMovingBarObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            position: position,
            faceYaw: faceYaw,
            speedSetting: speedSetting,
            behaviorByte: behaviorByte,
            randomDelay: randomDelay,
            randomPauseSelected: randomPauseSelected,
            randomPauseTimer: randomPauseTimer,
            randomFakeout: randomFakeout,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned TTC moving bar could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int16 = 0,
        speedSetting: Int32,
        behaviorByte: Int32,
        randomDelay: Int32 = 12,
        randomPauseSelected: Bool = false,
        randomPauseTimer: Int32 = 0,
        randomFakeout: Bool = false,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, (0...3).contains(speedSetting) else { return false }
        let initialization = SM64TTCMovingBarBehavior.initialize(
            speedSetting: speedSetting,
            behaviorByte: behaviorByte,
            faceYaw: faceYaw
        )
        registered.insert(id)
        states[id] = State(
            speedSetting: speedSetting,
            delay: initialization.delay,
            stoppedTimer: initialization.stoppedTimer,
            offset: initialization.offset,
            speed: 0,
            randomDelay: randomDelay,
            randomPauseSelected: randomPauseSelected,
            randomPauseTimer: randomPauseTimer,
            randomFakeout: randomFakeout
        )
        _ = pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = Int32(initialization.moveYaw)
            record.action = 0
            record.timer = 0
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
    ) -> SM64TTCMovingBarObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              var barState = states[id] else { return nil }
        let output = SM64TTCMovingBarBehavior.update(
            SM64TTCMovingBarInput(
                speedSetting: barState.speedSetting,
                action: record.action,
                timer: record.timer,
                delay: barState.delay,
                stoppedTimer: barState.stoppedTimer,
                offset: barState.offset,
                speed: barState.speed,
                faceYaw: Int16(truncatingIfNeeded: record.faceAngles.yaw),
                randomDelay: barState.randomDelay,
                randomPauseSelected: barState.randomPauseSelected,
                randomPauseTimer: barState.randomPauseTimer,
                randomFakeout: barState.randomFakeout
            )
        )
        barState.delay = output.delay
        barState.stoppedTimer = output.stoppedTimer
        barState.offset = output.offset
        barState.speed = output.speed
        states[id] = barState

        let cosine = SM64CanonicalTrig.coss(output.moveYaw)
        let sine = SM64CanonicalTrig.sins(output.moveYaw)
        let nextX = record.homePosition.x + output.offset * cosine
        let nextZ = record.homePosition.z + output.offset * sine
        let nextVelocityX = nextX - record.position.x
        let nextVelocityZ = nextZ - record.position.z
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.moveAngles.yaw = Int32(output.moveYaw)
            next.position.x = nextX
            next.position.z = nextZ
            next.velocity.x = nextVelocityX
            next.velocity.y = 0
            next.velocity.z = nextVelocityZ
            next.forwardVelocity = output.speed
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TTCMovingBarObjectEffectRecord(objectID: id, output: output)
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
