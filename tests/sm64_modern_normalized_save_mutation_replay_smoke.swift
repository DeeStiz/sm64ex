import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func h8(_ h: UInt64, _ value: UInt8) -> UInt64 {
    var next = h
    next ^= UInt64(value)
    next &*= fnvPrime
    return next
}

private func hash(_ h: UInt64, _ bytes: [UInt8]) -> UInt64 {
    bytes.reduce(h) { h8($0, $1) }
}

private func hash(
    _ h: UInt64,
    save: SM64SaveFileSnapshot,
    menu: SM64MenuDataSnapshot,
    didMutate: Bool
) -> UInt64 {
    var next = hash(h, SM64SaveFileCodec.encode(save))
    next = hash(next, SM64MenuDataCodec.encode(menu))
    return h8(next, didMutate ? 1 : 0)
}

private func hash(
    _ h: UInt64,
    runtime: SM64ProgressionRuntime
) -> UInt64 {
    var next = hash(h, SM64SaveFileCodec.encode(runtime.saveSnapshot()))
    next = hash(next, SM64MenuDataCodec.encode(runtime.menuSnapshot()))
    next = h8(next, runtime.progression.saveModified ? 1 : 0)
    return h8(next, runtime.menuAges.modified ? 1 : 0)
}

@main
enum SM64ModernNormalizedSaveMutationReplaySmoke {
    static func main() throws {
        var stars = Array(repeating: UInt8(0), count: 25)
        stars[0] = 0x04
        let baseSave = SM64SaveFileSnapshot(
            capLevel: 8, capArea: 2,
            capPosition: .init(x: -10, y: 20, z: 30),
            flags: SM64SaveFileMutator.fileExistsFlag
                | SM64SaveFileMutator.capOnGroundFlag
                | SM64SaveFileMutator.capOnKleptoFlag,
            courseStars: stars
        )
        let baseMenu = SM64MenuDataSnapshot(
            coinScoreAges: [0x0123_4567, 0x89AB_CDEF, 0x1020_3040, 0x5566_7788],
            soundMode: 0x1234,
            filler: Array(0xA0..<0xAA)
        )
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-modern-normalized-replay-\(UUID().uuidString)")
        let adapter = try SM64OwnerThreadEEPROMAdapter(
            rootURL: root, ownerThreadToken: 7
        )
        try adapter.commit(
            saveFileIndex: 0, save: baseSave, menu: baseMenu,
            ownerThreadToken: 7
        )

        var loaded = try adapter.load(saveFileIndex: 0, ownerThreadToken: 7)
        var fingerprint = hash(
            fnvOffset, save: loaded.save, menu: loaded.menu, didMutate: false
        )

        let paused = try adapter.apply(
            .setFlags(1 << 10), saveFileIndex: 0,
            ownerThreadToken: 7, legacyDomainAdvances: false
        )
        precondition(!paused.didMutate)
        fingerprint = hash(
            fingerprint, save: paused.save, menu: paused.menu,
            didMutate: paused.didMutate
        )

        let mutations: [SM64SaveFileMutation] = [
            .setFlags(1 << 10),
            .clearFlags(
                SM64SaveFileMutator.capOnGroundFlag
                    | SM64SaveFileMutator.fileExistsFlag
            ),
            .setStarFlags(starFlags: 0x03, courseIndex: -1),
            .setStarFlags(starFlags: 0x82, courseIndex: 0),
            .setCannonUnlocked(currentCourseNumber: 1),
            .setCapPosition(
                level: 9, area: 3,
                position: .init(x: -100, y: 200, z: 300)
            ),
            .moveCapToDefaultLocation(level: 0x08),
            .setSoundMode(0x4321)
        ]
        for mutation in mutations {
            let result = try adapter.apply(
                mutation, saveFileIndex: 0, ownerThreadToken: 7
            )
            precondition(result.didMutate)
            fingerprint = hash(
                fingerprint, save: result.save, menu: result.menu,
                didMutate: result.didMutate
            )
        }

        do {
            _ = try adapter.apply(
                .moveCapToDefaultLocation(level: 0x08),
                saveFileIndex: 0, ownerThreadToken: 7
            )
            preconditionFailure("invalid no-ground move was accepted")
        } catch SM64PersistenceAdapterError.invalidMutation {
            loaded = try adapter.load(saveFileIndex: 0, ownerThreadToken: 7)
            fingerprint = hash(
                fingerprint, save: loaded.save, menu: loaded.menu,
                didMutate: false
            )
        } catch {
            preconditionFailure("unexpected normalized mutation error: \(error)")
        }

        let beforeRuntime = try adapter.load(
            saveFileIndex: 0, ownerThreadToken: 7
        )
        precondition(beforeRuntime.save.courseStars[0] == 0x86)
        let imageBytes = Array(try Data(contentsOf: adapter.imageURL))
        let image = SM64PersistenceImage.decode(imageBytes)!
        precondition(image.savePrimary == image.saveBackup)
        precondition(image.menuPrimary == image.menuBackup)
        precondition(image.savePrimary.dropFirst().allSatisfy {
            $0 == SM64SaveFileCodec.encode(SM64SaveFileSnapshot())
        })

        var runtime = SM64ProgressionRuntime()
        runtime.adoptPersistedSnapshots(save: loaded.save, menu: loaded.menu)
        precondition(runtime.setSaveFlags(1 << 20))
        fingerprint = hash(fingerprint, runtime: runtime)
        let committed = try runtime.commitIfNeeded(
            using: adapter, ownerThreadToken: 7
        )
        precondition(committed)
        precondition(!runtime.progression.saveModified && !runtime.menuAges.modified)
        fingerprint = hash(fingerprint, runtime: runtime)

        let final = try adapter.load(saveFileIndex: 0, ownerThreadToken: 7)
        precondition(final.save.flags & (1 << 20) != 0)
        precondition(final.menu.filler == Array(0xA0..<0xAA))

        print(String(
            format: "normalizedSaveMutationReplayFingerprint=0x%016llx",
            fingerprint
        ))
        print("SM64 Modern normalized save-mutation replay smoke passed")
    }
}
