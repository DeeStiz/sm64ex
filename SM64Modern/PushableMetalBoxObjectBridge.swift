import Foundation

struct SM64PushableMetalBoxObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64PushableMetalBoxOutput
}

/// Owner-thread adapter for `bhvPushableMetalBox`.
final class SM64PushableMetalBoxObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6D626F
    static let defaultModel: UInt32 = 0

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64PushableMetalBoxObjectEffectRecord] = []

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
        model: UInt32 = SM64PushableMetalBoxObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            model: model,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned pushable metal box could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.hitboxRadius = 220
            record.hitboxHeight = 300
            record.hurtboxRadius = 220
            record.hurtboxHeight = 300
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState,
        floorDeltaAhead: Float = 0
    ) -> SM64PushableMetalBoxObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else {
            return nil
        }
        let mario = record.collidedObjects.compactMap { $0 }.first.flatMap {
            engineState.objects.record(for: $0)
        }
        let output = SM64PushableMetalBoxBehavior.update(.init(
            position: record.position,
            moveYaw: record.moveAngles.yaw,
            forwardVelocity: record.forwardVelocity,
            velocityY: record.velocity.y,
            gravity: record.gravity,
            marioCollided: mario != nil,
            marioFlags: mario?.heldState ?? 0,
            boxToMarioYaw: record.angleToMario,
            marioMoveYaw: mario?.moveAngles.yaw ?? 0,
            floorDeltaAhead: floorDeltaAhead
        ))
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.hitboxRadius = output.hitboxRadius
            next.hitboxHeight = output.hitboxHeight
            next.hurtboxRadius = output.hitboxRadius
            next.hurtboxHeight = output.hitboxHeight
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64PushableMetalBoxObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { registered.remove(id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
