import Foundation

struct SM64BreakBoxTriangleObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64BreakBoxTriangleOutput }

final class SM64BreakBoxTriangleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_627472
    private struct State { let angleVelocityPitch: Int32; let angleVelocityYaw: Int32; let angleVelocityRoll: Int32; let gravity: Float; let forwardVelocity: Float; var velocityY: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BreakBoxTriangleObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawn(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, facePitch: Int32 = 0, faceYaw: Int32 = 0, faceRoll: Int32 = 0, angleVelocityPitch: Int32 = 0x100, angleVelocityYaw: Int32 = 0x100, angleVelocityRoll: Int32 = 0x100, forwardVelocity: Float = 5, velocityY: Float = 15, gravity: Float = -1) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, moveYaw: moveYaw, facePitch: facePitch, faceYaw: faceYaw, faceRoll: faceRoll, angleVelocityPitch: angleVelocityPitch, angleVelocityYaw: angleVelocityYaw, angleVelocityRoll: angleVelocityRoll, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned break-box triangle could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, moveYaw: Int32, facePitch: Int32, faceYaw: Int32, faceRoll: Int32, angleVelocityPitch: Int32, angleVelocityYaw: Int32, angleVelocityRoll: Int32, forwardVelocity: Float, velocityY: Float, gravity: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(angleVelocityPitch: angleVelocityPitch, angleVelocityYaw: angleVelocityYaw, angleVelocityRoll: angleVelocityRoll, gravity: gravity, forwardVelocity: forwardVelocity, velocityY: velocityY)
        return pool.mutate(id) { record in record.position = position; record.moveAngles.yaw = moveYaw; record.faceAngles.pitch = facePitch; record.faceAngles.yaw = faceYaw; record.faceAngles.roll = faceRoll; record.forwardVelocity = forwardVelocity; record.velocity.y = velocityY; record.gravity = gravity; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64BreakBoxTriangleObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64BreakBoxTriangleBehavior.update(.init(position: record.position, moveYaw: record.moveAngles.yaw, facePitch: record.faceAngles.pitch, faceYaw: record.faceAngles.yaw, faceRoll: record.faceAngles.roll, angleVelocityPitch: state.angleVelocityPitch, angleVelocityYaw: state.angleVelocityYaw, angleVelocityRoll: state.angleVelocityRoll, forwardVelocity: state.forwardVelocity, velocityY: state.velocityY, gravity: state.gravity, timer: record.timer))
        state.velocityY = output.velocityY; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.faceAngles.pitch = output.facePitch; next.faceAngles.yaw = output.faceYaw; next.faceAngles.roll = output.faceRoll; next.velocity.y = output.velocityY; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64BreakBoxTriangleObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
