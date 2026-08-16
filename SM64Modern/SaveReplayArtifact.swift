import Foundation

enum SM64SaveReplayArtifactError: Error, Equatable {
    case truncated
    case invalidMagic
    case unsupportedVersion(UInt32)
    case invalidHeaderSize(UInt32)
    case invalidRecordSize(UInt32)
    case invalidAuthority(UInt32)
    case invalidRecordCount(UInt32)
    case nonCanonicalHeader
    case nonCanonicalRecord(UInt64)
    case nonCanonicalArtifact
    case trailingBytes
}

enum SM64SaveReplayDirection: UInt32, Equatable, Sendable {
    case cToSwift = 1
    case swiftToC = 2
}

enum SM64SaveReplayOperation: UInt32, Equatable, Sendable {
    case initialize = 1
    case load = 2
    case reload = 3
    case persist = 4
    case mutation = 5
    case recovery = 6
}

/// Fixed-width save replay record shared by the Swift artifact writer and the
/// independent C reader. Hashes are over encoded save/menu bytes, so replay
/// qualification never depends on Swift value layout or pointer identity.
struct SM64SaveReplayRecord: Equatable, Sendable {
    static let encodedSize = 128

    let sequence: UInt64
    let simulationTick: UInt64
    let direction: SM64SaveReplayDirection
    let operation: SM64SaveReplayOperation
    let saveFileIndex: UInt32
    let mutationKind: UInt32
    let mutationOperation: UInt32
    let sourceFileIndex: UInt32
    let saveRecoveryDecision: UInt32
    let menuRecoveryDecision: UInt32
    let status: UInt32
    let beforeSaveHash: UInt64
    let beforeMenuHash: UInt64
    let afterSaveHash: UInt64
    let afterMenuHash: UInt64
    let imageHash: UInt64

    var canonicalHash: UInt64 {
        SM64SaveReplayHash.bytes(
            Data(encoded(includeCanonical: false).prefix(112))
        )
    }

    func encoded() -> Data {
        encoded(includeCanonical: true)
    }

    private func encoded(includeCanonical: Bool) -> Data {
        var data = Data(capacity: Self.encodedSize)
        data.appendLE(UInt32(1))
        data.appendLE(UInt32(Self.encodedSize))
        data.appendLE(sequence)
        data.appendLE(simulationTick)
        data.appendLE(direction.rawValue)
        data.appendLE(operation.rawValue)
        data.appendLE(saveFileIndex)
        data.appendLE(mutationKind)
        data.appendLE(mutationOperation)
        data.appendLE(sourceFileIndex)
        data.appendLE(saveRecoveryDecision)
        data.appendLE(menuRecoveryDecision)
        data.appendLE(status)
        data.appendLE(UInt32(0))
        data.appendLE(beforeSaveHash)
        data.appendLE(beforeMenuHash)
        data.appendLE(afterSaveHash)
        data.appendLE(afterMenuHash)
        data.appendLE(imageHash)
        data.appendLE(UInt64(0))
        data.appendLE(includeCanonical ? canonicalHash : UInt64(0))
        data.appendLE(UInt64(0))
        precondition(data.count == Self.encodedSize)
        return data
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count == encodedSize else {
            throw SM64SaveReplayArtifactError.truncated
        }
        var cursor = SM64SaveReplayCursor(data)
        guard try cursor.readUInt32() == 1,
              try cursor.readUInt32() == UInt32(encodedSize) else {
            throw SM64SaveReplayArtifactError.invalidRecordSize(try cursor.peekUInt32())
        }
        let sequence = try cursor.readUInt64()
        let simulationTick = try cursor.readUInt64()
        guard let direction = SM64SaveReplayDirection(
            rawValue: try cursor.readUInt32()
        ), let operation = SM64SaveReplayOperation(
            rawValue: try cursor.readUInt32()
        ) else {
            throw SM64SaveReplayArtifactError.nonCanonicalRecord(sequence)
        }
        let record = Self(
            sequence: sequence,
            simulationTick: simulationTick,
            direction: direction,
            operation: operation,
            saveFileIndex: try cursor.readUInt32(),
            mutationKind: try cursor.readUInt32(),
            mutationOperation: try cursor.readUInt32(),
            sourceFileIndex: try cursor.readUInt32(),
            saveRecoveryDecision: try cursor.readUInt32(),
            menuRecoveryDecision: try cursor.readUInt32(),
            status: try cursor.readUInt32(),
            beforeSaveHash: try cursor.readUInt64(afterReserved: true),
            beforeMenuHash: try cursor.readUInt64(),
            afterSaveHash: try cursor.readUInt64(),
            afterMenuHash: try cursor.readUInt64(),
            imageHash: try cursor.readUInt64()
        )
        _ = try cursor.readUInt64()
        let storedHash = try cursor.readUInt64()
        _ = try cursor.readUInt64()
        guard storedHash == record.canonicalHash else {
            throw SM64SaveReplayArtifactError.nonCanonicalRecord(sequence)
        }
        return record
    }
}

