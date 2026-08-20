import Foundation

struct SM64BlueBowserFlameObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BlueBowserFlameOutput; let spawnedChildren: [SM64ObjectID] }

final class SM64BlueBowserFlameObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626266
    private struct State { let moveYaw: Int32; let forwardVelocity: Float; let gravity: Float; let behaviorParam: Int32; let phase: Int32; let globalTimer: Int32; let initialOffset: SM64ObjectVector3; let initialAnimationState: Int32; var velocityY: Float; var scale: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BlueBowserFlameObjectEffectRecord] = []
    private let floatingBridge: SM64FlameFloatingLandingObjectBridge
    init(floatingBridge: SM64FlameFloatingLandingObjectBridge) { self.floatingBridge = floatingBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, forwardVelocity: Float = 35, velocityY: Float = 7, gravity: Float = 1, behaviorParam: Int32 = 0, scale: Float = 3, phase: Int32 = 0, globalTimer: Int32 = 0, initialOffset: SM64ObjectVector3 = .zero, initialAnimationState: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, behaviorParam: behaviorParam, scale: scale, phase: phase, globalTimer: globalTimer, initialOffset: initialOffset, initialAnimationState: initialAnimationState, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned blue Bowser flame could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, moveYaw: Int32, forwardVelocity: Float, velocityY: Float, gravity: Float, behaviorParam: Int32, scale: Float, phase: Int32, globalTimer: Int32, initialOffset: SM64ObjectVector3, initialAnimationState: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(moveYaw: moveYaw, forwardVelocity: forwardVelocity, gravity: gravity, behaviorParam: behaviorParam, phase: phase, globalTimer: globalTimer, initialOffset: initialOffset, initialAnimationState: initialAnimationState, velocityY: velocityY, scale: scale)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.forwardVelocity = forwardVelocity; record.velocity.y = velocityY; record.gravity = gravity; record.behaviorParams2ndByte = behaviorParam; record.scale = .init(x: scale, y: scale, z: scale); record.interactionType = 1; record.hitboxRadius = 50; record.hitboxHeight = 25; record.hitboxDownOffset = 25; record.intangibleTimer = 0; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64BlueBowserFlameObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64BlueBowserFlameBehavior.update(.init(position: record.position, moveYaw: state.moveYaw, forwardVelocity: state.forwardVelocity, velocityY: state.velocityY, gravity: state.gravity, scale: state.scale, timer: record.timer, animationState: record.animationState, behaviorParam: state.behaviorParam, phase: state.phase, globalTimer: state.globalTimer, initialOffset: state.initialOffset, initialAnimationState: state.initialAnimationState))
        state.velocityY = output.velocityY; state.scale = output.scale; states[id] = state
        var children: [SM64ObjectID] = []
        if output.spawnCount > 0 { for _ in 0..<Int(output.spawnCount) { if let child = try? floatingBridge.spawnFlame(in: engineState, position: output.position, behaviorParam: state.behaviorParam, scale: output.childScale) { children.append(child) } } }
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.velocity.y = output.velocityY; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.animationState = output.animationState; next.timer &+= 1; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64BlueBowserFlameObjectEffectRecord(objectID: id, output: output, spawnedChildren: children); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
