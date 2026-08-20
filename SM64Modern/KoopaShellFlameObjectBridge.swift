import Foundation

struct SM64KoopaShellFlameObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64KoopaShellFlameOutput }

final class SM64KoopaShellFlameObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6B7366
    private struct State { let forwardVelocity: Float; let gravity: Float; let initialOffset: SM64ObjectVector3; let initialYaw: Int32; let initialVelocityY: Float; let initialAnimationState: Int32; var moveYaw: Int32; var velocityY: Float; var scale: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64KoopaShellFlameObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, forwardVelocity: Float = 4, gravity: Float = -4, initialOffset: SM64ObjectVector3 = .zero, initialYaw: Int32 = 0, initialVelocityY: Float = 0, initialAnimationState: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, forwardVelocity: forwardVelocity, gravity: gravity, initialOffset: initialOffset, initialYaw: initialYaw, initialVelocityY: initialVelocityY, initialAnimationState: initialAnimationState, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Koopa shell flame could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, forwardVelocity: Float, gravity: Float, initialOffset: SM64ObjectVector3, initialYaw: Int32, initialVelocityY: Float, initialAnimationState: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(forwardVelocity: forwardVelocity, gravity: gravity, initialOffset: initialOffset, initialYaw: initialYaw, initialVelocityY: initialVelocityY, initialAnimationState: initialAnimationState, moveYaw: initialYaw, velocityY: initialVelocityY, scale: 4)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = initialYaw; record.forwardVelocity = forwardVelocity; record.velocity.y = initialVelocityY; record.gravity = gravity; record.scale = .init(x: 4, y: 4, z: 4); record.interactionType = 1; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64KoopaShellFlameObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64KoopaShellFlameBehavior.update(.init(position: record.position, moveYaw: state.moveYaw, forwardVelocity: state.forwardVelocity, velocityY: state.velocityY, gravity: state.gravity, scale: state.scale, timer: record.timer, animationState: record.animationState, initialOffset: state.initialOffset, initialYaw: state.initialYaw, initialVelocityY: state.initialVelocityY, initialAnimationState: state.initialAnimationState, floorBelowPosition: record.floorHeight > record.position.y))
        state.moveYaw = output.moveYaw; state.velocityY = output.velocityY; state.scale = output.scale; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.moveAngles.yaw = output.moveYaw; next.velocity.y = output.velocityY; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.animationState = output.animationState; next.timer &+= 1; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64KoopaShellFlameObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
