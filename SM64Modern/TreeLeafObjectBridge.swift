import Foundation

struct SM64TreeLeafObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TreeLeafOutput
}

final class SM64TreeLeafObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_746C66
    static let snowBehaviorIdentity: UInt64 = 0x6268_765F_74736E

    private struct State {
        let floorHeight: Float
        let prevFrameObjectCount: Int32
        let angleVelocityPitch: Int32
        let angleVelocityRoll: Int32
        let phaseRate: Int32
        var phase: Int32
        var forwardVelocity: Float
        var velocityY: Float
        var scale: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TreeLeafObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnLeaf(in engineState: SM64SwiftEngineState, kind: SM64TreeParticleKind = .leaf, position: SM64ObjectVector3 = .zero, floorHeight: Float = -10_000, moveYaw: Int32 = 0, facePitch: Int32 = 0, faceRoll: Int32 = 0, angleVelocityPitch: Int32 = 0, angleVelocityRoll: Int32 = 0, phase: Int32 = 0, phaseRate: Int32 = 0x800, forwardVelocity: Float = 5, velocityY: Float = 15, scale: Float = 1, prevFrameObjectCount: Int32 = 0) throws -> SM64ObjectID {
        let identity = kind == .leaf ? Self.defaultBehaviorIdentity : Self.snowBehaviorIdentity
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: identity)
        guard attach(id, position: position, floorHeight: floorHeight, moveYaw: moveYaw, facePitch: facePitch, faceRoll: faceRoll, angleVelocityPitch: angleVelocityPitch, angleVelocityRoll: angleVelocityRoll, phase: phase, phaseRate: phaseRate, forwardVelocity: forwardVelocity, velocityY: velocityY, scale: scale, prevFrameObjectCount: prevFrameObjectCount, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned tree particle could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, floorHeight: Float, moveYaw: Int32, facePitch: Int32, faceRoll: Int32, angleVelocityPitch: Int32, angleVelocityRoll: Int32, phase: Int32, phaseRate: Int32, forwardVelocity: Float, velocityY: Float, scale: Float, prevFrameObjectCount: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(floorHeight: floorHeight, prevFrameObjectCount: prevFrameObjectCount, angleVelocityPitch: angleVelocityPitch, angleVelocityRoll: angleVelocityRoll, phaseRate: phaseRate, phase: phase, forwardVelocity: forwardVelocity, velocityY: velocityY, scale: scale)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.faceAngles.pitch = facePitch; record.faceAngles.roll = faceRoll; record.forwardVelocity = forwardVelocity; record.velocity.y = velocityY; record.scale = .init(x: scale, y: scale, z: scale); record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64TreeLeafObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64TreeLeafBehavior.update(.init(position: record.position, floorHeight: state.floorHeight, timer: record.timer, prevFrameObjectCount: state.prevFrameObjectCount, moveYaw: record.moveAngles.yaw, facePitch: record.faceAngles.pitch, faceRoll: record.faceAngles.roll, angleVelocityPitch: state.angleVelocityPitch, angleVelocityRoll: state.angleVelocityRoll, phase: state.phase, phaseRate: state.phaseRate, forwardVelocity: state.forwardVelocity, velocityY: state.velocityY, scale: state.scale))
        state.phase = output.phase; state.forwardVelocity = output.forwardVelocity; state.velocityY = output.velocityY; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.moveAngles.yaw = output.moveYaw; next.faceAngles.pitch = output.facePitch; next.faceAngles.roll = output.faceRoll; next.forwardVelocity = output.forwardVelocity; next.velocity.y = output.velocityY; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64TreeLeafObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
