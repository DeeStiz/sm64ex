import Foundation

struct SM64VolcanoFallingTrapObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64VolcanoFallingTrapOutput
}

final class SM64VolcanoFallingTrapObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_766674
    static let defaultModel: UInt32 = 0
    private var registered: Set<SM64ObjectID> = []
    private(set) var effectLog: [SM64VolcanoFallingTrapObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: Self.defaultModel,
            behaviorIdentity: Self.defaultBehaviorIdentity
        )
        guard engineState.objects.mutate(id, { record in
            record.position = position
            record.homePosition = position
            record.action = 0
            record.timer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned volcano falling trap could not attach")
        }
        registered.insert(id)
        return id
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard registered.contains(id), let record = engineState.objects.record(for: id) else { return false }
        let output = SM64VolcanoFallingTrapBehavior.update(.init(
            action: record.action,
            timer: record.timer,
            distanceToMario: record.distanceToMario,
            positionY: record.position.y,
            homeY: record.homePosition.y,
            facePitch: record.faceAngles.pitch,
            angleVelocityPitch: record.angleVelocity.pitch,
            acceleration: record.behaviorParams == 0 ? record.velocity.y : Float(record.behaviorParams)
        ))
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.position.y = output.positionY
            next.faceAngles.pitch = output.facePitch
            next.angleVelocity.pitch = output.angleVelocityPitch
            next.behaviorParams = Int32(output.acceleration)
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { registered.remove(id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
