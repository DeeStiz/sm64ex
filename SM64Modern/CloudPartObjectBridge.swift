import Foundation

struct SM64CloudPartObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64CloudPartOutput }

final class SM64CloudPartObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_636C70
    private struct State { var parentCenterX: Float; var parentCenterY: Float; var parentPositionZ: Float; var parentFaceYaw: Int32; var parentScale: Float; let partIndex: Int32; var parentUnloading: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64CloudPartObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnPart(in engineState: SM64SwiftEngineState, parentCenterX: Float = 0, parentCenterY: Float = 0, parentPositionZ: Float = 0, parentFaceYaw: Int32 = 0, parentScale: Float = 1, partIndex: Int32 = 0, parentUnloading: Bool = false, parent: SM64ObjectID? = nil) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity, parent: parent)
        guard attach(id, parentCenterX: parentCenterX, parentCenterY: parentCenterY, parentPositionZ: parentPositionZ, parentFaceYaw: parentFaceYaw, parentScale: parentScale, partIndex: partIndex, parentUnloading: parentUnloading, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned cloud part could not attach") }
        return id
    }

    @discardableResult
    func updateParentState(_ id: SM64ObjectID, centerX: Float, centerY: Float, positionZ: Float, faceYaw: Int32, scale: Float, unloading: Bool) -> Bool {
        guard var state = states[id] else { return false }
        state.parentCenterX = centerX; state.parentCenterY = centerY; state.parentPositionZ = positionZ; state.parentFaceYaw = faceYaw; state.parentScale = scale; state.parentUnloading = unloading
        states[id] = state
        return true
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, parentCenterX: Float, parentCenterY: Float, parentPositionZ: Float, parentFaceYaw: Int32, parentScale: Float, partIndex: Int32, parentUnloading: Bool, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(parentCenterX: parentCenterX, parentCenterY: parentCenterY, parentPositionZ: parentPositionZ, parentFaceYaw: parentFaceYaw, parentScale: parentScale, partIndex: partIndex, parentUnloading: parentUnloading)
        return pool.mutate(id) { record in record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64CloudPartObjectEffectRecord? {
        guard let state = states[id], engineState.objects.record(for: id) != nil else { return nil }
        let output = SM64CloudPartBehavior.update(.init(parentCenterX: state.parentCenterX, parentCenterY: state.parentCenterY, parentPositionZ: state.parentPositionZ, parentFaceYaw: state.parentFaceYaw, parentScale: state.parentScale, partIndex: state.partIndex, globalFrame: engineState.globals.frame, parentUnloading: state.parentUnloading))
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.faceAngles.yaw = output.faceYaw; next.scale = .init(x: output.scaleX, y: output.scaleY, z: output.scaleZ); next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64CloudPartObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
