import Foundation

struct SM64AmbientSoundsObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64AmbientSoundsOutput
}

final class SM64AmbientSoundsObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_616D_6273

    private var cameraBehindMario: [SM64ObjectID: Bool] = [:]
    private(set) var effectLog: [SM64AmbientSoundsObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        cameraBehindMario.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnAmbientSounds(
        in engineState: SM64SwiftEngineState,
        cameraBehindMario: Bool = false,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(
            id,
            cameraBehindMario: cameraBehindMario,
            position: position,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned ambient-sounds object could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        cameraBehindMario: Bool,
        position: SM64ObjectVector3,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        self.cameraBehindMario[id] = cameraBehindMario
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
        }
    }

    @discardableResult
    func setCameraBehindMario(_ value: Bool, for id: SM64ObjectID) -> Bool {
        guard cameraBehindMario[id] != nil else { return false }
        cameraBehindMario[id] = value
        return true
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64AmbientSoundsObjectEffectRecord? {
        guard let cameraBehindMario = cameraBehindMario[id], engineState.objects.record(for: id) != nil else {
            return nil
        }
        let effect = SM64AmbientSoundsObjectEffectRecord(
            objectID: id,
            output: SM64AmbientSoundsBehavior.update(
                SM64AmbientSoundsInput(cameraBehindMario: cameraBehindMario)
            )
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        cameraBehindMario.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
