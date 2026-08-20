import Foundation

struct SM64KoopaFlagObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64KoopaFlagOutput
}

final class SM64KoopaFlagObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6B6667
    static let poleGrabbingBehaviorIdentity: UInt64 = 0x6268_765F_706F6C
    static let treeBehaviorIdentity: UInt64 = 0x6268_765F_747265
    static let defaultModel: UInt32 = 0
    static let poleInteractionType: UInt32 = 1 << 6

    private struct State: Sendable {
        var marioY: Float
        var marioPunching: Bool
    }

    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64KoopaFlagObjectEffectRecord] = []

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        hitboxHeight: Float = 700,
        behaviorIdentity: UInt64 = SM64KoopaFlagObjectBridge.defaultBehaviorIdentity,
        parent: SM64ObjectID? = nil
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(
            in: .polelike,
            model: Self.defaultModel,
            behaviorIdentity: behaviorIdentity,
            parent: parent
        )
        guard engineState.objects.mutate(id, { record in
            record.position = position
            record.homePosition = position
            record.interactionType = Self.poleInteractionType
            record.hitboxRadius = 80
            record.hitboxHeight = hitboxHeight
            record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Koopa Flag could not attach")
        }
        states[id] = State(marioY: position.y, marioPunching: false)
        return id
    }

    @discardableResult
    func setMario(marioY: Float, punching: Bool, for id: SM64ObjectID) -> Bool {
        guard states[id] != nil else { return false }
        states[id] = State(marioY: marioY, marioPunching: punching)
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64KoopaFlagBehavior.update(.init(
            timer: record.timer,
            positionY: record.position.y,
            hitboxHeight: record.hitboxHeight,
            marioY: state.marioY,
            marioPunching: state.marioPunching
        ))
        _ = engineState.objects.mutate(id) { next in
            next.timer = output.timer
            next.hitboxRadius = 80
            next.hitboxHeight = record.hitboxHeight
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output))
        return true
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
