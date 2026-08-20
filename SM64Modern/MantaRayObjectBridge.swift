import Foundation

struct SM64MantaRayObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64MantaRayOutput; let spawnedRing: SM64ObjectID? }

final class SM64MantaRayObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6D6E74
    private let ringBridge: SM64MantaRayWaterRingObjectBridge
    private struct State { var trajectoryIndex: Int; var ringsCollected: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64MantaRayObjectEffectRecord] = []
    init(ringBridge: SM64MantaRayWaterRingObjectBridge) { self.ringBridge = ringBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in record.position = position; record.homePosition = position; record.scale = .init(x: 2.5, y: 2.5, z: 2.5); record.hitboxRadius = 210; record.hitboxHeight = 60; record.hurtboxRadius = 200; record.hurtboxHeight = 50; record.interactionType = 1; record.health = 3; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Manta Ray could not attach") }
        states[id] = State(trajectoryIndex: 0, ringsCollected: 0)
        return id
    }

    @discardableResult
    func setRingsCollected(_ value: Int32, for id: SM64ObjectID) -> Bool { guard var state = states[id] else { return false }; state.ringsCollected = value; states[id] = state; return true }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64MantaRayBehavior.update(.init(action: record.action, timer: record.timer, position: record.position, moveYaw: record.moveAngles.yaw, movePitch: record.moveAngles.pitch, faceRoll: record.faceAngles.roll, trajectoryIndex: state.trajectoryIndex, ringsCollected: state.ringsCollected))
        state.trajectoryIndex = output.trajectoryIndex; states[id] = state
        var child: SM64ObjectID?
        if output.spawnRing { child = try? ringBridge.spawnRing(in: engineState, position: output.ringPosition) }
        _ = engineState.objects.mutate(id) { next in next.action = output.action; next.timer = output.timer; next.position = output.position; next.moveAngles.yaw = output.moveYaw; next.moveAngles.pitch = output.movePitch; next.faceAngles.roll = output.faceRoll; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        effectLog.append(.init(objectID: id, output: output, spawnedRing: child)); return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
