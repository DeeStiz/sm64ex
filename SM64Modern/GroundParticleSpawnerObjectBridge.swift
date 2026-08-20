import Foundation

struct SM64GroundParticleSpawnerObjectEffectRecord: Equatable, Sendable { let objectID: SM64ObjectID; let output: SM64GroundParticleSpawnerOutput; let spawnedChildren: [SM64ObjectID] }
final class SM64GroundParticleSpawnerObjectBridge {
    static let dirtBehaviorIdentity: UInt64 = 0x6268_765F_647073
    static let snowBehaviorIdentity: UInt64 = 0x6268_765F_737073
    private struct State { let kind: SM64GroundParticleKind; let particleFlag: UInt32; let seeds: [SM64StarKeyPuffSeed] }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64GroundParticleSpawnerObjectEffectRecord] = []
    private let puffBridge: SM64WhitePuffExplosionObjectBridge
    init(puffBridge: SM64WhitePuffExplosionObjectBridge) { self.puffBridge = puffBridge }
    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }
    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, kind: SM64GroundParticleKind, position: SM64ObjectVector3 = .zero, activeParticleFlags: UInt32 = 0, seeds: [SM64StarKeyPuffSeed] = SM64GroundParticleSpawnerObjectBridge.defaultSeeds) throws -> SM64ObjectID {
        let identity = kind == .dirt ? Self.dirtBehaviorIdentity : Self.snowBehaviorIdentity
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: identity)
        guard attach(id, kind: kind, position: position, activeParticleFlags: activeParticleFlags, seeds: seeds, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned ground particle spawner could not attach") }
        return id
    }
    @discardableResult
    func attach(_ id: SM64ObjectID, kind: SM64GroundParticleKind, position: SM64ObjectVector3, activeParticleFlags: UInt32, seeds: [SM64StarKeyPuffSeed], in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: kind, particleFlag: kind == .dirt ? 0x4000 : 1 << 16, seeds: seeds)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.activeParticleFlags = activeParticleFlags; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }
    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64GroundParticleSpawnerObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64GroundParticleSpawnerBehavior.update(.init(kind: state.kind, position: record.position, timer: record.timer, activeParticleFlags: record.activeParticleFlags, particleFlag: state.particleFlag, seeds: state.seeds))
        var children: [SM64ObjectID] = []
        for seed in output.seeds.prefix(4) {
            if let child = try? engineState.spawnObject(in: .unimportant, behaviorIdentity: SM64WhitePuffExplosionObjectBridge.defaultBehaviorIdentity, parent: id) {
                _ = puffBridge.attach(child, position: .init(x: output.position.x, y: output.position.y, z: output.position.z), velocity: seed.velocity, gravity: -4, dragStrength: 30, initialScale: seed.scale, behaviorParam: 0, in: engineState.objects); children.append(child)
            }
        }
        _ = engineState.objects.mutate(id) { next in if output.clearParticleFlag { next.activeParticleFlags &= ~state.particleFlag }; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 } }
        let effect = SM64GroundParticleSpawnerObjectEffectRecord(objectID: id, output: output, spawnedChildren: children); effectLog.append(effect); return effect
    }
    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
    static let defaultSeeds: [SM64StarKeyPuffSeed] = (0..<4).map { index in SM64StarKeyPuffSeed(velocity: .init(x: Float(index), y: 20, z: Float(index + 1)), scale: 0.5 + Float(index) * 0.05) }
}
