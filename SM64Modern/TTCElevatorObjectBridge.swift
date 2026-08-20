import Foundation

struct SM64TTCElevatorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TTCElevatorOutput
}

/// Owner-thread adapter for `bhvTTCElevator`. The value kernel owns speed,
/// random direction, endpoint clamp, and timer behavior; this bridge owns
/// authored peak height, copied direction/move-time state, and level-list
/// position/velocity mutation.
final class SM64TTCElevatorObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_74656C
    static let defaultModel: UInt32 = 0

    private struct State {
        let speedSetting: Int32
        let homeY: Float
        let peakY: Float
        var direction: Int32
        var moveTime: Int32
        let gravity: Float
        let randomSign: Int32
        let randomMoveTime: Int32
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TTCElevatorObjectEffectRecord] = []

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
    func spawnElevator(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        behaviorParameterHigh: UInt16 = 0,
        speedSetting: Int32 = 0,
        direction: Int32 = 1,
        gravity: Float = 0,
        randomSign: Int32 = -1,
        randomMoveTime: Int32 = 20,
        model: UInt32 = SM64TTCElevatorObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64TTCElevatorObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(
            id,
            positionY: positionY,
            behaviorParameterHigh: behaviorParameterHigh,
            speedSetting: speedSetting,
            direction: direction,
            gravity: gravity,
            randomSign: randomSign,
            randomMoveTime: randomMoveTime,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned TTC elevator could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        positionY: Float,
        behaviorParameterHigh: UInt16,
        speedSetting: Int32,
        direction: Int32 = 1,
        gravity: Float = 0,
        randomSign: Int32 = -1,
        randomMoveTime: Int32 = 20,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil,
              (0...3).contains(speedSetting), direction != 0,
              positionY.isFinite, gravity.isFinite else { return false }
        let initialization = SM64TTCElevatorBehavior.initialize(
            positionY: positionY,
            behaviorParameterHigh: behaviorParameterHigh
        )
        registered.insert(id)
        states[id] = State(
            speedSetting: speedSetting,
            homeY: positionY,
            peakY: initialization.peakY,
            direction: direction,
            moveTime: 0,
            gravity: gravity,
            randomSign: randomSign,
            randomMoveTime: randomMoveTime
        )
        _ = pool.mutate(id) { record in
            record.position.y = positionY
            record.homePosition.y = positionY
            record.velocity.y = 0
            record.behaviorParams = Int32(bitPattern: UInt32(behaviorParameterHigh) << 16)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64TTCElevatorObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              var elevatorState = states[id] else { return nil }
        let output = SM64TTCElevatorBehavior.update(
            SM64TTCElevatorInput(
                speedSetting: elevatorState.speedSetting,
                timer: record.timer,
                direction: elevatorState.direction,
                moveTime: elevatorState.moveTime,
                positionY: record.position.y,
                homeY: elevatorState.homeY,
                peakY: elevatorState.peakY,
                gravity: elevatorState.gravity,
                randomSign: elevatorState.randomSign,
                randomMoveTime: elevatorState.randomMoveTime
            )
        )
        elevatorState.direction = output.direction
        elevatorState.moveTime = output.moveTime
        states[id] = elevatorState
        let nextTimer = output.timer == record.timer ? record.timer &+ 1 : output.timer
        _ = engineState.objects.mutate(id) { next in
            next.timer = nextTimer
            next.position.y = output.positionY
            next.velocity.y = output.velocityY
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TTCElevatorObjectEffectRecord(objectID: id, output: output)
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
