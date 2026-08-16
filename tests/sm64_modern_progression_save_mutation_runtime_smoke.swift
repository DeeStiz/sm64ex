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
    _ runtime: SM64ProgressionRuntime
) -> UInt64 {
    var next = hash(h, SM64SaveFileCodec.encode(runtime.saveSnapshot()))
    next = hash(next, SM64MenuDataCodec.encode(runtime.menuSnapshot()))
    next = h8(next, runtime.progression.saveModified ? 1 : 0)
    next = h8(next, runtime.menuAges.modified ? 1 : 0)
    return h8(next, runtime.progression.capLocation.rawValue)
}

@main
enum SM64ModernProgressionSaveMutationRuntimeSmoke {
    static func main() throws {
        var stars = Array(repeating: UInt8(0), count: 25)
        stars[0] = 0x04
        let ages = SM64CoinScoreAgeState(
            ages: [0x0123_4567, 0x89AB_CDEF, 0x1020_3040, 0x5566_7788]
        )
        var runtime = SM64ProgressionRuntime(
            progression: .init(
                flags: SM64SaveFileMutator.fileExistsFlag
                    | SM64SaveFileMutator.capOnGroundFlag
                    | SM64SaveFileMutator.capOnKleptoFlag,
                courseStars: stars,
                courseNumber: 1,
                capLocation: .ground,
                capLevel: 8,
                capArea: 2,
                capPosition: .init(x: -10, y: 20, z: 30)
            ),
            menuAges: ages,
            soundMode: 0x1234,
            saveFileIndex: 0
        )

        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, runtime)

        precondition(!runtime.setSaveFlags(1 << 10, legacyDomainAdvances: false))
        precondition(!runtime.setSaveSoundMode(0x4321, legacyDomainAdvances: false))
        precondition(!runtime.progression.saveModified && !runtime.menuAges.modified)
        fingerprint = hash(fingerprint, runtime)

        precondition(runtime.setSaveFlags(1 << 10))
        precondition(runtime.progression.saveModified)
        fingerprint = hash(fingerprint, runtime)

        precondition(runtime.clearSaveFlags(
            SM64SaveFileMutator.capOnGroundFlag
                | SM64SaveFileMutator.fileExistsFlag
        ))
        precondition(runtime.saveSnapshot().flags
            & SM64SaveFileMutator.fileExistsFlag != 0)
        precondition(runtime.saveSnapshot().flags
            & SM64SaveFileMutator.capOnGroundFlag == 0)
        fingerprint = hash(fingerprint, runtime)

        precondition(runtime.setSaveStarFlags(0x03, courseIndex: -1))
        precondition(runtime.setSaveStarFlags(0x82, courseIndex: 0))
        precondition(runtime.saveSnapshot().flags >> 24 == 0x03)
        precondition(runtime.saveSnapshot().courseStars[0] == 0x86)
        fingerprint = hash(fingerprint, runtime)

        precondition(runtime.setSaveCannonUnlocked())
        precondition(runtime.saveSnapshot().courseStars[1] & 0x80 != 0)
        fingerprint = hash(fingerprint, runtime)

        precondition(runtime.setSaveCapPosition(
            level: 9, area: 3,
            position: .init(x: -100, y: 200, z: 300)
        ))
        precondition(runtime.progression.capLocation == .ground)
        fingerprint = hash(fingerprint, runtime)

        precondition(
            runtime.moveSaveCapToDefaultLocation(level: 0x08) == .klepto
        )
        precondition(runtime.progression.capLocation == .klepto)
        precondition(runtime.saveSnapshot().flags
            & SM64SaveFileMutator.capOnGroundFlag == 0)
        fingerprint = hash(fingerprint, runtime)
        precondition(runtime.moveSaveCapToDefaultLocation(level: 0x08) == nil)
        fingerprint = hash(fingerprint, runtime)

        precondition(runtime.setSaveSoundMode(0x4321))
        precondition(runtime.menuAges.modified)
        precondition(runtime.menuSnapshot().soundMode == 0x4321)
        fingerprint = hash(fingerprint, runtime)

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-modern-save-mutation-runtime-\(UUID().uuidString)")
        let adapter = try SM64OwnerThreadPersistenceAdapter(
            rootURL: root, ownerThreadToken: 7
        )
        let committed = try runtime.commitIfNeeded(
            using: adapter, ownerThreadToken: 7
        )
        precondition(committed)
        precondition(!runtime.progression.saveModified && !runtime.menuAges.modified)
        let loaded = try adapter.reload(ownerThreadToken: 7)
        precondition(
            SM64SaveFileCodec.encode(loaded.save)
                == SM64SaveFileCodec.encode(runtime.saveSnapshot())
        )
        precondition(
            SM64MenuDataCodec.encode(loaded.menu)
                == SM64MenuDataCodec.encode(runtime.menuSnapshot())
        )
        fingerprint = hash(fingerprint, runtime)

        print(String(
            format: "progressionSaveMutationRuntimeFingerprint=0x%016llx",
            fingerprint
        ))
        print("SM64 Modern progression save-mutation runtime smoke passed")
    }
}
