import Foundation

struct SM64LllMovingOctagonalMeshObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64LllMovingOctagonalMeshOutput
}

/// Owner-thread adapter for the two authored LLL octagonal mesh tables.
final class SM64LllMovingOctagonalMeshObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6C6F6D
    static let defaultModel: UInt32 = 0

    private struct State {
        let mode: UInt8
        var sequenceIndex: Int32
        var verticalAngle: Int32
        var rotationAngle: Int32
        var baseOffset: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64LllMovingOctagonalMeshObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawnPlatform(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        mode: UInt8 = 0,
        model: UInt32 = SM64LllMovingOctagonalMeshObjectBridge.defaultModel,
        behaviorIdentity: UInt64 = SM64LllMovingOctagonalMeshObjectBridge.defaultBehaviorIdentity
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, model: model,
                                             behaviorIdentity: behaviorIdentity)
        guard attach(id, position: position, mode: mode, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned LLL moving octagonal mesh could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3 = .zero,
                mode: UInt8, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil, mode < 2 else { return false }
        states[id] = State(mode: mode, sequenceIndex: 0, verticalAngle: 0,
                            rotationAngle: 0, baseOffset: 0)
        return pool.mutate(id) { record in
            record.position.x = position.x
            record.position.y = position.y - 50
            record.position.z = position.z
            record.homePosition = position
            record.behaviorParams2ndByte = Int32(mode)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState)
        -> SM64LllMovingOctagonalMeshObjectEffectRecord?
    {
        guard var meshState = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64LllMovingOctagonalMeshBehavior.update(
            SM64LllMovingOctagonalMeshInput(
                mode: meshState.mode,
                action: record.action,
                timer: record.timer,
                sequenceIndex: meshState.sequenceIndex,
                positionX: record.position.x,
                positionY: record.position.y,
                positionZ: record.position.z,
                homeY: record.homePosition.y,
                forwardVelocity: record.forwardVelocity,
                moveYaw: record.moveAngles.yaw,
                verticalAngle: meshState.verticalAngle,
                rotationAngle: meshState.rotationAngle,
                baseOffset: meshState.baseOffset,
                marioOnPlatform: record.platform == id
            )
        )
        meshState.sequenceIndex = output.sequenceIndex
        meshState.verticalAngle = output.verticalAngle
        meshState.rotationAngle = output.rotationAngle
        meshState.baseOffset = output.baseOffset
        states[id] = meshState
        let nextTimer = output.timer == record.timer && output.action == record.action
            ? record.timer &+ 1
            : output.timer
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.position.x = output.positionX
            next.position.y = output.positionY
            next.position.z = output.positionZ
            next.forwardVelocity = output.forwardVelocity
            next.moveAngles.yaw = output.moveYaw
            next.velocity.x = output.velocityX
            next.velocity.z = output.velocityZ
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64LllMovingOctagonalMeshObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
