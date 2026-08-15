import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func h8(_ h: UInt64, _ value: UInt8) -> UInt64 {
    var next = h; next ^= UInt64(value); next &*= fnvPrime; return next
}

private func h16(_ h: UInt64, _ value: UInt16) -> UInt64 {
    var next = h
    for index in 0..<2 {
        next = h8(next, UInt8(truncatingIfNeeded: value >> UInt16(index * 8)))
    }
    return next
}

private func h32(_ h: UInt64, _ value: UInt32) -> UInt64 {
    var next = h
    for index in 0..<4 {
        next = h8(next, UInt8(truncatingIfNeeded: value >> UInt32(index * 8)))
    }
    return next
}

private func hash(_ h: UInt64, _ state: SM64CoinScoreAgeState) -> UInt64 {
    var next = h
    for age in state.ages { next = h32(next, age) }
    return h8(next, state.modified ? 1 : 0)
}

private func hash(_ h: UInt64, _ snapshot: SM64MenuDataSnapshot) -> UInt64 {
    var next = h
    for age in snapshot.coinScoreAges { next = h32(next, age) }
    next = h16(next, snapshot.soundMode)
    for value in snapshot.filler { next = h8(next, value) }
    return h16(next, snapshot.checksum)
}

@main
enum SM64ModernCoinScoreAgesSmoke {
    static func main() {
        var state = SM64CoinScoreAgeState()
        var fingerprint = fnvOffset

        for (fileIndex, courseIndex) in [(3, 0), (2, 0), (1, 0), (0, 0)] {
            let result = SM64CoinScoreAgeReducer.touch(
                fileIndex: fileIndex, courseIndex: courseIndex, state: state
            )!
            state = result.state
            fingerprint = hash(fingerprint, state)
            fingerprint = h8(fingerprint, result.changed ? 1 : 0)
        }
        let unchanged = SM64CoinScoreAgeReducer.touch(
            fileIndex: 0, courseIndex: 0, state: state
        )!
        precondition(!unchanged.changed && unchanged.state == state)
        state = SM64CoinScoreAgeReducer.touchAll(fileIndex: 2, state: state)!
        fingerprint = hash(fingerprint, state)

        precondition(SM64CoinScoreAgeReducer.age(
            fileIndex: 2, courseIndex: 0, state: state
        ) == 0)
        precondition(SM64CoinScoreAgeReducer.touch(
            fileIndex: 4, courseIndex: 0, state: state
        ) == nil)

        var menu = SM64MenuDataCodec.snapshot(from: state)
        menu.soundMode = 0x1234
        menu.filler = Array(0xA0..<0xAA)
        let bytes = SM64MenuDataCodec.encode(menu)
        let decoded = SM64MenuDataCodec.decode(bytes)!
        precondition(bytes.count == SM64MenuDataSnapshot.byteCount)
        precondition(decoded.coinScoreAges == state.ages)
        precondition(decoded.soundMode == 0x1234)
        precondition(decoded.filler == Array(0xA0..<0xAA))
        fingerprint = hash(fingerprint, decoded)
        fingerprint = h8(fingerprint, SM64MenuDataCodec.verify(bytes) ? 1 : 0)

        var corrupt = bytes
        corrupt[7] ^= 0x01
        let primaryGood = SM64MenuDataCodec.recover(primary: bytes, backup: corrupt)
        precondition(primaryGood.decision == .usePrimaryAndRewriteBackup)
        precondition(primaryGood.selected == decoded)
        fingerprint = h8(fingerprint, primaryGood.decision.rawValue)

        let backupGood = SM64MenuDataCodec.recover(primary: corrupt, backup: bytes)
        precondition(backupGood.decision == .useBackupAndRewritePrimary)
        fingerprint = h8(fingerprint, backupGood.decision.rawValue)

        let wiped = SM64MenuDataCodec.recover(primary: corrupt, backup: corrupt)
        precondition(wiped.decision == .wipeAndRewriteBoth && wiped.selected == nil)
        fingerprint = h8(fingerprint, wiped.decision.rawValue)

        print(String(format: "coinScoreAgesFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern coin-score ages/menu codec smoke passed")
    }
}
