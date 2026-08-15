import Foundation

/// The four two-bit-per-course age words stored in MainMenuSaveData.
/// A zero age is newest; larger values are older and are used to break
/// equal-score ties on the high-score screen.
struct SM64CoinScoreAgeState: Equatable, Sendable {
    static let fileCount = 4
    static let courseCount = 15

    var ages: [UInt32]
    var modified: Bool

    init(
        ages: [UInt32] = SM64CoinScoreAgeState.wipedAges,
        modified: Bool = false
    ) {
        precondition(ages.count == Self.fileCount)
        self.ages = ages
        self.modified = modified
    }

    static let wipedAges: [UInt32] = [
        0x3FFF_FFFF, // every course is age 3
        0x2AAA_AAAA, // every course is age 2
        0x1555_5555, // every course is age 1
        0x0000_0000  // every course is age 0
    ]
}

struct SM64CoinScoreAgeResult: Equatable, Sendable {
    let state: SM64CoinScoreAgeState
    let changed: Bool
}

/// Pure value counterpart of touch_coin_score_age/touch_high_score_ages.
enum SM64CoinScoreAgeReducer {
    static func age(
        fileIndex: Int,
        courseIndex: Int,
        state: SM64CoinScoreAgeState
    ) -> UInt8? {
        guard valid(fileIndex: fileIndex, courseIndex: courseIndex) else {
            return nil
        }
        let shift = UInt32(courseIndex * 2)
        return UInt8(truncatingIfNeeded: (state.ages[fileIndex] >> shift) & 0x3)
    }

    static func touch(
        fileIndex: Int,
        courseIndex: Int,
        state: SM64CoinScoreAgeState
    ) -> SM64CoinScoreAgeResult? {
        guard valid(fileIndex: fileIndex, courseIndex: courseIndex) else {
            return nil
        }

        let shift = UInt32(courseIndex * 2)
        let mask = UInt32(3) << shift
        let currentAge = (state.ages[fileIndex] >> shift) & 0x3
        guard currentAge != 0 else {
            return SM64CoinScoreAgeResult(state: state, changed: false)
        }

        var next = state
        for index in 0..<SM64CoinScoreAgeState.fileCount {
            let age = (next.ages[index] >> shift) & 0x3
            if age < currentAge {
                next.ages[index] = (next.ages[index] & ~mask)
                    | ((age + 1) << shift)
            }
        }
        next.ages[fileIndex] = next.ages[fileIndex] & ~mask
        next.modified = true
        return SM64CoinScoreAgeResult(state: next, changed: true)
    }

    static func touchAll(
        fileIndex: Int,
        state: SM64CoinScoreAgeState
    ) -> SM64CoinScoreAgeState? {
        guard (0..<SM64CoinScoreAgeState.fileCount).contains(fileIndex) else {
            return nil
        }
        var next = state
        for courseIndex in 0..<SM64CoinScoreAgeState.courseCount {
            next = touch(fileIndex: fileIndex, courseIndex: courseIndex, state: next)!.state
        }
        return next
    }

    private static func valid(fileIndex: Int, courseIndex: Int) -> Bool {
        (0..<SM64CoinScoreAgeState.fileCount).contains(fileIndex)
            && (0..<SM64CoinScoreAgeState.courseCount).contains(courseIndex)
    }
}

struct SM64MenuDataSnapshot: Equatable, Sendable {
    static let byteCount = 32
    static let fillerCount = 10
    static let magic: UInt16 = 0x4849

    var coinScoreAges: [UInt32]
    var soundMode: UInt16
    var filler: [UInt8]
    var checksum: UInt16

    init(
        coinScoreAges: [UInt32] = SM64CoinScoreAgeState.wipedAges,
        soundMode: UInt16 = 0,
        filler: [UInt8] = Array(repeating: 0, count: Self.fillerCount),
        checksum: UInt16 = 0
    ) {
        precondition(coinScoreAges.count == SM64CoinScoreAgeState.fileCount)
        precondition(filler.count == Self.fillerCount)
        self.coinScoreAges = coinScoreAges
        self.soundMode = soundMode
        self.filler = filler
        self.checksum = checksum
    }
}

enum SM64MenuDataRecoveryDecision: UInt8, Equatable, Sendable {
    case usePrimary = 0
    case usePrimaryAndRewriteBackup = 1
    case useBackupAndRewritePrimary = 2
    case wipeAndRewriteBoth = 3
}

