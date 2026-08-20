import Foundation

struct SM64FireSpitterObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64FireSpitterOutput; let spawnedFlame: SM64ObjectID? }

final class SM64FireSpitterObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_667370
    private struct State { var moveYaw: Int32; var action: Int32; var timer: Int32; var scale: Float; var scaleVelocity: Float; let distanceToMario: Float; let targetYaw: Int32; let inWater: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64FireSpitterObjectEffectRecord] = []
    private let smallFlameBridge: SM64SmallPiranhaFlameObjectBridge
    init(smallFlameBridge: SM64SmallPiranhaFlameObjectBridge) { self.smallFlameBridge = smallFlameBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnSpitter(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, distanceToMario: Float = .greatestFiniteMagnitude, targetYaw: Int32 = 0, inWater: Bool = false) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, distanceToMario: distanceToMario, targetYaw: targetYaw, inWater: inWater, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned fire spitter could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, distanceToMario: Float, targetYaw: Int32, inWater: Bool, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }; states[id] = State(moveYaw: 0, action: 0, timer: 0, scale: 1, scaleVelocity: 0, distanceToMario: distanceToMario, targetYaw: targetYaw, inWater: inWater); return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.scale = .init(x: 1, y: 1, z: 1); record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64FireSpitterObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64FireSpitterBehavior.update(.init(position: record.position, moveYaw: state.moveYaw, action: state.action, timer: state.timer, scale: state.scale, scaleVelocity: state.scaleVelocity, distanceToMario: state.distanceToMario, targetYaw: state.targetYaw, inWater: state.inWater))
        state.moveYaw = output.moveYaw; state.action = output.action; state.timer = output.timer; state.scale = output.scale; state.scaleVelocity = output.scaleVelocity; states[id] = state
        var child: SM64ObjectID?
        if output.spawnSmallFlame { child = try? smallFlameBridge.spawnFlame(in: engineState, position: output.position, mode: .projectile, moveYaw: output.moveYaw, movePitch: output.smallFlamePitch, currentSpeed: output.smallFlameSpeedStart, targetSpeed: output.smallFlameSpeedEnd, targetYaw: output.moveYaw, scale: 5, flyGuySpawnTimer: 8) }
        _ = engineState.objects.mutate(id) { next in next.moveAngles.yaw = output.moveYaw; next.action = output.action; next.timer = output.timer; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64FireSpitterObjectEffectRecord(objectID: id, output: output, spawnedFlame: child); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
