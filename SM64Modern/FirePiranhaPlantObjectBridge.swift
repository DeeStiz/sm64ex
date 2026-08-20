import Foundation

struct SM64FirePiranhaPlantObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64FirePiranhaPlantOutput; let spawnedFlame: SM64ObjectID? }

final class SM64FirePiranhaPlantObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_667070
    private struct State { let neutralScale: Float; let behaviorVariant: Int32; var action: SM64FirePiranhaPlantAction; var scale: Float; var timer: Int32; var moveYaw: Int32; var active: Bool; var activeCount: Int32; var health: Int32; var deathSpinTimer: Int32; var deathSpinVelocity: Float; var animationFrame: Int32; var killedCount: Int32 }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64FirePiranhaPlantObjectEffectRecord] = []
    private let flameBridge: SM64SmallPiranhaFlameObjectBridge
    init(flameBridge: SM64SmallPiranhaFlameObjectBridge) { self.flameBridge = flameBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnPlant(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorVariant: Int32 = 0, distanceToMario: Float = .greatestFiniteMagnitude) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        let neutral: Float = behaviorVariant == 0 ? 0.5 : 2
        guard attach(id, position: position, neutralScale: neutral, behaviorVariant: behaviorVariant, distanceToMario: distanceToMario, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned fire Piranha Plant could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, neutralScale: Float, behaviorVariant: Int32, distanceToMario: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(neutralScale: neutralScale, behaviorVariant: behaviorVariant, action: .hide, scale: 0, timer: 0, moveYaw: 0, active: false, activeCount: 0, health: behaviorVariant == 0 ? 0 : 1, deathSpinTimer: 0, deathSpinVelocity: 0, animationFrame: 0, killedCount: 0)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.distanceToMario = distanceToMario; record.interactionType = 1; record.hitboxRadius = 80; record.hitboxHeight = 160; record.hurtboxRadius = 50; record.hurtboxHeight = 150; record.intangibleTimer = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64FirePiranhaPlantObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let action = SM64FirePiranhaPlantAction(rawValue: record.action) ?? state.action
        let output = SM64FirePiranhaPlantBehavior.update(.init(neutralScale: state.neutralScale, scale: state.scale, action: action, timer: record.timer, moveYaw: state.moveYaw, angleToMario: record.angleToMario, distanceToMario: record.distanceToMario, active: state.active, activePlantCount: state.activeCount, health: state.health, behaviorVariant: state.behaviorVariant, deathSpinTimer: state.deathSpinTimer, deathSpinVelocity: state.deathSpinVelocity, animationFrame: state.animationFrame, renderingEnabled: true, nearAnimationEnd: false, attacked: record.interactionStatus != 0, killedCount: state.killedCount))
        state.action = output.action; state.scale = output.scale; state.timer = output.timer; state.moveYaw = output.moveYaw; state.active = output.active; state.activeCount = output.activePlantCount; state.health = output.health; state.deathSpinTimer = output.deathSpinTimer; state.deathSpinVelocity = output.deathSpinVelocity; state.animationFrame = (state.animationFrame + 1) % 60; state.killedCount = output.killedCount; states[id] = state
        var child: SM64ObjectID?
        if output.spawnFlame { child = try? flameBridge.spawnFlame(in: engineState, position: record.position, mode: .projectile, moveYaw: output.moveYaw, movePitch: 0x1000, currentSpeed: 20, targetSpeed: 15, targetYaw: output.moveYaw, scale: 2.5) }
        _ = engineState.objects.mutate(id) { next in next.moveAngles.yaw = output.moveYaw; next.action = output.action.rawValue; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.interactionStatus = 0; next.timer = output.timer; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64FirePiranhaPlantObjectEffectRecord(objectID: id, output: output, spawnedFlame: child); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
