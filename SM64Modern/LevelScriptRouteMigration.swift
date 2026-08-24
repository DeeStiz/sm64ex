import Darwin
import Foundation

enum SM64LevelScriptRouteMigrationError: Error, Equatable, Sendable {
    case invalidRecord
    case outOfOrder
    case unexpectedDomain
}

/// A value-only receipt for the generated CotMC level-script shard.  The C
/// interpreter remains authoritative; this service only validates and copies
/// the schema-4 global/script records published at the owner-thread boundary.
struct SM64LevelScriptRouteReceipt: Equatable, Sendable {
    let native: SM64OracleTraceRecord

    init(native: SM64OracleTraceRecord) throws {
        switch (native.domain, native.recordKind) {
        case (0, 1):
            guard (1...6).contains(native.recordID), native.values.count == 1 else {
                throw SM64LevelScriptRouteMigrationError.invalidRecord
            }
        case (6, 3):
            guard (1...5).contains(native.recordID),
                  native.values.count == Self.scriptValueCount(for: native.recordID)
            else {
                throw SM64LevelScriptRouteMigrationError.invalidRecord
            }
        default:
            throw SM64LevelScriptRouteMigrationError.unexpectedDomain
        }
        guard native.simulationTick == 2 || native.simulationTick == 3 else {
            throw SM64LevelScriptRouteMigrationError.invalidRecord
        }
        self.native = native
    }

    static func scriptValueCount(for eventID: UInt64) -> Int {
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

/// Owner-thread/value-only mirror for the exact generated level-script route.
/// It deliberately does not execute an opcode or infer a transition that the
/// native route did not publish.
final class SM64LevelScriptRouteMigrationService {
    private let ownerThreadToken: UInt64
    private(set) var receipts: [SM64LevelScriptRouteReceipt] = []

    init(ownerThreadToken: UInt64 = currentLevelScriptRouteThreadToken()) {
        self.ownerThreadToken = ownerThreadToken
    }

    func observe(native: SM64OracleTraceRecord) throws {
        precondition(currentLevelScriptRouteThreadToken() == ownerThreadToken)
        let receipt = try SM64LevelScriptRouteReceipt(native: native)
        if let previous = receipts.last {
            let current = receipt.native
            guard current.simulationTick >= previous.native.simulationTick else {
                throw SM64LevelScriptRouteMigrationError.outOfOrder
            }

            // The trace stream is interleaved by native owner calls.  Sequence
            // numbers are scoped to each schema-4 domain, so compare only the
            // immediately preceding record in the same domain.
            if let sameDomain = receipts.last(where: { $0.native.domain == current.domain }) {
                guard current.simulationTick == sameDomain.native.simulationTick
                        ? current.sequence == sameDomain.native.sequence &+ 1
                        : current.simulationTick == sameDomain.native.simulationTick + 1
                            && current.sequence == 0 else {
                    throw SM64LevelScriptRouteMigrationError.outOfOrder
                }
            } else {
                guard current.sequence == 0 else {
                    throw SM64LevelScriptRouteMigrationError.outOfOrder
                }
            }
        } else {
            guard receipt.native.simulationTick == 2 else {
                throw SM64LevelScriptRouteMigrationError.outOfOrder
            }
        }
        receipts.append(receipt)
    }

    var traceRecords: [SM64OracleTraceRecord] { receipts.map(\.native) }

    var globalRecords: Int { receipts.reduce(into: 0) { if $1.native.domain == 0 { $0 += 1 } } }
    var scriptRecords: Int { receipts.reduce(into: 0) { if $1.native.domain == 6 { $0 += 1 } } }
    var transitionRecords: Int {
        receipts.reduce(into: 0) {
            if $1.native.domain == 6 && $1.native.recordID == 3 { $0 += 1 }
        }
    }

}

private func currentLevelScriptRouteThreadToken() -> UInt64 {
    var identifier: UInt64 = 0
    precondition(pthread_threadid_np(nil, &identifier) == 0)
    return identifier
}
