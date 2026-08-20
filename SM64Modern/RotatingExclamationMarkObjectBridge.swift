import Foundation

struct SM64RotatingExclamationMarkObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let parentID: SM64ObjectID
    let output: SM64RotatingExclamationMarkOutput
}

final class SM64RotatingExclamationMarkObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_65786D

    private var parents: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64RotatingExclamationMarkObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        parents.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnMark(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        moveYaw: Int32 = 0
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity,
            parent: parent
        )
        guard attach(id, parent: parent, moveYaw: moveYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned rotating exclamation mark could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        moveYaw: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else { return false }
        parents[id] = parent
        return pool.mutate(id) { record in
            record.parent = parent
            record.moveAngles.yaw = moveYaw
            record.faceAngles.yaw = moveYaw
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64RotatingExclamationMarkObjectEffectRecord? {
        guard let parentID = parents[id],
              let parent = engineState.objects.record(for: parentID),
              let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64RotatingExclamationMarkBehavior.update(
            SM64RotatingExclamationMarkInput(
                parentAction: parent.action,
                moveYaw: record.moveAngles.yaw
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.moveAngles.yaw = output.moveYaw
            next.faceAngles.yaw = output.moveYaw
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        let effect = SM64RotatingExclamationMarkObjectEffectRecord(
            objectID: id,
            parentID: parentID,
            output: output
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { parents.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
