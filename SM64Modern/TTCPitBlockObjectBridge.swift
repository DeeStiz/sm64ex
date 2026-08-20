import Foundation

struct SM64TTCPitBlockObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TTCPitBlockOutput
}

/// Owner-thread adapter for `bhvTTCPitBlock`. State that is represented by
/// C object fields is copied into a generation-safe value record; authored
/// collision/model selection and explicit random waits stay at this seam.
final class SM64TTCPitBlockObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_747070
    static let defaultModel: UInt32 = 0

    private struct State {
        let speedSetting: Int32
        let homeY: Float
        let peakY: Float
        let collisionModelIndex: UInt8
        let randomWaitTime: Int32
        var direction: Int32
        var waitTime: Int32
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TTCPitBlockObjectEffectRecord] = []

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
    func spawnPitBlock(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        behaviorByte: UInt8 = 0,
        speedSetting: Int32 = 0,
        randomWaitTime: Int32 = 10,
        model: UInt32 = SM64TTCPitBlockObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TTCPitBlockObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            positionY: positionY,
            behaviorByte: behaviorByte,
            speedSetting: speedSetting,
            randomWaitTime: randomWaitTime,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned TTC pit block could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        positionY: Float,
        behaviorByte: UInt8,
        speedSetting: Int32,
        randomWaitTime: Int32 = 10,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil,
              (0...3).contains(speedSetting), positionY.isFinite,
              randomWaitTime >= 0 else { return false }
        let initialization = SM64TTCPitBlockBehavior.initialize(
            positionY: positionY,
            behaviorByte: behaviorByte,
            speedSetting: speedSetting
        )
        registered.insert(id)
        states[id] = State(
            speedSetting: speedSetting,
            homeY: positionY,
            peakY: initialization.peakY,
            collisionModelIndex: initialization.collisionModelIndex,
            randomWaitTime: randomWaitTime,
            direction: 0,
            waitTime: 0
        )
        _ = pool.mutate(id) { record in
            record.position.y = initialization.initialPositionY
            record.homePosition.y = positionY
            record.velocity.y = 0
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
    ) -> SM64TTCPitBlockObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              var blockState = states[id] else { return nil }
        let output = SM64TTCPitBlockBehavior.update(
            SM64TTCPitBlockInput(
                speedSetting: blockState.speedSetting,
                timer: record.timer,
                direction: blockState.direction,
                waitTime: blockState.waitTime,
                velocityY: record.velocity.y,
                positionY: record.position.y,
                homeY: blockState.homeY,
                peakY: blockState.peakY,
                randomWaitTime: blockState.randomWaitTime
            )
        )
        blockState.direction = output.direction
        blockState.waitTime = output.waitTime
        states[id] = blockState
        let nextTimer = output.timer == record.timer ? record.timer &+ 1 : output.timer
        _ = engineState.objects.mutate(id) { next in
            next.timer = nextTimer
            next.position.y = output.positionY
            next.velocity.y = output.velocityY
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TTCPitBlockObjectEffectRecord(objectID: id, output: output)
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
