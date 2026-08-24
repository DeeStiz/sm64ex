import Darwin
import Foundation

enum SM64ScriptEventsMigrationError: Error, Equatable, Sendable {
    case invalidRecord
    case outOfOrder
}

/// A copied, value-only receipt of one native level/behavior script event.
/// The C level and behavior interpreters remain authoritative; this type does
/// not execute an opcode, advance a command pointer, or infer a transition.
struct SM64ScriptEventReceipt: Equatable, Sendable {
    let simulationTick: UInt64
    let eventID: UInt64
    let subjectID: UInt64
    let sequence: UInt32
    let values: [UInt64]

    init(native: SM64OracleTraceRecord) throws {
        guard native.domain == 6,
              native.recordKind == 3,
              (1...5).contains(native.recordID),
              native.simulationTick >= 2,
              native.values.count == Self.valueCount(for: native.recordID) else {
            throw SM64ScriptEventsMigrationError.invalidRecord
        }
        simulationTick = native.simulationTick
        eventID = native.recordID
        subjectID = native.subjectID
        sequence = native.sequence
        values = native.values
    }

    func makeTraceRecord() throws -> SM64OracleTraceRecord {
        // The initializer recomputes the canonical hash from copied values.
        // It cannot retain a C pointer or a C-provided hash.
        try SM64OracleTraceRecord(
            simulationTick: simulationTick,
            domain: 6,
            recordKind: 3,
            subjectID: subjectID,
            recordID: eventID,
            sequence: sequence,
            values: values
        )
    }

    static func valueCount(for eventID: UInt64) -> Int {
        switch eventID {
        case 1: return 7 // level command
        case 2: return 6 // behavior command
        case 3: return 5 // level transition
        case 4: return 5 // native behavior
        case 5: return 3 // lifecycle
        default: return 0
        }
    }
}

/// Owner-thread receipt path used by the script-event route pair. It accepts
/// only native schema-4 records and publishes a complete copied window. Swift
/// remains a receipt/mirror here; script execution itself stays in C.
struct SM64ScriptEventsMirror: Equatable, Sendable {
    private(set) var receipts: [SM64ScriptEventReceipt] = []
    private(set) var traceRecords: [SM64OracleTraceRecord] = []

    mutating func observe(native: SM64OracleTraceRecord) throws {
        let receipt = try SM64ScriptEventReceipt(native: native)
        if let previous = receipts.last {
            guard receipt.simulationTick >= previous.simulationTick,
                  (receipt.simulationTick == previous.simulationTick
                      ? receipt.sequence == previous.sequence &+ 1
                      : receipt.simulationTick == previous.simulationTick + 1
                          && receipt.sequence == 0) else {
                throw SM64ScriptEventsMigrationError.outOfOrder
            }
        } else if receipt.simulationTick != 2 || receipt.sequence != 0 {
            throw SM64ScriptEventsMigrationError.outOfOrder
        }
        receipts.append(receipt)
        traceRecords.append(try receipt.makeTraceRecord())
    }
}

private func currentScriptEventsThreadIdentity() -> UInt64 {
    var identifier: UInt64 = 0
    let result = pthread_threadid_np(nil, &identifier)
    precondition(result == 0, "pthread_threadid_np must produce an owner token")
    return identifier
}

/// Narrow owner-thread service for the native script-event receipt boundary.
/// No platform callback is installed because the existing C parity recorder
/// is the canonical stream owner; this service is deliberately an adapter for
/// independent C-trace receipt/pair validation.
final class SwiftScriptEventsMigrationService {
    private let ownerThreadToken: UInt64
    private(set) var mirror = SM64ScriptEventsMirror()

    init(ownerThreadToken: UInt64 = currentScriptEventsThreadIdentity()) {
        self.ownerThreadToken = ownerThreadToken
    }

    func observe(native: SM64OracleTraceRecord) throws {
        assertOwnerThread()
        try mirror.observe(native: native)
    }

    private func assertOwnerThread() {
        precondition(currentScriptEventsThreadIdentity() == ownerThreadToken)
    }
}
