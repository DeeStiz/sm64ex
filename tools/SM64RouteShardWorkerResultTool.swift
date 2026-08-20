import Foundation

/// Writes and validates one isolated worker-result file.
///
/// This tool only serializes evidence supplied by its caller. It does not run
/// the engine, create traces, or promote a route shard; live/fixture truth is
/// carried explicitly by `fixture_only` and is enforced by the caller and the
/// merge gate.
@main
struct SM64RouteShardWorkerResultTool {
    private static let resultHeader = "# sm64-modern-route-shard-worker-result-v1"
    private static let resultSchema = "# shard_id|from_state|to_state|expected_records|actual_records|matched_records|first_divergence|fixture_only|build_fingerprint|content_fingerprint|timebase_fingerprint|configuration_fingerprint|initial_save_fingerprint|coverage_fingerprint"

    private enum State: String {
        case planned
        case running
        case passed
        case failed
        case blocked

        var isTerminal: Bool {
            switch self {
            case .planned, .running: return false
            case .passed, .failed, .blocked: return true
            }
        }
    }

    private struct WorkerResult {
        let id: UInt64
        let fromState: State
        let toState: State
        let expectedRecords: UInt64
        let actualRecords: UInt64
        let matchedRecords: UInt64
        let firstDivergence: String?
        let fixtureOnly: Bool
        let buildFingerprint: UInt64
        let contentFingerprint: UInt64
        let timebaseFingerprint: UInt64
        let configurationFingerprint: UInt64
        let initialSaveFingerprint: UInt64
        let coverageFingerprint: UInt64

        var encoded: String {
            [
                formatHex(id),
                fromState.rawValue,
                toState.rawValue,
                String(expectedRecords),
                String(actualRecords),
                String(matchedRecords),
                firstDivergence ?? "",
                fixtureOnly ? "1" : "0",
                formatHex(buildFingerprint),
                formatHex(contentFingerprint),
                formatHex(timebaseFingerprint),
                formatHex(configurationFingerprint),
                formatHex(initialSaveFingerprint),
                formatHex(coverageFingerprint),
            ].joined(separator: "|")
        }
    }

    private struct ParsedFile {
        let url: URL
        let rows: [WorkerResult]
    }

    private enum ToolError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case unreadable(URL, Error)
        case unwritable(URL, Error)
        case malformed(URL, line: Int, reason: String)
        case duplicateID(UInt64, URL, line: Int)
        case fixtureOnly(UInt64, URL, line: Int)
        case invalidTerminalEvidence(UInt64, URL, line: Int, reason: String)
        case duplicateAcrossFiles(UInt64, URL, URL)

        var description: String {
            switch self {
            case let .invalidArguments(message):
                return message
            case let .unreadable(url, error):
                return "cannot read \(url.path): \(error)"
            case let .unwritable(url, error):
                return "cannot write \(url.path): \(error)"
            case let .malformed(url, line, reason):
                return "malformed worker result \(url.path) line \(line): \(reason)"
            case let .duplicateID(id, url, line):
                return String(
                    format: "duplicate worker-result shard ID 0x%016llx in %@ line %d",
                    id,
                    url.path,
                    line
                )
            case let .fixtureOnly(id, url, line):
                return String(
                    format: "fixture_only evidence is not allowed for live validation (shard 0x%016llx in %@ line %d)",
                    id,
                    url.path,
                    line
                )
            case let .invalidTerminalEvidence(id, url, line, reason):
                return String(
                    format: "invalid terminal evidence for shard 0x%016llx in %@ line %d: %@",
                    id,
                    url.path,
                    line,
                    reason
                )
            case let .duplicateAcrossFiles(id, first, second):
                return String(
                    format: "worker-result shard ID 0x%016llx appears in both %@ and %@",
                    id,
                    first.path,
                    second.path
                )
            }
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-route-shard-worker-result: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        guard let command = arguments.first else {
            throw ToolError.invalidArguments(usage)
        }
        switch command {
        case "write":
            try write(arguments: Array(arguments.dropFirst()))
        case "validate":
            try validate(arguments: Array(arguments.dropFirst()))
        default:
            throw ToolError.invalidArguments(usage)
        }
    }

