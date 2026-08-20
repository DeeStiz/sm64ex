import Foundation

struct SM64SmallPiranhaFlameObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64SmallPiranhaFlameOutput; let spawnedChildFlame: SM64ObjectID?; let spawnedFlyGuyFlame: SM64ObjectID? }

final class SM64SmallPiranhaFlameObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_737066
    private struct State { let mode: SM64SmallPiranhaFlameMode; let movePitch: Int32; let targetSpeed: Float; let targetYaw: Int32; let randomScaleJitter: Float; let initialAnimationState: Int32; var moveYaw: Int32; var currentSpeed: Float; var flyGuySpawnTimer: Int32; var distanceTravelled: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64SmallPiranhaFlameObjectEffectRecord] = []
    private let flyGuyBridge: SM64FlyGuyObjectBridge
    init(flyGuyBridge: SM64FlyGuyObjectBridge) { self.flyGuyBridge = flyGuyBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, mode: SM64SmallPiranhaFlameMode = .ephemeral, moveYaw: Int32 = 0, movePitch: Int32 = 0, currentSpeed: Float = 0, targetSpeed: Float = 0, targetYaw: Int32 = 0, scale: Float = 1, randomScaleJitter: Float = 0, initialAnimationState: Int32 = 0, flyGuySpawnTimer: Int32 = 8) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .generalActor, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, mode: mode, moveYaw: moveYaw, movePitch: movePitch, currentSpeed: currentSpeed, targetSpeed: targetSpeed, targetYaw: targetYaw, scale: scale, randomScaleJitter: randomScaleJitter, initialAnimationState: initialAnimationState, flyGuySpawnTimer: flyGuySpawnTimer, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned small Piranha flame could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, mode: SM64SmallPiranhaFlameMode, moveYaw: Int32, movePitch: Int32, currentSpeed: Float, targetSpeed: Float, targetYaw: Int32, scale: Float, randomScaleJitter: Float, initialAnimationState: Int32, flyGuySpawnTimer: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(mode: mode, movePitch: movePitch, targetSpeed: targetSpeed, targetYaw: targetYaw, randomScaleJitter: randomScaleJitter, initialAnimationState: initialAnimationState, moveYaw: moveYaw, currentSpeed: currentSpeed, flyGuySpawnTimer: flyGuySpawnTimer, distanceTravelled: 0)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.moveAngles.pitch = movePitch; record.forwardVelocity = currentSpeed; record.scale = .init(x: scale, y: scale, z: scale); record.interactionType = 1; record.hitboxRadius = 50; record.hitboxHeight = 25; record.hitboxDownOffset = 25; record.intangibleTimer = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64SmallPiranhaFlameObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64SmallPiranhaFlameBehavior.update(.init(mode: state.mode, position: record.position, moveYaw: state.moveYaw, movePitch: state.movePitch, currentSpeed: state.currentSpeed, targetSpeed: state.targetSpeed, targetYaw: state.targetYaw, timer: record.timer, scaleZ: record.scale.z, animationState: record.animationState, graphYOffset: record.graphYOffset, distanceTravelled: state.distanceTravelled, flyGuySpawnTimer: state.flyGuySpawnTimer, flyGuySpawnInterval: 8, randomScaleJitter: state.randomScaleJitter, initialAnimationState: state.initialAnimationState, moveFlags: record.moveFlags))
        state.moveYaw = output.moveYaw; state.currentSpeed = output.currentSpeed; state.distanceTravelled = output.distanceTravelled; state.flyGuySpawnTimer = output.nextFlyGuySpawnTimer; states[id] = state
        var child: SM64ObjectID?
        var flyChild: SM64ObjectID?
        if output.spawnChildFlame && !output.shouldDelete { child = try? spawnFlame(in: engineState, position: output.position, mode: .ephemeral, scale: output.scaleX, randomScaleJitter: 0, initialAnimationState: output.animationState) }
        if output.spawnFlyGuyFlame && !output.shouldDelete { flyChild = try? flyGuyBridge.spawnFlame(in: engineState, position: output.position, parent: id) }
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.moveAngles.yaw = output.moveYaw; next.velocity.y = output.velocityY; next.forwardVelocity = output.currentSpeed; next.scale = .init(x: output.scaleX, y: output.scaleY, z: output.scaleX); next.graphYOffset = output.graphYOffset; next.animationState = output.animationState; next.timer &+= 1; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64SmallPiranhaFlameObjectEffectRecord(objectID: id, output: output, spawnedChildFlame: child, spawnedFlyGuyFlame: flyChild); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
