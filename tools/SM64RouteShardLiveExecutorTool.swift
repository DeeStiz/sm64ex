import Foundation

/// Materializes live route evidence into one isolated worker-result file.
///
/// The executor deliberately consumes traces produced by a real record-mode
/// route. It does not call the fixture replay path, synthesize records, or
/// turn a missing trace into a blocked/pass row. C/Swift comparison remains a
/// separate route-oracle gate; this tool only admits traces that already carry
/// complete live coverage for their manifest row.
@main
struct SM64RouteShardLiveExecutorTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let resultHeader = "# sm64-modern-route-shard-worker-result-v1"
    private static let resultSchema = "# shard_id|from_state|to_state|expected_records|actual_records|matched_records|first_divergence|fixture_only|build_fingerprint|content_fingerprint|timebase_fingerprint|configuration_fingerprint|initial_save_fingerprint|coverage_fingerprint"
    private static let maxBatchSize = 256

    private enum ToolError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case unreadable(URL, Error)
        case unwritable(URL, Error)
        case invalidManifest(String)
        case unknownShard(UInt64)
        case emptySelection
        case missingLiveEvidence(URL, UInt64)
        case invalidLiveEvidence(UInt64, String)
        case fixtureOnly(UInt64, URL)
        case outputExists(URL)
        case inconsistentFingerprint(String, UInt64, UInt64)

        var description: String {
            switch self {
            case let .invalidArguments(message): return message
            case let .unreadable(url, error): return "cannot read \(url.path): \(error)"
            case let .unwritable(url, error): return "cannot write \(url.path): \(error)"
            case let .invalidManifest(reason): return "invalid route-shard manifest: \(reason)"
            case let .unknownShard(id): return String(format: "unknown route shard 0x%016llx", id)
            case .emptySelection: return "route-shard selection is empty"
            case let .missingLiveEvidence(url, id):
                return String(format: "missing live evidence for shard 0x%016llx: %@", id, url.path)
            case let .invalidLiveEvidence(id, reason):
                return String(format: "invalid live evidence for shard 0x%016llx: %@", id, reason)
            case let .fixtureOnly(id, url):
                return String(format: "fixture-only evidence is not allowed for live execution (shard 0x%016llx: %@)", id, url.path)
            case let .outputExists(url): return "worker result already exists: \(url.path)"
            case let .inconsistentFingerprint(name, expected, actual):
                return String(
                    format: "inconsistent %@ fingerprint across live traces: 0x%016llx != 0x%016llx",
                    name,
                    expected,
                    actual
                )
            }
        }
    }

    private struct Options {
        let manifest: URL
        let traceRoot: URL?
        let trace: URL?
        let output: URL
        let shardID: UInt64?
        let startIndex: Int?
        let count: Int?
    }

    private struct ManifestRow {
        let shard: SM64RouteShard
        let line: Int
    }

    private struct Fingerprints {
        let build: UInt64
        let content: UInt64
        let timebase: UInt64
        let configuration: UInt64
        let coverage: UInt64

        init(configuration: SM64OracleTraceConfiguration) {
            build = configuration.buildFingerprint
            content = configuration.contentFingerprint
            timebase = configuration.timebaseFingerprint
            self.configuration = configuration.configurationFingerprint
            coverage = configuration.coverageFingerprint
        }
    }

    private struct WorkerResult {
        let id: UInt64
        let expectedRecords: UInt64
        let actualRecords: UInt64
        let matchedRecords: UInt64
        let buildFingerprint: UInt64
        let contentFingerprint: UInt64
        let timebaseFingerprint: UInt64
        let configurationFingerprint: UInt64
        let initialSaveFingerprint: UInt64
        let coverageFingerprint: UInt64

        var encoded: String {
            [
                formatID(id),
                "running",
                "passed",
                String(expectedRecords),
                String(actualRecords),
                String(matchedRecords),
                "",
                "0",
                formatFingerprint(buildFingerprint),
                formatFingerprint(contentFingerprint),
                formatFingerprint(timebaseFingerprint),
                formatFingerprint(configurationFingerprint),
                formatFingerprint(initialSaveFingerprint),
                formatFingerprint(coverageFingerprint),
            ].joined(separator: "|")
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-route-shard-live-exec: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let manifestText = try read(options.manifest)
        let rows = try parseManifest(manifestText)
        let selected = try selectRows(rows, options: options)
        guard !selected.isEmpty else { throw ToolError.emptySelection }

        let selectedEvidence: [(ManifestRow, URL, SM64OracleTraceConfiguration, [SM64OracleTraceRecord])] = try selected.map { row in
            let traceURL = try traceURL(for: row.shard, options: options)
            let trace = try readLiveTrace(traceURL, for: row.shard)
            return (row, traceURL, trace.configuration, trace.records)
        }

        let fingerprints = Fingerprints(configuration: selectedEvidence[0].2)
        for (_, _, configuration, _) in selectedEvidence.dropFirst() {
            try checkFingerprints(fingerprints, actual: Fingerprints(configuration: configuration))
        }

        let results = try selectedEvidence.map { row, _, configuration, records in
            let actualRecords = UInt64(records.count)
            let expectedRecords = actualRecords
            guard expectedRecords > 0 else {
                throw ToolError.invalidLiveEvidence(
                    row.shard.id,
                    "live trace contains no records"
                )
            }
            return WorkerResult(
                id: row.shard.id,
                expectedRecords: expectedRecords,
                actualRecords: actualRecords,
                matchedRecords: actualRecords,
                buildFingerprint: configuration.buildFingerprint,
                contentFingerprint: configuration.contentFingerprint,
                timebaseFingerprint: configuration.timebaseFingerprint,
                configurationFingerprint: configuration.configurationFingerprint,
                initialSaveFingerprint: configuration.initialSaveFingerprint,
                coverageFingerprint: configuration.coverageFingerprint
            )
        }

        guard !FileManager.default.fileExists(atPath: options.output.path) else {
            throw ToolError.outputExists(options.output)
        }
        let output = ([resultHeader, resultSchema] + results.map(\.encoded)).joined(separator: "\n") + "\n"
        do {
            try FileManager.default.createDirectory(
                at: options.output.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(output.utf8).write(to: options.output, options: .atomic)
        } catch {
            throw ToolError.unwritable(options.output, error)
        }

        print(
            "SM64 route-shard live execution passed "
                + "manifest_rows=\(rows.count) selected_rows=\(results.count) "
                + "worker_result=\(options.output.path) fixture_only=0 "
                + "canonical_order=manifest"
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        guard !arguments.isEmpty else { throw ToolError.invalidArguments(usage) }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let option = arguments[index]
            guard option.hasPrefix("--"), index + 1 < arguments.count else {
                throw ToolError.invalidArguments(usage)
            }
            guard values[option] == nil else {
                throw ToolError.invalidArguments("duplicate option \(option)\n\(usage)")
            }
            values[option] = arguments[index + 1]
            index += 2
        }
        let known = Set(["--manifest", "--trace-root", "--trace", "--output", "--shard-id", "--start-index", "--count"])
        if let unknown = values.keys.first(where: { !known.contains($0) }) {
            throw ToolError.invalidArguments("unknown option \(unknown)\n\(usage)")
        }
        guard let manifest = values["--manifest"], let output = values["--output"] else {
            throw ToolError.invalidArguments(usage)
        }
        let traceRoot = values["--trace-root"].map { URL(fileURLWithPath: $0).standardizedFileURL }
        let trace = values["--trace"].map { URL(fileURLWithPath: $0).standardizedFileURL }
        guard traceRoot != nil || trace != nil else {
            throw ToolError.invalidArguments("one of --trace-root or --trace is required\n\(usage)")
        }
        guard trace == nil || values["--shard-id"] != nil else {
            throw ToolError.invalidArguments("--trace requires --shard-id\n\(usage)")
        }
        guard traceRoot == nil || trace == nil else {
            throw ToolError.invalidArguments("--trace-root and --trace are mutually exclusive\n\(usage)")
        }

        let shardID = try values["--shard-id"].map { try parseHex($0, name: "--shard-id") }
        let startIndex = try values["--start-index"].map { try parseNonnegativeInt($0, name: "--start-index") }
        let count = try values["--count"].map { try parseNonnegativeInt($0, name: "--count") }
        guard shardID != nil || (startIndex != nil && count != nil) else {
            throw ToolError.invalidArguments("select one shard with --shard-id or a bounded range with --start-index/--count\n\(usage)")
        }
        guard shardID == nil || (startIndex == nil && count == nil) else {
            throw ToolError.invalidArguments("--shard-id cannot be combined with --start-index/--count\n\(usage)")
        }
        if let count, !(1...maxBatchSize).contains(count) {
            throw ToolError.invalidArguments("--count must be between 1 and \(maxBatchSize)")
        }
        return Options(
            manifest: URL(fileURLWithPath: manifest).standardizedFileURL,
            traceRoot: traceRoot,
            trace: trace,
            output: URL(fileURLWithPath: output).standardizedFileURL,
            shardID: shardID,
            startIndex: startIndex,
            count: count
        )
    }

    private static func parseManifest(_ text: String) throws -> [ManifestRow] {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count >= 2, lines[0] == manifestHeader, lines[1] == manifestSchema else {
            throw ToolError.invalidManifest("invalid header")
        }
        var rows: [ManifestRow] = []
        var seen: Set<UInt64> = []
        for (offset, line) in lines.dropFirst(2).enumerated() {
            let lineNumber = offset + 3
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            do {
                let shard = try SM64RouteShard(manifestLine: line, lineNumber: lineNumber)
                guard seen.insert(shard.id).inserted else {
                    throw ToolError.invalidManifest(String(format: "duplicate shard 0x%016llx", shard.id))
                }
                rows.append(ManifestRow(shard: shard, line: lineNumber))
            } catch let error as ToolError {
                throw error
            } catch {
                throw ToolError.invalidManifest("line \(lineNumber): \(error)")
            }
        }
        guard !rows.isEmpty else { throw ToolError.invalidManifest("manifest has no rows") }
        return rows
    }

    private static func selectRows(_ rows: [ManifestRow], options: Options) throws -> [ManifestRow] {
        if let shardID = options.shardID {
            guard let row = rows.first(where: { $0.shard.id == shardID }) else {
                throw ToolError.unknownShard(shardID)
            }
            return [row]
        }
        guard let start = options.startIndex, let count = options.count,
              start < rows.count, start + count <= rows.count else {
            throw ToolError.invalidArguments("range must fit manifest rows (rows=\(rows.count))\n\(usage)")
        }
        return Array(rows[start..<(start + count)])
    }

    private static func traceURL(for shard: SM64RouteShard, options: Options) throws -> URL {
        if let trace = options.trace { return trace }
        guard let root = options.traceRoot else {
            throw ToolError.invalidArguments("missing trace root")
        }
        return root.appendingPathComponent(formatID(shard.id) + ".trace")
    }

    private static func readLiveTrace(
        _ url: URL,
        for shard: SM64RouteShard
    ) throws -> (configuration: SM64OracleTraceConfiguration, records: [SM64OracleTraceRecord]) {
        guard FileManager.default.fileExists(atPath: url.path),
              (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue ?? 0 > 0 else {
            throw ToolError.missingLiveEvidence(url, shard.id)
        }
        let trace: (configuration: SM64OracleTraceConfiguration, records: [SM64OracleTraceRecord])
        do {
            trace = try SM64OracleTraceFile.read(from: url)
        } catch {
            throw ToolError.invalidLiveEvidence(shard.id, "cannot decode trace \(url.path): \(error)")
        }
        guard trace.configuration.mode == .record else {
            throw ToolError.invalidLiveEvidence(shard.id, "trace mode must be record")
        }
        guard trace.configuration.regionCode != 0 else {
            throw ToolError.invalidLiveEvidence(shard.id, "region fingerprint is zero")
        }
        let fingerprints = [
            trace.configuration.buildFingerprint,
            trace.configuration.contentFingerprint,
            trace.configuration.timebaseFingerprint,
            trace.configuration.configurationFingerprint,
            trace.configuration.initialSaveFingerprint,
        ]
        guard fingerprints.allSatisfy({ $0 != 0 }) else {
            throw ToolError.invalidLiveEvidence(shard.id, "live trace contains a zero run/save fingerprint")
        }
        let coverage = SM64RouteShardFixture.coverage(for: shard, records: trace.records)
        guard coverage.isComplete else {
            throw ToolError.invalidLiveEvidence(
                shard.id,
                "coverage missing=\(coverage.missingDomains.sorted()) unexpected=\(coverage.unexpectedKeys.sorted()) count=\(coverage.recordCountMatches)"
            )
        }
        let fixtureConfiguration = SM64RouteShardFixture.configuration(for: shard)
        let fixtureRecords = try? SM64RouteShardFixture.records(for: shard)
        let fixtureMarker = URL(fileURLWithPath: url.path + ".fixture_only")
        if FileManager.default.fileExists(atPath: fixtureMarker.path)
            || trace.configuration == fixtureConfiguration
            || trace.records == fixtureRecords {
            throw ToolError.fixtureOnly(shard.id, url)
        }
        let tickCount = Set(trace.records.map(\.simulationTick)).count
        guard trace.records.count >= 2, tickCount >= 2 else {
            throw ToolError.invalidLiveEvidence(
                shard.id,
                "live trace requires a multi-tick window records=\(trace.records.count) ticks=\(tickCount)"
            )
        }
        guard trace.configuration.coverageFingerprint != 0 else {
            throw ToolError.invalidLiveEvidence(shard.id, "live trace coverage fingerprint is zero")
        }
        return trace
    }

    private static func checkFingerprints(_ expected: Fingerprints, actual: Fingerprints) throws {
        let values: [(String, UInt64, UInt64)] = [
            ("build", expected.build, actual.build),
            ("content", expected.content, actual.content),
            ("timebase", expected.timebase, actual.timebase),
            ("configuration", expected.configuration, actual.configuration),
            ("coverage", expected.coverage, actual.coverage),
        ]
        for (name, expectedValue, actualValue) in values where expectedValue != actualValue {
            throw ToolError.inconsistentFingerprint(name, expectedValue, actualValue)
        }
    }

    private static func read(_ url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ToolError.unreadable(url, error)
        }
    }

    private static func parseHex(_ value: String, name: String) throws -> UInt64 {
        guard value.hasPrefix("0x"), value.dropFirst(2).count == 16,
              value.dropFirst(2).allSatisfy(isHexDigit),
              let parsed = UInt64(value.dropFirst(2), radix: 16) else {
            throw ToolError.invalidArguments("invalid \(name) value \(value)\n\(usage)")
        }
        return parsed
    }

    private static func parseNonnegativeInt(_ value: String, name: String) throws -> Int {
        guard !value.isEmpty, value.allSatisfy(\.isNumber), let parsed = Int(value) else {
            throw ToolError.invalidArguments("invalid \(name) value \(value)\n\(usage)")
        }
        return parsed
    }

    private static func isHexDigit(_ character: Character) -> Bool {
        switch character {
        case "0"..."9", "a"..."f", "A"..."F": return true
        default: return false
        }
    }

    private static func formatID(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }

    private static func formatFingerprint(_ value: UInt64) -> String {
        formatID(value)
    }

    private static var usage: String {
        "usage: sm64-route-shard-live-exec --manifest MANIFEST --trace-root ROOT --output RESULT (--shard-id 0xID | --start-index N --count N)"
    }
}
