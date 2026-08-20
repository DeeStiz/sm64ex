import Foundation

struct SM64CcmTouchedStarSpawnObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64CcmTouchedStarSpawnOutput
    let spawnedStar: SM64ObjectID?
}

final class SM64CcmTouchedStarSpawnObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_63636D
    static let hitboxRadius: Float = 500
    static let hitboxHeight: Float = 500

    private let starSpawnBridge: SM64StarSpawnCoordinatesObjectBridge?
    private struct State { var enteredSlide: Bool }
    private var states: [SM64ObjectID: State] = [:]
    private(set) var effectLog: [SM64CcmTouchedStarSpawnObjectEffectRecord] = []

    init(starSpawnBridge: SM64StarSpawnCoordinatesObjectBridge? = nil) {
        self.starSpawnBridge = starSpawnBridge
    }

    var registeredIDs: [SM64ObjectID] {
        states.keys.sorted {
            $0.slot == $1.slot ? $0.generation < $1.generation : $0.slot < $1.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero,
        enteredSlide: Bool = false
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .level, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard attach(id, position: position, enteredSlide: enteredSlide, in: engineState.objects) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned CCM star-spawn trigger could not attach")
        }
        return id
    }

    @discardableResult
    func attach(_ id: SM64ObjectID, position: SM64ObjectVector3, enteredSlide: Bool, in pool: SM64ObjectPool) -> Bool {
        guard pool.record(for: id) != nil else { return false }
        states[id] = State(enteredSlide: enteredSlide)
        return pool.mutate(id) { record in
            record.position = position
            record.homePosition = position
            record.hitboxRadius = Self.hitboxRadius
            record.hitboxHeight = Self.hitboxHeight
            record.intangibleTimer = 0
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
    }

    @discardableResult
    func setEnteredSlide(_ entered: Bool, for id: SM64ObjectID) -> Bool {
        guard var state = states[id] else { return false }
        state.enteredSlide = entered
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> SM64CcmTouchedStarSpawnObjectEffectRecord? {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return nil }
        let output = SM64CcmTouchedStarSpawnBehavior.update(.init(enteredSlide: state.enteredSlide, position: record.position))
        var spawnedStar: SM64ObjectID?
        if output.spawnStar, let starSpawnBridge {
            spawnedStar = try? starSpawnBridge.spawnStar(in: engineState, starCollected: false, position: output.starPosition, homePosition: output.starHomePosition)
        }
        _ = engineState.objects.mutate(id) { next in
            next.position = output.position
            next.timer &+= 1
            if output.shouldDelete { next.activeFlags = 0 }
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        let effect = SM64CcmTouchedStarSpawnObjectEffectRecord(objectID: id, output: output, spawnedStar: spawnedStar)
        effectLog.append(effect)
        return effect
    }

    func remove(_ id: SM64ObjectID) { states.removeValue(forKey: id) }
    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) { for id in unloaded { remove(id) }; for id in registeredIDs where pool.record(for: id) == nil { remove(id) } }
}
