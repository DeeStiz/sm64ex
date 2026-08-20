import Foundation

struct SM64VolcanoFlamesObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64VolcanoFlamesOutput }

final class SM64VolcanoFlamesObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_76666C
    private struct State { let moveYaw: Int32; let forwardVelocity: Float; let gravity: Float; var velocityY: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64VolcanoFlamesObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnFlame(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, forwardVelocity: Float = 0, velocityY: Float = 0, gravity: Float = -4) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned volcano flame could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, moveYaw: Int32, forwardVelocity: Float, velocityY: Float, gravity: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(moveYaw: moveYaw, forwardVelocity: forwardVelocity, gravity: gravity, velocityY: velocityY)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.forwardVelocity = forwardVelocity; record.velocity.y = velocityY; record.gravity = gravity; record.interactionType = 1; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64VolcanoFlamesObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64VolcanoFlamesBehavior.update(.init(position: record.position, moveYaw: state.moveYaw, forwardVelocity: state.forwardVelocity, velocityY: state.velocityY, gravity: state.gravity, timer: record.timer, animationState: record.animationState, landedOrWaterSurface: record.moveFlags & 0x0000_0003 != 0))
        state.velocityY = output.velocityY; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.velocity.y = output.velocityY; next.animationState = output.animationState; next.timer &+= 1; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64VolcanoFlamesObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
