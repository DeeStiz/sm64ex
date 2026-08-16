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

private func hBool(_ h: UInt64, _ value: Bool?) -> UInt64 {
    guard let value else { return h8(h, 0xFF) }
    return h8(h, value ? 1 : 0)
}

private func makeSave(
    flags: UInt32,
    stars: [(Int, UInt8)],
    scores: [(Int, UInt8)],
    capFlags: Bool = false
) -> SM64SaveFileSnapshot {
    var courseStars = Array(repeating: UInt8(0), count: 25)
    var courseScores = Array(repeating: UInt8(0), count: 15)
    for (index, value) in stars { courseStars[index] = value }
    for (index, value) in scores { courseScores[index] = value }
    return SM64SaveFileSnapshot(
        capLevel: 7, capArea: 2,
        capPosition: .init(x: -10, y: 20, z: 30),
        flags: flags | (capFlags ? SM64SaveFileQueries.capOnGroundFlag : 0),
        courseStars: courseStars, courseCoinScores: courseScores
    )
}

@main
enum SM64ModernSaveFileQueriesSmoke {
    static func main() {
        let save0 = makeSave(
            flags: SM64SaveFileQueries.fileExistsFlag,
            stars: [(0, 0x05), (1, 0x81), (4, 0x02)],
            scores: [(0, 100), (1, 42)], capFlags: true
        )
        let save1 = makeSave(
            flags: SM64SaveFileQueries.fileExistsFlag,
            stars: [(0, 0x03), (1, 0x01)],
            scores: [(0, 120), (1, 42)]
        )
        let save2 = makeSave(flags: 0, stars: [], scores: [])
        let save3 = makeSave(flags: 0, stars: [], scores: [])
        let saves = [save0, save1, save2, save3]
        let menu = SM64MenuDataSnapshot(
            coinScoreAges: SM64CoinScoreAgeState.wipedAges,
            soundMode: 0x1234
        )

        precondition(SM64SaveFileQueries.exists(save0))
        precondition(!SM64SaveFileQueries.exists(save2))
        precondition(SM64SaveFileQueries.starFlags(save0, courseIndex: -1) == 0)
        precondition(SM64SaveFileQueries.starFlags(save0, courseIndex: 0) == 0x05)
        precondition(SM64SaveFileQueries.starFlags(save0, courseIndex: 99) == nil)
        precondition(SM64SaveFileQueries.cannonFlags(save0, courseIndex: 0) == 1)
        precondition(SM64SaveFileQueries.cannonUnlocked(save0, currentCourseNumber: 1) == true)
        precondition(SM64SaveFileQueries.cannonUnlocked(save0, currentCourseNumber: 0) == nil)
        precondition(SM64SaveFileQueries.courseCoinScore(save0, courseIndex: 1) == 42)
        precondition(SM64SaveFileQueries.courseStarCount(save0, courseIndex: 0) == 2)
        precondition(SM64SaveFileQueries.totalStarCount(
            save0, minimumCourse: 0, maximumCourse: 4
        ) == 4)
        precondition(SM64SaveFileQueries.capPosition(
            save0, currentLevel: 7, currentArea: 2
        ) == .init(x: -10, y: 20, z: 30))
        precondition(SM64SaveFileQueries.capPosition(
            save0, currentLevel: 8, currentArea: 2
        ) == nil)
        precondition(SM64SaveFileQueries.maximumCoinScore(
            saves: saves, menu: menu, courseIndex: 0
        ) == 0x0002_0078)
        precondition(SM64SaveFileQueries.maximumCoinScore(
            saves: saves, menu: menu, courseIndex: 1
        ) == 0x0001_002A)

        var fingerprint = fnvOffset
        for save in saves {
            let bytes = SM64SaveFileCodec.encode(save)
            for byte in bytes { fingerprint = h8(fingerprint, byte) }
        }
        for age in menu.coinScoreAges { fingerprint = h32(fingerprint, age) }
        fingerprint = h16(fingerprint, menu.soundMode)
        for save in saves {
            fingerprint = hBool(fingerprint, SM64SaveFileQueries.exists(save))
            for course in [-1, 0, 1, 4] {
                fingerprint = h8(
                    fingerprint,
                    SM64SaveFileQueries.starFlags(save, courseIndex: course) ?? 0xFF
                )
            }
            fingerprint = h8(
                fingerprint,
                SM64SaveFileQueries.cannonFlags(save, courseIndex: 0) ?? 0xFF
            )
            fingerprint = hBool(
                fingerprint,
                SM64SaveFileQueries.cannonUnlocked(save, currentCourseNumber: 1)
            )
            fingerprint = h8(
                fingerprint,
                SM64SaveFileQueries.courseCoinScore(save, courseIndex: 1) ?? 0xFF
            )
            fingerprint = h32(
                fingerprint,
                UInt32(SM64SaveFileQueries.courseStarCount(save, courseIndex: 0) ?? -1)
            )
            fingerprint = h32(
                fingerprint,
                UInt32(SM64SaveFileQueries.totalStarCount(
                    save, minimumCourse: 0, maximumCourse: 4
                ) ?? -1)
            )
            if let cap = SM64SaveFileQueries.capPosition(
                save, currentLevel: 7, currentArea: 2
            ) {
                fingerprint = h16(fingerprint, UInt16(bitPattern: cap.x))
                fingerprint = h16(fingerprint, UInt16(bitPattern: cap.y))
                fingerprint = h16(fingerprint, UInt16(bitPattern: cap.z))
            } else {
                fingerprint = h8(fingerprint, 0xFF)
            }
        }
        for course in 0..<SM64SaveFileSnapshot.stageCount {
            fingerprint = h32(
                fingerprint,
                SM64SaveFileQueries.maximumCoinScore(
                    saves: saves, menu: menu, courseIndex: course
                ) ?? 0xFFFF_FFFF
            )
        }

        print(String(format: "saveFileQueriesFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern save-file queries smoke passed")
    }
}
