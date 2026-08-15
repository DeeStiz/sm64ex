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
    private(set) var saveFileIndex: Int

    init(
        actor: SM64ProgressionActorState = .init(),
        progression: SM64ProgressionState = .init(),
        menuAges: SM64CoinScoreAgeState = .init(),
        saveFileIndex: Int = 0
    ) {
        precondition((0..<SM64CoinScoreAgeState.fileCount).contains(saveFileIndex))
        self.actor = actor
        self.progression = progression
        self.menuAges = menuAges
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

    func saveSnapshot() -> SM64SaveFileSnapshot {
        SM64SaveFileCodec.snapshot(from: progression)
    }

    func menuSnapshot() -> SM64MenuDataSnapshot {
        SM64MenuDataCodec.snapshot(from: menuAges)
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
