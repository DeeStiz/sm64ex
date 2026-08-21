import Foundation

/// Promotes a trace emitted by a real Swift route into the canonical M33
/// execution ledger. Unlike the fixture replay tool, this tool never creates
/// records: the trace must already exist and must cover the manifest row's
/// complete expected domain set.
@main
struct SM64RouteShardPromotionTool {
    private enum ToolError: Error, CustomStringConvertible {
        case invalidArguments
        case missingArgument(String)
        case wrongTraceMode(SM64OracleTraceMode)
        case coverageFingerprintDeferred
        case incompleteWindow(UInt64)
        case incompleteCoverage(String)
        case reportRequired

        var description: String {
            switch self {
            case .invalidArguments:
                return "usage: sm64-route-shard-promote --manifest MANIFEST --shard-id 0xID --trace TRACE --report REPORT"
            case let .missingArgument(name):
                return "missing argument " + name
            case let .wrongTraceMode(mode):
                return "live promotion requires a record trace, got " + String(describing: mode)
            case .coverageFingerprintDeferred:
                return "live promotion requires a nonzero coverage fingerprint"
            case let .incompleteWindow(count):
                return "live promotion requires an independently recorded multi-tick window (records=\(count))"
            case let .incompleteCoverage(reason):
                return "live trace coverage incomplete: " + reason
            case .reportRequired:
                return "live promotion requires --report"
            }
        }
    }

    private struct Options {
        let manifest: URL
        let shardID: UInt64
        let trace: URL
        let report: URL
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-route-shard-promote: " + String(describing: error) + "\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let manifest = try String(contentsOf: options.manifest, encoding: .utf8)
        let previousReport: String?
        if FileManager.default.fileExists(atPath: options.report.path) {
            previousReport = try String(contentsOf: options.report, encoding: .utf8)
        } else {
            previousReport = nil
        }
        var ledger = try SM64RouteShardExecutionLedger(manifest: manifest, report: previousReport)
        let shard = try ledger.shard(id: options.shardID)
        try ledger.begin(id: options.shardID)

        do {
            let trace = try SM64OracleTraceFile.read(from: options.trace)
            guard trace.configuration.mode == .record else {
                throw ToolError.wrongTraceMode(trace.configuration.mode)
            }
            guard trace.configuration.coverageFingerprint != 0 else {
                throw ToolError.coverageFingerprintDeferred
            }
            guard trace.records.count >= 2 else {
                throw ToolError.incompleteWindow(UInt64(trace.records.count))
            }
            let coverage = SM64RouteShardFixture.coverage(for: shard, records: trace.records)
            guard coverage.isComplete else {
                throw ToolError.incompleteCoverage(
                    "missing=\(coverage.missingDomains.sorted()) "
                        + "unexpected=\(coverage.unexpectedKeys.sorted()) "
                        + "count=\(coverage.recordCountMatches)"
                )
            }
            let count = UInt64(trace.records.count)
            try ledger.finish(
                id: options.shardID,
                state: .passed,
                evidence: SM64RouteShardExecutionEvidence(
                    expectedRecords: count,
                    actualRecords: count,
                    matchedRecords: count
                )
            )
            try Data(ledger.report().utf8).write(to: options.report, options: .atomic)
            print(
                "SM64 route-shard live promotion passed id="
                    + String(format: "0x%016llx", shard.id)
                    + " records=\(trace.records.count) status=passed fixture_only=0"
            )
        } catch {
            let evidence = SM64RouteShardExecutionEvidence(
                expectedRecords: 0,
                actualRecords: 0,
                matchedRecords: 0,
                firstDivergence: String(describing: error)
            )
            try? ledger.finish(id: options.shardID, state: .failed, evidence: evidence)
            throw error
        }
    }

    private static func parse(arguments: [String]) throws -> Options {
        guard !arguments.isEmpty, arguments.count.isMultiple(of: 2) else {
            throw ToolError.invalidArguments
        }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            guard arguments[index].hasPrefix("--"), index + 1 < arguments.count else {
                throw ToolError.invalidArguments
            }
            values[arguments[index]] = arguments[index + 1]
            index += 2
        }
        guard let manifest = values["--manifest"],
              let rawID = values["--shard-id"],
              let trace = values["--trace"] else {
            throw ToolError.missingArgument("--manifest, --shard-id, or --trace")
        }
        guard let report = values["--report"] else {
            throw ToolError.reportRequired
        }
        guard rawID.hasPrefix("0x"),
              let shardID = UInt64(rawID.dropFirst(2), radix: 16) else {
            throw ToolError.invalidArguments
        }
        return Options(
            manifest: URL(fileURLWithPath: manifest).standardizedFileURL,
            shardID: shardID,
            trace: URL(fileURLWithPath: trace).standardizedFileURL,
            report: URL(fileURLWithPath: report).standardizedFileURL
        )
    }
}
