import Foundation

private let routeShard: UInt64 = 0xdf0ce0c6988b445d
private let routeInputSeed: UInt64 = 0x35afd86ac2cdbe71
private let routeSaveSeed: UInt64 = 0x864b0c215a13472e
private let routeSource = "src/game/text_save.inc.h"
private let routeBuildFingerprint = "sm64-modern-text-route-build-v1"
private let routeContentFingerprint = "src/game/text_save.inc.h|text|save_write"

private enum TextRouteError: Error, CustomStringConvertible {
    case usage
    case invalid(String)
    case tamperExpected

    var description: String {
        switch self {
        case .usage: return "usage: write|audit|tamper|admit ..."
        case let .invalid(message): return message
        case .tamperExpected: return "tampered text route was accepted"
        }
    }
}

private func fnv(_ value: String) -> UInt64 {
    var hash: UInt64 = 1_469_598_103_934_665_603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1_099_511_628_211
    }
    return hash
}

private func update(_ hash: UInt64, _ value: UInt64) -> UInt64 {
    var result = hash
    for byte in 0..<8 {
        result ^= (value >> UInt64(byte * 8)) & 0xff
        result &*= 1_099_511_628_211
    }
    return result
}

private func expectedCoverageFingerprint() -> UInt64 {
    var hash: UInt64 = 1_469_598_103_934_665_603
    hash = update(hash, UInt64(SM64_MODERN_ORACLE_DOMAIN_SCRIPT))
    hash = update(hash, 0)
    hash = update(hash, UInt64(SM64_MODERN_TEXT_ORACLE_EVENT_LIFECYCLE))
    return update(hash, 1)
}

private func expectedConfigurationFingerprint() -> UInt64 {
    fnv("region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
        + String(format: "input_seed=0x%016llx;save_seed=0x%016llx;shard=0x%016llx",
                 routeInputSeed, routeSaveSeed, routeShard))
}

private func expectedInitialSaveFingerprint() -> UInt64 {
    fnv(String(format: "save=empty-us-slot-0;seed=0x%016llx", routeSaveSeed))
}

private func readReceipts(_ url: URL) throws -> SM64TextReceiptMirror {
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    guard !data.isEmpty, data.count % SM64TextReceipt.encodedSize == 0 else {
        throw TextRouteError.invalid("receipt sidecar is empty or truncated")
    }
    var mirror = SM64TextReceiptMirror()
    var offset = 0
    while offset < data.count {
        let start = data.index(data.startIndex, offsetBy: offset)
        let end = data.index(start, offsetBy: SM64TextReceipt.encodedSize)
        try mirror.observe(encoded: Data(data[start..<end]))
        offset += SM64TextReceipt.encodedSize
    }
    return mirror
}

private func validateRoute(
    cTraceURL: URL,
    swiftTraceURL: URL,
    receiptsURL: URL
) throws -> (
    configuration: SM64OracleTraceConfiguration,
    records: [SM64OracleTraceRecord],
    mirror: SM64TextReceiptMirror
) {
    let c = try SM64OracleTraceFile.read(from: cTraceURL)
    let swift = try SM64OracleTraceFile.read(from: swiftTraceURL)
    let mirror = try readReceipts(receiptsURL)
    guard c.configuration == swift.configuration else {
        throw TextRouteError.invalid("C/Swift configuration fingerprints differ")
    }
    guard c.configuration.regionCode == 0x5553,
          c.configuration.mode == .record,
          c.configuration.buildFingerprint == fnv(routeBuildFingerprint),
          c.configuration.contentFingerprint == fnv(routeContentFingerprint),
          c.configuration.timebaseFingerprint != 0,
          c.configuration.configurationFingerprint == expectedConfigurationFingerprint(),
          c.configuration.initialSaveFingerprint == expectedInitialSaveFingerprint(),
          c.configuration.coverageFingerprint == expectedCoverageFingerprint() else {
        throw TextRouteError.invalid("route fingerprints or coverage are not aligned")
    }
    guard mirror.receipts.count == 1,
          mirror.traceRecords.count == 1,
          c.records == mirror.traceRecords,
          swift.records == mirror.traceRecords else {
        throw TextRouteError.invalid("C/Swift/text receipt records are not an exact pair")
    }
    guard let receipt = mirror.receipts.first,
          receipt.sourceIdentity == fnv(routeSource),
          receipt.simulationTick == 2,
          receipt.eventID == SM64_MODERN_TEXT_EVENT_SAVE_WRITE,
          receipt.fileIndex == 0 else {
        throw TextRouteError.invalid("source text receipt identity or tick is not authored")
    }
    let record = mirror.traceRecords[0]
    guard record.domain == SM64_MODERN_ORACLE_DOMAIN_SCRIPT,
          record.recordKind == SM64_MODERN_ORACLE_RECORD_EVENT,
          record.subjectID == fnv(routeSource),
          record.recordID == UInt64(SM64_MODERN_TEXT_ORACLE_EVENT_LIFECYCLE),
          record.values == receipt.values,
          record.canonicalHash == receipt.canonicalHash else {
        throw TextRouteError.invalid("text receipt is not bound to its schema-4 record")
    }
    return (c.configuration, c.records, mirror)
}

