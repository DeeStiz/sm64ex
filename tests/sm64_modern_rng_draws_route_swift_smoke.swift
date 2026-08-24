import Foundation

private let routeInputSeed: UInt64 = 0xd90050c281a631b0
private let routeSeed16 = UInt16(truncatingIfNeeded: routeInputSeed)

private func validOrdering(_ records: [SM64OracleTraceRecord]) -> Bool {
    guard !records.isEmpty else { return false }
    var lastTick: UInt64?
    var lastSequence: UInt32 = 0
    for record in records {
        guard record.domain == 8, record.recordKind == 3,
              (1...3).contains(record.recordID), record.values.count == 2,
              (2...3).contains(record.simulationTick)
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
    var service = SM64RNGDrawMigration(seed: routeSeed16)
    for record in cTrace.records {
        try service.observe(native: record)
    }
    guard validOrdering(service.observed), service.observed.count == cTrace.records.count,
          Set(service.observed.map(\.recordID)).count >= 2 else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    try SM64OracleTraceFile.write(
        configuration: cTrace.configuration,
        records: service.observed,
        to: swiftURL
    )
    print(
        "swift_rng_draws_route_recorded records=\(service.observed.count) "
            + "ticks=2,3 events=\(Set(service.observed.map(\.recordID)).count) "
            + "seed16=0x\(String(routeSeed16, radix: 16)) "
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
        "rng_draws_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cTrace.records.count) swift_records=\(swiftTrace.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) first_divergence=\(firstDivergence)"
    )
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
        print("rng_draws_pairing_tamper_rejected=0")
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("rng_draws_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernRNGDrawsRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else { throw SM64OracleTraceCodecError.truncated }
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
