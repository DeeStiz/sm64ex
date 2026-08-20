import Foundation

struct SM64FlameFloatingLandingObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64FlameFloatingLandingOutput
    let spawnedChild: SM64ObjectID?
}

final class SM64FlameFloatingLandingObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_666C6C
    private struct State { let moveYaw: Int32; let forwardVelocity: Float; let gravity: Float; let phase: Int32; let globalTimer: Int32; let behaviorParam: Int32; let scale: Float; var velocityY: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64FlameFloatingLandingObjectEffectRecord] = []
    private let bowserFlameBridge: SM64BowserFlameObjectBridge
    private let blueGroupBridge: SM64BlueFlamesGroupObjectBridge
    init(bowserFlameBridge: SM64BowserFlameObjectBridge, blueGroupBridge: SM64BlueFlamesGroupObjectBridge) { self.bowserFlameBridge = bowserFlameBridge; self.blueGroupBridge = blueGroupBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, behaviorParam: Int32 = 0, scale: Float = 5, moveYaw: Int32 = 0, forwardVelocity: Float = 0, velocityY: Float = 0, gravity: Float = -1, phase: Int32 = 0, globalTimer: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, behaviorParam: behaviorParam, scale: scale, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, phase: phase, globalTimer: globalTimer, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned floating flame could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, behaviorParam: Int32, scale: Float, moveYaw: Int32, forwardVelocity: Float, velocityY: Float, gravity: Float, phase: Int32, globalTimer: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(moveYaw: moveYaw, forwardVelocity: forwardVelocity, gravity: gravity, phase: phase, globalTimer: globalTimer, behaviorParam: behaviorParam, scale: scale, velocityY: velocityY)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.forwardVelocity = forwardVelocity; record.velocity.y = velocityY; record.gravity = gravity; record.scale = .init(x: scale, y: scale, z: scale); record.behaviorParams2ndByte = behaviorParam; record.interactionType = 1; record.hitboxRadius = 50; record.hitboxHeight = 25; record.hitboxDownOffset = 25; record.intangibleTimer = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64FlameFloatingLandingObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64FlameFloatingLandingBehavior.update(.init(position: record.position, moveYaw: state.moveYaw, forwardVelocity: state.forwardVelocity, velocityY: state.velocityY, gravity: state.gravity, timer: record.timer, animationState: record.animationState, phase: state.phase, globalTimer: state.globalTimer, behaviorParam: state.behaviorParam, scale: state.scale, landed: record.moveFlags & 1 != 0, floorHazard: record.floorType == 1 || record.floorType == 10))
        state.velocityY = output.velocityY; states[id] = state
        var child: SM64ObjectID?
        if output.spawnBurningOut { child = try? bowserFlameBridge.spawnFlame(in: engineState, kind: .largeBurningOut, position: output.position) }
        if output.spawnBlueGroup { child = try? blueGroupBridge.spawnGroup(in: engineState, position: output.position, scale: 5) }
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.velocity.y = output.velocityY; next.graphYOffset = output.graphYOffset; next.animationState = output.animationState; next.timer &+= 1; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64FlameFloatingLandingObjectEffectRecord(objectID: id, output: output, spawnedChild: child); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
