import Foundation

struct SM64LllRotatingHexFlameObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let parentID: SM64ObjectID
    let output: SM64LllRotatingHexFlameOutput
}

/// Owner-thread bridge for parent-relative LLL rotating flame children.
final class SM64LllRotatingHexFlameObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6C666C
    static let defaultModel: UInt32 = 0

    private struct State {
        let parentID: SM64ObjectID
        let leftOffset: Float
        let forwardOffset: Float
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64LllRotatingHexFlameObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnFlame(in engineState: SM64SwiftEngineState, parent: SM64ObjectID,
                   leftOffset: Float = 0, forwardOffset: Float = 0,
                   model: UInt32 = SM64LllRotatingHexFlameObjectBridge.defaultModel) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, model: model,
                                             behaviorIdentity: Self.defaultBehaviorIdentity,
                                             parent: parent)
        guard attach(id, parent: parent, leftOffset: leftOffset, forwardOffset: forwardOffset,
                     in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned LLL flame could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, parent: SM64ObjectID, leftOffset: Float,
                forwardOffset: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil,
              leftOffset.isFinite, forwardOffset.isFinite else { return false }
        states[id] = State(parentID: parent, leftOffset: leftOffset, forwardOffset: forwardOffset)
        return pool.mutate(id) { record in
            record.parent = parent
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState)
        -> SM64LllRotatingHexFlameObjectEffectRecord? {
        guard let flame = states[id], let parent = engineState.objects.record(for: flame.parentID),
              let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64LllRotatingHexFlameBehavior.update(
            SM64LllRotatingHexFlameInput(
                parentPosition: parent.position,
                parentMoveYaw: Int16(truncatingIfNeeded: parent.moveAngles.yaw),
                parentAction: parent.action,
                leftOffset: flame.leftOffset,
                forwardOffset: flame.forwardOffset,
                previousPosition: record.position
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position; next.velocity = output.velocity
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        let effect = SM64LllRotatingHexFlameObjectEffectRecord(objectID: id, parentID: flame.parentID, output: output)
        effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
