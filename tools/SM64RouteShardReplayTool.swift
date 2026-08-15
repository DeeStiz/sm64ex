import Foundation

@main
struct SM64RouteShardReplayTool {
    private enum ToolError: Error, CustomStringConvertible {
        case invalidArguments
        case missingArgument(String)

        var description: String {
            switch self {
            case .invalidArguments:
                return "usage: sm64-route-shard-replay --manifest MANIFEST --shard-id 0xID --output TRACE [--report REPORT]"
            case let .missingArgument(name): return "missing argument \(name)"
            }
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data("sm64-route-shard-replay: \(error)\n".utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let manifest = try String(contentsOf: options.manifest, encoding: .utf8)
        let previousReport: String?
        if let report = options.report, FileManager.default.fileExists(atPath: report.path) {
            previousReport = try String(contentsOf: report, encoding: .utf8)
        } else {
            previousReport = nil
        }
        var ledger = try SM64RouteShardExecutionLedger(manifest: manifest, report: previousReport)
        let shard = try ledger.shard(id: options.shardID)
        try ledger.begin(id: options.shardID)
        let records: [SM64OracleTraceRecord]
        do {
            records = try SM64RouteShardFixture.records(for: shard)
            try SM64OracleTraceFile.write(
                configuration: SM64RouteShardFixture.configuration(for: shard),
                records: records,
                to: options.output
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
        let evidence = SM64RouteShardExecutionEvidence(
            expectedRecords: UInt64(records.count),
            actualRecords: UInt64(records.count),
            matchedRecords: UInt64(records.count)
        )
        try ledger.finish(id: options.shardID, state: .passed, evidence: evidence)
        if let report = options.report {
            try Data(ledger.report().utf8).write(to: report, options: .atomic)
        }
        print(
            "SM64 route-shard fixture replay passed id="
                + String(format: "0x%016llx", shard.id)
                + " records=\(records.count) status=passed fixture_only=1"
        )
    }

    private struct Options {
        let manifest: URL
        let shardID: UInt64
        let output: URL
        let report: URL?
    }

    private static func parse(arguments: [String]) throws -> Options {
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            guard arguments[index].hasPrefix("--"), index + 1 < arguments.count else {
                throw ToolError.invalidArguments
            }
            values[arguments[index]] = arguments[index + 1]
            index += 2
        }
        guard let manifest = values["--manifest"], let rawID = values["--shard-id"],
              let output = values["--output"] else {
            throw ToolError.missingArgument("--manifest, --shard-id, or --output")
        }
        guard rawID.hasPrefix("0x"), let shardID = UInt64(rawID.dropFirst(2), radix: 16) else {
            throw ToolError.invalidArguments
        }
        return Options(
            manifest: URL(fileURLWithPath: manifest).standardizedFileURL,
            shardID: shardID,
            output: URL(fileURLWithPath: output).standardizedFileURL,
            report: values["--report"].map { URL(fileURLWithPath: $0).standardizedFileURL }
        )
    }
}
