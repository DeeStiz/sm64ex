import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h8(_ h: UInt64, _ value: UInt8) -> UInt64 { var x = h; x ^= UInt64(value); x &*= fnvPrime; return x }
private func h32(_ h: UInt64, _ value: UInt32) -> UInt64 {
    (0..<4).reduce(h) { h8($0, UInt8(truncatingIfNeeded: value >> UInt32($1 * 8))) }
}
private func hash(_ h: UInt64, _ bytes: [UInt8]) -> UInt64 { bytes.reduce(h) { h8($0, $1) } }

private func makeSave() -> SM64SaveFileSnapshot {
    var stars = Array(repeating: UInt8(0), count: 25)
    stars[0] = 0x04
    return SM64SaveFileSnapshot(
        capLevel: 7, capArea: 2,
        capPosition: .init(x: -10, y: 20, z: 30),
        flags: SM64SaveFileMutator.fileExistsFlag
            | SM64SaveFileMutator.capOnGroundFlag
            | SM64SaveFileMutator.capOnKleptoFlag,
        courseStars: stars,
        courseCoinScores: Array(repeating: 0, count: 15)
    )
}

@main
enum SM64ModernSaveFileMutatorSmoke {
    static func main() {
        let base = SM64SaveFileCodec.decode(SM64SaveFileCodec.encode(makeSave()))!
        let set = SM64SaveFileMutator.setFlags(1 << 10, in: base)
        let cleared = SM64SaveFileMutator.clearFlags(
            SM64SaveFileMutator.capOnGroundFlag | SM64SaveFileMutator.fileExistsFlag,
            in: set
        )
        let secret = SM64SaveFileMutator.setStarFlags(
            0x03, courseIndex: -1, in: base
        )!
        let course = SM64SaveFileMutator.setStarFlags(
            0x82, courseIndex: 0, in: base
        )!
        let cannon = SM64SaveFileMutator.setCannonUnlocked(
            currentCourseNumber: 1, in: base
        )!
        let cap = SM64SaveFileMutator.setCapPosition(
            level: 9, area: 3,
            position: .init(x: -100, y: 200, z: 300), in: base
        )
        let klepto = SM64SaveFileMutator.moveCapToDefaultLocation(level: 0x08, in: base)
        let mrBlizzard = SM64SaveFileMutator.moveCapToDefaultLocation(level: 0x0A, in: base)
        let ukiki = SM64SaveFileMutator.moveCapToDefaultLocation(level: 0x24, in: base)
        let unknown = SM64SaveFileMutator.moveCapToDefaultLocation(level: 7, in: base)
        let menu = SM64MenuDataSnapshot(
            coinScoreAges: SM64CoinScoreAgeState.wipedAges,
            soundMode: 0x1234, filler: Array(0xA0..<0xAA)
        )
        let sound = SM64SaveFileMutator.setSoundMode(0x4321, in: menu)

        precondition(set.flags & (1 << 10) != 0 && set.flags & 1 != 0)
        precondition(cleared.flags & SM64SaveFileMutator.fileExistsFlag != 0)
        precondition(cleared.flags & SM64SaveFileMutator.capOnGroundFlag == 0)
        precondition(secret.flags >> 24 == 0x03)
        precondition(course.courseStars[0] == 0x86)
        precondition(cannon.courseStars[1] & 0x80 != 0)
        precondition(cap.capPosition == .init(x: -100, y: 200, z: 300))
        precondition(klepto.location == .klepto && klepto.save.flags & (1 << 16) == 0)
        precondition(mrBlizzard.location == .mrBlizzard && mrBlizzard.save.flags & (1 << 16) == 0)
        precondition(ukiki.location == .ukiki && ukiki.save.flags & (1 << 16) == 0)
        precondition(unknown.location == .none && unknown.save.flags & (1 << 16) == 0)
        precondition(sound.soundMode == 0x4321 && sound.filler == menu.filler)

        var fingerprint = fnvOffset
        for save in [base, set, cleared, secret, course, cannon, cap,
                     klepto.save, mrBlizzard.save, ukiki.save, unknown.save] {
            fingerprint = hash(fingerprint, SM64SaveFileCodec.encode(save))
        }
        for location in [klepto.location, mrBlizzard.location, ukiki.location, unknown.location] {
            fingerprint = h8(fingerprint, location.rawValue)
        }
        fingerprint = hash(fingerprint, SM64MenuDataCodec.encode(menu))
        fingerprint = hash(fingerprint, SM64MenuDataCodec.encode(sound))
        fingerprint = h32(fingerprint, set.flags)
        fingerprint = h32(fingerprint, cleared.flags)

        print(String(format: "saveFileMutatorFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern save-file mutator smoke passed")
    }
}
