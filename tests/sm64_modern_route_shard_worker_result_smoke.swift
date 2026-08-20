import Foundation

@main
struct SM64ModernRouteShardWorkerResultSmoke {
    private static let fingerprints = [
        "0x1111111111111111",
        "0x2222222222222222",
        "0x3333333333333333",
        "0x4444444444444444",
        "0x5555555555555555",
        "0x6666666666666666",
    ]
    private static let header = "# sm64-modern-route-shard-worker-result-v1"
    private static let schema = "# shard_id|from_state|to_state|expected_records|actual_records|matched_records|first_divergence|fixture_only|build_fingerprint|content_fingerprint|timebase_fingerprint|configuration_fingerprint|initial_save_fingerprint|coverage_fingerprint"

    private struct CommandResult {
        let status: Int32
        let stdout: String
        let stderr: String
    }

    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw SmokeError.message("usage: route-shard-worker-result-smoke WORKER_RESULT_TOOL")
        }
        let tool = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-route-shard-worker-result-smoke-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        try testLiveWriteAndValidation(tool: tool, root: root)
        try testFixtureAdmission(tool: tool, root: root)
        try testMalformedAndPartialInputs(tool: tool, root: root)
        try testDivergentAndTerminalEvidence(tool: tool, root: root)
        try testDuplicateIDsAcrossWorkers(tool: tool, root: root)

        print(
            "SM64 Modern route-shard worker-result smoke passed "
                + "isolated_rows=1 deterministic_schema=1 fingerprints=1 "
                + "malformed_rejected=1 partial_rejected=1 divergent_rejected=1 "
                + "fixture_gate=1 duplicate_ids_rejected=1"
        )
    }

    private static func testLiveWriteAndValidation(tool: URL, root: URL) throws {
        let output = root.appendingPathComponent("live.result")
        let result = try run(tool, arguments: writeArguments(output: output, id: "0x0000000000000001"))
        try require(result.status == 0, "live result write failed: \(result.stderr)")
        let text = try read(output)
        let lines = text.split(whereSeparator: { $0.isNewline }).map(String.init)
        try require(lines.count == 3, "live result did not contain exactly one row")
        try require(lines[0] == header && lines[1] == schema, "worker-result header/schema drifted")
        try require(lines[2].split(separator: "|", omittingEmptySubsequences: false).count == 14, "worker-result field count drifted")

        let validation = try run(tool, arguments: ["validate", "--require-live", "--result", output.path])
        try require(validation.status == 0, "live result validation failed: \(validation.stderr)")
        try require(validation.stdout.contains("live_rows=1 fixture_rows=0"), "live validation summary omitted row classification")
    }

    private static func testFixtureAdmission(tool: URL, root: URL) throws {
        let output = root.appendingPathComponent("fixture.result")
        let result = try run(
            tool,
            arguments: writeArguments(
                output: output,
                id: "0x0000000000000002",
                fixtureOnly: true
            )
        )
        try require(result.status == 0, "fixture result write failed: \(result.stderr)")
        let validation = try run(tool, arguments: ["validate", "--result", output.path])
        try require(validation.status == 0, "fixture result schema validation failed: \(validation.stderr)")
        try require(validation.stdout.contains("live_rows=0 fixture_rows=1"), "fixture validation summary omitted row classification")
        try expectFailure(
            tool,
            arguments: ["validate", "--require-live", "--result", output.path],
            expected: "fixture_only evidence is not allowed for live validation",
            name: "fixture-live-gate"
        )
    }

    private static func testMalformedAndPartialInputs(tool: URL, root: URL) throws {
        let malformed = root.appendingPathComponent("malformed.result")
        try write("not-a-worker-result\n", to: malformed)
        try expectFailure(
            tool,
            arguments: ["validate", "--result", malformed.path],
            expected: "invalid worker-result header",
            name: "malformed-header"
        )

        let partial = root.appendingPathComponent("partial.result")
        try write(([header, schema].joined(separator: "\n") + "\n"), to: partial)
        try expectFailure(
            tool,
            arguments: ["validate", "--result", partial.path],
            expected: "worker result contains no rows",
            name: "partial-result"
        )

        let short = root.appendingPathComponent("short.result")
        try write(([header, schema, "0x0000000000000003|running|passed|1"].joined(separator: "\n") + "\n"), to: short)
        try expectFailure(
            tool,
            arguments: ["validate", "--result", short.path],
            expected: "expected fourteen pipe-delimited fields",
            name: "short-row"
        )

        let nonCanonicalCount = root.appendingPathComponent("noncanonical-count.result")
        try write(
            ([header, schema, resultLine(id: "0x0000000000000004", expected: "01")].joined(separator: "\n") + "\n"),
            to: nonCanonicalCount
        )
        try expectFailure(
            tool,
            arguments: ["validate", "--result", nonCanonicalCount.path],
            expected: "expected canonical decimal",
            name: "noncanonical-count"
        )
    }

    private static func testDivergentAndTerminalEvidence(tool: URL, root: URL) throws {
        let divergentOutput = root.appendingPathComponent("divergent-write.result")
        try expectFailure(
            tool,
            arguments: writeArguments(
                output: divergentOutput,
                id: "0x0000000000000005",
                expected: 4,
                actual: 3,
                matched: 3
            ),
            expected: "passed requires positive equal expected/actual/matched counts",
            name: "divergent-passed"
        )
        try require(!FileManager.default.fileExists(atPath: divergentOutput.path), "rejected write left a result file")

        let invalidMatched = root.appendingPathComponent("invalid-matched.result")
        try expectFailure(
            tool,
            arguments: writeArguments(
                output: invalidMatched,
                id: "0x0000000000000006",
                expected: 3,
                actual: 2,
                matched: 3,
                divergence: "record mismatch"
            ),
            expected: "matched_records cannot exceed",
            name: "invalid-matched"
        )

        let missingTerminalReason = root.appendingPathComponent("missing-terminal-reason.result")
        try expectFailure(
            tool,
            arguments: writeArguments(
                output: missingTerminalReason,
                id: "0x0000000000000007",
                to: "failed",
                expected: 0,
                actual: 0,
                matched: 0
            ),
            expected: "failed/blocked requires first_divergence",
            name: "missing-terminal-reason"
        )

        let failed = root.appendingPathComponent("failed.result")
        let validFailed = try run(
            tool,
            arguments: writeArguments(
                output: failed,
                id: "0x0000000000000008",
                to: "failed",
                expected: 4,
                actual: 3,
                matched: 3,
                divergence: "tick=17"
            )
        )
        try require(validFailed.status == 0, "valid failed result was rejected: \(validFailed.stderr)")
        let validation = try run(tool, arguments: ["validate", "--result", failed.path])
        try require(validation.status == 0, "valid failed result did not validate: \(validation.stderr)")
    }

    private static func testDuplicateIDsAcrossWorkers(tool: URL, root: URL) throws {
        let first = root.appendingPathComponent("worker-a.result")
        let second = root.appendingPathComponent("worker-b.result")
        for output in [first, second] {
            let result = try run(tool, arguments: writeArguments(output: output, id: "0x0000000000000009"))
            try require(result.status == 0, "duplicate worker setup failed: \(result.stderr)")
        }
        try expectFailure(
            tool,
            arguments: ["validate", "--result", first.path, "--result", second.path],
            expected: "appears in both",
            name: "duplicate-worker-id"
        )
    }

    private static func writeArguments(
        output: URL,
        id: String,
        from: String = "running",
        to: String = "passed",
        expected: UInt64 = 1,
        actual: UInt64 = 1,
        matched: UInt64 = 1,
        divergence: String = "",
        fixtureOnly: Bool = false
    ) -> [String] {
        [
            "write",
            "--output", output.path,
            "--shard-id", id,
            "--from-state", from,
            "--to-state", to,
            "--expected-records", String(expected),
            "--actual-records", String(actual),
            "--matched-records", String(matched),
            "--first-divergence", divergence,
            "--fixture-only", fixtureOnly ? "1" : "0",
            "--build-fingerprint", fingerprints[0],
            "--content-fingerprint", fingerprints[1],
            "--timebase-fingerprint", fingerprints[2],
            "--configuration-fingerprint", fingerprints[3],
            "--initial-save-fingerprint", fingerprints[4],
            "--coverage-fingerprint", fingerprints[5],
        ]
    }

    private static func resultLine(
        id: String,
        expected: String = "1",
        actual: String = "1",
        matched: String = "1"
    ) -> String {
        [
            id, "running", "passed", expected, actual, matched, "", "0",
        ]
            .appending(contentsOf: fingerprints)
            .joined(separator: "|")
    }

    private static func expectFailure(
        _ tool: URL,
        arguments: [String],
        expected: String,
        name: String
    ) throws {
        let result = try run(tool, arguments: arguments)
        try require(result.status != 0, "\(name) input was accepted")
        try require(result.stderr.contains(expected), "\(name) failure omitted '\(expected)': \(result.stderr)")
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
