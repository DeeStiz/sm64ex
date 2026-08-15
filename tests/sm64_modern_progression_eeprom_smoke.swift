import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func h8(_ h: UInt64, _ value: UInt8) -> UInt64 {
    var next = h
    next ^= UInt64(value)
    next &*= fnvPrime
    return next
}

private func h16(_ h: UInt64, _ value: UInt16) -> UInt64 {
    (0..<2).reduce(h) {
        h8($0, UInt8(truncatingIfNeeded: value >> UInt16($1 * 8)))
    }
}

private func h32(_ h: UInt64, _ value: UInt32) -> UInt64 {
    (0..<4).reduce(h) {
        h8($0, UInt8(truncatingIfNeeded: value >> UInt32($1 * 8)))
    }
}

private func hash(_ h: UInt64, _ bytes: [UInt8]) -> UInt64 {
    bytes.reduce(h) { h8($0, $1) }
}

private func hash(
    _ h: UInt64, _ result: SM64PersistenceLoadResult
) -> UInt64 {
    var next = h8(h, result.saveDecision.rawValue)
    next = h8(next, result.menuDecision.rawValue)
    next = h32(next, result.save.flags)
    for value in result.save.courseStars { next = h8(next, value) }
    for value in result.save.courseCoinScores { next = h8(next, value) }
    for value in result.menu.coinScoreAges { next = h32(next, value) }
    return h16(next, result.menu.soundMode)
}

private func makeSave(
    capLevel: UInt8, capArea: UInt8, flags: UInt32,
    star: (Int, UInt8), score: (Int, UInt8)
) -> SM64SaveFileSnapshot {
    var stars = Array(repeating: UInt8(0), count: 25)
    var scores = Array(repeating: UInt8(0), count: 15)
    stars[star.0] = star.1
    scores[score.0] = score.1
    return SM64SaveFileSnapshot(
        capLevel: capLevel, capArea: capArea,
        capPosition: .init(x: -10, y: 20, z: 30), flags: flags,
        courseStars: stars, courseCoinScores: scores
    )
}

@main
enum SM64ModernProgressionEEPROMSmoke {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-modern-eeprom-\(UUID().uuidString)")
        let token: UInt64 = 0x1122_3344_5566_7788
        let adapter = try SM64OwnerThreadEEPROMAdapter(
            rootURL: root, ownerThreadToken: token
        )
        let legacyAdapter = try SM64OwnerThreadPersistenceAdapter(
            rootURL: root, ownerThreadToken: token
        )
        let save0 = SM64SaveFileCodec.decode(SM64SaveFileCodec.encode(makeSave(
            capLevel: 7, capArea: 2,
            flags: SM64ProgressionReducer.fileExists
                | SM64ProgressionReducer.haveWingCap,
            star: (2, 4), score: (2, 100)
        )))!
        let save2 = SM64SaveFileCodec.decode(SM64SaveFileCodec.encode(makeSave(
            capLevel: 9, capArea: 3,
            flags: SM64ProgressionReducer.fileExists
                | SM64ProgressionReducer.haveMetalCap,
            star: (5, 2), score: (5, 88)
        )))!
        let menu0 = SM64MenuDataCodec.decode(SM64MenuDataCodec.encode(SM64MenuDataSnapshot(
            coinScoreAges: SM64CoinScoreAgeState.wipedAges,
            soundMode: 0x1234, filler: Array(0xA0..<0xAA)
        )))!
        let menu2 = SM64MenuDataCodec.decode(SM64MenuDataCodec.encode(SM64MenuDataSnapshot(
            coinScoreAges: [0x0000_0000, 0x1555_5555, 0x2AAA_AAAA, 0x3FFF_FFFF],
            soundMode: 0x4321, filler: Array(0xB0..<0xBA)
        )))!

        try legacyAdapter.commit(
            save: save0, menu: menu0, ownerThreadToken: token
        )
        let legacyLoaded = try adapter.load(
            saveFileIndex: 0, ownerThreadToken: token
        )
        precondition(legacyLoaded.save == save0 && legacyLoaded.menu == menu0)
        try adapter.commit(
            saveFileIndex: 0, save: save0, menu: menu0,
            ownerThreadToken: token
        )
        try adapter.commit(
            saveFileIndex: 2, save: save2, menu: menu2,
            ownerThreadToken: token
        )

        var bytes = Array(try Data(contentsOf: adapter.imageURL))
        precondition(bytes.count == SM64PersistenceImage.byteCount)
        let image = SM64PersistenceImage.decode(bytes)!
        precondition(image.savePrimary[0] == SM64SaveFileCodec.encode(save0))
        precondition(image.savePrimary[2] == SM64SaveFileCodec.encode(save2))
        precondition(image.menuPrimary == SM64MenuDataCodec.encode(menu2))
        var fingerprint = hash(fnvOffset, bytes)

        let loaded0 = try adapter.load(
            saveFileIndex: 0, ownerThreadToken: token
        )
        precondition(
            loaded0.save == save0 && loaded0.menu == menu2
                && loaded0.saveDecision == .usePrimary
                && loaded0.menuDecision == .usePrimary
        )
        fingerprint = hash(fingerprint, loaded0)
        let loaded2 = try adapter.load(
            saveFileIndex: 2, ownerThreadToken: token
        )
        precondition(loaded2.save == save2 && loaded2.menu == menu2)
        fingerprint = hash(fingerprint, loaded2)

        let saveBytes = SM64SaveFileSnapshot.byteCount
        bytes[saveBytes * 2] ^= 1
        try Data(bytes).write(to: adapter.imageURL, options: .atomic)
        let recovered = try adapter.load(
            saveFileIndex: 2, ownerThreadToken: token
        )
        precondition(
            recovered.save == save2
                && recovered.saveDecision == .useBackupAndRewritePrimary
        )
        fingerprint = hash(fingerprint, bytes)
        fingerprint = hash(fingerprint, recovered)

        let menuOffset = saveBytes * SM64PersistenceImage.fileCount * 2
        bytes[menuOffset] ^= 1
        try Data(bytes).write(to: adapter.imageURL, options: .atomic)
        let menuRecovered = try adapter.load(
            saveFileIndex: 0, ownerThreadToken: token
        )
        precondition(
            menuRecovered.save == save0
                && menuRecovered.menu == menu2
                && menuRecovered.menuDecision == .useBackupAndRewritePrimary
        )
        fingerprint = hash(fingerprint, bytes)
        fingerprint = hash(fingerprint, menuRecovered)

        let reloaded = try adapter.reload(
            saveFileIndex: 2, ownerThreadToken: token
        )
        precondition(reloaded.save == save2 && reloaded.menu == menu2)
        fingerprint = hash(fingerprint, reloaded)

        print(String(format: "progressionEEPROMFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern progression-EEPROM smoke passed")
    }
}
