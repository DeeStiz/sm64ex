import Foundation

struct SM64WhitePuffExplosionObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WhitePuffExplosionOutput
}

final class SM64WhitePuffExplosionObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_777065

    private struct State {
        let gravity: Float
        let dragStrength: Float
        let initialScale: Float
        let behaviorParam: Int32
        var velocity: SM64ObjectVector3
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WhitePuffExplosionObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnExplosion(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        velocity: SM64ObjectVector3 = .zero,
        gravity: Float = 0,
        dragStrength: Float = 0,
        initialScale: Float = 1,
        behaviorParam: Int32 = 2
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(
            id,
            position: position,
            velocity: velocity,
            gravity: gravity,
            dragStrength: dragStrength,
            initialScale: initialScale,
            behaviorParam: behaviorParam,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned white puff explosion could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        velocity: SM64ObjectVector3,
        gravity: Float,
        dragStrength: Float,
        initialScale: Float,
        behaviorParam: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            gravity: gravity,
            dragStrength: dragStrength,
            initialScale: initialScale,
            behaviorParam: behaviorParam,
            velocity: velocity
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.velocity = velocity
            record.gravity = gravity
            record.dragStrength = dragStrength
            record.behaviorParams2ndByte = behaviorParam
            record.scale = .init(x: initialScale, y: initialScale, z: initialScale)
            record.opacity = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WhitePuffExplosionObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64WhitePuffExplosionBehavior.update(.init(
            position: record.position,
            velocity: state.velocity,
            gravity: state.gravity,
            dragStrength: state.dragStrength,
            timer: record.timer,
            opacity: record.opacity,
            initialScale: state.initialScale,
            behaviorParam: state.behaviorParam
        ))
        state.velocity = output.velocity
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.velocity = output.velocity
            next.opacity = output.opacity
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.timer = output.shouldDelete ? 21 : record.timer + 1
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64WhitePuffExplosionObjectEffectRecord(objectID: id, output: output)
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
