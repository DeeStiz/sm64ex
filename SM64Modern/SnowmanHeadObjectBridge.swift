import Foundation

struct SM64SnowmanHeadObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SnowmanHeadOutput
}

final class SM64SnowmanHeadObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_736865

    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64SnowmanHeadObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard engineState.objects.mutate(id, { record in
            record.position = position
            record.homePosition = position
            record.gravity = 5
            record.friction = 0.999
            record.buoyancy = 2
            record.scale = .init(x: 0.7, y: 0.7, z: 0.7)
            record.hitboxRadius = 180
            record.hitboxHeight = 150
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned snowman head could not attach")
        }
        registered.insert(id)
        return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else {
            return false
        }
        let output = SM64SnowmanHeadBehavior.update(.init(
            action: record.action,
            timer: record.timer,
            positionY: record.position.y,
            moveFlags: record.moveFlags,
            dialogTriggered: record.dialogResponse == 1,
            dialogCompleted: record.dialogResponse == 2
        ))
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.position.y = output.positionY
            next.gravity = output.gravity
            next.friction = output.friction
            next.buoyancy = output.buoyancy
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.hitboxRadius = 180
            next.hitboxHeight = 150
            next.dialogResponse = 0
            next.interactionStatus = 0
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
