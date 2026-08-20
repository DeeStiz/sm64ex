import Foundation

struct SM64TrackBallObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TrackBallOutput
}

final class SM64TrackBallObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_74726B
    static let defaultModel: UInt32 = 0

    private var baseIndices: [SM64ObjectID: Int32] = [:]
    private(set) var effectLog: [SM64TrackBallObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        baseIndices.keys.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        behaviorByte: Int32,
        parentBaseBallIndex: Int32,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .generalActor,
            model: Self.defaultModel,
            behaviorIdentity: Self.defaultBehaviorIdentity,
            parent: parent
        )
        guard attach(
            id,
            behaviorByte: behaviorByte,
            parentBaseBallIndex: parentBaseBallIndex,
            position: position,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned track ball could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        behaviorByte: Int32,
        parentBaseBallIndex: Int32,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        baseIndices[id] = parentBaseBallIndex
        return pool.mutate(id) { record in
            record.behaviorParams2ndByte = behaviorByte
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let parentBaseBallIndex = baseIndices[id], let record = engineState.objects.record(for: id) else {
            return false
        }
        let output = SM64TrackBallBehavior.update(.init(
            behaviorByte: record.behaviorParams2ndByte,
            parentBaseBallIndex: parentBaseBallIndex
        ))
        _ = engineState.objects.mutate(id) { next in
            if output.shouldDelete { next.activeFlags = 0 }
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { baseIndices.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
