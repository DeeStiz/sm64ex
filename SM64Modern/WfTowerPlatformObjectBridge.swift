import Foundation

struct SM64WfTowerPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let parentID: SM64ObjectID
    let kind: SM64WfTowerPlatformKind
    let output: SM64WfTowerPlatformOutput
}

/// Shared owner bridge for WF elevator and sliding tower children.
final class SM64WfTowerPlatformObjectBridge {
    static let elevatorBehaviorIdentity: UInt64 = 0x6268_765F_777465
    static let slidingBehaviorIdentity: UInt64 = 0x6268_765F_77746C
    static let defaultModel: UInt32 = 0

    private struct State {
        let parentID: SM64ObjectID
        let kind: SM64WfTowerPlatformKind
        let distance: Int32
        let speed: Float
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WfTowerPlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnElevator(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        model: UInt32 = SM64WfTowerPlatformObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        try spawn(
            in: engineState,
            parent: parent,
            kind: .elevator,
            position: position,
            distance: 0,
            speed: 0,
            model: model,
            behaviorIdentity: Self.elevatorBehaviorIdentity
        )
    }

    @discardableResult
    func spawnSliding(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        position: SM64ObjectVector3 = .zero,
        moveYaw: Int16 = 0,
        distance: Int32 = 380,
        speed: Float = 3,
        model: UInt32 = SM64WfTowerPlatformObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let id = try spawn(
            in: engineState,
            parent: parent,
            kind: .sliding,
            position: position,
            distance: distance,
            speed: speed,
            model: model,
            behaviorIdentity: Self.slidingBehaviorIdentity
        )
        _ = engineState.objects.mutate(id) { record in
            record.moveAngles.yaw = Int32(moveYaw)
        }
        return id
    }

    private func spawn(
        in engineState: SM64SwiftEngineState,
        parent: SM64ObjectID,
        kind: SM64WfTowerPlatformKind,
        position: SM64ObjectVector3,
        distance: Int32,
        speed: Float,
        model: UInt32,
        behaviorIdentity: UInt64
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard attach(id, parent: parent, kind: kind, position: position,
                     distance: distance, speed: speed, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned WF tower platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        parent: SM64ObjectID,
        kind: SM64WfTowerPlatformKind,
        position: SM64ObjectVector3 = .zero,
        distance: Int32 = 0,
        speed: Float = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, pool.record(for: parent) != nil,
              distance >= 0, speed.isFinite else { return false }
        states[id] = State(parentID: parent, kind: kind, distance: distance, speed: speed)
        return pool.mutate(id) { record in
            record.parent = parent
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
    ) -> SM64WfTowerPlatformObjectEffectRecord? {
        guard let platformState = states[id],
              let record = engineState.objects.record(for: id),
              let parent = engineState.objects.record(for: platformState.parentID) else { return nil }
        let output = SM64WfTowerPlatformBehavior.update(
            SM64WfTowerPlatformInput(
                kind: platformState.kind,
                action: record.action,
                timer: record.timer,
                positionX: record.position.x,
                positionY: record.position.y,
                positionZ: record.position.z,
                moveYaw: Int16(truncatingIfNeeded: record.moveAngles.yaw),
                distance: platformState.distance,
                speed: platformState.speed,
                marioOnPlatform: record.platform == id,
                parentAction: parent.action
            )
        )
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.position.x = output.positionX
            next.position.y = output.positionY
            next.position.z = output.positionZ
            next.forwardVelocity = output.forwardVelocity
            next.velocity.x = output.velocityX
            next.velocity.z = output.velocityZ
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
            if output.shouldDelete { next.activeFlags = 0 }
        }
        let effect = SM64WfTowerPlatformObjectEffectRecord(
            objectID: id,
            parentID: platformState.parentID,
            kind: platformState.kind,
            output: output
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs {
            guard let state = states[id], pool.record(for: id) != nil,
                  pool.record(for: state.parentID) != nil else { remove(id); continue }
        }
    }
}
