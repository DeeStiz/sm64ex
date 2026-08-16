import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func h8(_ h: UInt64, _ value: UInt8) -> UInt64 {
    var next = h
    next ^= UInt64(value)
    next &*= fnvPrime
    return next
}

private func h32(_ h: UInt64, _ value: UInt32) -> UInt64 {
    (0..<4).reduce(h) {
        h8($0, UInt8(truncatingIfNeeded: value >> UInt32($1 * 8)))
    }
}

private func hash(_ h: UInt64, _ bytes: [UInt8]) -> UInt64 {
    bytes.reduce(h) { h8($0, $1) }
}

private func makeSave() -> SM64SaveFileSnapshot {
    var stars = Array(repeating: UInt8(0), count: 25)
    var scores = Array(repeating: UInt8(0), count: 15)
    stars[0] = 0x05
    stars[1] = 0x81
    scores[0] = 100
    scores[1] = 42
    return SM64SaveFileSnapshot(
        capLevel: 7, capArea: 2,
        capPosition: .init(x: -10, y: 20, z: 30),
        flags: SM64ProgressionReducer.fileExists
            | SM64ProgressionReducer.capOnGround,
        courseStars: stars, courseCoinScores: scores
    )
}

@main
enum SM64ModernProgressionMutationsSmoke {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-modern-mutations-\(UUID().uuidString)")
        let token: UInt64 = 0x1122_3344_5566_7788
        let adapter = try SM64OwnerThreadEEPROMAdapter(
            rootURL: root, ownerThreadToken: token
        )
        let save = SM64SaveFileCodec.decode(SM64SaveFileCodec.encode(makeSave()))!
        let menu = SM64MenuDataSnapshot(
            coinScoreAges: SM64CoinScoreAgeState.wipedAges,
            soundMode: 0x1234,
            filler: Array(0xA0..<0xAA)
        )
        try adapter.commit(
            saveFileIndex: 0, save: save, menu: menu,
            ownerThreadToken: token
        )

        var fingerprint = fnvOffset
        let initialBytes = Array(try Data(contentsOf: adapter.imageURL))
        fingerprint = hash(fingerprint, initialBytes)
        try adapter.copy(
            saveFileIndex: 0,
            to: 1,
            ownerThreadToken: token
        )
        let copied = try adapter.load(saveFileIndex: 1, ownerThreadToken: token)
        precondition(copied.save == save)
        precondition(copied.menu.coinScoreAges == [
            0x3FFF_FFFF, 0x0000_0000, 0x2AAA_AAAA, 0x1555_5555
        ])
        fingerprint = hash(fingerprint, Array(try Data(contentsOf: adapter.imageURL)))

        try adapter.erase(saveFileIndex: 2, ownerThreadToken: token)
        let erased = try adapter.load(saveFileIndex: 2, ownerThreadToken: token)
        let emptySave = SM64SaveFileCodec.decode(
            SM64SaveFileCodec.encode(SM64SaveFileSnapshot())
        )!
        precondition(erased.save == emptySave)
        precondition(erased.menu.coinScoreAges == [
            0x3FFF_FFFF, 0x1555_5555, 0x0000_0000, 0x2AAA_AAAA
        ])
        precondition(erased.menu.soundMode == 0x1234)
        fingerprint = hash(fingerprint, Array(try Data(contentsOf: adapter.imageURL)))

        let final = SM64PersistenceImage.decode(
            Array(try Data(contentsOf: adapter.imageURL))
        )!
        precondition(final.savePrimary[1] == SM64SaveFileCodec.encode(save))
        precondition(final.saveBackup[1] == SM64SaveFileCodec.encode(save))
        precondition(final.savePrimary[2] == SM64SaveFileCodec.encode(emptySave))
        precondition(final.saveBackup[2] == SM64SaveFileCodec.encode(emptySave))
        for index in 0..<SM64PersistenceImage.fileCount {
            precondition(SM64SaveFileCodec.verify(final.savePrimary[index]))
            precondition(SM64SaveFileCodec.verify(final.saveBackup[index]))
        }
        precondition(SM64MenuDataCodec.verify(final.menuPrimary))
        precondition(SM64MenuDataCodec.verify(final.menuBackup))

        print(String(format: "progressionMutationsFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern progression mutations smoke passed")
    }
}
