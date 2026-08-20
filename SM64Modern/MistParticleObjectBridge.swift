import Foundation

struct SM64MistParticleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64MistParticleOutput
}

final class SM64MistParticleObjectBridge {
    static let puff1BehaviorIdentity: UInt64 = 0x6268_765F_777031
    static let puff2BehaviorIdentity: UInt64 = 0x6268_765F_777032

    private struct State {
        let kind: SM64MistParticleKind
        let initialOffsetX: Float
        let initialOffsetZ: Float
        let moveYaw: Int32
        let forwardVelocity: Float
        let velocityY: Float
    }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64MistParticleObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] { states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot } }
    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        kind: SM64MistParticleKind,
        position: SM64ObjectVector3 = .zero,
        initialOffsetX: Float = 0,
        initialOffsetZ: Float = 0,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 0,
        velocityY: Float = 0,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let identity = kind == .puff1 ? Self.puff1BehaviorIdentity : Self.puff2BehaviorIdentity
        let list: SM64ObjectList = kind == .puff1 ? .default : .unimportant
        let id = try engineState.spawnObject(in: list, behaviorIdentity: identity, parent: parent)
        guard attach(id, kind: kind, position: position, initialOffsetX: initialOffsetX, initialOffsetZ: initialOffsetZ, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned mist particle could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64MistParticleKind,
        position: SM64ObjectVector3,
        initialOffsetX: Float,
        initialOffsetZ: Float,
        moveYaw: Int32,
        forwardVelocity: Float,
        velocityY: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(kind: kind, initialOffsetX: initialOffsetX, initialOffsetZ: initialOffsetZ, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = moveYaw
            record.forwardVelocity = forwardVelocity
            record.velocity.y = velocityY
            record.animationState = -1
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64MistParticleObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64MistParticleBehavior.update(SM64MistParticleInput(kind: state.kind, position: record.position, timer: record.timer, animationState: record.animationState, initialOffsetX: state.initialOffsetX, initialOffsetZ: state.initialOffsetZ, moveYaw: state.moveYaw, forwardVelocity: state.forwardVelocity, velocityY: state.velocityY))
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.opacity = output.opacity
            next.animationState = output.animationState
            next.timer &+= 1
            if output.shouldDelete || output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64MistParticleObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
