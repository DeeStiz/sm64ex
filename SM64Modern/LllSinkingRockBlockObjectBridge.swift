import Foundation

struct SM64LllSinkingRockBlockObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64LllSinkingRockBlockOutput
}

/// Owner-thread adapter for the LLL sinking rock block.
final class SM64LllSinkingRockBlockObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6C7262
    static let defaultModel: UInt32 = 0

    private var angles: [SM64ObjectID: Int32] = [:]
    private(set) var effectLog: [SM64LllSinkingRockBlockObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        angles.keys.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBlock(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64LllSinkingRockBlockObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64LllSinkingRockBlockObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, model: model,
                                             behaviorIdentity: behaviorIdentity)
        guard attach(id, position: position, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned LLL sinking rock block could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3 = .zero,
                in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        angles[id] = 0
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.graphYOffset = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState)
        -> SM64LllSinkingRockBlockObjectEffectRecord?
    {
        guard let angle = angles[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64LllSinkingRockBlockBehavior.update(
            SM64LllSinkingRockBlockInput(
                oscillationAngle: angle,
                positionY: record.position.y,
                homeY: record.homePosition.y,
                marioOnPlatform: record.platform == id
            )
        )
        angles[id] = output.oscillationAngle
        _ = engineState.objects.mutate(id) { next in
            next.graphYOffset = 0
            next.position.y = output.positionY
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64LllSinkingRockBlockObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { angles.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
