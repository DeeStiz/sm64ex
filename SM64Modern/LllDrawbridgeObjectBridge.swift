import Foundation

struct SM64LllDrawbridgeSpawnerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let spawnedChildren: [SM64ObjectID]
}

struct SM64LllDrawbridgeObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64LllDrawbridgeOutput
}

/// Owner bridge for the LLL drawbridge spawner and its two surface halves.
final class SM64LllDrawbridgeObjectBridge {
    static let spawnerBehaviorIdentity: UInt64 = 0x6268_765F_6C6473
    static let drawbridgeBehaviorIdentity: UInt64 = 0x6268_765F_6C6462
    static let defaultModel: UInt32 = 0

    private var spawners: Set<SM64ObjectID> = []
    private var drawbridges: Set<SM64ObjectID> = []
    private(set) var spawnerEffectLog: [SM64LllDrawbridgeSpawnerObjectEffectRecord] = []
    private(set) var effectLog: [SM64LllDrawbridgeObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        (spawners.union(drawbridges)).sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() {
        spawnerEffectLog.removeAll(keepingCapacity: true)
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnSpawner(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        model: UInt32 = SM64LllDrawbridgeObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .default,
            model: model,
            behaviorIdentity: Self.spawnerBehaviorIdentity
        )
        guard attachSpawner(id, position: position, moveYaw: moveYaw, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned LLL drawbridge spawner could not attach")
        }
        return id
    }

    @discardableResult
    func attachSpawner(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        spawners.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.moveAngles.yaw = moveYaw
            record.faceAngles.yaw = moveYaw
            record.objectFlags |= SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func spawnDrawbridge(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        action: Int32 = 0,
        faceRoll: Int32 = 0,
        model: UInt32 = SM64LllDrawbridgeObjectBridge.defaultModel,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .surface,
            model: model,
            behaviorIdentity: Self.drawbridgeBehaviorIdentity,
            parent: parent
        )
        guard attachDrawbridge(
            id,
            position: position,
            moveYaw: moveYaw,
            action: action,
            faceRoll: faceRoll,
            in: engineState.objects
        ) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned LLL drawbridge half could not attach")
        }
        return id
    }

    @discardableResult
    func attachDrawbridge(
        _ id: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        action: Int32 = 0,
        faceRoll: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        drawbridges.insert(id)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.action = action
            record.timer = 0
            record.moveAngles.yaw = moveYaw
            record.faceAngles.yaw = moveYaw
            record.faceAngles.roll = faceRoll
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateSpawnerInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64LllDrawbridgeSpawnerObjectEffectRecord? {
        guard spawners.contains(id), let record = engineState.objects.record(for: id) else {
            return nil
        }
        let yaw = Int16(truncatingIfNeeded: record.moveAngles.yaw)
        let forwardX = SM64DeterministicPrimitives.cFloatMultiply(
            SM64CanonicalTrig.coss(yaw), 640
        )
        let forwardZ = SM64DeterministicPrimitives.cFloatMultiply(
            SM64CanonicalTrig.sins(yaw), 640
        )
        let offsets = [
            SM64ObjectVector3(
                x: record.position.x + forwardX,
                y: record.position.y,
                z: record.position.z + forwardZ
            ),
            SM64ObjectVector3(
                x: record.position.x - forwardX,
                y: record.position.y,
                z: record.position.z - forwardZ
            ),
        ]
        let yaws = [record.moveAngles.yaw, record.moveAngles.yaw &+ 0x8000]
        var children: [SM64ObjectID] = []
        for index in offsets.indices {
            if let child = try? spawnDrawbridge(
                in: engineState,
                position: offsets[index],
                moveYaw: yaws[index],
                parent: id
            ) {
                children.append(child)
            }
        }
        _ = engineState.objects.markForDeletion(id)
        let effect = SM64LllDrawbridgeSpawnerObjectEffectRecord(
            objectID: id,
            spawnedChildren: children
        )
        spawnerEffectLog.append(effect)
        return effect
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64LllDrawbridgeObjectEffectRecord? {
        guard drawbridges.contains(id), let record = engineState.objects.record(for: id) else {
            return nil
        }
        let output = SM64LllDrawbridgeBehavior.update(
            SM64LllDrawbridgeInput(
                action: record.action,
                timer: record.timer,
                globalTimer: engineState.globals.frame,
                faceRoll: record.faceAngles.roll
            )
        )
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = record.timer &+ 1
            next.faceAngles.roll = output.faceRoll
            next.faceAngles.yaw = next.moveAngles.yaw
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64LllDrawbridgeObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        spawners.remove(id)
        drawbridges.remove(id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
