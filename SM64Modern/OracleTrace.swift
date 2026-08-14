import Foundation

enum SM64OracleTraceCodecError: Error, Equatable {
    case truncated
    case invalidHeader
    case unsupportedSchema(UInt32)
    case invalidMode(UInt32)
    case invalidDomain(UInt32)
    case invalidKind(UInt32)
    case invalidValueCount(UInt32)
    case nonCanonicalHash
    case trailingBytes
}

enum SM64OracleTraceMode: UInt32, Sendable {
    case record = 1
    case replay = 2
}

struct SM64OracleTraceConfiguration: Sendable, Equatable {
    static let schemaVersion: UInt32 = 4

    var regionCode: UInt32
    var mode: SM64OracleTraceMode
    var buildFingerprint: UInt64
    var contentFingerprint: UInt64
    var timebaseFingerprint: UInt64
    var configurationFingerprint: UInt64
    var initialSaveFingerprint: UInt64
    var coverageFingerprint: UInt64

    func encoded() -> Data {
        var data = Data(capacity: 72)
        data.appendLE(UInt32(1))
        data.appendLE(UInt32(72))
        data.appendLE(Self.schemaVersion)
        data.appendLE(regionCode)
        data.appendLE(mode.rawValue)
        data.appendLE(UInt32(0))
        data.appendLE(buildFingerprint)
        data.appendLE(contentFingerprint)
        data.appendLE(timebaseFingerprint)
        data.appendLE(configurationFingerprint)
        data.appendLE(initialSaveFingerprint)
        data.appendLE(coverageFingerprint)
        return data
    }

    static func decode(_ data: Data) throws -> Self {
        var cursor = DataCursor(data)
        guard try cursor.readUInt32() == 1,
              try cursor.readUInt32() >= 72 else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        let schema = try cursor.readUInt32()
        guard schema == schemaVersion else {
            throw SM64OracleTraceCodecError.unsupportedSchema(schema)
        }
        let regionCode = try cursor.readUInt32()
        let modeRaw = try cursor.readUInt32()
        guard let mode = SM64OracleTraceMode(rawValue: modeRaw) else {
            throw SM64OracleTraceCodecError.invalidMode(modeRaw)
        }
        _ = try cursor.readUInt32()
        return Self(
            regionCode: regionCode,
            mode: mode,
            buildFingerprint: try cursor.readUInt64(),
            contentFingerprint: try cursor.readUInt64(),
            timebaseFingerprint: try cursor.readUInt64(),
            configurationFingerprint: try cursor.readUInt64(),
            initialSaveFingerprint: try cursor.readUInt64(),
            coverageFingerprint: try cursor.readUInt64()
        )
    }
}

struct SM64OracleTraceRecord: Sendable, Equatable {
    static let encodedSize = 128

    var simulationTick: UInt64
    var domain: UInt32
    var recordKind: UInt32
    var subjectID: UInt64
    var recordID: UInt64
    var sequence: UInt32
    var flags: UInt32
    var values: [UInt64]

    init(
        simulationTick: UInt64,
        domain: UInt32,
        recordKind: UInt32,
        subjectID: UInt64 = 0,
        recordID: UInt64,
        sequence: UInt32,
        flags: UInt32 = 0,
        values: [UInt64]
    ) throws {
        guard domain < 14 else { throw SM64OracleTraceCodecError.invalidDomain(domain) }
        guard (1...8).contains(recordKind) else {
            throw SM64OracleTraceCodecError.invalidKind(recordKind)
        }
        guard values.count <= 8 else {
            throw SM64OracleTraceCodecError.invalidValueCount(UInt32(values.count))
        }
        self.simulationTick = simulationTick
        self.domain = domain
        self.recordKind = recordKind
        self.subjectID = subjectID
        self.recordID = recordID
        self.sequence = sequence
        self.flags = flags
        self.values = values
    }

    var canonicalHash: UInt64 {
        var hash = SM64OracleTraceHash.offset
        hash = hash.update(simulationTick)
        hash = hash.update(UInt64(domain))
        hash = hash.update(UInt64(recordKind))
        hash = hash.update(subjectID)
        hash = hash.update(recordID)
        hash = hash.update(UInt64(sequence))
        hash = hash.update(UInt64(values.count))
        hash = hash.update(UInt64(flags))
        for value in values {
            hash = hash.update(value)
        }
        return hash
    }

