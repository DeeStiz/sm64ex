import Foundation

struct SM64DustSmokeObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64DustSmokeOutput
}

final class SM64DustSmokeObjectBridge {
    static let smokeBehaviorIdentity: UInt64 = 0x6268_765F_64736D
    static let bobombFuseBehaviorIdentity: UInt64 = 0x6268_765F_626673

    private struct State {
        let kind: SM64DustSmokeKind
        let moveYaw: Int32
        let forwardVelocity: Float
        var velocity: SM64ObjectVector3
        var smokeTimer: Int32
        var delayed: Bool
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64DustSmokeObjectEffectRecord] = []

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
        velocity: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 0
    ) throws -> SM64ObjectID {
        try spawn(
            kind: .smoke,
            in: engineState,
            position: position,
            velocity: velocity,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            initialOffset: .zero
        )
    }

    @discardableResult
    func spawnBobombFuseSmoke(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        velocity: SM64ObjectVector3 = .zero,
        initialOffset: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        try spawn(
            kind: .bobombFuse,
            in: engineState,
            position: position,
            velocity: velocity,
            moveYaw: 0,
            forwardVelocity: 0,
            initialOffset: initialOffset
        )
    }

    private func spawn(
        kind: SM64DustSmokeKind,
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3,
        velocity: SM64ObjectVector3,
        moveYaw: Int32,
        forwardVelocity: Float,
        initialOffset: SM64ObjectVector3
    ) throws -> SM64ObjectID {
        let identity = kind == .smoke ? Self.smokeBehaviorIdentity : Self.bobombFuseBehaviorIdentity
        let list: SM64ObjectList = kind == .smoke ? .unimportant : .default
        let id = try engineState.spawnObject(in: list, behaviorIdentity: identity)
        guard attach(
            id,
            kind: kind,
            position: .init(
                x: position.x + initialOffset.x,
                y: position.y + initialOffset.y,
                z: position.z + initialOffset.z
            ),
            velocity: velocity,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            scale: kind == .bobombFuse ? 1.2 : 1,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned dust smoke could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64DustSmokeKind,
        position: SM64ObjectVector3,
        velocity: SM64ObjectVector3,
        moveYaw: Int32,
        forwardVelocity: Float,
        scale: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            kind: kind,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            smokeTimer: 0,
            delayed: true
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.velocity = velocity
            record.moveAngles.yaw = moveYaw
            record.forwardVelocity = forwardVelocity
            record.scale = .init(x: scale, y: scale, z: scale)
            record.animationState = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64DustSmokeObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64DustSmokeBehavior.update(.init(
            kind: state.kind,
            position: record.position,
            velocity: state.velocity,
            moveYaw: state.moveYaw,
            forwardVelocity: state.forwardVelocity,
            timer: record.timer,
            smokeTimer: state.smokeTimer,
            animationState: record.animationState,
            delayed: state.delayed,
            scale: record.scale.x
        ))
        state.smokeTimer = output.smokeTimer
        state.delayed = output.delayed
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.velocity = output.velocity
            next.animationState = output.animationState
            next.timer &+= 1
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64DustSmokeObjectEffectRecord(objectID: id, output: output)
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
