import Foundation

struct SM64StrongWindParticleObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64StrongWindParticleOutput
}

final class SM64StrongWindParticleObjectBridge {
    static let visibleBehaviorIdentity: UInt64 = 0x6268_765F_7377_7031
    static let tinyBehaviorIdentity: UInt64 = 0x6268_765F_7477_7031

    private struct State {
        let kind: SM64StrongWindParticleKind
        let movePitch: Int32
        let initialRandomX: Float
        let initialRandomY: Float
        let initialRandomZ: Float
        let initialYawJitter: Int32
        let windSpread: UInt8
        let penguinCollisionPosition: SM64ObjectVector3?
        var moveYaw: Int32
        var forwardVelocity: Float
        var velocityY: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64StrongWindParticleObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnParticle(
        in engineState: SM64SwiftEngineState,
        kind: SM64StrongWindParticleKind = .visible,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        movePitch: Int32 = 0,
        initialRandomX: Float = 0,
        initialRandomY: Float = 0,
        initialRandomZ: Float = 0,
        initialYawJitter: Int32 = 0,
        windSpread: UInt8 = 0,
        penguinCollisionPosition: SM64ObjectVector3? = nil,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let identity = kind == .visible ? Self.visibleBehaviorIdentity : Self.tinyBehaviorIdentity
        let list: SM64ObjectList = kind == .visible ? .polelike : .unimportant
        let id = try engineState.spawnObject(in: list, behaviorIdentity: identity, parent: parent)
        guard attach(
            id,
            kind: kind,
            position: position,
            moveYaw: moveYaw,
            movePitch: movePitch,
            initialRandomX: initialRandomX,
            initialRandomY: initialRandomY,
            initialRandomZ: initialRandomZ,
            initialYawJitter: initialYawJitter,
            windSpread: windSpread,
            penguinCollisionPosition: penguinCollisionPosition,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned strong wind particle could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64StrongWindParticleKind,
        position: SM64ObjectVector3,
        moveYaw: Int32,
        movePitch: Int32,
        initialRandomX: Float,
        initialRandomY: Float,
        initialRandomZ: Float,
        initialYawJitter: Int32,
        windSpread: UInt8,
        penguinCollisionPosition: SM64ObjectVector3?,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            kind: kind,
            movePitch: movePitch,
            initialRandomX: initialRandomX,
            initialRandomY: initialRandomY,
            initialRandomZ: initialRandomZ,
            initialYawJitter: initialYawJitter,
            windSpread: windSpread,
            penguinCollisionPosition: penguinCollisionPosition,
            moveYaw: moveYaw,
            forwardVelocity: 0,
            velocityY: 0
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = moveYaw
            record.moveAngles.pitch = movePitch
            record.hitboxRadius = 20
            record.hitboxHeight = 70
            record.hurtboxRadius = 20
            record.hurtboxHeight = 70
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64StrongWindParticleObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64StrongWindParticleBehavior.update(
            SM64StrongWindParticleInput(
                kind: state.kind,
                position: record.position,
                moveYaw: state.moveYaw,
                movePitch: state.movePitch,
                forwardVelocity: state.forwardVelocity,
                velocityY: state.velocityY,
                timer: record.timer,
                initialRandomX: state.initialRandomX,
                initialRandomY: state.initialRandomY,
                initialRandomZ: state.initialRandomZ,
                initialYawJitter: state.initialYawJitter,
                windSpread: state.windSpread,
                penguinCollisionPosition: state.penguinCollisionPosition
            )
        )
        state.moveYaw = output.moveYaw
        state.forwardVelocity = output.forwardVelocity
        state.velocityY = output.velocityY
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.opacity = output.opacity
            next.intangibleTimer = output.intangible ? 1 : -1
            next.timer &+= 1
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64StrongWindParticleObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
