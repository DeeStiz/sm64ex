import Foundation

struct SM64WaveTrailObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WaveTrailOutput
}

final class SM64WaveTrailObjectBridge {
    static let marioBehaviorIdentity: UInt64 = 0x6268_765F_7774_3131
    static let objectBehaviorIdentity: UInt64 = 0x6268_765F_6F77_7431
    static let particleFlag: UInt32 = 1 << 10

    private struct State {
        let kind: SM64WaveTrailKind
        let waterLevel: Float
        let globalFrame: UInt64
        var animationState: Int32
        var waveTrailSize: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WaveTrailObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnTrail(
        in engineState: SM64SwiftEngineState,
        kind: SM64WaveTrailKind = .mario,
        position: SM64ObjectVector3 = .zero,
        waterLevel: Float = 100,
        globalFrame: UInt64 = 0,
        initialScale: Float = 1,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let identity = kind == .mario ? Self.marioBehaviorIdentity : Self.objectBehaviorIdentity
        let list: SM64ObjectList = kind == .mario ? .default : .unimportant
        let id = try engineState.spawnObject(in: list, behaviorIdentity: identity, parent: parent)
        guard attach(
            id,
            kind: kind,
            position: position,
            waterLevel: waterLevel,
            globalFrame: globalFrame,
            initialScale: initialScale,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned wave trail could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64WaveTrailKind,
        position: SM64ObjectVector3,
        waterLevel: Float,
        globalFrame: UInt64,
        initialScale: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            kind: kind,
            waterLevel: waterLevel,
            globalFrame: globalFrame,
            animationState: -1,
            waveTrailSize: initialScale
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.scale = .init(x: initialScale, y: 1, z: initialScale)
            record.animationState = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WaveTrailObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64WaveTrailBehavior.update(
            SM64WaveTrailInput(
                kind: state.kind,
                position: record.position,
                waterLevel: state.waterLevel,
                timer: record.timer,
                globalFrame: state.globalFrame,
                animationState: state.animationState,
                waveTrailSize: state.waveTrailSize,
                initialScale: record.scale.x
            )
        )
        state.animationState = output.animationState
        state.waveTrailSize = output.waveTrailSize
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.scale.x = output.scaleX
            next.scale.z = output.scaleZ
            next.animationState = output.animationState
            next.timer &+= 1
            if output.clearParticleFlag { next.activeParticleFlags &= ~Self.particleFlag }
            if output.shouldDelete || output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64WaveTrailObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
