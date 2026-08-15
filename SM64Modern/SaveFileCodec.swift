import Foundation

struct SM64SaveInt16Vector3: Equatable, Sendable {
    let x: Int16
    let y: Int16
    let z: Int16
}

struct SM64SaveFileSnapshot: Equatable, Sendable {
    static let byteCount = 56
    static let courseCount = SM64ProgressionState.courseCount
    static let stageCount = SM64ProgressionState.stageCount
    static let magic: UInt16 = 0x4441

    var capLevel: UInt8
    var capArea: UInt8
    var capPosition: SM64SaveInt16Vector3
    var flags: UInt32
    var courseStars: [UInt8]
    var courseCoinScores: [UInt8]
    var checksum: UInt16

    init(
        capLevel: UInt8 = 0,
        capArea: UInt8 = 0,
        capPosition: SM64SaveInt16Vector3 = .init(x: 0, y: 0, z: 0),
        flags: UInt32 = 0,
        courseStars: [UInt8] = Array(repeating: 0, count: Self.courseCount),
        courseCoinScores: [UInt8] = Array(repeating: 0, count: Self.stageCount),
        checksum: UInt16 = 0
    ) {
        precondition(courseStars.count == Self.courseCount)
        precondition(courseCoinScores.count == Self.stageCount)
        self.capLevel = capLevel
        self.capArea = capArea
        self.capPosition = capPosition
        self.flags = flags
        self.courseStars = courseStars
        self.courseCoinScores = courseCoinScores
        self.checksum = checksum
    }
}

enum SM64SaveRecoveryDecision: UInt8, Equatable, Sendable {
    case usePrimary = 0
    case usePrimaryAndRewriteBackup = 1
    case useBackupAndRewritePrimary = 2
    case eraseAndRewriteBoth = 3
}

struct SM64SaveRecoveryResult: Equatable, Sendable {
    let decision: SM64SaveRecoveryDecision
    let selected: SM64SaveFileSnapshot?
}

/// C SaveFile-compatible little-endian bytes and two-slot recovery policy.
/// The EEPROM byte-swap layer is intentionally outside this codec, just as it
/// is outside the value reducer; this makes the checksum oracle deterministic
/// on every host while retaining the C field order and literal-sum checksum.
enum SM64SaveFileCodec {
    static func snapshot(from state: SM64ProgressionState) -> SM64SaveFileSnapshot {
        let position = SM64SaveInt16Vector3(
            x: Int16(truncatingIfNeeded: Int32(state.capPosition.x)),
            y: Int16(truncatingIfNeeded: Int32(state.capPosition.y)),
            z: Int16(truncatingIfNeeded: Int32(state.capPosition.z))
        )
        let persistedFlags = (state.flags & 0x00FF_FFFF)
            | (UInt32(state.secretStars & 0x7F) << 24)
        return SM64SaveFileSnapshot(
            capLevel: state.capLevel, capArea: state.capArea,
            capPosition: position, flags: persistedFlags,
            courseStars: state.courseStars,
            courseCoinScores: state.courseCoinScores
        )
    }

    static func encode(_ snapshot: SM64SaveFileSnapshot) -> [UInt8] {
        precondition(snapshot.courseStars.count == SM64SaveFileSnapshot.courseCount)
        precondition(snapshot.courseCoinScores.count == SM64SaveFileSnapshot.stageCount)
        var bytes = [UInt8](repeating: 0, count: SM64SaveFileSnapshot.byteCount)
        bytes[0] = snapshot.capLevel
        bytes[1] = snapshot.capArea
        write16(snapshot.capPosition.x, to: &bytes, offset: 2)
        write16(snapshot.capPosition.y, to: &bytes, offset: 4)
        write16(snapshot.capPosition.z, to: &bytes, offset: 6)
        write32(snapshot.flags, to: &bytes, offset: 8)
        bytes.replaceSubrange(12..<37, with: snapshot.courseStars)
        bytes.replaceSubrange(37..<52, with: snapshot.courseCoinScores)
        write16(SM64SaveFileSnapshot.magic, to: &bytes, offset: 52)
        write16(checksum(bytes), to: &bytes, offset: 54)
        return bytes
    }

    static func decode(_ bytes: [UInt8]) -> SM64SaveFileSnapshot? {
        guard bytes.count == SM64SaveFileSnapshot.byteCount,
              read16(bytes, offset: 52) == SM64SaveFileSnapshot.magic,
              read16(bytes, offset: 54) == checksum(bytes) else { return nil }
        return SM64SaveFileSnapshot(
            capLevel: bytes[0], capArea: bytes[1],
            capPosition: .init(
                x: Int16(bitPattern: read16(bytes, offset: 2)),
                y: Int16(bitPattern: read16(bytes, offset: 4)),
                z: Int16(bitPattern: read16(bytes, offset: 6))
            ),
            flags: read32(bytes, offset: 8),
            courseStars: Array(bytes[12..<37]),
            courseCoinScores: Array(bytes[37..<52]),
            checksum: read16(bytes, offset: 54)
        )
    }

    static func verify(_ bytes: [UInt8]) -> Bool {
        decode(bytes) != nil
    }

    static func recover(
        primary: [UInt8], backup: [UInt8]
    ) -> SM64SaveRecoveryResult {
        let primarySnapshot = decode(primary)
        let backupSnapshot = decode(backup)
        switch (primarySnapshot, backupSnapshot) {
        case let (.some(snapshot), .some):
            return SM64SaveRecoveryResult(decision: .usePrimary, selected: snapshot)
        case let (.some(snapshot), .none):
            return SM64SaveRecoveryResult(
                decision: .usePrimaryAndRewriteBackup, selected: snapshot
            )
        case let (.none, .some(snapshot)):
            return SM64SaveRecoveryResult(
                decision: .useBackupAndRewritePrimary, selected: snapshot
            )
        case (.none, .none):
            return SM64SaveRecoveryResult(decision: .eraseAndRewriteBoth, selected: nil)
        }
    }

    static func checksum(_ bytes: [UInt8]) -> UInt16 {
        guard bytes.count >= 2 else { return 0 }
        var sum: UInt16 = 0
        for value in bytes.dropLast(2) { sum &+= UInt16(value) }
        return sum
    }

    private static func write16(
        _ value: Int16, to bytes: inout [UInt8], offset: Int
    ) {
        write16(UInt16(bitPattern: value), to: &bytes, offset: offset)
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
