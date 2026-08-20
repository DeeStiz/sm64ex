import Foundation

struct SM64SlidingPlatform2ObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SlidingPlatform2Output
}

final class SM64SlidingPlatform2ObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_737032

    private struct State {
        let initialization: SM64SlidingPlatform2Initialization
        var offset: Float
        var speed: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64SlidingPlatform2ObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        behaviorParams: UInt32 = 0
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        let initialization = SM64SlidingPlatform2Behavior.initialize(
            behaviorParams: behaviorParams,
            moveYaw: moveYaw
        )
        guard attach(
            id,
            position: position,
            behaviorParams: behaviorParams,
            initialization: initialization,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned sliding platform 2 could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        behaviorParams: UInt32,
        initialization: SM64SlidingPlatform2Initialization,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            initialization: initialization,
            offset: 0,
            speed: initialization.speed
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = initialization.moveYaw
            record.behaviorParams = Int32(bitPattern: behaviorParams)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64SlidingPlatform2ObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64SlidingPlatform2Behavior.update(
            SM64SlidingPlatform2Input(
                timer: record.timer,
                homePosition: record.homePosition,
                moveYaw: state.initialization.moveYaw,
                offset: state.offset,
                speed: state.speed,
                distance: state.initialization.distance,
                verticalSign: state.initialization.verticalSign
            )
        )
        state.offset = output.offset
        state.speed = output.speed
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.timer = output.timer
            next.velocity = SM64ObjectVector3(
                x: output.position.x - record.position.x,
                y: output.position.y - record.position.y,
                z: output.position.z - record.position.z
            )
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64SlidingPlatform2ObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
