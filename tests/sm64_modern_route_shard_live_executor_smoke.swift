import Foundation

@main
struct SM64ModernRouteShardLiveExecutorSmoke {
    private static let manifest = """
    # sm64-modern-route-shards-v1
    # shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes
    0x0000000000000001|oracle_hook|input|smoke|0x0000000000000011|0x0000000000000021|input|planned|live-one
    0x0000000000000002|oracle_hook|input|smoke|0x0000000000000022|0x0000000000000032|input|planned|live-two
    0x0000000000000003|oracle_hook|input|smoke|0x0000000000000033|0x0000000000000043|input|planned|fixture
    """
    private static let resultHeader = "# sm64-modern-route-shard-worker-result-v1"
    private static let resultSchema = "# shard_id|from_state|to_state|expected_records|actual_records|matched_records|first_divergence|fixture_only|build_fingerprint|content_fingerprint|timebase_fingerprint|configuration_fingerprint|initial_save_fingerprint|coverage_fingerprint"

    private struct CommandResult {
        let status: Int32
        let stdout: String
        let stderr: String
    }

    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw SmokeError.message("usage: route-shard-live-executor-smoke LIVE_EXECUTOR_TOOL")
        }
        let tool = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-route-shard-live-executor-smoke-\(UUID().uuidString)", isDirectory: true)
        let traceRoot = root.appendingPathComponent("traces", isDirectory: true)
        try FileManager.default.createDirectory(at: traceRoot, withIntermediateDirectories: true)
        let manifestURL = root.appendingPathComponent("manifest.tsv")
        try write(manifest, to: manifestURL)

        let rows = try manifest
            .split(whereSeparator: { $0.isNewline })
            .dropFirst(2)
            .map { try SM64RouteShard(manifestLine: $0, lineNumber: 3) }
        try writeLiveTrace(for: rows[0], to: traceRoot.appendingPathComponent("0x0000000000000001.trace"), value: 1)
        try writeLiveTrace(for: rows[1], to: traceRoot.appendingPathComponent("0x0000000000000002.trace"), value: 2)
        try writeFixtureTrace(for: rows[2], to: traceRoot.appendingPathComponent("0x0000000000000003.trace"))

        let resultURL = root.appendingPathComponent("worker-000.tsv")
        let success = try run(
            tool,
            arguments: [
                "--manifest", manifestURL.path,
                "--trace-root", traceRoot.path,
                "--output", resultURL.path,
                "--start-index", "0",
                "--count", "2",
            ]
        )
        try require(success.status == 0, "live range execution failed: \(success.stderr)")
        try require(success.stdout.contains("selected_rows=2"), "live range summary omitted selected rows")
        let resultLines = try read(resultURL).split(whereSeparator: { $0.isNewline }).map(String.init)
        try require(resultLines.count == 4, "worker result did not contain two rows")
        try require(resultLines[0] == resultHeader && resultLines[1] == resultSchema, "worker result header/schema drifted")
        try require(resultLines.dropFirst(2).allSatisfy { $0.split(separator: "|", omittingEmptySubsequences: false).count == 14 }, "worker result field count drifted")
        try require(resultLines.dropFirst(2).allSatisfy { $0.split(separator: "|", omittingEmptySubsequences: false)[7] == "0" }, "live rows were not marked fixture_only=0")

        try expectFailure(
            tool,
            arguments: [
                "--manifest", manifestURL.path,
                "--trace-root", traceRoot.path,
                "--output", root.appendingPathComponent("fixture.tsv").path,
                "--shard-id", "0x0000000000000003",
            ],
            expected: "fixture-only evidence is not allowed",
            name: "fixture-rejection"
        )
        try expectFailure(
            tool,
            arguments: [
                "--manifest", manifestURL.path,
                "--trace-root", root.appendingPathComponent("missing-traces").path,
                "--output", root.appendingPathComponent("missing.tsv").path,
                "--shard-id", "0x0000000000000001",
            ],
            expected: "missing live evidence",
            name: "missing-evidence-rejection"
        )
        try expectFailure(
            tool,
            arguments: [
                "--manifest", manifestURL.path,
                "--trace-root", traceRoot.path,
                "--output", resultURL.path,
                "--shard-id", "0x0000000000000001",
            ],
            expected: "worker result already exists",
            name: "output-reuse-rejection"
        )

        let markerTrace = traceRoot.appendingPathComponent("0x0000000000000001.trace.fixture_only")
        try write("1\n", to: markerTrace)
        try expectFailure(
            tool,
            arguments: [
                "--manifest", manifestURL.path,
                "--trace-root", traceRoot.path,
                "--output", root.appendingPathComponent("marker.tsv").path,
                "--shard-id", "0x0000000000000001",
            ],
            expected: "fixture-only evidence is not allowed",
            name: "fixture-marker-rejection"
        )

        print(
            "SM64 Modern route-shard live executor smoke passed "
                + "canonical_manifest=1 bounded_range=2 isolated_worker_result=1 "
                + "fixture_rejected=1 missing_live_evidence_rejected=1 "
                + "output_reuse_rejected=1 fixture_marker_rejected=1"
        )
    }

    private static func writeLiveTrace(for shard: SM64RouteShard, to url: URL, value: UInt64) throws {
        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x1111111111111111,
            contentFingerprint: 0x2222222222222222,
            timebaseFingerprint: 0x3333333333333333,
            configurationFingerprint: 0x4444444444444444,
            initialSaveFingerprint: shard.saveSeed,
            coverageFingerprint: 0x7777777777777777
        )
        let first = try SM64OracleTraceRecord(
            simulationTick: 1,
            domain: SM64RouteShardTraceDomain.input.cDomain,
            recordKind: SM64RouteShardTraceDomain.input.cRecordKind,
            subjectID: value,
            recordID: 0x90000000 + value,
            sequence: 0,
            values: [value]
        )
        let second = try SM64OracleTraceRecord(
            simulationTick: 2,
            domain: SM64RouteShardTraceDomain.input.cDomain,
            recordKind: SM64RouteShardTraceDomain.input.cRecordKind,
            subjectID: value,
            recordID: 0x90000000 + value,
            sequence: 0,
            values: [value]
        )
        try SM64OracleTraceFile.write(
            configuration: configuration,
            records: [first, second],
            to: url
        )
    }

    private static func writeFixtureTrace(for shard: SM64RouteShard, to url: URL) throws {
        try SM64OracleTraceFile.write(
            configuration: SM64RouteShardFixture.configuration(for: shard),
            records: SM64RouteShardFixture.records(for: shard),
            to: url
        )
    }

    private static func run(_ tool: URL, arguments: [String]) throws -> CommandResult {
        let process = Process()
        process.executableURL = tool
        process.arguments = arguments
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        return CommandResult(
            status: process.terminationStatus,
            stdout: String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            stderr: String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        )
    }

    private static func expectFailure(
        _ tool: URL,
        arguments: [String],
        expected: String,
        name: String
    ) throws {
        let result = try run(tool, arguments: arguments)
        try require(result.status != 0, "\(name) unexpectedly passed")
        try require(result.stderr.contains(expected), "\(name) omitted '\(expected)': \(result.stderr)")
    }

    private static func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url, options: .atomic)
    }

    private static func read(_ url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw SmokeError.message(message) }
    }

    private enum SmokeError: Error, CustomStringConvertible {
        case message(String)

        var description: String {
            switch self {
            case let .message(message): return message
            }
        }
    }
}
