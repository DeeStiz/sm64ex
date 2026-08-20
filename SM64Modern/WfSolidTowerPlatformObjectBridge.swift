import Foundation

struct SM64WfSolidTowerPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let parentID: SM64ObjectID
    let output: SM64WfSolidTowerPlatformOutput
}

/// Owner-thread bridge for the parent-owned solid tower child.
final class SM64WfSolidTowerPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_777473
    static let defaultModel: UInt32 = 0

    private var parents: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64WfSolidTowerPlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        parents.keys.sorted {
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
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64WfSolidTowerPlatformObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64WfSolidTowerPlatformObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard attach(id, parent: parent, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned WF solid tower platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil else { return false }
        parents[id] = parent
        return pool.mutate(id) { record in
            record.parent = parent
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WfSolidTowerPlatformObjectEffectRecord? {
        guard let parentID = parents[id],
              engineState.objects.record(for: id) != nil,
              let parent = engineState.objects.record(for: parentID) else { return nil }
        let output = SM64WfSolidTowerPlatformBehavior.update(
            SM64WfSolidTowerPlatformInput(parentAction: parent.action)
        )
        if output.shouldDelete { _ = engineState.objects.markForDeletion(id) }
        let effect = SM64WfSolidTowerPlatformObjectEffectRecord(
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
        for id in registeredIDs {
            guard let parent = parents[id], pool.record(for: id) != nil,
                  pool.record(for: parent) != nil else { remove(id); continue }
        }
    }
}
