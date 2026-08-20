import Foundation

struct SM64PurpleParticleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64PurpleParticleOutput
}

final class SM64PurpleParticleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_707270

    private struct State {
        let moveYaw: Int32
        let randomForwardUnit: Float
        let randomVerticalUnit: Float
        var forwardVelocity: Float
        var velocityY: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64PurpleParticleObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnParticle(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        randomForwardUnit: Float = 0,
        randomVerticalUnit: Float = 0
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(
            id,
            position: position,
            moveYaw: moveYaw,
            randomForwardUnit: randomForwardUnit,
            randomVerticalUnit: randomVerticalUnit,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned purple particle could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        moveYaw: Int32,
        randomForwardUnit: Float,
        randomVerticalUnit: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            moveYaw: moveYaw,
            randomForwardUnit: randomForwardUnit,
            randomVerticalUnit: randomVerticalUnit,
            forwardVelocity: 0,
            velocityY: 0
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64PurpleParticleObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64PurpleParticleBehavior.update(
            SM64PurpleParticleInput(
                position: record.position,
                timer: record.timer,
                moveYaw: state.moveYaw,
                forwardVelocity: state.forwardVelocity,
                velocityY: state.velocityY,
                randomForwardUnit: state.randomForwardUnit,
                randomVerticalUnit: state.randomVerticalUnit
            )
        )
        state.forwardVelocity = output.forwardVelocity
        state.velocityY = output.velocityY
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64PurpleParticleObjectEffectRecord(objectID: id, output: output)
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