/// Durable, fixed-width C↔Swift save replay artifact. The header records the
/// launch authority and restart requirement so a replay cannot silently run
/// under a different engine selection than the one that produced it.
struct SM64SaveReplayArtifact: Equatable, Sendable {
    static let magic: UInt32 = 0x5052_4D53 // little-endian "SMRP"
    static let schemaVersion: UInt32 = 1
    static let headerSize = 64

    let authority: SM64ModernEngineAuthority
    let requiresRestart: Bool
    let initialImageHash: UInt64
    let finalImageHash: UInt64
    let records: [SM64SaveReplayRecord]

    var artifactHash: UInt64 {
        SM64SaveReplayHash.bytes(headerPrefix() + recordsData)
    }

    func encoded() -> Data {
        var data = header(artifactHash: artifactHash)
        data.append(recordsData)
        return data
    }

    func write(to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try encoded().write(to: url, options: .atomic)
    }

    static func read(from url: URL) throws -> Self {
        try decode(Data(contentsOf: url, options: .mappedIfSafe))
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count >= headerSize else {
            throw SM64SaveReplayArtifactError.truncated
        }
        var cursor = SM64SaveReplayCursor(Data(data.prefix(headerSize)))
        guard try cursor.readUInt32() == magic else {
            throw SM64SaveReplayArtifactError.invalidMagic
        }
        let version = try cursor.readUInt32()
        guard version == schemaVersion else {
            throw SM64SaveReplayArtifactError.unsupportedVersion(version)
        }
        let headerSize = try cursor.readUInt32()
        guard headerSize == Self.headerSize else {
            throw SM64SaveReplayArtifactError.invalidHeaderSize(headerSize)
        }
        let recordSize = try cursor.readUInt32()
        guard recordSize == UInt32(SM64SaveReplayRecord.encodedSize) else {
            throw SM64SaveReplayArtifactError.invalidRecordSize(recordSize)
        }
        let authorityCode = try cursor.readUInt32()
        guard let authority = authority(code: authorityCode) else {
            throw SM64SaveReplayArtifactError.invalidAuthority(authorityCode)
        }
        let flags = try cursor.readUInt32()
        let recordCount = try cursor.readUInt32()
        _ = try cursor.readUInt32()
        let initialImageHash = try cursor.readUInt64()
        let finalImageHash = try cursor.readUInt64()
        let storedHeaderHash = try cursor.readUInt64()
        let storedArtifactHash = try cursor.readUInt64()
        guard storedHeaderHash == SM64SaveReplayHash.bytes(
            Data(data.prefix(48))
        ) else {
            throw SM64SaveReplayArtifactError.nonCanonicalHeader
        }
        let recordsStart = Int(headerSize)
        let recordsByteCount = Int(recordCount) * SM64SaveReplayRecord.encodedSize
        guard recordsStart + recordsByteCount == data.count else {
            throw data.count < recordsStart + recordsByteCount
                ? SM64SaveReplayArtifactError.truncated
                : SM64SaveReplayArtifactError.trailingBytes
        }
        var records: [SM64SaveReplayRecord] = []
        records.reserveCapacity(Int(recordCount))
        var offset = recordsStart
        for _ in 0..<recordCount {
            let end = offset + SM64SaveReplayRecord.encodedSize
            records.append(try SM64SaveReplayRecord.decode(
                Data(data[offset..<end])
            ))
            offset = end
        }
        let artifact = Self(
            authority: authority,
            requiresRestart: (flags & 1) != 0,
            initialImageHash: initialImageHash,
            finalImageHash: finalImageHash,
            records: records
        )
        guard storedArtifactHash == artifact.artifactHash else {
            throw SM64SaveReplayArtifactError.nonCanonicalArtifact
        }
        return artifact
    }

