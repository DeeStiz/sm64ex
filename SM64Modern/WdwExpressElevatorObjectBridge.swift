import Foundation

struct SM64WdwExpressElevatorObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let kind: SM64WdwExpressElevatorKind
    let output: SM64WdwExpressElevatorOutput
}

/// Shared owner route for WDW express-elevator and static surface identities.
final class SM64WdwExpressElevatorObjectBridge {
    static let elevatorBehaviorIdentity: UInt64 = 0x6268_765F_776465
    static let staticPlatformBehaviorIdentity: UInt64 = 0x6268_765F_776470
    static let defaultModel: UInt32 = 0

    private struct State {
        let kind: SM64WdwExpressElevatorKind
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64WdwExpressElevatorObjectEffectRecord] = []

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
        positionY: Float = 0,
        action: Int32 = 0,
        model: UInt32 = SM64WdwExpressElevatorObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        try spawn(in: engineState, kind: .elevator, positionY: positionY,
                  action: action, model: model, behaviorIdentity: Self.elevatorBehaviorIdentity)
    }

    @discardableResult
    func spawnStaticPlatform(
        in engineState: SM64SwiftEngineState,
        positionY: Float = 0,
        model: UInt32 = SM64WdwExpressElevatorObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        try spawn(in: engineState, kind: .staticPlatform, positionY: positionY,
                  action: 0, model: model, behaviorIdentity: Self.staticPlatformBehaviorIdentity)
    }

    private func spawn(
        in engineState: SM64SwiftEngineState,
        kind: SM64WdwExpressElevatorKind,
        positionY: Float,
        action: Int32,
        model: UInt32,
        behaviorIdentity: UInt64
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, model: model,
                                             behaviorIdentity: behaviorIdentity)
        guard attach(id, kind: kind, positionY: positionY, action: action,
                     in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned WDW express elevator could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        kind: SM64WdwExpressElevatorKind,
        positionY: Float,
        action: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, positionY.isFinite else { return false }
        states[id] = State(kind: kind)
        return pool.mutate(id) { record in
            record.position.y = positionY
            record.homePosition.y = positionY
            record.action = action
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64WdwExpressElevatorObjectEffectRecord? {
        guard let elevatorState = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64WdwExpressElevatorBehavior.update(
            SM64WdwExpressElevatorInput(
                kind: elevatorState.kind,
                action: record.action,
                timer: record.timer,
                positionY: record.position.y,
                homeY: record.homePosition.y,
                marioOnPlatform: record.platform == id
            )
        )
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.position.y = output.positionY
            next.velocity.y = output.velocityY
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64WdwExpressElevatorObjectEffectRecord(
            objectID: id,
            kind: elevatorState.kind,
            output: output
        )
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
