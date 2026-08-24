import Foundation

private func validOrdering(_ records: [SM64OracleTraceRecord]) -> Bool {
    guard !records.isEmpty else { return false }
    var lastTick: UInt64?
    var lastSequence: UInt32 = 0
    for record in records {
        guard record.domain == SM64CollisionQueryReceipt.domain,
              record.recordKind == SM64CollisionQueryReceipt.recordKind,
              (SM64CollisionQueryReceipt.firstEvent...SM64CollisionQueryReceipt.lastEvent)
                .contains(record.recordID),
              record.values.count == SM64CollisionQueryReceipt.valueCount(for: record.recordID)
        else { return false }
        if let lastTick {
            if record.simulationTick == lastTick {
                guard record.sequence == lastSequence &+ 1 else { return false }
            } else {
                guard record.simulationTick == lastTick + 1,
                      record.sequence == 0 else { return false }
            }
        } else {
            guard record.simulationTick == 2, record.sequence == 0 else { return false }
        }
        lastTick = record.simulationTick
        lastSequence = record.sequence
    }
    return Set(records.map(\.simulationTick)) == Set<UInt64>([2, 3])
}

private func writeTrace(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let service = SwiftCollisionQueriesMigrationService()
    for record in cTrace.records {
        try service.observe(native: record)
    }
    let records = service.traceRecords
    guard validOrdering(records), records.count == cTrace.records.count else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    try SM64OracleTraceFile.write(
        configuration: cTrace.configuration,
        records: records,
        to: swiftURL
    )
    let kinds = Set(records.map(\.recordID)).sorted()
        .map { String($0) }.joined(separator: ",")
    print(
        "swift_collision_queries_route_recorded records=\(records.count) "
            + "ticks=2,3 event_ids=\(kinds) "
            + "coverage=0x\(String(cTrace.configuration.coverageFingerprint, radix: 16))"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if !validOrdering(cTrace.records) || !validOrdering(swiftTrace.records) {
        blockers.append("ordering")
    }
    if cTrace.records.count != swiftTrace.records.count { blockers.append("record_count") }
    if cTrace.records != swiftTrace.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "collision_queries_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cTrace.records.count) swift_records=\(swiftTrace.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence)"
    )
    guard blockers.isEmpty else { throw SM64OracleTraceCodecError.invalidHeader }
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard data.count >= 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    data[data.index(before: data.endIndex)] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("collision_queries_pairing_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("collision_queries_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernCollisionQueriesRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else {
            throw SM64OracleTraceCodecError.truncated
        }
        switch mode {
        case "write":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try writeTrace(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "audit":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try audit(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "tamper":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try tamper(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
