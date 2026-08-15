import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ value: UInt8) -> UInt64 { var x = h; x ^= UInt64(value); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ value: UInt16) -> UInt64 {
    var x = h; for index in 0..<2 { x = h8(x, UInt8(truncatingIfNeeded: value >> UInt16(index * 8))) }; return x
}
private func h32(_ h: UInt64, _ value: UInt32) -> UInt64 {
    var x = h; for index in 0..<4 { x = h8(x, UInt8(truncatingIfNeeded: value >> UInt32(index * 8))) }; return x
}

private func hash(_ h: UInt64, _ bytes: [UInt8]) -> UInt64 {
    bytes.reduce(h) { h8($0, $1) }
}

private func hash(
    _ h: UInt64,
    _ result: SM64PersistenceLoadResult
) -> UInt64 {
    var x = h8(h, result.saveDecision.rawValue)
    x = h8(x, result.menuDecision.rawValue)
    x = h32(x, result.save.flags)
    for value in result.save.courseStars { x = h8(x, value) }
    for value in result.save.courseCoinScores { x = h8(x, value) }
    for value in result.menu.coinScoreAges { x = h32(x, value) }
    return h16(x, result.menu.soundMode)
}

private func hash(
    _ h: UInt64,
    _ lifetime: SM64ProgressionRouteLifetime
) -> UInt64 {
    var x = h16(h, lifetime.identity.level)
    x = h8(x, lifetime.identity.area)
    x = h32(x, UInt32(truncatingIfNeeded: lifetime.identity.behaviorIdentity))
    x = h8(x, UInt8(truncatingIfNeeded: lifetime.identity.behaviorIdentity >> 32))
    x = h16(x, lifetime.identity.instance)
    x = h8(x, lifetime.kind.rawValue)
    x = h32(x, lifetime.generation)
    return h8(x, lifetime.active ? 1 : 0)
}

@main
enum SM64ModernProgressionPersistenceSmoke {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-modern-persistence-\(UUID().uuidString)")
        let token: UInt64 = 0x1122_3344_5566_7788
        let adapter = try SM64OwnerThreadPersistenceAdapter(
            rootURL: root, ownerThreadToken: token
        )
        let saveTemplate = SM64SaveFileSnapshot(
            capLevel: 7, capArea: 2,
            capPosition: .init(x: -10, y: 20, z: 30),
            flags: SM64ProgressionReducer.fileExists | SM64ProgressionReducer.haveWingCap,
            courseStars: Array(repeating: 0, count: 25).enumerated().map {
                $0.offset == 2 ? 0x04 : 0
            },
            courseCoinScores: Array(repeating: 0, count: 15).enumerated().map {
                $0.offset == 2 ? 100 : 0
            }
        )
        let menuTemplate = SM64MenuDataSnapshot(
            coinScoreAges: SM64CoinScoreAgeState.wipedAges,
            soundMode: 0x1234,
            filler: Array(0xA0..<0xAA)
        )
        let save = SM64SaveFileCodec.decode(SM64SaveFileCodec.encode(saveTemplate))!
        let menu = SM64MenuDataCodec.decode(SM64MenuDataCodec.encode(menuTemplate))!
        try adapter.commit(save: save, menu: menu, ownerThreadToken: token)
        let bundle = Array(try Data(contentsOf: adapter.bundleURL))
        precondition(bundle.count == SM64PersistenceBundle.byteCount)

        var fingerprint = hash(fnvOffset, bundle)
        let loaded = try adapter.load(ownerThreadToken: token)
        precondition(loaded.saveDecision == .usePrimary)
        precondition(loaded.menuDecision == .usePrimary)
        precondition(loaded.save == save && loaded.menu == menu)
        fingerprint = hash(fingerprint, loaded)

        var primaryCorrupt = bundle
        primaryCorrupt[0] ^= 0x01
        try Data(primaryCorrupt).write(to: adapter.bundleURL, options: .atomic)
        let recovered = try adapter.load(ownerThreadToken: token)
        precondition(
            recovered.saveDecision == .useBackupAndRewritePrimary
                && recovered.menuDecision == .usePrimary
        )
        precondition(recovered.save == save && recovered.menu == menu)
        fingerprint = hash(fingerprint, primaryCorrupt)
        fingerprint = hash(fingerprint, recovered)

        var bothCorrupt = primaryCorrupt
        bothCorrupt[SM64SaveFileSnapshot.byteCount] ^= 0x01
        let menuPrimaryOffset = SM64SaveFileSnapshot.byteCount * 2
        bothCorrupt[menuPrimaryOffset] ^= 0x01
        bothCorrupt[menuPrimaryOffset + SM64MenuDataSnapshot.byteCount] ^= 0x01
        try Data(bothCorrupt).write(to: adapter.bundleURL, options: .atomic)
        let wiped = try adapter.load(ownerThreadToken: token)
        precondition(
            wiped.saveDecision == .eraseAndRewriteBoth
                && wiped.menuDecision == .wipeAndRewriteBoth
        )
        precondition(wiped.save.flags == 0 && wiped.menu.coinScoreAges == SM64CoinScoreAgeState.wipedAges)
        fingerprint = hash(fingerprint, bothCorrupt)
        fingerprint = hash(fingerprint, wiped)

        var lifetime = SM64ProgressionRouteLifetime(
            identity: .init(level: 7, area: 2, behaviorIdentity: 0x1234_5678_9ABC_DEF0, instance: 4),
            kind: .hiddenRedCoinStar
        )
        precondition(lifetime.activate() && !lifetime.activate())
        fingerprint = hash(fingerprint, lifetime)
        precondition(lifetime.deactivate() && !lifetime.deactivate())
        fingerprint = hash(fingerprint, lifetime)

        print(String(format: "progressionPersistenceFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern progression-persistence smoke passed")
    }
}
