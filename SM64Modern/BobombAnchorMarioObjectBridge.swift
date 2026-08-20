import Foundation

struct SM64BobombAnchorMarioObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BobombAnchorMarioOutput
}

final class SM64BobombAnchorMarioObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_62616D

    private var parents: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64BobombAnchorMarioObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        parents.keys.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnAnchor(in engineState: SM64SwiftEngineState, parent: SM64ObjectID) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity, parent: parent)
        guard attach(id, parent: parent, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bob-omb Mario anchor could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, parent: SM64ObjectID, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else { return false }
        parents[id] = parent
        return pool.mutate(id) { record in
            record.parentRelativePosition = .init(x: 100, y: 0, z: 150)
            record.objectFlags |= SM64ObjectScheduler.objectFlagTransformRelativeToParent
                | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let parentID = parents[id], let parent = engineState.objects.record(for: parentID), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64BobombAnchorMarioBehavior.update(.init(
            parentMoveYaw: parent.moveAngles.yaw,
            parentThrowState: parent.action,
            parentActive: parent.activeFlags & SM64ObjectPool.activeFlagActive != 0
        ))
        _ = engineState.objects.mutate(id) { next in
            next.parentRelativePosition = output.parentRelativePosition
            next.moveAngles.yaw = output.moveYaw
            next.faceAngles.yaw = output.moveYaw
            next.objectFlags |= SM64ObjectScheduler.objectFlagTransformRelativeToParent
                | SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        _ = record
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { parents.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
