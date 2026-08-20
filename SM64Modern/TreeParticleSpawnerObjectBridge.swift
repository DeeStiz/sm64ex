import Foundation

struct SM64TreeParticleSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TreeParticleSpawnerOutput
    let spawnedChild: SM64ObjectID?
}

final class SM64TreeParticleSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6C7073
    private struct State {
        let particleFlag: UInt32
        let snowMode: Bool
        let spawnDecision: Float
        let randomScale: Float
        let randomYaw: Int32
        let randomForwardUnit: Float
        let randomVerticalUnit: Float
        let randomFacePitch: Int32
        let randomFaceRoll: Int32
    }
    private let treeBridge: SM64TreeLeafObjectBridge
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TreeParticleSpawnerObjectEffectRecord] = []
    init(treeBridge: SM64TreeLeafObjectBridge) { self.treeBridge = treeBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, activeParticleFlags: UInt32 = 0, particleFlag: UInt32 = 0x2000, snowMode: Bool = false, spawnDecision: Float = 1, randomScale: Float = 1, randomYaw: Int32 = 0, randomForwardUnit: Float = 0, randomVerticalUnit: Float = 0, randomFacePitch: Int32 = 0, randomFaceRoll: Int32 = 0) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, activeParticleFlags: activeParticleFlags, particleFlag: particleFlag, snowMode: snowMode, spawnDecision: spawnDecision, randomScale: randomScale, randomYaw: randomYaw, randomForwardUnit: randomForwardUnit, randomVerticalUnit: randomVerticalUnit, randomFacePitch: randomFacePitch, randomFaceRoll: randomFaceRoll, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned tree-particle spawner could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, activeParticleFlags: UInt32, particleFlag: UInt32, snowMode: Bool, spawnDecision: Float, randomScale: Float, randomYaw: Int32, randomForwardUnit: Float, randomVerticalUnit: Float, randomFacePitch: Int32, randomFaceRoll: Int32, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(particleFlag: particleFlag, snowMode: snowMode, spawnDecision: spawnDecision, randomScale: randomScale, randomYaw: randomYaw, randomForwardUnit: randomForwardUnit, randomVerticalUnit: randomVerticalUnit, randomFacePitch: randomFacePitch, randomFaceRoll: randomFaceRoll)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.activeParticleFlags = activeParticleFlags; record.graphFlags |= 0x10; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64TreeParticleSpawnerObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64TreeParticleSpawnerBehavior.update(.init(position: record.position, timer: record.timer, activeParticleFlags: record.activeParticleFlags, particleFlag: state.particleFlag, snowMode: state.snowMode, spawnDecision: state.spawnDecision, randomScale: state.randomScale, randomYaw: state.randomYaw, randomForwardUnit: state.randomForwardUnit, randomVerticalUnit: state.randomVerticalUnit, randomFacePitch: state.randomFacePitch, randomFaceRoll: state.randomFaceRoll))
        var child: SM64ObjectID?
        if let kind = output.childKind { child = try? treeBridge.spawnLeaf(in: engineState, kind: kind, position: output.childPosition, moveYaw: output.childMoveYaw, facePitch: output.childFacePitch, faceRoll: output.childFaceRoll, forwardVelocity: output.childForwardVelocity, velocityY: output.childVelocityY, scale: output.childScale) }
        _ = engineState.objects.mutate(id) { next in if output.clearParticleFlag { next.activeParticleFlags &= ~state.particleFlag }; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle }
        let effect = SM64TreeParticleSpawnerObjectEffectRecord(objectID: id, output: output, spawnedChild: child); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