private func writeSwiftTrace(cTraceURL: URL, receiptsURL: URL, outputURL: URL) throws {
    let c = try SM64OracleTraceFile.read(from: cTraceURL)
    let mirror = try readReceipts(receiptsURL)
    guard c.records == mirror.traceRecords else {
        throw TextRouteError.invalid("native trace does not equal source text receipts")
    }
    try SM64OracleTraceFile.write(
        configuration: c.configuration,
        records: mirror.traceRecords,
        to: outputURL
    )
    print(String(format: "swift_text_route_recorded records=%d ticks=2 source=0x%016llx text=0x%016llx payload=0x%016llx fixture_only=0",
                 mirror.traceRecords.count,
                 mirror.receipts[0].sourceIdentity,
                 mirror.receipts[0].textIdentity,
                 mirror.receipts[0].payloadHash))
}

private func tamper(cTraceURL: URL, receiptsURL: URL,
                    tamperedTraceURL: URL, tamperedReceiptsURL: URL) throws {
    var trace = try Data(contentsOf: cTraceURL)
    var receipts = try Data(contentsOf: receiptsURL)
    guard trace.count >= 72 + SM64OracleTraceRecord.encodedSize,
          receipts.count >= SM64TextReceipt.encodedSize else {
        throw TextRouteError.invalid("cannot tamper truncated artifacts")
    }
    trace[72 + SM64OracleTraceRecord.encodedSize - 1] ^= 0x01
    receipts[SM64TextReceipt.encodedSize - 1] ^= 0x01
    try trace.write(to: tamperedTraceURL, options: .atomic)
    try receipts.write(to: tamperedReceiptsURL, options: .atomic)
    print("text_route_tamper_artifacts_written=1")
}

private func admit(cTraceURL: URL, swiftTraceURL: URL,
                   receiptsURL: URL, reportURL: URL) throws {
    let paths = [cTraceURL.standardizedFileURL.path,
                 swiftTraceURL.standardizedFileURL.path,
                 receiptsURL.standardizedFileURL.path]
    guard Set(paths).count == paths.count else {
        throw TextRouteError.invalid("single-artifact admission is rejected")
    }
    guard !FileManager.default.fileExists(atPath: reportURL.path) else {
        throw TextRouteError.invalid("persistent rerun is rejected: report exists")
    }
    let result = try validateRoute(
        cTraceURL: cTraceURL,
        swiftTraceURL: swiftTraceURL,
        receiptsURL: receiptsURL
    )
    let body = String(format: "# sm64-modern-text-route-admission-v1\n"
                      + "shard=0x%016llx|passed|records=%d|receipts=%d|fixture_only=0|"
                      + "source=0x%016llx|coverage=0x%016llx\n",
                      routeShard, result.records.count,
                      result.mirror.receipts.count,
                      result.mirror.receipts[0].sourceIdentity,
                      result.configuration.coverageFingerprint)
    try Data(body.utf8).write(to: reportURL, options: .atomic)
    print("text_route_admission_passed=1 records=1 receipts=1 fixture_only=0")
}

@main
struct SM64TextRouteSwiftSmoke {
    static func main() {
        do {
            let args = Array(CommandLine.arguments.dropFirst())
            guard let command = args.first else { throw TextRouteError.usage }
            switch command {
            case "write":
                guard args.count == 4 else { throw TextRouteError.usage }
                try writeSwiftTrace(
                    cTraceURL: URL(fileURLWithPath: args[1]),
                    receiptsURL: URL(fileURLWithPath: args[2]),
                    outputURL: URL(fileURLWithPath: args[3])
                )
            case "audit":
                guard args.count == 4 else { throw TextRouteError.usage }
                let result = try validateRoute(
                    cTraceURL: URL(fileURLWithPath: args[1]),
                    swiftTraceURL: URL(fileURLWithPath: args[2]),
                    receiptsURL: URL(fileURLWithPath: args[3])
                )
                print("text_route_pair_audit admitted=1 records=1 receipts=1 "
                      + "first_divergence=none fixture_only=0")
                _ = result
            case "tamper":
                guard args.count == 5 else { throw TextRouteError.usage }
                try tamper(
                    cTraceURL: URL(fileURLWithPath: args[1]),
                    receiptsURL: URL(fileURLWithPath: args[2]),
                    tamperedTraceURL: URL(fileURLWithPath: args[3]),
                    tamperedReceiptsURL: URL(fileURLWithPath: args[4])
                )
            case "admit":
                guard args.count == 5 else { throw TextRouteError.usage }
                try admit(
                    cTraceURL: URL(fileURLWithPath: args[1]),
                    swiftTraceURL: URL(fileURLWithPath: args[2]),
                    receiptsURL: URL(fileURLWithPath: args[3]),
                    reportURL: URL(fileURLWithPath: args[4])
                )
            default:
                throw TextRouteError.usage
            }
        } catch {
            FileHandle.standardError.write(Data("text-route: \(error)\n".utf8))
            exit(1)
        }
    }
}
