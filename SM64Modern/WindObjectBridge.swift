import Foundation

struct SM64WindObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64WindOutput
}

final class SM64WindObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_7769_6E31

    private struct State {
        let initialRandomX: Float
        let initialRandomY: Float
        let initialRandomZ: Float
        let initialYawJitter: Int32
        let initialForwardVelocity: Float
        let initialVelocityY: Float
        let initialRandomYaw: Int32
        let facePitchJitter: Float
        let faceYawJitter: Float
        var moveYaw: Int32
        var forwardVelocity: Float
        var velocityY: Float
        var facePitch: Int32
        var faceYaw: Int32
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WindObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnWind(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        movePitch: Int32 = 0,
        initialRandomX: Float = 0,
        initialRandomY: Float = 0,
        initialRandomZ: Float = 0,
        initialYawJitter: Int32 = 0,
        initialForwardVelocity: Float = 50,
        initialVelocityY: Float = 50,
        initialRandomYaw: Int32 = 0,
        facePitchJitter: Float = 0,
        faceYawJitter: Float = 0
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .unimportant,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard attach(
            id,
            position: position,
            moveYaw: moveYaw,
            movePitch: movePitch,
            initialRandomX: initialRandomX,
            initialRandomY: initialRandomY,
            initialRandomZ: initialRandomZ,
            initialYawJitter: initialYawJitter,
            initialForwardVelocity: initialForwardVelocity,
            initialVelocityY: initialVelocityY,
            initialRandomYaw: initialRandomYaw,
            facePitchJitter: facePitchJitter,
            faceYawJitter: faceYawJitter,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned wind could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3,
        moveYaw: Int32,
        movePitch: Int32,
        initialRandomX: Float,
        initialRandomY: Float,
        initialRandomZ: Float,
        initialYawJitter: Int32,
        initialForwardVelocity: Float,
        initialVelocityY: Float,
        initialRandomYaw: Int32,
        facePitchJitter: Float,
        faceYawJitter: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(
            initialRandomX: initialRandomX,
            initialRandomY: initialRandomY,
            initialRandomZ: initialRandomZ,
            initialYawJitter: initialYawJitter,
            initialForwardVelocity: initialForwardVelocity,
            initialVelocityY: initialVelocityY,
            initialRandomYaw: initialRandomYaw,
            facePitchJitter: facePitchJitter,
            faceYawJitter: faceYawJitter,
            moveYaw: moveYaw,
            forwardVelocity: 0,
            velocityY: 0,
            facePitch: 0,
            faceYaw: 0
        )
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = moveYaw
            record.moveAngles.pitch = movePitch
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WindObjectEffectRecord? {
        guard var state = states[id], let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64WindBehavior.update(
            SM64WindInput(
                position: record.position,
                moveYaw: state.moveYaw,
                movePitch: record.moveAngles.pitch,
                forwardVelocity: state.forwardVelocity,
                velocityY: state.velocityY,
                facePitch: state.facePitch,
                faceYaw: state.faceYaw,
                timer: record.timer,
                initialRandomX: state.initialRandomX,
                initialRandomY: state.initialRandomY,
                initialRandomZ: state.initialRandomZ,
                initialYawJitter: state.initialYawJitter,
                initialForwardVelocity: state.initialForwardVelocity,
                initialVelocityY: state.initialVelocityY,
                initialRandomYaw: state.initialRandomYaw,
                facePitchJitter: state.facePitchJitter,
                faceYawJitter: state.faceYawJitter
            )
        )
        state.moveYaw = output.moveYaw
        state.forwardVelocity = output.forwardVelocity
        state.velocityY = output.velocityY
        state.facePitch = output.facePitch
        state.faceYaw = output.faceYaw
        states[id] = state
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.moveAngles.yaw = output.moveYaw
            next.forwardVelocity = output.forwardVelocity
            next.velocity.y = output.velocityY
            next.faceAngles.pitch = output.facePitch
            next.faceAngles.yaw = output.faceYaw
            next.opacity = output.opacity
            next.scale = .init(x: output.scale, y: output.scale, z: output.scale)
            next.timer &+= 1
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        let effect = SM64WindObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
