import Foundation

struct SM64BlackSmokeBowserObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64BlackSmokeBowserOutput
}

final class SM64BlackSmokeBowserObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_626231

    private struct State {
        let initialMoveYaw: Int32
        let initialForwardVelocity: Float
        let initialVelocityY: Float
        let angleVelocityYaw: Int32
        var moveYaw: Int32
        var forwardVelocity: Float
        var velocityY: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64BlackSmokeBowserObjectEffectRecord] = []

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
        initialMoveYaw: Int32 = 0,
        // Deterministic fallback for source `random_float() * 2 + 0.5`; callers
        // may inject the replayed random value explicitly.
        initialForwardVelocity: Float = 1.25,
        initialVelocityY: Float = 8,
        angleVelocityYaw: Int32 = 0,
        scale: Float = 1,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            behaviorIdentity: Self.defaultBehaviorIdentity,
            parent: parent
        )
        guard attach(
            id,
            position: position,
            initialMoveYaw: initialMoveYaw,
            initialForwardVelocity: initialForwardVelocity,
            initialVelocityY: initialVelocityY,
            angleVelocityYaw: angleVelocityYaw,
            scale: scale,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Bowser black smoke could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        initialMoveYaw: Int32,
        initialForwardVelocity: Float,
        initialVelocityY: Float,
        angleVelocityYaw: Int32,
        scale: Float = 1,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            initialMoveYaw: initialMoveYaw,
            initialForwardVelocity: initialForwardVelocity,
            initialVelocityY: initialVelocityY,
            angleVelocityYaw: angleVelocityYaw,
            moveYaw: initialMoveYaw,
            forwardVelocity: 0,
            velocityY: 0
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = initialMoveYaw
            record.forwardVelocity = 0
            record.scale = .init(x: scale, y: scale, z: scale)
            record.graphYOffset = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64BlackSmokeBowserObjectEffectRecord? {
        guard
            var state = states[id],
            let record = engineState.objects.record(for: id)
        else { return nil }

        let output = SM64BlackSmokeBowserBehavior.update(.init(
            position: record.position,
            moveYaw: state.moveYaw,
            forwardVelocity: state.forwardVelocity,
            velocityY: state.velocityY,
            timer: record.timer,
            initialMoveYaw: state.initialMoveYaw,
            initialForwardVelocity: state.initialForwardVelocity,
            initialVelocityY: state.initialVelocityY,
            angleVelocityYaw: state.angleVelocityYaw,
            animationState: record.animationState
        ))
        state.moveYaw = output.moveYaw
        state.forwardVelocity = output.forwardVelocity
        state.velocityY = output.velocityY
        states[id] = state

        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.animationState = output.animationState
            next.timer = output.shouldDeactivate ? 8 : record.timer + 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }

        let effect = SM64BlackSmokeBowserObjectEffectRecord(objectID: id, output: output)
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
