import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ value: UInt8) -> UInt64 { var x = h; x ^= UInt64(value); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ value: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x = h8(x, UInt8(truncatingIfNeeded: value >> UInt16(i * 8))) }; return x }
private func h32(_ h: UInt64, _ value: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x = h8(x, UInt8(truncatingIfNeeded: value >> UInt32(i * 8))) }; return x }
private func h64(_ h: UInt64, _ value: UInt64) -> UInt64 { var x = h; for i in 0..<8 { x = h8(x, UInt8(truncatingIfNeeded: value >> UInt64(i * 8))) }; return x }

private func hash(_ h: UInt64, _ result: SM64ProgressionRuntimeResult) -> UInt64 {
    var x = h64(h, result.trace.simulationTick)
    x = h32(x, result.trace.eventID.rawValue)
    x = h8(x, result.trace.accepted ? 1 : 0)
    for value in result.trace.values { x = h64(x, value) }
    x = h16(x, result.actorEffects.rawValue)
    x = h16(x, result.progressionEffects.rawValue)
    x = h8(x, result.persistenceNeeded ? 1 : 0)
    return x
}

@main
enum SM64ModernProgressionRuntimeSmoke {
    static func main() throws {
        var runtime = SM64ProgressionRuntime(
            progression: .init(
                flags: SM64ProgressionReducer.fileExists,
                coins: 10, courseNumber: 3
            ),
            saveFileIndex: 0
        )
        var fingerprint = fnvOffset
        for tick in 0..<8 {
            let result = runtime.apply(
                .collectRedCoin, simulationTick: UInt64(tick)
            )!
            fingerprint = hash(fingerprint, result)
        }
        precondition(runtime.progression.coins == 26)
        precondition(!runtime.menuAges.modified)

        let reward = runtime.apply(
            .completeLevel(
                kind: .courseStar, starIndex: 2, coinScore: 100,
                globalMaxCoinScore: 95
            ), simulationTick: 8
        )!
        fingerprint = hash(fingerprint, reward)
        precondition(reward.persistenceNeeded)
        precondition(runtime.menuAges.modified)
        precondition(SM64CoinScoreAgeReducer.age(
            fileIndex: 0, courseIndex: 2, state: runtime.menuAges
        ) == 0)
        precondition(runtime.saveSnapshot().courseCoinScores[2] == 100)

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-modern-runtime-\(UUID().uuidString)")
        let adapter = try SM64OwnerThreadPersistenceAdapter(
            rootURL: root, ownerThreadToken: 7
        )
        let committed = try runtime.commitIfNeeded(
            using: adapter, ownerThreadToken: 7
        )
        precondition(committed)
        precondition(!runtime.progression.saveModified && !runtime.menuAges.modified)

        _ = runtime.apply(.resetLevel, simulationTick: 9)
        let reload = try runtime.reloadFromBackup(using: adapter, ownerThreadToken: 7)
        precondition(reload.save.courseCoinScores[2] == 100)
        precondition(runtime.progression.coins == 26)
        precondition(runtime.actor == .init())

        print(String(format: "progressionRuntimeFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern progression-runtime smoke passed")
    }
}
