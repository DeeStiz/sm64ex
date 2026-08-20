import Foundation

struct SM64YellowBackgroundMenuObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64YellowBackgroundMenuOutput
}

final class SM64YellowBackgroundMenuObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_79626D
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64YellowBackgroundMenuObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { registered.sorted { lhs, rhs in lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in
            record.position = position
            record.homePosition = position
            record.faceAngles.yaw = -0x8000
            record.scale = .init(x: 9, y: 9, z: 9)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned yellow menu background could not attach")
        }
        registered.insert(id)
        return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64YellowBackgroundMenuBehavior.update(.init(timer: record.timer))
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer
            next.faceAngles.yaw = output.faceAngleYaw
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
