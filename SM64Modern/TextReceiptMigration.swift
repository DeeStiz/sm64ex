import Foundation

/// Fixed-width copy of the native authored save-text receipt. The C writer
/// remains authoritative; Swift receives only source/text/payload hashes and
/// the corresponding schema-4 script record values.
struct SM64TextReceipt: Equatable, Sendable {
    static let encodedSize = 64

    let simulationTick: UInt64
    let sourceIdentity: UInt64
    let textIdentity: UInt64
    let payloadHash: UInt64
    let eventID: UInt32
    let fileIndex: UInt32
    let sequence: UInt32

    init(encoded data: Data) throws {
        guard data.count == Self.encodedSize else {
            throw SM64OracleTraceCodecError.truncated
        }
        var cursor = TextReceiptDataCursor(data)
        guard try cursor.readUInt32() == 1,
              try cursor.readUInt32() >= UInt32(Self.encodedSize) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        simulationTick = try cursor.readUInt64()
        sourceIdentity = try cursor.readUInt64()
        textIdentity = try cursor.readUInt64()
        payloadHash = try cursor.readUInt64()
        eventID = try cursor.readUInt32()
        fileIndex = try cursor.readUInt32()
        sequence = try cursor.readUInt32()
        guard try cursor.readUInt32() == 0 else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        let canonicalHash = try cursor.readUInt64()
        guard simulationTick > 0,
              sourceIdentity != 0,
              textIdentity != 0,
              payloadHash != 0,
              eventID == SM64_MODERN_TEXT_EVENT_SAVE_WRITE,
              fileIndex < 4,
              canonicalHash == self.canonicalHash else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
    }

    var values: [UInt64] {
        [textIdentity, payloadHash, UInt64(fileIndex), UInt64(eventID)]
    }

    var traceRecord: SM64OracleTraceRecord {
        get throws {
            try SM64OracleTraceRecord(
                simulationTick: simulationTick,
                domain: SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
                recordKind: SM64_MODERN_ORACLE_RECORD_EVENT,
                subjectID: sourceIdentity,
                recordID: UInt64(SM64_MODERN_TEXT_ORACLE_EVENT_LIFECYCLE),
                sequence: sequence,
                values: values
            )
        }
    }

    var canonicalHash: UInt64 {
        get {
            (try? traceRecord.canonicalHash) ?? 0
        }
    }
}

struct SM64TextReceiptMirror: Equatable, Sendable {
    private(set) var receipts: [SM64TextReceipt] = []
    private(set) var traceRecords: [SM64OracleTraceRecord] = []

    mutating func observe(encoded data: Data) throws {
        let receipt = try SM64TextReceipt(encoded: data)
        if let previous = receipts.last {
            guard receipt.simulationTick > previous.simulationTick
                    || (receipt.simulationTick == previous.simulationTick
                        && receipt.sequence > previous.sequence) else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
        }
        let record = try receipt.traceRecord
        receipts.append(receipt)
        traceRecords.append(record)
    }
}

private struct TextReceiptDataCursor {
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
