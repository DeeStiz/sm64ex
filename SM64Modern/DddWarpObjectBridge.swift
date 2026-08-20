import Foundation

struct SM64DddWarpObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64DddWarpOutput
}

final class SM64DddWarpObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_646477

    private struct State {
        var paintingBeaten: Bool
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64DddWarpObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnWarp(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        paintingBeaten: Bool = false
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, position: position, paintingBeaten: paintingBeaten, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned DDD warp could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        paintingBeaten: Bool,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(paintingBeaten: paintingBeaten)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.collisionDistance = SM64DddWarpBehavior.collisionDistance
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setPaintingBeaten(_ beaten: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.paintingBeaten = beaten
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64DddWarpObjectEffectRecord? {
        guard let state = states[id], engineState.objects.record(for: id) != nil else {
            return nil
        }
        let output = SM64DddWarpBehavior.update(.init(paintingBeaten: state.paintingBeaten))
        _ = engineState.objects.mutate(id) { next in
            next.collisionDataIdentity = output.collisionDataIdentity
            next.collisionDistance = output.collisionDistance
            next.timer &+= 1
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64DddWarpObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
