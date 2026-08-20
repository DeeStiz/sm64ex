import Foundation

/// Serial coordinator for per-worker route-shard evidence.
///
/// Workers must write isolated result files using the worker-result schema
/// below. This process is the only writer of the consolidated report: it
/// reads every result serially, validates the complete manifest, and writes
/// the terminal rows in canonical manifest order. Fixture evidence is never
/// eligible for this live-qualification merge.
@main
struct SM64RouteShardMergeTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let resultHeader = "# sm64-modern-route-shard-worker-result-v1"
    private static let resultSchema = "# shard_id|from_state|to_state|expected_records|actual_records|matched_records|first_divergence|fixture_only|build_fingerprint|content_fingerprint|timebase_fingerprint|configuration_fingerprint|initial_save_fingerprint|coverage_fingerprint"
    private static let fnvOffset: UInt64 = 1_469_598_103_934_665_603
    private static let fnvPrime: UInt64 = 1_099_511_628_211

    private enum MergeError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case unreadable(URL, Error)
        case unwritable(URL, Error)
        case invalidManifest(String)
        case invalidResult(URL, line: Int, reason: String)
        case duplicateResult(UInt64, URL, line: Int)
        case unknownResult(UInt64, URL, line: Int)
        case missingRows([UInt64])
        case invalidTransition(UInt64, from: String, to: String)
        case invalidTerminalEvidence(UInt64, String)
        case fixtureOnly(UInt64)
        case inconsistentFingerprint(String, UInt64, UInt64)
        case outputCollision(URL)

        var description: String {
            switch self {
            case let .invalidArguments(message):
                return message
            case let .unreadable(url, error):
                return "cannot read \(url.path): \(error)"
            case let .unwritable(url, error):
                return "cannot write \(url.path): \(error)"
            case let .invalidManifest(reason):
                return "invalid route-shard manifest: \(reason)"
            case let .invalidResult(url, line, reason):
                return "invalid worker result \(url.path) line \(line): \(reason)"
            case let .duplicateResult(id, url, line):
                return String(
                    format: "duplicate result shard ID 0x%016llx in %@ line %d",
                    id,
                    url.path,
                    line
                )
            case let .unknownResult(id, url, line):
                return String(
                    format: "unknown result shard ID 0x%016llx in %@ line %d",
                    id,
                    url.path,
                    line
                )
            case let .missingRows(ids):
                let values = ids.map(formatID).joined(separator: ",")
                return "missing result rows: [\(values)]"
            case let .invalidTransition(id, from, to):
                return String(
                    format: "invalid transition for shard 0x%016llx: %@ -> %@",
                    id,
                    from,
                    to
                )
            case let .invalidTerminalEvidence(id, reason):
                return String(
                    format: "invalid terminal evidence for shard 0x%016llx: %@",
                    id,
                    reason
                )
            case let .fixtureOnly(id):
                return String(
                    format: "fixture_only evidence is not allowed for live qualification (shard 0x%016llx)",
                    id
                )
            case let .inconsistentFingerprint(name, expected, actual):
                return String(
                    format: "inconsistent %@ fingerprint: expected 0x%016llx, got 0x%016llx",
                    name,
                    expected,
                    actual
                )
            case let .outputCollision(url):
                return "output paths collide: \(url.path)"
            }
        }
    }

    private struct Options {
        let manifest: URL
        let results: [URL]
        let output: URL
        let evidenceOutput: URL?
    }

    private struct ManifestRow {
        let shard: SM64RouteShard
        let line: Int
    }

    private struct WorkerResult {
        let id: UInt64
        let fromState: SM64RouteShardExecutionState
        let toState: SM64RouteShardExecutionState
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
        let source: URL
        let line: Int

        var legacyEncoded: String {
            [
                formatID(id),
                toState.rawValue,
                String(expectedRecords),
                String(actualRecords),
                String(matchedRecords),
                firstDivergence ?? "",
            ].joined(separator: "|")
        }

        var evidenceEncoded: String {
            [
                formatID(id),
                fromState.rawValue,
                toState.rawValue,
                String(expectedRecords),
                String(actualRecords),
                String(matchedRecords),
                firstDivergence ?? "",
                fixtureOnly ? "1" : "0",
                formatFingerprint(buildFingerprint),
                formatFingerprint(contentFingerprint),
                formatFingerprint(timebaseFingerprint),
                formatFingerprint(configurationFingerprint),
                formatFingerprint(initialSaveFingerprint),
                formatFingerprint(coverageFingerprint),
            ].joined(separator: "|")
        }
    }

    private struct SharedFingerprints {
        let build: UInt64
        let content: UInt64
        let timebase: UInt64
        let configuration: UInt64
        let coverage: UInt64
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            let message = "sm64-route-shard-merge: \(error)\n"
            FileHandle.standardError.write(Data(message.utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let manifestText = try read(options.manifest)
        let manifestRows = try parseManifest(manifestText)
        let manifestIDs = Set(manifestRows.map { $0.shard.id })
        var resultsByID: [UInt64: WorkerResult] = [:]
        var sharedFingerprints: SharedFingerprints?

        for resultURL in options.results {
            let resultText = try read(resultURL)
            let results = try parseResults(resultText, from: resultURL)
            for result in results {
                guard manifestIDs.contains(result.id) else {
                    throw MergeError.unknownResult(result.id, result.source, line: result.line)
                }
                guard resultsByID[result.id] == nil else {
                    throw MergeError.duplicateResult(result.id, result.source, line: result.line)
                }
                if let existing = sharedFingerprints {
                    try validateSharedFingerprints(existing, result: result)
                } else {
                    sharedFingerprints = SharedFingerprints(
                        build: result.buildFingerprint,
                        content: result.contentFingerprint,
                        timebase: result.timebaseFingerprint,
                        configuration: result.configurationFingerprint,
                        coverage: result.coverageFingerprint
                    )
                }
                resultsByID[result.id] = result
            }
        }

        let missing = manifestRows
            .map { $0.shard.id }
            .filter { resultsByID[$0] == nil }
        guard missing.isEmpty else {
            throw MergeError.missingRows(missing)
        }

        let orderedResults = manifestRows.compactMap { resultsByID[$0.shard.id] }
        let legacyReport = orderedResults.map(\.legacyEncoded).joined(separator: "\n") + "\n"
        let evidenceReport = ([resultHeader, resultSchema] + orderedResults.map(\.evidenceEncoded))
            .joined(separator: "\n") + "\n"

        guard options.evidenceOutput != options.output else {
            throw MergeError.outputCollision(options.output)
        }
        try write(legacyReport, to: options.output)
        if let evidenceOutput = options.evidenceOutput {
            try write(evidenceReport, to: evidenceOutput)
        }

        let fingerprintSummary = sharedFingerprints.map { fingerprints in
            [
                "build=\(formatFingerprint(fingerprints.build))",
                "content=\(formatFingerprint(fingerprints.content))",
                "timebase=\(formatFingerprint(fingerprints.timebase))",
                "configuration=\(formatFingerprint(fingerprints.configuration))",
                "coverage=\(formatFingerprint(fingerprints.coverage))",
            ].joined(separator: ",")
        } ?? "none"
        let passed = orderedResults.filter { $0.toState == .passed }.count
        let failed = orderedResults.filter { $0.toState == .failed }.count
        let blocked = orderedResults.filter { $0.toState == .blocked }.count
        let manifestFingerprint = hash(
            manifestRows.map { $0.shard.encodedIdentity + "|" + $0.shard.notes }.joined(separator: "\n")
        )
        print(
            "SM64 route-shard merge passed "
                + "manifest_rows=\(manifestRows.count) "
                + "result_files=\(options.results.count) "
                + "terminal_rows=\(orderedResults.count) "
                + "passed=\(passed) failed=\(failed) blocked=\(blocked) "
                + "fixture_only=0 "
                + "manifest_fingerprint=\(formatFingerprint(manifestFingerprint)) "
                + "fingerprints=[\(fingerprintSummary)] "
                + "canonical_order=manifest "
                + "report=\(options.output.path)"
        )
        if let evidenceOutput = options.evidenceOutput {
            print("SM64 route-shard merge evidence=\(evidenceOutput.path)")
        }
    }

    private static func parse(arguments: [String]) throws -> Options {
        guard !arguments.isEmpty else {
            throw MergeError.invalidArguments(usage)
        }
        var manifest: String?
        var output: String?
        var evidenceOutput: String?
        var results: [String] = []
        var index = 0
        while index < arguments.count {
            let option = arguments[index]
            guard option.hasPrefix("--"), index + 1 < arguments.count else {
                throw MergeError.invalidArguments(usage)
            }
            let value = arguments[index + 1]
            switch option {
            case "--manifest":
                guard manifest == nil else {
                    throw MergeError.invalidArguments("duplicate --manifest\n\(usage)")
                }
                manifest = value
            case "--result":
                results.append(value)
            case "--output":
                guard output == nil else {
                    throw MergeError.invalidArguments("duplicate --output\n\(usage)")
                }
                output = value
            case "--evidence-output":
                guard evidenceOutput == nil else {
                    throw MergeError.invalidArguments("duplicate --evidence-output\n\(usage)")
                }
                evidenceOutput = value
            default:
                throw MergeError.invalidArguments("unknown option \(option)\n\(usage)")
            }
            index += 2
        }
        guard let manifest, let output, !results.isEmpty else {
            throw MergeError.invalidArguments(usage)
        }
        return Options(
            manifest: URL(fileURLWithPath: manifest).standardizedFileURL,
            results: results.map { URL(fileURLWithPath: $0).standardizedFileURL },
            output: URL(fileURLWithPath: output).standardizedFileURL,
            evidenceOutput: evidenceOutput.map { URL(fileURLWithPath: $0).standardizedFileURL }
        )
    }

    private static var usage: String {
        "usage: sm64-route-shard-merge --manifest MANIFEST --result RESULT [--result RESULT ...] --output REPORT [--evidence-output EVIDENCE]"
    }

    private static func read(_ url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw MergeError.unreadable(url, error)
        }
    }

    private static func write(_ text: String, to url: URL) throws {
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(text.utf8).write(to: url, options: .atomic)
        } catch {
            throw MergeError.unwritable(url, error)
        }
    }

    private static func parseManifest(_ text: String) throws -> [ManifestRow] {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count >= 2,
              lines[0] == manifestHeader,
              lines[1] == manifestSchema else {
            throw MergeError.invalidManifest("invalid header")
        }
        var rows: [ManifestRow] = []
        var seen: Set<UInt64> = []
        for (offset, line) in lines.dropFirst(2).enumerated() {
            let lineNumber = offset + 3
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            do {
                let shard = try SM64RouteShard(manifestLine: line, lineNumber: lineNumber)
                guard seen.insert(shard.id).inserted else {
                    throw MergeError.invalidManifest(
                        "duplicate shard ID \(formatID(shard.id)) at line \(lineNumber)"
                    )
                }
                rows.append(ManifestRow(shard: shard, line: lineNumber))
            } catch let error as MergeError {
                throw error
            } catch {
                throw MergeError.invalidManifest("line \(lineNumber): \(error)")
            }
        }
        guard !rows.isEmpty else {
            throw MergeError.invalidManifest("manifest has no rows")
        }
        return rows
    }

    private static func parseResults(_ text: String, from url: URL) throws -> [WorkerResult] {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count >= 3, lines[0] == resultHeader, lines[1] == resultSchema else {
            throw MergeError.invalidResult(url, line: 1, reason: "invalid worker-result header")
        }
        var parsed: [WorkerResult] = []
        var localIDs: Set<UInt64> = []
        for (offset, line) in lines.dropFirst(2).enumerated() {
            let lineNumber = offset + 3
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 14 else {
                throw MergeError.invalidResult(
                    url,
                    line: lineNumber,
                    reason: "expected fourteen pipe-delimited fields"
                )
            }
            let id = try parseID(fields[0], url: url, line: lineNumber)
            guard localIDs.insert(id).inserted else {
                throw MergeError.duplicateResult(id, url, line: lineNumber)
            }
            guard let fromState = SM64RouteShardExecutionState(rawValue: fields[1]),
                  let toState = SM64RouteShardExecutionState(rawValue: fields[2]) else {
                throw MergeError.invalidResult(url, line: lineNumber, reason: "unknown execution state")
            }
            guard fromState == .running, toState.isTerminal else {
                throw MergeError.invalidTransition(
                    id,
                    from: fields[1],
                    to: fields[2]
                )
            }
            let expected = try parseCount(fields[3], name: "expected_records", url: url, line: lineNumber)
            let actual = try parseCount(fields[4], name: "actual_records", url: url, line: lineNumber)
            let matched = try parseCount(fields[5], name: "matched_records", url: url, line: lineNumber)
            let divergence: String?
            if fields[6].isEmpty {
                divergence = nil
            } else {
                guard !fields[6].contains(where: { $0 == "\n" || $0 == "\r" }) else {
                    throw MergeError.invalidResult(url, line: lineNumber, reason: "first_divergence contains a newline")
                }
                divergence = fields[6]
            }
            guard fields[7] == "0" || fields[7] == "1" else {
                throw MergeError.invalidResult(url, line: lineNumber, reason: "fixture_only must be 0 or 1")
            }
            let fixtureOnly = fields[7] == "1"
            guard !fixtureOnly else {
                throw MergeError.fixtureOnly(id)
            }
            let build = try parseFingerprint(fields[8], name: "build", url: url, line: lineNumber)
            let content = try parseFingerprint(fields[9], name: "content", url: url, line: lineNumber)
            let timebase = try parseFingerprint(fields[10], name: "timebase", url: url, line: lineNumber)
            let configuration = try parseFingerprint(fields[11], name: "configuration", url: url, line: lineNumber)
            let initialSave = try parseFingerprint(fields[12], name: "initial_save", url: url, line: lineNumber)
            let coverage = try parseFingerprint(fields[13], name: "coverage", url: url, line: lineNumber)
            if toState == .passed {
                guard expected > 0,
                      actual == expected,
                      matched == expected,
                      divergence == nil else {
                    throw MergeError.invalidTerminalEvidence(
                        id,
                        "passed requires positive equal expected/actual/matched counts and no first divergence"
                    )
                }
            }
            parsed.append(
                WorkerResult(
                    id: id,
                    fromState: fromState,
                    toState: toState,
                    expectedRecords: expected,
                    actualRecords: actual,
                    matchedRecords: matched,
                    firstDivergence: divergence,
                    fixtureOnly: fixtureOnly,
                    buildFingerprint: build,
                    contentFingerprint: content,
                    timebaseFingerprint: timebase,
                    configurationFingerprint: configuration,
                    initialSaveFingerprint: initialSave,
                    coverageFingerprint: coverage,
                    source: url,
                    line: lineNumber
                )
            )
        }
        guard !parsed.isEmpty else {
            throw MergeError.invalidResult(url, line: 3, reason: "worker result contains no rows")
        }
        return parsed
    }

    private static func parseID(_ value: String, url: URL, line: Int) throws -> UInt64 {
        guard value.hasPrefix("0x"), value.dropFirst(2).count == 16,
              value.dropFirst(2).allSatisfy(isHexDigit),
              let parsed = UInt64(value.dropFirst(2), radix: 16) else {
            throw MergeError.invalidResult(url, line: line, reason: "invalid shard ID \(value)")
        }
        return parsed
    }

    private static func parseCount(
        _ value: String,
        name: String,
        url: URL,
        line: Int
    ) throws -> UInt64 {
        guard !value.isEmpty, value.allSatisfy(\.isNumber), let parsed = UInt64(value) else {
            throw MergeError.invalidResult(url, line: line, reason: "invalid \(name) count \(value)")
        }
        return parsed
    }

    private static func parseFingerprint(
        _ value: String,
        name: String,
        url: URL,
        line: Int
    ) throws -> UInt64 {
        guard value.hasPrefix("0x"), value.dropFirst(2).count == 16,
              value.dropFirst(2).allSatisfy(isHexDigit),
              let parsed = UInt64(value.dropFirst(2), radix: 16) else {
            throw MergeError.invalidResult(url, line: line, reason: "invalid \(name) fingerprint \(value)")
        }
        return parsed
    }

    private static func validateSharedFingerprints(
        _ shared: SharedFingerprints,
        result: WorkerResult
    ) throws {
        let values: [(String, UInt64, UInt64)] = [
            ("build", shared.build, result.buildFingerprint),
            ("content", shared.content, result.contentFingerprint),
            ("timebase", shared.timebase, result.timebaseFingerprint),
            ("configuration", shared.configuration, result.configurationFingerprint),
            ("coverage", shared.coverage, result.coverageFingerprint),
        ]
        for (name, expected, actual) in values where expected != actual {
            throw MergeError.inconsistentFingerprint(name, expected, actual)
        }
    }

    private static func isHexDigit(_ character: Character) -> Bool {
        switch character {
        case "0"..."9", "a"..."f", "A"..."F": return true
        default: return false
        }
    }

    private static func hash(_ value: String) -> UInt64 {
        value.utf8.reduce(fnvOffset) { partial, byte in
            (partial ^ UInt64(byte)) &* fnvPrime
        }
    }

    private static func formatID(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }

    private static func formatFingerprint(_ value: UInt64) -> String {
        formatID(value)
    }
}