struct SM64MenuDataRecoveryResult: Equatable, Sendable {
    let decision: SM64MenuDataRecoveryDecision
    let selected: SM64MenuDataSnapshot?
}

/// C-compatible MainMenuSaveData bytes and the same two-slot repair policy
/// used by save_file_load_all. The EEPROM byte-swap layer is intentionally
/// separate from this deterministic little-endian representation.
enum SM64MenuDataCodec {
    static func snapshot(from state: SM64CoinScoreAgeState) -> SM64MenuDataSnapshot {
        SM64MenuDataSnapshot(coinScoreAges: state.ages)
    }

    static func encode(_ snapshot: SM64MenuDataSnapshot) -> [UInt8] {
        precondition(snapshot.coinScoreAges.count == SM64CoinScoreAgeState.fileCount)
        precondition(snapshot.filler.count == SM64MenuDataSnapshot.fillerCount)
        var bytes = [UInt8](repeating: 0, count: SM64MenuDataSnapshot.byteCount)
        for index in 0..<SM64CoinScoreAgeState.fileCount {
            write32(snapshot.coinScoreAges[index], to: &bytes, offset: index * 4)
        }
        write16(snapshot.soundMode, to: &bytes, offset: 16)
        bytes.replaceSubrange(18..<28, with: snapshot.filler)
        write16(SM64MenuDataSnapshot.magic, to: &bytes, offset: 28)
        write16(checksum(bytes), to: &bytes, offset: 30)
        return bytes
    }

    static func decode(_ bytes: [UInt8]) -> SM64MenuDataSnapshot? {
        guard bytes.count == SM64MenuDataSnapshot.byteCount,
              read16(bytes, offset: 28) == SM64MenuDataSnapshot.magic,
              read16(bytes, offset: 30) == checksum(bytes) else { return nil }
        var ages = [UInt32]()
        ages.reserveCapacity(SM64CoinScoreAgeState.fileCount)
        for index in 0..<SM64CoinScoreAgeState.fileCount {
            ages.append(read32(bytes, offset: index * 4))
        }
        return SM64MenuDataSnapshot(
            coinScoreAges: ages,
            soundMode: read16(bytes, offset: 16),
            filler: Array(bytes[18..<28]),
            checksum: read16(bytes, offset: 30)
        )
    }

    static func verify(_ bytes: [UInt8]) -> Bool { decode(bytes) != nil }

    static func recover(
        primary: [UInt8], backup: [UInt8]
    ) -> SM64MenuDataRecoveryResult {
        let primarySnapshot = decode(primary)
        let backupSnapshot = decode(backup)
        switch (primarySnapshot, backupSnapshot) {
        case let (.some(snapshot), .some):
            return .init(decision: .usePrimary, selected: snapshot)
        case let (.some(snapshot), .none):
            return .init(
                decision: .usePrimaryAndRewriteBackup, selected: snapshot
            )
        case let (.none, .some(snapshot)):
            return .init(
                decision: .useBackupAndRewritePrimary, selected: snapshot
            )
        case (.none, .none):
            return .init(decision: .wipeAndRewriteBoth, selected: nil)
        }
    }

    static func checksum(_ bytes: [UInt8]) -> UInt16 {
        guard bytes.count >= 2 else { return 0 }
        var sum: UInt16 = 0
        for value in bytes.dropLast(2) { sum &+= UInt16(value) }
        return sum
    }

    private static func write16(
        _ value: UInt16, to bytes: inout [UInt8], offset: Int
    ) {
        bytes[offset] = UInt8(truncatingIfNeeded: value)
        bytes[offset + 1] = UInt8(truncatingIfNeeded: value >> 8)
    }

    private static func write32(
        _ value: UInt32, to bytes: inout [UInt8], offset: Int
    ) {
        for index in 0..<4 {
            bytes[offset + index] = UInt8(truncatingIfNeeded: value >> UInt32(index * 8))
        }
    }

    private static func read16(_ bytes: [UInt8], offset: Int) -> UInt16 {
        UInt16(bytes[offset]) | UInt16(bytes[offset + 1]) << 8
    }

    private static func read32(_ bytes: [UInt8], offset: Int) -> UInt32 {
        var value: UInt32 = 0
        for index in 0..<4 {
            value |= UInt32(bytes[offset + index]) << UInt32(index * 8)
        }
        return value
    }
}
