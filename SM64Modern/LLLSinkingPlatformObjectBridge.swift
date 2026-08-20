import Foundation

struct SM64LLLSinkingPlatformObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64LLLSinkingPlatformOutput
}

/// Shared owner bridge for the LLL rectangular and square sinking-platform
/// behavior identities. Oscillation is copied by stable object ID rather than
/// stored in a C object pointer or a second scheduler.
final class SM64LLLSinkingPlatformObjectBridge {
    static let rectangularBehaviorIdentity: UInt64 = 0x6268_765F_6C6C72
    static let squareBehaviorIdentity: UInt64 = 0x6268_765F_6C6C73
    static let defaultModel: UInt32 = 0

    private struct State {
        let rectangularMode: Bool
        var oscillationTimer: Int32
    }

    private var registered: Set<SM64ObjectID> = []
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64LLLSinkingPlatformObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        registered.sorted {
            if $0.slot != $1.slot { return $0.slot < $1.slot }
            return $0.generation < $1.generation
        }
    }

    func beginExternalTick() {
        effectLog.removeAll(keepingCapacity: true)
    }

    @discardableResult
    func spawnPlatform(
        in engineState: SM64SwiftEngineState,
        rectangularMode: Bool = true,
        positionY: Float = 0,
        model: UInt32 = SM64LLLSinkingPlatformObjectBridge.defaultModel
    ) throws -> SM64ObjectID {
        let identity = rectangularMode
            ? Self.rectangularBehaviorIdentity
            : Self.squareBehaviorIdentity
        let id = try engineState.spawnObject(
            in: .level,
            model: model,
            behaviorIdentity: identity
        )
        guard attach(id, rectangularMode: rectangularMode, positionY: positionY,
                     in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned LLL sinking platform could not attach")
        }
        return id
    }

    @discardableResult
    func attach(
        _ id: SM64ObjectID,
        rectangularMode: Bool,
        positionY: Float = 0,
        oscillationTimer: Int32 = 0,
        in pool: SM64ObjectPool
    ) -> Bool {
        guard pool.record(for: id) != nil, positionY.isFinite else { return false }
        registered.insert(id)
        states[id] = State(rectangularMode: rectangularMode, oscillationTimer: oscillationTimer)
        return pool.mutate(id) { record in
            record.position.y = positionY
            record.homePosition.y = positionY
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func updateInline(
        _ id: SM64ObjectID,
        state engineState: SM64SwiftEngineState
    ) -> SM64LLLSinkingPlatformObjectEffectRecord? {
        guard registered.contains(id),
              let record = engineState.objects.record(for: id),
              var platformState = states[id] else { return nil }
        let output = SM64LLLSinkingPlatformBehavior.update(
            SM64LLLSinkingPlatformInput(
                rectangularMode: platformState.rectangularMode,
                action: record.action,
                oscillationTimer: platformState.oscillationTimer,
                positionY: record.position.y,
                facePitch: record.faceAngles.pitch
            )
        )
        platformState.oscillationTimer = output.oscillationTimer
        states[id] = platformState
        let nextTimer = output.action == record.action ? record.timer &+ 1 : 0
        _ = engineState.objects.mutate(id) { next in
            next.action = output.action
            next.timer = nextTimer
            next.position.y = output.positionY
            next.faceAngles.pitch = output.facePitch
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64LLLSinkingPlatformObjectEffectRecord(objectID: id, output: output)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) {
        registered.remove(id)
        states.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
