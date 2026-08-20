import Foundation

struct SM64SparkleParticleSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64SparkleParticleSpawnerOutput
}

final class SM64SparkleParticleSpawnerObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_73706B

    private struct State {
        let particleFlag: UInt32
        let randomOffset: SM64ObjectVector3
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64SparkleParticleSpawnerObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnSpawner(in engineState: SM64SwiftEngineState, position: SM64ObjectVector3 = .zero, activeParticleFlags: UInt32 = 0, particleFlag: UInt32 = 0x800, randomOffset: SM64ObjectVector3 = .zero) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, activeParticleFlags: activeParticleFlags, particleFlag: particleFlag, randomOffset: randomOffset, in: engineState.objects) else { _ = engineState.objects.despawn(id); preconditionFailure("newly spawned sparkle particle spawner could not attach") }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, activeParticleFlags: UInt32, particleFlag: UInt32, randomOffset: SM64ObjectVector3, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(particleFlag: particleFlag, randomOffset: randomOffset)
        return pool.mutate(id) { record in record.position = position; record.homePosition = position; record.activeParticleFlags = activeParticleFlags; record.graphYOffset = 25; record.animationState = -1; record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64SparkleParticleSpawnerObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64SparkleParticleSpawnerBehavior.update(.init(position: record.position, timer: record.timer, animationState: record.animationState, activeParticleFlags: record.activeParticleFlags, particleFlag: state.particleFlag, randomOffset: state.randomOffset))
        _ = engineState.objects.mutate(id) { next in next.position = output.position; next.animationState = output.animationState; next.graphYOffset = output.graphYOffset; if output.clearParticleFlag { next.activeParticleFlags &= ~state.particleFlag }; next.timer &+= 1; if output.shouldDeactivate { next.activeFlags = 0 }; next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform }
        let effect = SM64SparkleParticleSpawnerObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
