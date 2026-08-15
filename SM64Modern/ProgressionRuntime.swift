import Foundation

enum SM64ProgressionRuntimeEventID: UInt32, Sendable {
    case resetLevel = 1
    case collectRedCoin = 2
    case pressCapSwitch = 3
    case completeLevel = 4
}

struct SM64ProgressionRuntimeTrace: Equatable, Sendable {
    let simulationTick: UInt64
    let eventID: SM64ProgressionRuntimeEventID
    let accepted: Bool
    let values: [UInt64]
}

struct SM64ProgressionRuntimeResult: Equatable, Sendable {
    let actor: SM64ProgressionActorState
    let progression: SM64ProgressionState
    let menuAges: SM64CoinScoreAgeState
    let actorEffects: SM64ProgressionActorEffect
    let progressionEffects: SM64ProgressionEffect
    let persistenceNeeded: Bool
    let trace: SM64ProgressionRuntimeTrace
}

/// Owner-thread composition of actor mutation, high-score age mutation, and
/// persistence snapshots. The runtime owns no C globals; a caller decides
/// when to commit the returned snapshots at a logical save boundary.
struct SM64ProgressionRuntime: Equatable, Sendable {
    private(set) var actor: SM64ProgressionActorState
    private(set) var progression: SM64ProgressionState
    private(set) var menuAges: SM64CoinScoreAgeState
    private(set) var soundMode: UInt16
    private(set) var saveFileIndex: Int

    init(
        actor: SM64ProgressionActorState = .init(),
        progression: SM64ProgressionState = .init(),
        menuAges: SM64CoinScoreAgeState = .init(),
        soundMode: UInt16 = 0,
        saveFileIndex: Int = 0
    ) {
        precondition((0..<SM64CoinScoreAgeState.fileCount).contains(saveFileIndex))
        self.actor = actor
        self.progression = progression
        self.menuAges = menuAges
        self.soundMode = soundMode
        self.saveFileIndex = saveFileIndex
    }

    mutating func apply(
        _ event: SM64ProgressionActorEvent,
        simulationTick: UInt64
    ) -> SM64ProgressionRuntimeResult? {
        let previousScore = courseScore(for: progression)
        guard let reduced = SM64ProgressionActorReducer.reduce(
            event, actor: actor, progression: progression
        ) else { return nil }
        actor = reduced.actor
        progression = reduced.progression

        if case let .completeLevel(kind, _, coinScore, _) = event,
           kind == .courseStar,
           let courseIndex = courseIndex,
           courseIndex < SM64ProgressionState.stageCount,
           coinScore > previousScore,
           let aged = SM64CoinScoreAgeReducer.touch(
               fileIndex: saveFileIndex, courseIndex: courseIndex, state: menuAges
           ) {
            menuAges = aged.state
        }

        let eventID = Self.eventID(for: event)
        let trace = SM64ProgressionRuntimeTrace(
            simulationTick: simulationTick,
            eventID: eventID,
            accepted: reduced.accepted,
            values: [
                UInt64(actor.redCoinsCollected),
                actor.redCoinStarSpawned ? 1 : 0,
                UInt64(actor.capSwitchesPressed),
                actor.levelCompleted ? 1 : 0,
                UInt64(progression.flags),
                UInt64(bitPattern: Int64(progression.coins)),
                UInt64(courseScore(for: progression)),
                UInt64(SM64CoinScoreAgeReducer.age(
                    fileIndex: saveFileIndex,
                    courseIndex: courseIndex ?? 0,
                    state: menuAges
                ) ?? 0)
            ]
        )
        return SM64ProgressionRuntimeResult(
            actor: actor, progression: progression, menuAges: menuAges,
            actorEffects: reduced.effects,
            progressionEffects: reduced.progressionEffects,
            persistenceNeeded: progression.saveModified || menuAges.modified,
            trace: trace
        )
    }

    @discardableResult
    mutating func applyProgression(
        _ event: SM64ProgressionEvent
    ) -> SM64ProgressionReduceResult? {
        guard let reduced = SM64ProgressionReducer.reduce(
            event, state: progression
        ) else { return nil }
        progression = reduced.state
        return reduced
    }

    func saveSnapshot() -> SM64SaveFileSnapshot {
        SM64SaveFileCodec.snapshot(from: progression)
    }

    func menuSnapshot() -> SM64MenuDataSnapshot {
        var snapshot = SM64MenuDataCodec.snapshot(from: menuAges)
        snapshot.soundMode = soundMode
        return snapshot
    }

