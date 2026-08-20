import Foundation

struct SM64WhitePuffSmokeObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WhitePuffSmokeOutput
}

final class SM64WhitePuffSmokeObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_77707331

    private struct State { let initialScale: Float }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WhitePuffSmokeObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnSmoke(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        initialScale: Float = 3
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(id, position: position, initialScale: initialScale, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned white puff smoke could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        initialScale: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(initialScale: initialScale)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.scale = .init(x: initialScale, y: initialScale, z: initialScale)
            record.animationState = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WhitePuffSmokeObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64WhitePuffSmokeBehavior.update(.init(
            position: record.position,
            timer: record.timer,
            animationState: record.animationState,
            initialScale: state.initialScale
        ))
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.animationState = output.animationState
            next.timer = output.shouldDeactivate ? 10 : record.timer + 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64WhitePuffSmokeObjectEffectRecord(objectID: id, output: output)
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
