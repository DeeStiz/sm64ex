import Foundation

/// Schema-4 collision receipt accepted from the native owner thread. The C
/// surface lists and query functions remain authoritative; this mirror does
/// not synthesize geometry, surface identity, or a collision answer.
struct SM64CollisionQueryReceipt: Equatable, Sendable {
    static let domain: UInt32 = 7
    static let recordKind: UInt32 = 3
    static let firstEvent: UInt64 = 1
    static let lastEvent: UInt64 = 4

    let record: SM64OracleTraceRecord

    init(native: SM64OracleTraceRecord) throws {
        guard native.domain == Self.domain,
              native.recordKind == Self.recordKind,
              (Self.firstEvent...Self.lastEvent).contains(native.recordID),
              native.simulationTick >= 2,
              native.simulationTick <= 3,
              native.values.count == Self.valueCount(for: native.recordID)
        else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        record = try SM64OracleTraceRecord(
            simulationTick: native.simulationTick,
            domain: native.domain,
            recordKind: native.recordKind,
            subjectID: native.subjectID,
            recordID: native.recordID,
            sequence: native.sequence,
            flags: native.flags,
            values: native.values
        )
        guard record == native else {
            throw SM64OracleTraceCodecError.nonCanonicalHash
        }
    }

    static func valueCount(for eventID: UInt64) -> Int {
        switch eventID {
        case 1, 2: return 7 // floor and ceiling: x,y,z,height,type,flags,normalY
        case 3: return 8 // wall: input x/y/z/offset/radius, output x/z, counts
        case 4: return 4 // water/gas: x,z,height,environment kind
        default: return 0
        }
    }
}

/// Owner-thread receipt mirror for the canonical collision-query window.
/// Source-backed query answers are copied byte-for-byte and rehashed by the
/// Swift schema-4 codec; no fallback or default query result is emitted.
final class SwiftCollisionQueriesMigrationService {
    private var lastTick: UInt64?
    private var lastSequence: UInt32 = 0
    private(set) var mirror: [SM64CollisionQueryReceipt] = []

    func observe(native: SM64OracleTraceRecord) throws {
        let receipt = try SM64CollisionQueryReceipt(native: native)
        if let lastTick {
            guard receipt.record.simulationTick >= lastTick,
                  (receipt.record.simulationTick != lastTick
                      ? receipt.record.sequence == 0
                      : receipt.record.sequence == lastSequence &+ 1)
            else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
        } else {
            guard receipt.record.simulationTick == 2,
                  receipt.record.sequence == 0 else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
        }
        mirror.append(receipt)
        lastTick = receipt.record.simulationTick
        lastSequence = receipt.record.sequence
    }

    var traceRecords: [SM64OracleTraceRecord] {
        mirror.map(\.record)
    }
}
