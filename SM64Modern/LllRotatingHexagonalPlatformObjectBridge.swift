import Foundation

struct SM64LllRotatingHexagonalPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64LllRotatingHexagonalPlatformOutput
}

/// Owner-thread adapter for the fixed-step LLL rotating hexagonal platform.
final class SM64LllRotatingHexagonalPlatformObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6C6878
    static let defaultModel: UInt32 = 0
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64LllRotatingHexagonalPlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { registered.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPlatform(in engineState: SM64SwiftEngineState, moveYaw: Int32 = 0,
                      model: UInt32 = SM64LllRotatingHexagonalPlatformObjectBridge.defaultModel) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, model: model, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, moveYaw: moveYaw, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned LLL rotating hexagonal platform could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, moveYaw: Int32 = 0, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        registered.insert(id)
        return pool.mutate(id) { record in
            record.moveAngles.yaw = moveYaw
            record.faceAngles.yaw = moveYaw
            record.angleVelocity.yaw = 0x100
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64LllRotatingHexagonalPlatformObjectEffectRecord? {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64LllRotatingHexagonalPlatformBehavior.update(SM64LllRotatingHexagonalPlatformInput(moveYaw: record.moveAngles.yaw))
        _ = engineState.objects.mutate(id) { next in
            next.moveAngles.yaw = output.moveYaw; next.faceAngles.yaw = output.faceYaw; next.angleVelocity.yaw = output.angleVelocityYaw
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64LllRotatingHexagonalPlatformObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
