import Foundation

struct SM64TweesterSandParticleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TweesterSandParticleOutput
}

final class SM64TweesterSandParticleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_74737031
    private struct State { let initialRandomX: Float; let initialRandomZ: Float; let initialFacePitch: Int32; let initialFaceYaw: Int32; let randomScale: Float; var moveYaw: Int32; var forwardVelocity: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TweesterSandParticleObjectEffectRecord] = []
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnParticle(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, moveYaw: Int32 = 0, forwardVelocity: Float = 0, initialRandomX: Float = 0, initialRandomZ: Float = 0, initialFacePitch: Int32 = 0, initialFaceYaw: Int32 = 0, randomScale: Float = 0, parent: SM64ObjectID? = nil) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity, parent: parent)
        guard attach(id, position: position, moveYaw: moveYaw, forwardVelocity: forwardVelocity, initialRandomX: initialRandomX, initialRandomZ: initialRandomZ, initialFacePitch: initialFacePitch, initialFaceYaw: initialFaceYaw, randomScale: randomScale, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned Tweester sand particle could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, moveYaw: Int32, forwardVelocity: Float, initialRandomX: Float, initialRandomZ: Float, initialFacePitch: Int32, initialFaceYaw: Int32, randomScale: Float, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(initialRandomX: initialRandomX, initialRandomZ: initialRandomZ, initialFacePitch: initialFacePitch, initialFaceYaw: initialFaceYaw, randomScale: randomScale, moveYaw: moveYaw, forwardVelocity: forwardVelocity)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.moveAngles.yaw = moveYaw; record.forwardVelocity = forwardVelocity; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64TweesterSandParticleObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64TweesterSandParticleBehavior.update(.init(position: record.position, moveYaw: state.moveYaw, forwardVelocity: state.forwardVelocity, timer: record.timer, initialRandomX: state.initialRandomX, initialRandomZ: state.initialRandomZ, initialFacePitch: state.initialFacePitch, initialFaceYaw: state.initialFaceYaw, randomScale: state.randomScale))
        state.moveYaw = output.moveYaw; state.forwardVelocity = output.forwardVelocity; states[id] = state
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.moveAngles.yaw = output.moveYaw; next.forwardVelocity = output.forwardVelocity; next.faceAngles.pitch = output.facePitch; next.faceAngles.yaw = output.faceYaw; next.scale = .init(x: output.scale, y: output.scale, z: output.scale); next.timer &+= 1; if output.shouldDelete { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64TweesterSandParticleObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
