import Foundation

struct SM64WfBreakableWallObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WfBreakableWallOutput
}

final class SM64WfBreakableWallObjectBridge {
    static let leftBehaviorIdentity: UInt64 = 0x6268_765F_77626C
    static let rightBehaviorIdentity: UInt64 = 0x6268_765F_776272
    static let interactionType: UInt32 = 8

    private struct State: Sendable {
        let rightVariant: Bool
        var marioShotFromCannon: Bool
        var collidedWithMario: Bool
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WfBreakableWallObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        rightVariant: Bool,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let identity = rightVariant ? Self.rightBehaviorIdentity : Self.leftBehaviorIdentity
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: identity)
        guard engineState.objects.mutate(id, { record in
            record.position = position
            record.homePosition = position
            record.hitboxRadius = 300
            record.hitboxHeight = 400
            record.interactionType = 0
            record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned WF breakable wall could not attach")
        }
        states[id] = State(rightVariant: rightVariant, marioShotFromCannon: false, collidedWithMario: false)
        return id
    }

    @discardableResult
    func setInput(marioShotFromCannon: Bool, collidedWithMario: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.marioShotFromCannon = marioShotFromCannon
        state.collidedWithMario = collidedWithMario
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id] else { return false }
        let output = SM64WfBreakableWallBehavior.update(.init(
            marioShotFromCannon: state.marioShotFromCannon,
            collidedWithMario: state.collidedWithMario,
            rightVariant: state.rightVariant
        ))
        states[id] = State(rightVariant: state.rightVariant, marioShotFromCannon: false, collidedWithMario: false)
        _ = engineState.objects.mutate(id) { next in
            next.intangibleTimer = output.tangible ? -1 : 1
            next.interactionType = output.interactionType
            next.damageOrCoinValue = output.damageOrCoinValue
            if output.exploded { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