    private static func write(arguments: [String]) throws {
        let values = try parsePairs(arguments, usage: writeUsage)
        let allowed = Set([
            "--output",
            "--shard-id",
            "--from-state",
            "--to-state",
            "--expected-records",
            "--actual-records",
            "--matched-records",
            "--first-divergence",
            "--fixture-only",
            "--build-fingerprint",
            "--content-fingerprint",
            "--timebase-fingerprint",
            "--configuration-fingerprint",
            "--initial-save-fingerprint",
            "--coverage-fingerprint",
        ])
        guard values.keys.allSatisfy({ allowed.contains($0) }) else {
            let unknown = values.keys.first(where: { !allowed.contains($0) }) ?? "unknown"
            throw ToolError.invalidArguments("unknown option \(unknown)\n\(writeUsage)")
        }

        let output = try required(values, "--output")
        let row = try makeRow(values: values, source: URL(fileURLWithPath: output).standardizedFileURL, line: 3)
        try validate(row: row, source: URL(fileURLWithPath: output).standardizedFileURL, line: 3, requireLive: false)

        let url = URL(fileURLWithPath: output).standardizedFileURL
        let text = ([resultHeader, resultSchema, row.encoded]).joined(separator: "\n") + "\n"
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(text.utf8).write(to: url, options: .atomic)
        } catch {
            throw ToolError.unwritable(url, error)
        }
        print(
            "SM64 route-shard worker result written "
                + "shard_id=\(formatHex(row.id)) "
                + "status=\(row.toState.rawValue) "
                + "fixture_only=\(row.fixtureOnly ? 1 : 0) "
                + "output=\(url.path)"
        )
    }

    private static func validate(arguments: [String]) throws {
        var resultPaths: [String] = []
        var requireLive = false
        var index = 0
        while index < arguments.count {
            let option = arguments[index]
            if option == "--require-live" {
                guard !requireLive else {
                    throw ToolError.invalidArguments("duplicate --require-live\n\(validateUsage)")
                }
                requireLive = true
                index += 1
                continue
            }
            guard option == "--result", index + 1 < arguments.count else {
                throw ToolError.invalidArguments("expected --result PATH or --require-live\n\(validateUsage)")
            }
            resultPaths.append(arguments[index + 1])
            index += 2
        }
        guard !resultPaths.isEmpty else {
            throw ToolError.invalidArguments(validateUsage)
        }

        var files: [ParsedFile] = []
        var seen: [UInt64: URL] = [:]
        for path in resultPaths {
            let url = URL(fileURLWithPath: path).standardizedFileURL
            let parsed = try parseFile(url)
            for row in parsed.rows {
                try validate(row: row, source: url, line: 3, requireLive: requireLive)
                if let first = seen[row.id] {
                    throw ToolError.duplicateAcrossFiles(row.id, first, url)
                }
                seen[row.id] = url
            }
            files.append(parsed)
        }

        let fixtureCount = files.flatMap(\.rows).filter(\.fixtureOnly).count
        let liveCount = seen.count - fixtureCount
        print(
            "SM64 route-shard worker result validation passed "
                + "files=\(files.count) rows=\(seen.count) "
                + "live_rows=\(liveCount) fixture_rows=\(fixtureCount) "
                + "require_live=\(requireLive ? 1 : 0)"
        )
    }

    private static func parseFile(_ url: URL) throws -> ParsedFile {
        let text: String
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ToolError.unreadable(url, error)
        }
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count >= 2, lines[0] == resultHeader, lines[1] == resultSchema else {
            throw ToolError.malformed(url, line: 1, reason: "invalid worker-result header")
        }

        var rows: [WorkerResult] = []
        var localIDs: Set<UInt64> = []
        for (offset, line) in lines.dropFirst(2).enumerated() {
            let lineNumber = offset + 3
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 14 else {
                throw ToolError.malformed(
                    url,
                    line: lineNumber,
                    reason: "expected fourteen pipe-delimited fields"
                )
            }
            let row = try makeRow(fields: fields, source: url, line: lineNumber)
            guard localIDs.insert(row.id).inserted else {
                throw ToolError.duplicateID(row.id, url, line: lineNumber)
            }
            try validate(row: row, source: url, line: lineNumber, requireLive: false)
            rows.append(row)
        }
        guard !rows.isEmpty else {
            throw ToolError.malformed(url, line: 3, reason: "worker result contains no rows")
        }
        return ParsedFile(url: url, rows: rows)
    }

    private static func makeRow(
        values: [String: String],
        source: URL,
        line: Int
    ) throws -> WorkerResult {
        let fields = try [
            required(values, "--shard-id"),
            required(values, "--from-state"),
            required(values, "--to-state"),
            required(values, "--expected-records"),
            required(values, "--actual-records"),
            required(values, "--matched-records"),
            required(values, "--first-divergence"),
            required(values, "--fixture-only"),
            required(values, "--build-fingerprint"),
            required(values, "--content-fingerprint"),
            required(values, "--timebase-fingerprint"),
            required(values, "--configuration-fingerprint"),
            required(values, "--initial-save-fingerprint"),
            required(values, "--coverage-fingerprint"),
        ]
        return try makeRow(fields: fields, source: source, line: line)
    }

    private static func makeRow(
        fields: [String],
        source: URL,
        line: Int
    ) throws -> WorkerResult {
        guard fields.count == 14 else {
            throw ToolError.malformed(source, line: line, reason: "expected fourteen worker-result fields")
        }
        let id = try parseHex(fields[0], name: "shard_id", source: source, line: line)
        guard let fromState = State(rawValue: fields[1]),
              let toState = State(rawValue: fields[2]) else {
            throw ToolError.malformed(source, line: line, reason: "unknown execution state")
        }
        let expected = try parseCount(fields[3], name: "expected_records", source: source, line: line)
        let actual = try parseCount(fields[4], name: "actual_records", source: source, line: line)
        let matched = try parseCount(fields[5], name: "matched_records", source: source, line: line)
        let divergence: String?
        if fields[6].isEmpty {
            divergence = nil
        } else {
            guard !fields[6].contains("|"), !fields[6].contains("\n"), !fields[6].contains("\r") else {
                throw ToolError.malformed(source, line: line, reason: "first_divergence contains a delimiter or newline")
            }
            divergence = fields[6]
        }
        guard fields[7] == "0" || fields[7] == "1" else {
            throw ToolError.malformed(source, line: line, reason: "fixture_only must be 0 or 1")
        }
        let fingerprints = try (8..<14).map { index in
            try parseHex(fields[index], name: "fingerprint", source: source, line: line)
        }
        return WorkerResult(
            id: id,
            fromState: fromState,
            toState: toState,
            expectedRecords: expected,
            actualRecords: actual,
            matchedRecords: matched,
            firstDivergence: divergence,
            fixtureOnly: fields[7] == "1",
            buildFingerprint: fingerprints[0],
            contentFingerprint: fingerprints[1],
            timebaseFingerprint: fingerprints[2],
            configurationFingerprint: fingerprints[3],
            initialSaveFingerprint: fingerprints[4],
            coverageFingerprint: fingerprints[5]
        )
    }

    private static func validate(
        row: WorkerResult,
        source: URL,
        line: Int,
        requireLive: Bool
    ) throws {
        guard row.fromState == .running, row.toState.isTerminal else {
            throw ToolError.invalidTerminalEvidence(
                row.id,
                source,
                line: line,
                reason: "from_state must be running and to_state must be terminal"
            )
        }
        if requireLive && row.fixtureOnly {
            throw ToolError.fixtureOnly(row.id, source, line: line)
        }
        guard row.matchedRecords <= row.expectedRecords,
              row.matchedRecords <= row.actualRecords else {
            throw ToolError.invalidTerminalEvidence(
                row.id,
                source,
                line: line,
                reason: "matched_records cannot exceed expected_records or actual_records"
            )
        }
        switch row.toState {
        case .passed:
            guard row.expectedRecords > 0,
                  row.actualRecords == row.expectedRecords,
                  row.matchedRecords == row.expectedRecords,
                  row.firstDivergence == nil else {
                throw ToolError.invalidTerminalEvidence(
                    row.id,
                    source,
                    line: line,
                    reason: "passed requires positive equal expected/actual/matched counts and no first divergence"
                )
            }
        case .failed, .blocked:
            guard row.firstDivergence != nil else {
                throw ToolError.invalidTerminalEvidence(
                    row.id,
                    source,
                    line: line,
                    reason: "failed/blocked requires first_divergence"
                )
            }
        case .planned, .running:
            throw ToolError.invalidTerminalEvidence(
                row.id,
                source,
                line: line,
                reason: "non-terminal to_state is not persistable"
            )
        }
    }

    private static func parsePairs(_ arguments: [String], usage: String) throws -> [String: String] {
        guard !arguments.isEmpty, arguments.count.isMultiple(of: 2) else {
            throw ToolError.invalidArguments(usage)
        }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let option = arguments[index]
            guard option.hasPrefix("--") else {
                throw ToolError.invalidArguments(usage)
            }
            guard values[option] == nil else {
                throw ToolError.invalidArguments("duplicate option \(option)\n\(usage)")
            }
            values[option] = arguments[index + 1]
            index += 2
        }
        return values
    }

    private static func required(_ values: [String: String], _ key: String) throws -> String {
        guard let value = values[key] else {
            throw ToolError.invalidArguments("missing argument \(key)\n\(writeUsage)")
        }
        return value
    }

    private static func parseHex(
        _ value: String,
        name: String,
        source: URL,
        line: Int
    ) throws -> UInt64 {
        let digits = value.dropFirst(2)
        guard value.hasPrefix("0x"), digits.count == 16,
              digits.allSatisfy(isHexDigit),
              let parsed = UInt64(digits, radix: 16) else {
            throw ToolError.malformed(source, line: line, reason: "invalid (name) (value); expected 0x plus 16 hex digits")
        }
        return parsed
    }

    private static func parseCount(
        _ value: String,
        name: String,
        source: URL,
        line: Int
    ) throws -> UInt64 {
        guard !value.isEmpty,
              value.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }),
              let parsed = UInt64(value),
              value == String(parsed) else {
            throw ToolError.malformed(source, line: line, reason: "invalid (name) (value); expected canonical decimal")
        }
        return parsed
    }

    private static func isHexDigit(_ character: Character) -> Bool {
        switch character {
        case "0"..."9", "a"..."f", "A"..."F": return true
        default: return false
        }
    }

    private static func formatHex(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }

    private static let writeUsage = "usage: sm64-route-shard-worker-result write --output PATH --shard-id 0xID --from-state running --to-state passed|failed|blocked --expected-records N --actual-records N --matched-records N --first-divergence TEXT --fixture-only 0|1 --build-fingerprint 0xFINGERPRINT --content-fingerprint 0xFINGERPRINT --timebase-fingerprint 0xFINGERPRINT --configuration-fingerprint 0xFINGERPRINT --initial-save-fingerprint 0xFINGERPRINT --coverage-fingerprint 0xFINGERPRINT"
    private static let validateUsage = "usage: sm64-route-shard-worker-result validate [--require-live] --result RESULT [--result RESULT ...]"
    private static let usage = writeUsage + "\n" + validateUsage
}
