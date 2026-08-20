import Foundation

struct SM64AmbientSoundLoopObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64AmbientSoundLoopOutput
}

final class SM64AmbientSoundLoopObjectBridge {
    static let birdsBehaviorIdentity: UInt64 = 0x6268_765F_627264_73
    static let sandBehaviorIdentity: UInt64 = 0x6268_765F_736E64_73

    private struct State {
        let kind: SM64AmbientSoundKind
        let behaviorByte: UInt8
        var cameraBehindMario: Bool
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64AmbientSoundLoopObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnBirds(
        in engineState: SM64SwiftEngineState,
        behaviorByte: UInt8 = 0,
        cameraBehindMario: Bool = false,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try spawn(
            in: engineState,
            kind: .birds,
            behaviorIdentity: Self.birdsBehaviorIdentity,
            behaviorByte: behaviorByte,
            cameraBehindMario: cameraBehindMario,
            position: position
        )
    }

    @discardableResult
    func spawnSand(
        in engineState: SM64SwiftEngineState,
        cameraBehindMario: Bool = false,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try spawn(
            in: engineState,
            kind: .sand,
            behaviorIdentity: Self.sandBehaviorIdentity,
            behaviorByte: 0,
            cameraBehindMario: cameraBehindMario,
            position: position
        )
    }

    private func spawn(
        in engineState: SM64SwiftEngineState,
        kind: SM64AmbientSoundKind,
        behaviorIdentity: UInt64,
        behaviorByte: UInt8,
        cameraBehindMario: Bool,
        position: SM64ObjectVector3
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: behaviorIdentity)
        guard engineState.objects.record(for: id) != nil else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("ambient sound loop allocation failed")
        }
        states[id] = State(
            kind: kind,
            behaviorByte: behaviorByte,
            cameraBehindMario: cameraBehindMario
        )
        _ = engineState.objects.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.behaviorParams2ndByte = Int32(behaviorByte)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
        return id
    }

    @discardableResult
    func setCameraBehindMario(_ value: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.cameraBehindMario = value
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64AmbientSoundLoopObjectEffectRecord? {
        guard let state = states[id], engineState.objects.record(for: id) != nil else {
            return nil
        }
        let output = SM64AmbientSoundLoopBehavior.update(
            SM64AmbientSoundLoopInput(
                kind: state.kind,
                behaviorByte: state.behaviorByte,
                cameraBehindMario: state.cameraBehindMario
            )
        )
        let effect = SM64AmbientSoundLoopObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