    private var recordsData: Data {
        records.reduce(into: Data(capacity: records.count * SM64SaveReplayRecord.encodedSize)) {
            $0.append($1.encoded())
        }
    }

    private func headerPrefix() -> Data {
        var data = Data(capacity: 48)
        data.appendLE(Self.magic)
        data.appendLE(Self.schemaVersion)
        data.appendLE(UInt32(Self.headerSize))
        data.appendLE(UInt32(SM64SaveReplayRecord.encodedSize))
        data.appendLE(Self.authorityCode(authority))
        data.appendLE(requiresRestart ? UInt32(1) : UInt32(0))
        data.appendLE(UInt32(records.count))
        data.appendLE(UInt32(0))
        data.appendLE(initialImageHash)
        data.appendLE(finalImageHash)
        precondition(data.count == 48)
        return data
    }

    private func header(artifactHash: UInt64) -> Data {
        var data = headerPrefix()
        data.appendLE(SM64SaveReplayHash.bytes(data))
        data.appendLE(artifactHash)
        precondition(data.count == Self.headerSize)
        return data
    }

    private static func authorityCode(_ authority: SM64ModernEngineAuthority) -> UInt32 {
        authority == .swift ? 1 : 2
    }

    private static func authority(code: UInt32) -> SM64ModernEngineAuthority? {
        switch code {
        case 1: return .swift
        case 2: return .cCompatibility
        default: return nil
        }
    }
}

/// In-memory owner-thread ledger with opt-in atomic persistence. The live
/// migration bridge can keep this disabled for normal play so cap-position
/// callbacks never turn into per-frame filesystem writes.
struct SM64SaveReplayLedger: Sendable {
    let authority: SM64ModernEngineAuthority
    let requiresRestart: Bool
    let initialImageHash: UInt64
    private(set) var records: [SM64SaveReplayRecord] = []

    init(
        authority: SM64ModernEngineAuthority,
        requiresRestart: Bool = false,
        initialImageHash: UInt64 = 0
    ) {
        self.authority = authority
        self.requiresRestart = requiresRestart
        self.initialImageHash = initialImageHash
    }

    mutating func append(_ record: SM64SaveReplayRecord) {
        records.append(record)
    }

    func artifact(finalImageHash: UInt64) -> SM64SaveReplayArtifact {
        SM64SaveReplayArtifact(
            authority: authority,
            requiresRestart: requiresRestart,
            initialImageHash: initialImageHash,
            finalImageHash: finalImageHash,
            records: records
        )
    }
}

private enum SM64SaveReplayHash {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    static func bytes(_ data: Data) -> UInt64 {
        data.reduce(offset) { hash, byte in
            (hash ^ UInt64(byte)) &* prime
        }
    }
}

private struct SM64SaveReplayCursor {
    let data: Data
    var offset = 0

    init(_ data: Data) { self.data = data }

    mutating func readUInt32() throws -> UInt32 {
        let bytes = try read(4)
        return bytes.enumerated().reduce(UInt32(0)) {
            $0 | UInt32($1.element) << UInt32($1.offset * 8)
        }
    }

    mutating func peekUInt32() throws -> UInt32 {
        let saved = offset
        defer { offset = saved }
        return try readUInt32()
    }

    mutating func readUInt64(afterReserved: Bool = false) throws -> UInt64 {
        if afterReserved { _ = try readUInt32() }
        let bytes = try read(8)
        return bytes.enumerated().reduce(UInt64(0)) {
            $0 | UInt64($1.element) << UInt64($1.offset * 8)
        }
    }

    private mutating func read(_ count: Int) throws -> [UInt8] {
        guard offset + count <= data.count else {
            throw SM64SaveReplayArtifactError.truncated
        }
        let start = data.index(data.startIndex, offsetBy: offset)
        let end = data.index(start, offsetBy: count)
        offset += count
        return Array(data[start..<end])
    }
}

private extension Data {
    mutating func appendLE(_ value: UInt32) {
        var value = value.littleEndian
        Swift.withUnsafeBytes(of: &value) { append(contentsOf: $0) }
    }

    mutating func appendLE(_ value: UInt64) {
        var value = value.littleEndian
        Swift.withUnsafeBytes(of: &value) { append(contentsOf: $0) }
    }
}
