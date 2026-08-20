import Foundation

struct SM64SquarishPathMovingObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SquarishPathMovingOutput
}

/// Owner-thread adapter for the four-way BitDW moving platform.
final class SM64SquarishPathMovingObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_737071
    static let defaultModel: UInt32 = 0

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64SquarishPathMovingObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        behaviorByte: Int32 = 0,
        model: UInt32 = SM64SquarishPathMovingObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            model: model,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, position: position, behaviorByte: behaviorByte, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned squarish platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        behaviorByte: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams2ndByte = behaviorByte
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64SquarishPathMovingObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64SquarishPathMovingBehavior.update(.init(
            action: record.action,
            timer: record.timer,
            behaviorByte: record.behaviorParams2ndByte,
            position: record.position,
            moveYaw: record.moveAngles.yaw,
            velocityY: record.velocity.y,
            gravity: record.gravity
        ))
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64SquarishPathMovingObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { registered.remove(id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