    func encoded() -> Data {
        var data = Data(capacity: Self.encodedSize)
        data.appendLE(UInt32(1))
        data.appendLE(UInt32(Self.encodedSize))
        data.appendLE(simulationTick)
        data.appendLE(domain)
        data.appendLE(recordKind)
        data.appendLE(subjectID)
        data.appendLE(recordID)
        data.appendLE(sequence)
        data.appendLE(UInt32(values.count))
        data.appendLE(flags)
        data.appendLE(UInt32(0))
        for index in 0..<8 {
            data.appendLE(index < values.count ? values[index] : 0)
        }
        data.appendLE(canonicalHash)
        return data
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count == encodedSize else { throw SM64OracleTraceCodecError.truncated }
        var cursor = DataCursor(data)
        guard try cursor.readUInt32() == 1,
              try cursor.readUInt32() >= UInt32(encodedSize) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        let simulationTick = try cursor.readUInt64()
        let domain = try cursor.readUInt32()
        let recordKind = try cursor.readUInt32()
        let subjectID = try cursor.readUInt64()
        let recordID = try cursor.readUInt64()
        let sequence = try cursor.readUInt32()
        let valueCount = try cursor.readUInt32()
        guard valueCount <= 8 else {
            throw SM64OracleTraceCodecError.invalidValueCount(valueCount)
        }
        let flags = try cursor.readUInt32()
        _ = try cursor.readUInt32()
        let allValues = try (0..<8).map { _ in try cursor.readUInt64() }
        let record = try Self(
            simulationTick: simulationTick,
            domain: domain,
            recordKind: recordKind,
            subjectID: subjectID,
            recordID: recordID,
            sequence: sequence,
            flags: flags,
            values: Array(allValues.prefix(Int(valueCount)))
        )
        let storedHash = try cursor.readUInt64()
        guard storedHash == record.canonicalHash else {
            throw SM64OracleTraceCodecError.nonCanonicalHash
        }
        return record
    }
}

enum SM64OracleTraceFile {
    static func write(
        configuration: SM64OracleTraceConfiguration,
        records: [SM64OracleTraceRecord],
        to url: URL
    ) throws {
        var data = configuration.encoded()
        for record in records {
            data.append(record.encoded())
        }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }

    static func read(from url: URL) throws -> (
        configuration: SM64OracleTraceConfiguration,
        records: [SM64OracleTraceRecord]
    ) {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard data.count >= 72 else { throw SM64OracleTraceCodecError.truncated }
        let configuration = try SM64OracleTraceConfiguration.decode(Data(data.prefix(72)))
        let recordData = data.dropFirst(72)
        guard recordData.count % SM64OracleTraceRecord.encodedSize == 0 else {
            throw SM64OracleTraceCodecError.trailingBytes
        }
        var records: [SM64OracleTraceRecord] = []
        records.reserveCapacity(recordData.count / SM64OracleTraceRecord.encodedSize)
        var offset = 0
        while offset < recordData.count {
            let start = recordData.index(recordData.startIndex, offsetBy: offset)
            let end = recordData.index(start, offsetBy: SM64OracleTraceRecord.encodedSize)
            records.append(try SM64OracleTraceRecord.decode(Data(recordData[start..<end])))
            offset += SM64OracleTraceRecord.encodedSize
        }
        return (configuration, records)
    }
}

private enum SM64OracleTraceHash {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211
}

private extension UInt64 {
    func update(_ value: UInt64) -> UInt64 {
        var hash = self
        for byte in 0..<8 {
            hash ^= (value >> UInt64(byte * 8)) & 0xff
            hash &*= SM64OracleTraceHash.prime
        }
        return hash
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

private struct DataCursor {
    private let data: Data
    private var offset = 0

    init(_ data: Data) { self.data = data }

    mutating func readUInt32() throws -> UInt32 {
        let bytes = try read(4)
        return bytes.enumerated().reduce(UInt32(0)) { value, element in
            value | (UInt32(element.element) << UInt32(element.offset * 8))
        }
    }

    mutating func readUInt64() throws -> UInt64 {
        let bytes = try read(8)
        return bytes.enumerated().reduce(UInt64(0)) { value, element in
            value | (UInt64(element.element) << UInt64(element.offset * 8))
        }
    }

    private mutating func read(_ count: Int) throws -> [UInt8] {
        guard offset + count <= data.count else {
            throw SM64OracleTraceCodecError.truncated
        }
        let start = data.index(data.startIndex, offsetBy: offset)
        let end = data.index(start, offsetBy: count)
        offset += count
        return Array(data[start..<end])
    }
}
