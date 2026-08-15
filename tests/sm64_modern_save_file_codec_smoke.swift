import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ v: UInt8) -> UInt64 { var x = h; x ^= UInt64(v); x &*= fnvPrime; return x }
private func h16(_ h: UInt64, _ v: UInt16) -> UInt64 { var x = h; for i in 0..<2 { x ^= UInt64((v >> UInt16(i * 8)) & 0xff); x &*= fnvPrime }; return x }
private func h32(_ h: UInt64, _ v: UInt32) -> UInt64 { var x = h; for i in 0..<4 { x ^= UInt64((v >> UInt32(i * 8)) & 0xff); x &*= fnvPrime }; return x }

private func hash(_ h: UInt64, _ bytes: [UInt8]) -> UInt64 {
    bytes.reduce(h) { h8($0, $1) }
}

private func hash(
    _ h: UInt64,
    _ recovery: SM64SaveRecoveryResult
) -> UInt64 {
    var x = h8(h, recovery.decision.rawValue)
    if let snapshot = recovery.selected {
        x = h8(x, 1)
        x = h8(x, snapshot.capLevel); x = h8(x, snapshot.capArea)
        x = h16(x, UInt16(bitPattern: snapshot.capPosition.x))
        x = h16(x, UInt16(bitPattern: snapshot.capPosition.y))
        x = h16(x, UInt16(bitPattern: snapshot.capPosition.z))
        x = h32(x, snapshot.flags)
        for value in snapshot.courseStars { x = h8(x, value) }
        for value in snapshot.courseCoinScores { x = h8(x, value) }
        x = h16(x, snapshot.checksum)
    } else {
        x = h8(x, 0)
    }
    return x
}

@main
enum SM64ModernSaveFileCodecSmoke {
    static func main() {
        var stars = [UInt8](repeating: 0, count: SM64SaveFileSnapshot.courseCount)
        stars[2] = 0x04; stars[3] = 0x80
        var scores = [UInt8](repeating: 0, count: SM64SaveFileSnapshot.stageCount)
        scores[2] = 100
        let snapshot = SM64SaveFileSnapshot(
            capLevel: 7, capArea: 2,
            capPosition: .init(x: -10, y: 20, z: 30),
            flags: SM64ProgressionReducer.fileExists
                | SM64ProgressionReducer.unlockedBasementDoor
                | SM64ProgressionReducer.capOnUkiki,
            courseStars: stars, courseCoinScores: scores
        )
        let bytes = SM64SaveFileCodec.encode(snapshot)
        precondition(bytes.count == SM64SaveFileSnapshot.byteCount)
        precondition(SM64SaveFileCodec.verify(bytes))
        let decoded = SM64SaveFileCodec.decode(bytes)!
        precondition(decoded.capPosition == snapshot.capPosition
            && decoded.flags == snapshot.flags
            && decoded.courseStars == stars
            && decoded.courseCoinScores == scores)

        var corruptPrimary = bytes
        corruptPrimary[20] ^= 0x01
        let backupRecovery = SM64SaveFileCodec.recover(
            primary: corruptPrimary, backup: bytes
        )
        precondition(backupRecovery.decision == .useBackupAndRewritePrimary
            && backupRecovery.selected == decoded)

        var corruptBackup = bytes
        corruptBackup[54] ^= 0x80
        let primaryRecovery = SM64SaveFileCodec.recover(
            primary: bytes, backup: corruptBackup
        )
        precondition(primaryRecovery.decision == .usePrimaryAndRewriteBackup)

        var bothCorrupt = corruptPrimary
        bothCorrupt[52] ^= 0xFF
        let erased = SM64SaveFileCodec.recover(
            primary: corruptPrimary, backup: bothCorrupt
        )
        precondition(erased.decision == .eraseAndRewriteBoth && erased.selected == nil)

        var fingerprint = fnvOffset
        fingerprint = hash(fingerprint, bytes)
        fingerprint = hash(fingerprint, backupRecovery)
        fingerprint = hash(fingerprint, primaryRecovery)
        fingerprint = hash(fingerprint, erased)
        print(String(format: "saveFileCodecFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern save-file codec smoke passed")
    }
}
