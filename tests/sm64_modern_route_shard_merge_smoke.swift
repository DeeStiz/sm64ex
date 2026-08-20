import Foundation

@main
struct SM64ModernRouteShardMergeSmoke {
    private static let resultHeader = "# sm64-modern-route-shard-worker-result-v1"
    private static let resultSchema = "# shard_id|from_state|to_state|expected_records|actual_records|matched_records|first_divergence|fixture_only|build_fingerprint|content_fingerprint|timebase_fingerprint|configuration_fingerprint|initial_save_fingerprint|coverage_fingerprint"
    private static let manifest = """
    # sm64-modern-route-shards-v1
    # shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes
    0x0000000000000003|oracle_hook|third|smoke|0x0000000000000033|0x0000000000000043|input|planned|third
    0x0000000000000001|oracle_hook|first|smoke|0x0000000000000011|0x0000000000000021|input|planned|first
    0x0000000000000002|oracle_hook|second|smoke|0x0000000000000022|0x0000000000000032|input|planned|second
    """
    private static let fingerprints = [
        "0x1111111111111111",
        "0x2222222222222222",
        "0x3333333333333333",
        "0x4444444444444444",
        "0x5555555555555555",
        "0x6666666666666666",
    ]

    private struct CommandResult {
        let status: Int32
        let stdout: String
        let stderr: String
    }

    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw SmokeError.message("usage: route-shard-merge-smoke MERGE_TOOL")
        }
        let tool = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-route-shard-merge-smoke-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let manifestURL = root.appendingPathComponent("manifest.tsv")
        try write(manifest, to: manifestURL)
        try testSuccessfulMerge(tool: tool, root: root, manifestURL: manifestURL)
        try testRejectedInputs(tool: tool, root: root, manifestURL: manifestURL)
        print(
            "SM64 Modern route-shard merge smoke passed "
                + "canonical_order=1 duplicate_ids_rejected=1 unknown_ids_rejected=1 "
                + "missing_rows_rejected=1 invalid_transitions_rejected=1 "
                + "fixture_only_rejected=1 terminal_only=1 fingerprints=1"
        )
    }

    private static func testSuccessfulMerge(
        tool: URL,
        root: URL,
        manifestURL: URL
    ) throws {
        let workerThird = try makeWorker(
            root: root,
            name: "worker-third",
            rows: [resultLine(id: "0x0000000000000003")]
        )
        let workerFirst = try makeWorker(
            root: root,
            name: "worker-first",
            rows: [resultLine(id: "0x0000000000000001")]
        )
        let workerSecond = try makeWorker(
            root: root,
            name: "worker-second",
            rows: [resultLine(id: "0x0000000000000002")]
        )
        let reportURL = root.appendingPathComponent("merged-report.tsv")
        let evidenceURL = root.appendingPathComponent("merged-evidence.tsv")
        let result = try run(
            tool,
            arguments: [
                "--manifest", manifestURL.path,
                "--result", workerSecond.path,
                "--result", workerThird.path,
                "--result", workerFirst.path,
                "--output", reportURL.path,
                "--evidence-output", evidenceURL.path,
            ]
        )
        try require(result.status == 0, "successful merge failed: \(result.stderr)")
        try require(result.stdout.contains("canonical_order=manifest"), "merge did not report manifest order")
        try require(result.stdout.contains("fixture_only=0"), "merge did not report live-only evidence")
        try require(result.stdout.contains("manifest_fingerprint=0x"), "merge did not report manifest fingerprint")
        try require(result.stdout.contains("fingerprints=["), "merge did not report run fingerprints")

        let report = try read(reportURL)
        let reportLines = report.split(whereSeparator: { $0.isNewline }).map(String.init)
        let expectedIDs = [
            "0x0000000000000003",
            "0x0000000000000001",
            "0x0000000000000002",
        ]
        try require(
            reportLines.map { String($0.split(separator: "|", omittingEmptySubsequences: false)[0]) } == expectedIDs,
            "legacy report did not preserve manifest order"
        )
        try require(reportLines.allSatisfy { $0.split(separator: "|", omittingEmptySubsequences: false).count == 6 }, "legacy report schema changed")
        let evidence = try read(evidenceURL)
        let evidenceLines = evidence.split(whereSeparator: { $0.isNewline }).map(String.init)
        try require(evidenceLines.count == 5, "evidence sidecar row count mismatch")
        try require(evidenceLines[0] == resultHeader && evidenceLines[1] == resultSchema, "evidence header mismatch")
        try require(
            evidenceLines.dropFirst(2).map { String($0.split(separator: "|", omittingEmptySubsequences: false)[0]) } == expectedIDs,
            "evidence sidecar did not preserve manifest order"
        )
        let ledger = try SM64RouteShardExecutionLedger(
            manifest: manifest,
            report: report
        )
        try require(ledger.allTerminal && ledger.terminalCount == 3, "legacy report did not restore in the existing ledger")
    }

    private static func testRejectedInputs(
        tool: URL,
        root: URL,
        manifestURL: URL
    ) throws {
        let validIDs = [
            "0x0000000000000001",
            "0x0000000000000002",
            "0x0000000000000003",
        ]
        try expectFailure(
            tool: tool,
            manifestURL: manifestURL,
            root: root,
            name: "duplicate",
            rows: [
                resultLine(id: validIDs[0]),
                resultLine(id: validIDs[0]),
            ],
            expected: "duplicate result shard ID"
        )
        try expectFailure(
            tool: tool,
            manifestURL: manifestURL,
            root: root,
            name: "unknown",
            rows: [
                resultLine(id: "0x0000000000000099"),
            ],
            expected: "unknown result shard ID"
        )
        try expectFailure(
            tool: tool,
            manifestURL: manifestURL,
            root: root,
            name: "missing",
            rows: [
                resultLine(id: validIDs[0]),
                resultLine(id: validIDs[1]),
            ],
            expected: "missing result rows"
        )
        try expectFailure(
            tool: tool,
            manifestURL: manifestURL,
            root: root,
            name: "transition",
            rows: [
                resultLine(id: validIDs[0], from: "planned"),
                resultLine(id: validIDs[1]),
                resultLine(id: validIDs[2]),
            ],
            expected: "invalid transition"
        )
        try expectFailure(
            tool: tool,
            manifestURL: manifestURL,
            root: root,
            name: "nonterminal",
            rows: [
                resultLine(id: validIDs[0], to: "running"),
                resultLine(id: validIDs[1]),
                resultLine(id: validIDs[2]),
            ],
            expected: "invalid transition"
        )
        try expectFailure(
            tool: tool,
            manifestURL: manifestURL,
            root: root,
            name: "fixture",
            rows: [
                resultLine(id: validIDs[0], fixtureOnly: true),
                resultLine(id: validIDs[1]),
                resultLine(id: validIDs[2]),
            ],
            expected: "fixture_only evidence is not allowed"
        )
        var mismatched = fingerprints
        mismatched[0] = "0x9999999999999999"
        try expectFailure(
            tool: tool,
            manifestURL: manifestURL,
            root: root,
            name: "fingerprint",
            rows: [
                resultLine(id: validIDs[0]),
                resultLine(id: validIDs[1], fingerprintValues: mismatched),
                resultLine(id: validIDs[2]),
            ],
            expected: "inconsistent build fingerprint"
        )
    }

    private static func expectFailure(
        tool: URL,
        manifestURL: URL,
        root: URL,
        name: String,
        rows: [String],
        expected: String
    ) throws {
        let resultURL = try makeWorker(root: root, name: "failure-\(name)", rows: rows)
        let outputURL = root.appendingPathComponent("failure-\(name)-output.tsv")
        let result = try run(
            tool,
            arguments: [
                "--manifest", manifestURL.path,
                "--result", resultURL.path,
                "--output", outputURL.path,
            ]
        )
        try require(result.status != 0, "\(name) input was accepted")
        try require(result.stderr.contains(expected), "\(name) failure omitted '\(expected)': \(result.stderr)")
        try require(!FileManager.default.fileExists(atPath: outputURL.path), "\(name) wrote output before validation")
    }

    private static func resultLine(
        id: String,
        from: String = "running",
        to: String = "passed",
        expectedRecords: UInt64 = 1,
        actualRecords: UInt64 = 1,
        matchedRecords: UInt64 = 1,
        divergence: String = "",
        fixtureOnly: Bool = false,
        fingerprintValues: [String] = fingerprints
    ) -> String {
        [
            id,
            from,
            to,
            String(expectedRecords),
            String(actualRecords),
            String(matchedRecords),
            divergence,
            fixtureOnly ? "1" : "0",
        ]
            .appending(contentsOf: fingerprintValues)
            .joined(separator: "|")
    }

    private static func makeWorker(root: URL, name: String, rows: [String]) throws -> URL {
        let url = root.appendingPathComponent("\(name).result")
        let text = ([resultHeader, resultSchema] + rows).joined(separator: "\n") + "\n"
        try write(text, to: url)
        return url
    }

    private static func run(_ tool: URL, arguments: [String]) throws -> CommandResult {
        let process = Process()
        process.executableURL = tool
        process.arguments = arguments
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        try process.run()
        process.waitUntilExit()
        let stdout = String(
            data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let stderr = String(
            data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        return CommandResult(status: process.terminationStatus, stdout: stdout, stderr: stderr)
    }

    private static func read(_ url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    private static func write(_ text: String, to url: URL) throws {
        try Data(text.utf8).write(to: url, options: .atomic)
    }

    private static func require(_ condition: Bool, _ message: String) throws {
        guard condition else { throw SmokeError.message(message) }
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

private extension Array where Element == String {
    func appending(contentsOf values: [String]) -> [String] {
        self + values
    }
}