    /// Replaces persisted fields from a canonical C snapshot after a live
    /// save boundary. Transient course/actor routing stays under the owner
    /// thread's event policy; dirty bits are cleared only after the caller has
    /// accepted these bytes as the new durable source.
    mutating func adoptPersistedSnapshots(
        save: SM64SaveFileSnapshot,
        menu: SM64MenuDataSnapshot
    ) {
        progression.flags = save.flags & 0x00FF_FFFF
        progression.secretStars = UInt8((save.flags >> 24) & 0x7F)
        progression.courseStars = save.courseStars
        progression.courseCoinScores = save.courseCoinScores
        progression.capLevel = save.capLevel
        progression.capArea = save.capArea
        progression.capPosition = .init(
            x: Float(save.capPosition.x),
            y: Float(save.capPosition.y),
            z: Float(save.capPosition.z)
        )
        progression.saveModified = false
        menuAges = SM64CoinScoreAgeState(
            ages: menu.coinScoreAges, modified: false
        )
        soundMode = menu.soundMode
    }

    @discardableResult
    mutating func selectSaveFile(_ index: Int) -> Bool {
        guard (0..<SM64CoinScoreAgeState.fileCount).contains(index) else {
            return false
        }
        saveFileIndex = index
        return true
    }

    @discardableResult
    mutating func selectCourse(_ number: Int) -> Bool {
        guard (1...SM64ProgressionState.courseCount).contains(number) else {
            return false
        }
        progression.courseNumber = Int16(number)
        return true
    }

    @discardableResult
    mutating func commitIfNeeded(
        using adapter: SM64OwnerThreadPersistenceAdapter,
        ownerThreadToken: UInt64
    ) throws -> Bool {
        guard progression.saveModified || menuAges.modified else { return false }
        try adapter.commit(
            save: saveSnapshot(), menu: menuSnapshot(),
            ownerThreadToken: ownerThreadToken
        )
        progression.saveModified = false
        menuAges.modified = false
        return true
    }

    mutating func reloadFromBackup(
        using adapter: SM64OwnerThreadPersistenceAdapter,
        ownerThreadToken: UInt64
    ) throws -> SM64PersistenceLoadResult {
        let loaded = try adapter.reload(ownerThreadToken: ownerThreadToken)
        progression.flags = loaded.save.flags
        progression.secretStars = UInt8((loaded.save.flags >> 24) & 0x7F)
        progression.flags &= 0x00FF_FFFF
        progression.courseStars = loaded.save.courseStars
        progression.courseCoinScores = loaded.save.courseCoinScores
        progression.capLevel = loaded.save.capLevel
        progression.capArea = loaded.save.capArea
        progression.capPosition = .init(
            x: Float(loaded.save.capPosition.x),
            y: Float(loaded.save.capPosition.y),
            z: Float(loaded.save.capPosition.z)
        )
        progression.saveModified = false
        menuAges = SM64CoinScoreAgeState(
            ages: loaded.menu.coinScoreAges, modified: false
        )
        soundMode = loaded.menu.soundMode
        actor = .init()
        return loaded
    }

    private var courseIndex: Int? {
        let index = Int(progression.courseNumber) - 1
        return (0..<SM64ProgressionState.stageCount).contains(index) ? index : nil
    }

    private func courseScore(for state: SM64ProgressionState) -> Int16 {
        guard let index = {
            let value = Int(state.courseNumber) - 1
            return (0..<SM64ProgressionState.stageCount).contains(value) ? value : nil
        }() else { return 0 }
        return Int16(state.courseCoinScores[index])
    }

    private static func eventID(
        for event: SM64ProgressionActorEvent
    ) -> SM64ProgressionRuntimeEventID {
        switch event {
        case .resetLevel: return .resetLevel
        case .collectRedCoin: return .collectRedCoin
        case .pressCapSwitch: return .pressCapSwitch
        case .completeLevel: return .completeLevel
        }
    }
}

/// Compact owner-thread result used by the M17 route replay fixture. It keeps
/// route identity/generation and durable snapshot hashes together so a replay
/// can reject stale object lifetimes without serializing Swift object graphs.
struct SM64ProgressionReplayRecord: Equatable, Sendable {
    let routeID: UInt8
    let generation: UInt32
    let accepted: Bool
    let saveHash: UInt64
    let menuHash: UInt64
}

private enum SM64ProgressionReplayHash {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211
}

/// Owner-thread progression route replay. This is deliberately a value-level
/// harness: it drives the same reducer/runtime and EEPROM adapter composition
/// used by the migration service, while C remains the differential authority.
struct SM64ProgressionRouteReplay: Sendable {
    private let adapter: SM64OwnerThreadEEPROMAdapter
    private let ownerThreadToken: UInt64
    private let saveFileIndex: Int
    private var runtime: SM64ProgressionRuntime
    private(set) var records: [SM64ProgressionReplayRecord] = []

    init(
        adapter: SM64OwnerThreadEEPROMAdapter,
        ownerThreadToken: UInt64,
        saveFileIndex: Int = 0
    ) {
        precondition(
            (0..<SM64CoinScoreAgeState.fileCount).contains(saveFileIndex)
        )
        self.adapter = adapter
        self.ownerThreadToken = ownerThreadToken
        self.saveFileIndex = saveFileIndex
        self.runtime = SM64ProgressionRuntime(saveFileIndex: saveFileIndex)
    }

