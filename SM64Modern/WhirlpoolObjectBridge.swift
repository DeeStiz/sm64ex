import Foundation

struct SM64WhirlpoolObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64WhirlpoolOutput }

final class SM64WhirlpoolObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_777268
    private struct State { let initialFacePitch: Int32; let initialFaceRoll: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WhirlpoolObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, distanceToMario: Float = 10_000, facePitch: Int32 = 0, faceRoll: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .polelike, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.distanceToMario = distanceToMario; record.hitboxRadius = 200; record.hitboxHeight = 500; record.interactionType = 1 << 24; record.faceAngles.pitch = facePitch; record.faceAngles.roll = faceRoll; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned whirlpool could not attach") }
        states[id] = State(initialFacePitch: facePitch, initialFaceRoll: faceRoll)
        return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64WhirlpoolBehavior.update(.init(distanceToMario: record.distanceToMario, position: record.position, initialFacePitch: state.initialFacePitch, initialFaceRoll: state.initialFaceRoll, facePitch: record.faceAngles.pitch, faceRoll: record.faceAngles.roll, faceYaw: record.faceAngles.yaw, timer: record.timer))
        _ = engineState.objects.mutate(id) { next in next.timer = output.timer; next.faceAngles.yaw = output.faceYaw; next.graphFlags = output.visible ? next.graphFlags & ~UInt16(0x10) : next.graphFlags | UInt16(0x10); next.hitboxRadius = 200; next.hitboxHeight = 500; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output)); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
