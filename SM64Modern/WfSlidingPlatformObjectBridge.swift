import Foundation

struct SM64WfSlidingPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WfSlidingPlatformOutput
}

/// Owner-thread adapter for the used WF sliding brick platform.
final class SM64WfSlidingPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_777366
    static let defaultModel: UInt32 = 0

    private struct State {
        let speed: Float
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WfSlidingPlatformObjectEffectRecord] = []

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
    func spawnPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int32 = 0,
        moveYaw: Int32 = 0,
        behaviorByte: UInt8 = 1,
        initialTimer: Int32 = 0,
        model: UInt32 = SM64WfSlidingPlatformObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64WfSlidingPlatformObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity
        )
        guard attach(id, position: position, faceYaw: faceYaw, moveYaw: moveYaw,
                     behaviorByte: behaviorByte, initialTimer: initialTimer,
                     in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned WF sliding platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        faceYaw: Int32 = 0,
        moveYaw: Int32 = 0,
        behaviorByte: UInt8,
        initialTimer: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, (1...3).contains(behaviorByte),
              initialTimer >= 0 else { return false }
        let initialization = SM64WfSlidingPlatformBehavior.initialize(
            position: SM64WfSlidingPlatformPosition(x: position.x, y: position.y, z: position.z),
            faceYaw: faceYaw,
            moveYaw: moveYaw,
            behaviorByte: behaviorByte,
            initialTimer: initialTimer
        )
        registered.insert(id)
        states[id] = State(speed: initialization.speed)
        return pool.mutate(id) { record in
            record.position.x = initialization.positionX
            record.position.y = position.y
            record.position.z = position.z
            record.homePosition.x = initialization.homeX
            record.homePosition.y = position.y
            record.homePosition.z = position.z
            record.faceAngles.yaw = initialization.faceYaw
            record.moveAngles.yaw = moveYaw
            record.timer = initialization.timer
            record.behaviorParams2ndByte = Int32(behaviorByte)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WfSlidingPlatformObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id),
              let platformState = states[id] else { return nil }
        let output = SM64WfSlidingPlatformBehavior.update(
            SM64WfSlidingPlatformInput(
                action: record.action,
                timer: record.timer,
                positionX: record.position.x,
                positionY: record.position.y,
                positionZ: record.position.z,
                homeX: record.homePosition.x,
                forwardVelocity: record.forwardVelocity,
                faceYaw: record.faceAngles.yaw,
                moveYaw: record.moveAngles.yaw,
                speed: platformState.speed
            )
        )
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.position.x = output.positionX
            next.position.y = output.positionY
            next.position.z = output.positionZ
            next.forwardVelocity = output.forwardVelocity
            next.moveAngles.yaw = output.moveYaw
            next.velocity.x = output.velocityX
            next.velocity.z = output.velocityZ
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64WfSlidingPlatformObjectEffectRecord(objectID: id, output: output)
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
