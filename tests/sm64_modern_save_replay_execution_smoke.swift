import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hash(_ bytes: [UInt8]) -> UInt64 {
    bytes.reduce(fnvOffset) { ($0 ^ UInt64($1)) &* fnvPrime }
}

private func imageHash(
    save: SM64SaveFileSnapshot,
    menu: SM64MenuDataSnapshot
) -> UInt64 {
    hash(SM64SaveFileCodec.encode(save) + SM64MenuDataCodec.encode(menu))
}

private func corruptSelectedPrimary(at url: URL) throws {
    var bytes = Array(try Data(contentsOf: url))
    precondition(bytes.count == SM64PersistenceImage.byteCount)
    bytes[0] ^= 0x01
    try Data(bytes).write(to: url, options: .atomic)
}

private func replayRecord(
    sequence: UInt64,
    direction: SM64SaveReplayDirection,
    operation: SM64SaveReplayOperation,
    before: (save: SM64SaveFileSnapshot, menu: SM64MenuDataSnapshot),
    after: (save: SM64SaveFileSnapshot, menu: SM64MenuDataSnapshot),
    saveFileIndex: UInt32 = 0,
    mutationKind: UInt32 = 0,
    mutationOperation: UInt32 = 0,
    sourceFileIndex: UInt32 = UInt32.max,
    mutationFlags: UInt32 = 0,
    mutationCourseIndex: UInt32 = UInt32.max,
    mutationStarFlags: Int32 = -1,
    mutationLevel: UInt32 = 0,
    mutationArea: UInt32 = 0,
    mutationCapX: Int32 = 0,
    mutationCapY: Int32 = 0,
    mutationCapZ: Int32 = 0,
    mutationSoundMode: UInt32 = 0,
    saveRecoveryDecision: UInt32 = 0,
    menuRecoveryDecision: UInt32 = 0
) -> SM64SaveReplayRecord {
    SM64SaveReplayRecord(
        sequence: sequence,
        simulationTick: sequence,
        direction: direction,
        operation: operation,
        saveFileIndex: saveFileIndex,
        mutationKind: mutationKind,
        mutationOperation: mutationOperation,
        sourceFileIndex: sourceFileIndex,
        mutationFlags: mutationFlags,
        mutationCourseIndex: mutationCourseIndex,
        mutationStarFlags: mutationStarFlags,
        mutationLevel: mutationLevel,
        mutationArea: mutationArea,
        mutationCapX: mutationCapX,
        mutationCapY: mutationCapY,
        mutationCapZ: mutationCapZ,
        mutationSoundMode: mutationSoundMode,
        saveRecoveryDecision: saveRecoveryDecision,
        menuRecoveryDecision: menuRecoveryDecision,
        status: 0,
        beforeSaveHash: hash(SM64SaveFileCodec.encode(before.save)),
        beforeMenuHash: hash(SM64MenuDataCodec.encode(before.menu)),
        afterSaveHash: hash(SM64SaveFileCodec.encode(after.save)),
        afterMenuHash: hash(SM64MenuDataCodec.encode(after.menu)),
        imageHash: imageHash(save: after.save, menu: after.menu)
    )
}

