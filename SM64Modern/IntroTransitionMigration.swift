import Foundation

enum SM64IntroTransitionMigrationError: Error, Equatable, Sendable {
    case invalidHeader
    case invalidRecord
    case unexpectedRecordCount
    case unexpectedOrder
    case singleArtifact
    case rerunRejected
}

/// The authored intro route emits this receipt through the existing C
/// level-script producer (`record_id == 3`). Swift copies the fixed-width
/// values and recomputes the schema-4 record hash; it does not execute a
/// level command or call the transition implementation.
struct SM64IntroTransitionReceipt: Equatable, Sendable {
    static let firstTick: UInt64 = 311
    static let secondTick: UInt64 = 391
    static let firstHash: UInt64 = 0xb9e7_7a79_7c34_bb9e
    static let secondHash: UInt64 = 0x0eb9_1077_dbe7_2aa4

    let simulationTick: UInt64
    let subjectID: UInt64
    let sequence: UInt32
    let values: [UInt64]
    let canonicalHash: UInt64

    init(native: SM64OracleTraceRecord) throws {
        guard native.domain == 6,
              native.recordKind == 3,
              native.subjectID == 1,
              native.recordID == 3,
              native.values.count == 5,
              (native.simulationTick == Self.firstTick
                  || native.simulationTick == Self.secondTick) else {
            throw SM64IntroTransitionMigrationError.invalidRecord
        }

        let expectedValues: [UInt64]
        let expectedSequence: UInt32
        let expectedHash: UInt64
        switch native.simulationTick {
        case Self.firstTick:
            expectedValues = [1, 16, 0, 0, 0]
            expectedSequence = 2
            expectedHash = Self.firstHash
        case Self.secondTick:
            expectedValues = [8, 20, 0, 0, 0]
            expectedSequence = 5
            expectedHash = Self.secondHash
        default:
            throw SM64IntroTransitionMigrationError.invalidRecord
        }
        guard native.sequence == expectedSequence,
              native.values == expectedValues,
              native.canonicalHash == expectedHash else {
            throw SM64IntroTransitionMigrationError.invalidRecord
        }

        simulationTick = native.simulationTick
        subjectID = native.subjectID
        sequence = native.sequence
        values = native.values
        canonicalHash = expectedHash
    }

    func makeTraceRecord() throws -> SM64OracleTraceRecord {
        let record = try SM64OracleTraceRecord(
            simulationTick: simulationTick,
            domain: 6,
            recordKind: 3,
            subjectID: subjectID,
            recordID: 3,
            sequence: sequence,
            values: values
        )
        guard record.canonicalHash == canonicalHash else {
            throw SM64IntroTransitionMigrationError.invalidRecord
        }
        return record
    }
}

/// Exactly the two authored transition records in the 320-step intro window.
/// This route-local window is intentionally stricter than the generic script
/// event mirror: non-transition script records are not part of this seam.
struct SM64IntroTransitionWindow: Equatable, Sendable {
    let receipts: [SM64IntroTransitionReceipt]
    let traceRecords: [SM64OracleTraceRecord]

    init(records: [SM64OracleTraceRecord]) throws {
        guard records.count == 2 else {
            throw SM64IntroTransitionMigrationError.unexpectedRecordCount
        }
        let receipts = try records.map(SM64IntroTransitionReceipt.init(native:))
        guard receipts.map(\.simulationTick)
                == [SM64IntroTransitionReceipt.firstTick,
                    SM64IntroTransitionReceipt.secondTick],
              receipts.map(\.canonicalHash)
                == [SM64IntroTransitionReceipt.firstHash,
                    SM64IntroTransitionReceipt.secondHash] else {
            throw SM64IntroTransitionMigrationError.unexpectedOrder
        }
        self.receipts = receipts
        self.traceRecords = try receipts.map { try $0.makeTraceRecord() }
    }
}
