import Foundation

struct SM64UnusedPoundablePlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64UnusedPoundablePlatformOutput
}

final class SM64UnusedPoundablePlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_757070
    private var groundPounded: [SM64ObjectID: Bool] = [:]
    private(set) var effectLog: [SM64UnusedPoundablePlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        groundPounded.keys.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .surface, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in
            record.position = position
            record.homePosition = position
            record.scale = .init(x: 1.02, y: 1.02, z: 1.02)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned unused poundable platform could not attach")
        }
        groundPounded[id] = false
        return id
    }

    @discardableResult
    func setGroundPounded(_ value: Bool, for id: SM64ObjectID) -> Bool {
        guard groundPounded[id] != nil else { return false }
        groundPounded[id] = value
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let pounded = groundPounded[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64UnusedPoundablePlatformBehavior.update(.init(action: record.action, timer: record.timer, marioGroundPounded: pounded))
        groundPounded[id] = false
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = output.timer
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { groundPounded.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