@main
enum SM64ModernSaveReplayExecutionSmoke {
    static func main() throws {
        var stars = Array(repeating: UInt8(0), count: 25)
        stars[0] = 0x04
        let baseSave = SM64SaveFileSnapshot(
            capLevel: 8, capArea: 2,
            capPosition: .init(x: -10, y: 20, z: 30),
            flags: SM64SaveFileMutator.fileExistsFlag
                | SM64SaveFileMutator.capOnGroundFlag,
            courseStars: stars
        )
        let baseMenu = SM64MenuDataSnapshot(
            coinScoreAges: [1, 2, 3, 4], soundMode: 0x1234,
            filler: Array(0xA0..<0xAA)
        )
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-modern-save-replay-execution-\(UUID().uuidString)")
        let adapter = try SM64OwnerThreadEEPROMAdapter(rootURL: root, ownerThreadToken: 9)
        try adapter.commit(saveFileIndex: 0, save: baseSave, menu: baseMenu, ownerThreadToken: 9)
        var loaded = try adapter.load(saveFileIndex: 0, ownerThreadToken: 9)
        var ledger = SM64SaveReplayLedger(
            authority: .swift,
            requiresRestart: true,
            initialImageHash: imageHash(save: loaded.save, menu: loaded.menu)
        )
        var sequence: UInt64 = 0
        ledger.append(replayRecord(
            sequence: sequence, direction: .cToSwift, operation: .initialize,
            before: (loaded.save, loaded.menu), after: (loaded.save, loaded.menu)
        ))

        sequence += 1
        let beforeFlags = loaded
        let flagsResult = try adapter.apply(
            .setFlags(1 << 10), saveFileIndex: 0, ownerThreadToken: 9
        )
        ledger.append(replayRecord(
            sequence: sequence, direction: .cToSwift, operation: .mutation,
            before: (beforeFlags.save, beforeFlags.menu),
            after: (flagsResult.save, flagsResult.menu), mutationKind: 3,
            mutationFlags: 1 << 10
        ))
        loaded = try adapter.load(saveFileIndex: 0, ownerThreadToken: 9)

        sequence += 1
        let beforeRecovery = loaded
        try corruptSelectedPrimary(at: adapter.imageURL)
        let recovered = try adapter.load(saveFileIndex: 0, ownerThreadToken: 9)
        precondition(recovered.saveDecision == .useBackupAndRewritePrimary)
        ledger.append(replayRecord(
            sequence: sequence, direction: .cToSwift, operation: .recovery,
            before: (beforeRecovery.save, beforeRecovery.menu),
            after: (recovered.save, recovered.menu),
            saveRecoveryDecision: UInt32(recovered.saveDecision.rawValue),
            menuRecoveryDecision: UInt32(recovered.menuDecision.rawValue)
        ))
        loaded = recovered

        sequence += 1
        let beforeStars = loaded
        let starsResult = try adapter.apply(
            .setStarFlags(starFlags: 0x82, courseIndex: 0),
            saveFileIndex: 0, ownerThreadToken: 9
        )
        ledger.append(replayRecord(
            sequence: sequence, direction: .cToSwift, operation: .mutation,
            before: (beforeStars.save, beforeStars.menu),
            after: (starsResult.save, starsResult.menu), mutationKind: 4,
            mutationCourseIndex: 0, mutationStarFlags: 0x82
        ))
        loaded = try adapter.load(saveFileIndex: 0, ownerThreadToken: 9)

        sequence += 1
        let beforeCap = loaded
        let capResult = try adapter.apply(
            .setCapPosition(level: 9, area: 3, position: .init(x: -100, y: 200, z: 300)),
            saveFileIndex: 0, ownerThreadToken: 9
        )
        ledger.append(replayRecord(
            sequence: sequence, direction: .cToSwift, operation: .mutation,
            before: (beforeCap.save, beforeCap.menu),
            after: (capResult.save, capResult.menu), mutationKind: 6,
            mutationLevel: 9, mutationArea: 3,
            mutationCapX: -100, mutationCapY: 200, mutationCapZ: 300
        ))
        loaded = try adapter.load(saveFileIndex: 0, ownerThreadToken: 9)

        sequence += 1
        let beforePersist = loaded
        try adapter.commit(
            saveFileIndex: 0, save: loaded.save, menu: loaded.menu,
            ownerThreadToken: 9
        )
        ledger.append(replayRecord(
            sequence: sequence, direction: .swiftToC, operation: .persist,
            before: (beforePersist.save, beforePersist.menu),
            after: (loaded.save, loaded.menu)
        ))

        sequence += 1
        let reloaded = try adapter.reload(saveFileIndex: 0, ownerThreadToken: 9)
        ledger.append(replayRecord(
            sequence: sequence, direction: .cToSwift, operation: .reload,
            before: (loaded.save, loaded.menu),
            after: (reloaded.save, reloaded.menu)
        ))

        let artifactURL = root.appendingPathComponent("replay.bin")
        let artifact = ledger.artifact(
            finalImageHash: imageHash(save: reloaded.save, menu: reloaded.menu)
        )
        try artifact.write(to: artifactURL)
        let persisted = try SM64SaveReplayArtifact.read(from: artifactURL)
        precondition(persisted.records.count == 7)
        precondition(persisted.records[1].mutationFlags == 1 << 10)
        precondition(persisted.records[3].mutationStarFlags == 0x82)
        precondition(persisted.records[4].mutationCapX == -100)

        let replayRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-modern-save-replay-replay-\(UUID().uuidString)")
        let replayAdapter = try SM64OwnerThreadEEPROMAdapter(
            rootURL: replayRoot, ownerThreadToken: 11
        )
        try replayAdapter.commit(
            saveFileIndex: 0, save: baseSave, menu: baseMenu,
            ownerThreadToken: 11
        )
        for record in persisted.records.dropFirst() {
            let before = try replayAdapter.load(saveFileIndex: 0, ownerThreadToken: 11)
            precondition(hash(SM64SaveFileCodec.encode(before.save)) == record.beforeSaveHash)
            precondition(hash(SM64MenuDataCodec.encode(before.menu)) == record.beforeMenuHash)
            let after: SM64PersistenceLoadResult
            switch record.operation {
            case .mutation:
                let mutation: SM64SaveFileMutation
                switch record.mutationKind {
                case 3:
                    mutation = record.mutationOperation == 0
                        ? .setFlags(record.mutationFlags)
                        : .clearFlags(record.mutationFlags)
                case 4:
                    mutation = .setStarFlags(
                        starFlags: UInt32(bitPattern: record.mutationStarFlags),
                        courseIndex: record.mutationCourseIndex == UInt32.max
                            ? -1 : Int(record.mutationCourseIndex)
                    )
                case 6:
                    mutation = .setCapPosition(
                        level: UInt8(record.mutationLevel),
                        area: UInt8(record.mutationArea),
                        position: .init(
                            x: Int16(record.mutationCapX),
                            y: Int16(record.mutationCapY),
                            z: Int16(record.mutationCapZ)
                        )
                    )
                default:
                    throw NSError(domain: "SaveReplay", code: 3)
                }
                let result = try replayAdapter.apply(
                    mutation, saveFileIndex: 0, ownerThreadToken: 11
                )
                after = SM64PersistenceLoadResult(
                    save: result.save, menu: result.menu,
                    saveDecision: .usePrimary, menuDecision: .usePrimary
                )
            case .recovery:
                try corruptSelectedPrimary(at: replayAdapter.imageURL)
                after = try replayAdapter.load(saveFileIndex: 0, ownerThreadToken: 11)
                precondition(after.saveDecision.rawValue == record.saveRecoveryDecision)
            case .persist:
                try replayAdapter.commit(
                    saveFileIndex: 0, save: before.save, menu: before.menu,
                    ownerThreadToken: 11
                )
                after = try replayAdapter.load(saveFileIndex: 0, ownerThreadToken: 11)
            case .reload:
                after = try replayAdapter.reload(saveFileIndex: 0, ownerThreadToken: 11)
            case .initialize, .load:
                after = before
            }
            precondition(hash(SM64SaveFileCodec.encode(after.save)) == record.afterSaveHash)
            precondition(hash(SM64MenuDataCodec.encode(after.menu)) == record.afterMenuHash)
        }
        let final = try replayAdapter.load(saveFileIndex: 0, ownerThreadToken: 11)
        precondition(imageHash(save: final.save, menu: final.menu) == persisted.finalImageHash)

        var tampered = Array(try Data(contentsOf: artifactURL))
        tampered[64 + 64] ^= 1
        do {
            _ = try SM64SaveReplayArtifact.decode(Data(tampered))
            preconditionFailure("tampered replay artifact was accepted")
        } catch SM64SaveReplayArtifactError.nonCanonicalRecord {
            // Expected terminal tamper rejection.
        }
        print(String(
            format: "saveReplayExecutionFingerprint=0x%016llx",
            persisted.artifactHash
        ))
        print("SM64 Modern save replay execution smoke passed")
    }
}