    mutating func run() throws -> [SM64ProgressionReplayRecord] {
        let fresh = try adapter.load(
            saveFileIndex: saveFileIndex, ownerThreadToken: ownerThreadToken
        )
        runtime.adoptPersistedSnapshots(save: fresh.save, menu: fresh.menu)
        append(
            routeID: 1, generation: 0,
            accepted: fresh.saveDecision == .eraseAndRewriteBoth
                || fresh.menuDecision == .wipeAndRewriteBoth
        )
        try adapter.commit(
            saveFileIndex: saveFileIndex, save: fresh.save, menu: fresh.menu,
            ownerThreadToken: ownerThreadToken
        )

        let recovery = try recoverPrimary()
        append(
            routeID: 2, generation: 0,
            accepted: recovery.saveDecision == .useBackupAndRewritePrimary
        )

        _ = runtime.selectCourse(1)
        for tick in 0..<8 {
            guard let result = runtime.apply(
                .collectRedCoin, simulationTick: UInt64(tick)
            ) else { throw SM64ProgressionReplayError.reducerRejected }
            if tick == 7 {
                append(
                    routeID: 3, generation: 1, accepted: result.actor.redCoinStarSpawned
                )
            }
        }
        guard runtime.apply(
            .pressCapSwitch(index: 0), simulationTick: 8
        ) != nil else { throw SM64ProgressionReplayError.reducerRejected }
        append(routeID: 4, generation: 1, accepted: true)

        guard runtime.apply(
            .completeLevel(
                kind: .courseStar, starIndex: 0,
                coinScore: 100, globalMaxCoinScore: 90
            ), simulationTick: 9
        ) != nil else { throw SM64ProgressionReplayError.reducerRejected }
        try commitAndAdopt()
        append(routeID: 5, generation: 1, accepted: true)

        _ = runtime.apply(.resetLevel, simulationTick: 10)
        let deathReload = try adapter.reload(
            saveFileIndex: saveFileIndex, ownerThreadToken: ownerThreadToken
        )
        runtime.adoptPersistedSnapshots(
            save: deathReload.save, menu: deathReload.menu
        )
        append(
            routeID: 6, generation: 1,
            accepted: SM64SaveFileCodec.encode(deathReload.save)
                == SM64SaveFileCodec.encode(runtime.saveSnapshot())
        )

        guard runtime.applyProgression(
            .setCapLocation(.klepto)
        ) != nil else { throw SM64ProgressionReplayError.reducerRejected }
        try commitAndAdopt()
        append(routeID: 7, generation: 1, accepted: true)

        guard runtime.applyProgression(
            .requestWarp(
                destination: .init(level: 9, area: 2, node: 3, argument: 4),
                checkpoint: .init(act: 1, course: 1, level: 9, area: 2, node: 3)
            )
        ) != nil else { throw SM64ProgressionReplayError.reducerRejected }
        append(routeID: 8, generation: 1, accepted: true)

        var lifetime = SM64ProgressionRouteLifetime(
            identity: .init(
                level: 9, area: 2,
                behaviorIdentity: 0x1234_5678_9ABC_DEF0, instance: 7
            ),
            kind: .hiddenRedCoinStar
        )
        let activated = lifetime.activate()
        let duplicate = lifetime.activate()
        let generation = lifetime.generation
        let deactivated = lifetime.deactivate()
        append(
            routeID: 9, generation: generation,
            accepted: activated && !duplicate && deactivated
        )
        return records
    }

    private mutating func commitAndAdopt() throws {
        let save = runtime.saveSnapshot()
        let menu = runtime.menuSnapshot()
        try adapter.commit(
            saveFileIndex: saveFileIndex, save: save, menu: menu,
            ownerThreadToken: ownerThreadToken
        )
        runtime.adoptPersistedSnapshots(save: save, menu: menu)
    }

    private func recoverPrimary() throws -> SM64PersistenceLoadResult {
        var bytes = Array(try Data(contentsOf: adapter.imageURL))
        bytes[SM64SaveFileSnapshot.byteCount * saveFileIndex] ^= 1
        try Data(bytes).write(to: adapter.imageURL, options: .atomic)
        return try adapter.load(
            saveFileIndex: saveFileIndex, ownerThreadToken: ownerThreadToken
        )
    }

    private mutating func append(
        routeID: UInt8, generation: UInt32, accepted: Bool
    ) {
        records.append(
            SM64ProgressionReplayRecord(
                routeID: routeID, generation: generation, accepted: accepted,
                saveHash: hash(SM64SaveFileCodec.encode(runtime.saveSnapshot())),
                menuHash: hash(SM64MenuDataCodec.encode(runtime.menuSnapshot()))
            )
        )
    }

    private func hash(_ bytes: [UInt8]) -> UInt64 {
        bytes.reduce(SM64ProgressionReplayHash.offset) { hash, byte in
            (hash ^ UInt64(byte)) &* SM64ProgressionReplayHash.prime
        }
    }
}

enum SM64ProgressionReplayError: Error {
    case reducerRejected
}
