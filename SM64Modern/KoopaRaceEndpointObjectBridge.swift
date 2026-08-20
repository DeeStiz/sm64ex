import Foundation

struct SM64KoopaRaceEndpointObjectEffectRecord: Equatable, Sendable {
    let objectID: SM64ObjectID
    let output: SM64KoopaRaceEndpointOutput
    let spawnedFlag: SM64ObjectID?
}

final class SM64KoopaRaceEndpointObjectBridge {
    static let defaultBehaviorIdentity: UInt64 = 0x6268_765F_6B7265

    private struct State: Sendable {
        var raceBegun: Bool
        var koopaFinished: Bool
        var distanceToMario: Float
        var marioShotFromCannon: Bool
    }

    private let flagBridge: SM64KoopaFlagObjectBridge
    private var states: [SM64ObjectID: State] = [:]
    private var flags: [SM64ObjectID: SM64ObjectID] = [:]
    private(set) var effectLog: [SM64KoopaRaceEndpointObjectEffectRecord] = []

    init(flagBridge: SM64KoopaFlagObjectBridge) { self.flagBridge = flagBridge }

    var registeredIDs: [SM64ObjectID] {
        var ids = Array(states.keys)
        ids.append(contentsOf: flags.keys)
        return ids.sorted { lhs, rhs in
            lhs.slot == rhs.slot ? lhs.generation < rhs.generation : lhs.slot < rhs.slot
        }
    }

    func beginExternalTick() { effectLog.removeAll(keepingCapacity: true) }

    @discardableResult
    func spawn(
        in engineState: SM64SwiftEngineState,
        position: SM64ObjectVector3 = .zero
    ) throws -> SM64ObjectID {
        let id = try engineState.spawnObject(in: .default, behaviorIdentity: Self.defaultBehaviorIdentity)
        guard engineState.objects.mutate(id, { record in
            record.position = position
            record.homePosition = position
            record.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }) else {
            _ = engineState.objects.despawn(id)
            preconditionFailure("newly spawned Koopa race endpoint could not attach")
        }
        let flag = try flagBridge.spawn(
            in: engineState,
            position: position,
            hitboxHeight: 700,
            behaviorIdentity: SM64KoopaFlagObjectBridge.defaultBehaviorIdentity,
            parent: id
        )
        states[id] = State(raceBegun: false, koopaFinished: false, distanceToMario: 10_000, marioShotFromCannon: false)
        flags[id] = flag
        return id
    }

    @discardableResult
    func setRaceState(
        raceBegun: Bool,
        koopaFinished: Bool = false,
        distanceToMario: Float = 10_000,
        marioShotFromCannon: Bool = false,
        for id: SM64ObjectID
    ) -> Bool {
        guard var state = states[id] else { return false }
        state.raceBegun = raceBegun
        state.koopaFinished = koopaFinished
        state.distanceToMario = distanceToMario
        state.marioShotFromCannon = marioShotFromCannon
        states[id] = state
        return true
    }

    @discardableResult
    func updateInline(_ id: SM64ObjectID, state engineState: SM64SwiftEngineState) -> Bool {
        guard let state = states[id], let record = engineState.objects.record(for: id) else { return false }
        let output = SM64KoopaRaceEndpointBehavior.update(.init(
            raceBegun: state.raceBegun,
            raceEnded: record.action != 0,
            koopaFinished: state.koopaFinished,
            distanceToMario: state.distanceToMario,
            marioShotFromCannon: state.marioShotFromCannon,
            raceStatus: record.behaviorParams
        ))
        states[id] = State(raceBegun: state.raceBegun, koopaFinished: false, distanceToMario: 10_000, marioShotFromCannon: false)
        _ = engineState.objects.mutate(id) { next in
            next.action = output.raceEnded ? 1 : 0
            next.behaviorParams = output.raceStatus
            next.objectFlags |= SM64ObjectScheduler.objectFlagUpdateGfxPositionAndAngle
                | SM64ObjectScheduler.objectFlagBuildTransform
        }
        effectLog.append(.init(objectID: id, output: output, spawnedFlag: flags[id]))
        return true
    }

    func remove(_ id: SM64ObjectID) {
        states.removeValue(forKey: id)
        flags.removeValue(forKey: id)
    }

    func pruneExternal(unloaded: [SM64ObjectID], pool: SM64ObjectPool) {
        for id in unloaded { remove(id) }
        for id in registeredIDs where pool.record(for: id) == nil { remove(id) }
    }
}
