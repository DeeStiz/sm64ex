import Foundation

struct SM64PyramidElevatorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64PyramidElevatorOutput
}

struct SM64PyramidMarkerObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let active: Bool
}

/// Owner bridge for the pyramid elevator and its parent-owned trajectory
/// marker balls. The marker route is intentionally separate so deactivation
/// never invents a fake elevator callback.
final class SM64PyramidElevatorObjectBridge {
    static let elevatorBehaviorIdentity: UInt64 = 0x6268_765F_707965
    static let markerBehaviorIdentity: UInt64 = 0x6268_765F_70796D
    static let defaultModel: UInt32 = 0

    private var elevatorIDs: Set<SM64ObjectID> = []
    private var markerIDs: Set<SM64ObjectID> = []
    private(set) var elevatorEffectLog: [SM64PyramidElevatorObjectEffectRecord] = []
    private(set) var markerEffectLog: [SM64PyramidMarkerObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        (elevatorIDs.union(markerIDs)).sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() {
        elevatorEffectLog.removeAll(keepingCapacity: true)
        markerEffectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnElevator(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 4600,
        model: UInt32 = SM64PyramidElevatorObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, model: model,
                                             behaviorIdentity: Self.elevatorBehaviorIdentity)
        guard attachElevator(id, positionY: positionY, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned pyramid elevator could not attach")
        }
        return id
    }

    @discardableResult
    func spawnMarker(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        positionY: Float,
        model: UInt32 = SM64PyramidElevatorObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .unimportant, model: model,
                                             behaviorIdentity: Self.markerBehaviorIdentity,
                                             parent: parent)
        guard engineState.objects.mutate(id, { record in
            record.position.y = positionY
            record.homePosition.y = positionY
            record.scale = .init(x: 0.15, y: 0.15, z: 0.15)
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned pyramid marker could not attach")
        }
        markerIDs.insert(id)
        return id
    }

    @discardableResult
    func attachElevator(
        _ id: SM64ObjectID,
        positionY: Float,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, positionY.isFinite else { return false }
        elevatorIDs.insert(id)
        return pool.mutate(id) { record in
            record.position.y = positionY
            record.homePosition.y = positionY
            record.action = 0
            record.timer = 0
            record.velocity.y = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateElevator(_ id: SM64ObjectID, state: SM64SwiftEngineState)
        -> SM64PyramidElevatorObjectEffectRecord?
    {
        guard elevatorIDs.contains(id), let record = state.objects.record(for: id) else { return nil }
        let output = SM64PyramidElevatorBehavior.update(
            SM64PyramidElevatorInput(
                action: record.action,
                timer: record.timer,
                positionY: record.position.y,
                homeY: record.homePosition.y,
                velocityY: record.velocity.y,
                marioOnPlatform: record.platform != nil
            )
        )
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = state.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.position.y = output.positionY
            next.velocity.y = output.velocityY
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64PyramidElevatorObjectEffectRecord(objectID: id, output: output)
        elevatorEffectLog.append(effect)
        return effect
    }

    @discardableResult
    func updateMarker(_ id: SM64ObjectID, state: SM64SwiftEngineState)
        -> SM64PyramidMarkerObjectEffectRecord?
    {
        guard markerIDs.contains(id), let record = state.objects.record(for: id),
              let parent = state.objects.record(for: record.parent) else { return nil }
        let active = parent.action == 0
        _ = state.objects.mutate(id) { next in
            next.scale = .init(x: 0.15, y: 0.15, z: 0.15)
            next.activeFlags = active
                ? SM64ObjectPool.activeFlagActive | SM64ObjectPool.activeFlagUnknown8
                : 0
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64PyramidMarkerObjectEffectRecord(objectID: id, active: active)
        markerEffectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        elevatorIDs.remove(id)
        markerIDs.remove(id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in elevatorIDs where pool.record(for: id) == nil { remove(id) }
        for id in markerIDs where pool.record(for: id) == nil { remove(id) }
    }
}
