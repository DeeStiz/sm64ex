import Foundation

struct SM64TriangleParticleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64TriangleParticleOutput
}

final class SM64TriangleParticleObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_747269

    private struct State {
        let marioPosition: SM64ObjectVector3
        let marioYaw: Int32
        let gravity: Float
        let lifetime: Int32
        var forwardVelocity: Float
        var velocityY: Float
        var scale: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64TriangleParticleObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnParticle(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        marioPosition: SM64ObjectVector3 = .zero,
        marioYaw: Int32 = 0,
        moveYaw: Int32 = 0,
        forwardVelocity: Float = 25,
        velocityY: Float = 14,
        gravity: Float = 0,
        lifetime: Int32 = 6
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, marioPosition: marioPosition, marioYaw: marioYaw, moveYaw: moveYaw, forwardVelocity: forwardVelocity, velocityY: velocityY, gravity: gravity, lifetime: lifetime, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned triangle particle could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        marioPosition: SM64ObjectVector3,
        marioYaw: Int32,
        moveYaw: Int32,
        forwardVelocity: Float,
        velocityY: Float,
        gravity: Float,
        lifetime: Int32,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(marioPosition: marioPosition, marioYaw: marioYaw, gravity: gravity, lifetime: lifetime, forwardVelocity: forwardVelocity, velocityY: velocityY, scale: 1)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = moveYaw
            record.forwardVelocity = forwardVelocity
            record.velocity.y = velocityY
            record.gravity = gravity
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64TriangleParticleObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64TriangleParticleBehavior.update(.init(position: record.position, marioPosition: state.marioPosition, marioYaw: state.marioYaw, timer: record.timer, moveYaw: record.moveAngles.yaw, forwardVelocity: state.forwardVelocity, velocityY: state.velocityY, gravity: state.gravity, scale: state.scale, lifetime: state.lifetime))
        state.forwardVelocity = output.forwardVelocity
        state.velocityY = output.velocityY
        state.scale = output.scale - 0.2
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.animationState = output.animationState
            next.timer &+= 1
            if output.shouldDeactivate { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64TriangleParticleObjectEffectRecord(objectID: id, output: output); effectLog.append(effect); return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
