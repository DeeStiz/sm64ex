import Foundation

struct SM64IdleWaterWaveObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64IdleWaterWaveOutput
}

final class SM64IdleWaterWaveObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6977_77
    static let objectWaterWaveBehaviorIdentity: UInt64 = 0x6268_765F_6F7777
    static let defaultModel: UInt32 = 0

    private enum Kind: Sendable { case idle, object }
    private struct State: Sendable {
        let kind: Kind
        let waterLevel: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64IdleWaterWaveObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnWave(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 0,
        model: UInt32 = SM64IdleWaterWaveObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            model: model,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, kind: .idle, position: position, waterLevel: waterLevel, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned idle water wave could not attach")
        }
        return id
    }

    @discardableResult
    func spawnObjectWaterWave(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64IdleWaterWaveObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            model: model,
            behaviorIdentity: Self.objectWaterWaveBehaviorIdentity
        )
        guard attach(id, kind: .object, position: position, waterLevel: 0, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned object water wave could not attach")
        }
        return id
    }

    @discardableResult
    private func attach(
        _ id: SM64ObjectID,
        kind: Kind,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: kind, waterLevel: waterLevel)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.animationState = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64IdleWaterWaveObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let mario = engineState.globals.marioObject.flatMap { engineState.objects.record(for: $0) }
        let input = SM64IdleWaterWaveInput(
            animationState: record.animationState,
            globalTimer: engineState.globals.frame,
            marioPosition: mario?.position ?? .zero,
            marioWaterLevel: state.waterLevel,
            marioParticleFlags: mario?.activeParticleFlags ?? 0
        )
        let output = state.kind == .idle
            ? SM64IdleWaterWaveBehavior.updateIdle(input)
            : SM64IdleWaterWaveBehavior.updateObject(input)
        _ = engineState.objects.mutate(id) { next in
            next.animationState = output.animationState
            next.position = output.position
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.deactivate {
                next.activeFlags = 0
            }
        }
        if output.clearMarioFlag, let marioID = engineState.globals.marioObject {
            _ = engineState.objects.mutate(marioID) { $0.activeParticleFlags &= ~UInt32(0x80) }
        }
        let effect = SM64IdleWaterWaveObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
