import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func selectedRecords(from records: [SM64OracleTraceRecord]) -> [SM64OracleTraceRecord] {
    records.filter { record in
        if record.domain == 0 && record.recordKind == 1 {
            return (1...6).contains(record.recordID) && record.values.count == 1
        }
        if record.domain == 6 && record.recordKind == 3 {
            return (1...5).contains(record.recordID)
                && record.values.count == SM64LevelScriptRouteReceipt.scriptValueCount(
                    for: record.recordID)
        }
        return false
    }
}

private func writeTrace(cURL: URL, swiftURL: URL) throws {
    let native = try SM64OracleTraceFile.read(from: cURL)
    let service = SM64LevelScriptRouteMigrationService()
    for record in selectedRecords(from: native.records) {
        try service.observe(native: record)
    }
    let records = service.traceRecords
    require(records.count == native.records.count, "native route filter changed record count")
    require(service.globalRecords == 12, "global records")
    require(service.scriptRecords > 0, "script records")
    require(service.transitionRecords == 0, "bounded CotMC transition blocker must remain explicit")
    require(Set(records.map(\.simulationTick)) == Set([2, 3]), "ticks")
    try SM64OracleTraceFile.write(
        configuration: native.configuration,
        records: records,
        to: swiftURL
    )
    print(
        "swift_level_script_route_recorded records=\(records.count) "
            + "global=\(service.globalRecords) script=\(service.scriptRecords) "
            + "transition=\(service.transitionRecords) ticks=2,3 "
            + "coverage=0x\(String(native.configuration.coverageFingerprint, radix: 16))"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if cTrace.records.count != swiftTrace.records.count { blockers.append("record_count") }
    if cTrace.records != swiftTrace.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "level_script_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
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
        print("level_script_pairing_tamper_rejected=0")
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("level_script_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernLevelScriptRouteSwiftSmoke {
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
