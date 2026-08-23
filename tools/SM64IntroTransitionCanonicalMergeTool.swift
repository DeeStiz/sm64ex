import CryptoKit
import Foundation

/// Phase 85f33 promotes the independently admitted intro-transition evidence
/// into a fresh, phase-local cumulative report.  The admitted route used an
/// authored shard ID, so promotion is bound to the generated manifest row by
/// its exact source identity and keeps the generated canonical row ID.
@main
struct SM64IntroTransitionCanonicalMergeTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let proofHeader = "# sm64-modern-phase85h-evidence-v1"
    private static let proofSchema = "# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256..."

    private static let manifestRowCount = 7_420
    private static let priorPassedCount = 25
    private static let priorPlannedCount = 7_395
    private static let outputPassedCount = 26
    private static let outputPlannedCount = 7_394
    private static let expectedManifestHash = "23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715"
    private static let expectedPriorReportHash = "aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d"
    private static let expectedTargetReportHash = "6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2"
    private static let expectedOutputHash = "4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4"
    private static let admittedTargetID: UInt64 = 0x9a0f_7b4f_7ecf_6c41
    private static let authoredDomain = "level_script"
    private static let authoredIdentity = "levels/intro/script.c"
    private static let authoredSource = "levels/intro/script.c"
    private static let expectedArtifactCount = 16

    private enum MergeError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case unreadable(URL, Error)
        case invalidManifest(String)
        case manifestHashMismatch(String, String)
        case invalidReport(URL, Int, String)
        case reportHashMismatch(URL, String, String)
        case priorReportCounts(Int, Int)
        case priorTargetNotPlanned(UInt64)
        case duplicateTarget(URL, Int)
        case invalidTarget(URL, String)
        case invalidProof(URL, String)
        case fixtureEvidence(URL)
        case artifactMissing(URL)
        case artifactHashMismatch(URL, String, String)
        case duplicateArtifact(URL)
        case outputCollision(URL)
        case outputExists(URL)
        case outputHashMismatch(String, String)
        case outputInvalid(String)
        case unwritable(URL, Error)

        var description: String {
            switch self {
            case let .invalidArguments(message):
                return message
            case let .unreadable(url, error):
                return "cannot read \(url.path): \(error)"
            case let .invalidManifest(reason):
                return "invalid regenerated route manifest: \(reason)"
            case let .manifestHashMismatch(expected, actual):
                return "manifest SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .invalidReport(url, line, reason):
                return "invalid route report \(url.path) line \(line): \(reason)"
            case let .reportHashMismatch(url, expected, actual):
                return "report SHA-256 mismatch \(url.path): expected \(expected), got \(actual)"
            case let .priorReportCounts(passed, planned):
                return "prior report counts mismatch: passed=\(passed) planned=\(planned), expected passed=25 planned=7395"
            case let .priorTargetNotPlanned(id):
                return String(format: "canonical intro row 0x%016llx was not planned in the retained report", id)
            case let .duplicateTarget(url, line):
                return String(format: "duplicate target row in %@ line %d", url.path, line)
            case let .invalidTarget(url, reason):
                return "invalid admitted intro target \(url.path): \(reason)"
            case let .invalidProof(url, reason):
                return "invalid Phase85f32 proof \(url.path): \(reason)"
            case let .fixtureEvidence(url):
                return "fixture_only evidence is not allowed: \(url.path)"
            case let .artifactMissing(url):
                return "missing Phase85f32 proof artifact: \(url.path)"
            case let .artifactHashMismatch(url, expected, actual):
                return "Phase85f32 artifact SHA-256 mismatch \(url.path): expected \(expected), got \(actual)"
            case let .duplicateArtifact(url):
                return "duplicate Phase85f32 proof artifact: \(url.path)"
            case let .outputCollision(url):
                return "output path collides with an immutable input: \(url.path)"
            case let .outputExists(url):
                return "terminal rerun rejected; isolated output already exists: \(url.path)"
            case let .outputHashMismatch(expected, actual):
                return "deterministic output SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .outputInvalid(reason):
                return "generated output validation failed: \(reason)"
            case let .unwritable(url, error):
                return "cannot write \(url.path): \(error)"
            }
        }
    }

    private struct Options {
        let manifest: URL
        let priorReport: URL
        let targetReport: URL
        let targetProof: URL
        let output: URL
    }

    private struct ManifestRow {
        let id: UInt64
        let domain: String
        let identity: String
        let source: String
        let line: Int
    }

    private struct ReportRow {
        let id: UInt64
        let state: String
        let expected: UInt64
        let actual: UInt64
        let matched: UInt64
        let divergence: String?

        var encoded: String {
            [
                formatID(id), state, String(expected), String(actual), String(matched), divergence ?? "",
            ].joined(separator: "|")
        }
    }

    private struct Proof {
        let reportHash: String
        let artifactURLs: [URL]
        let artifactHashes: [String]
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-intro-transition-canonical-merge: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let manifestData = try readData(options.manifest)
        let manifestText = try decode(manifestData, from: options.manifest)
        let manifestHash = sha256(manifestData)
        guard manifestHash == expectedManifestHash else {
            throw MergeError.manifestHashMismatch(expectedManifestHash, manifestHash)
        }
        let manifestRows = try parseManifest(manifestText)
        guard let canonicalTarget = manifestRows.first(where: {
            $0.domain == authoredDomain && $0.identity == authoredIdentity && $0.source == authoredSource
        }) else {
            throw MergeError.invalidManifest("missing generated intro source row")
        }
        guard manifestRows.filter({
            $0.domain == authoredDomain && $0.identity == authoredIdentity && $0.source == authoredSource
        }).count == 1 else {
            throw MergeError.invalidManifest("duplicate generated intro source row")
        }

        let priorData = try readData(options.priorReport)
        let priorHash = sha256(priorData)
        guard priorHash == expectedPriorReportHash else {
            throw MergeError.reportHashMismatch(options.priorReport, expectedPriorReportHash, priorHash)
        }
        let priorRows = try parseReport(
            try decode(priorData, from: options.priorReport),
            from: options.priorReport,
            manifestIDs: Set(manifestRows.map(\.id))
        )
        let priorByID = Dictionary(uniqueKeysWithValues: priorRows.map { ($0.id, $0) })
        let priorPassed = priorRows.filter { $0.state == "passed" }.count
        let priorPlanned = priorRows.filter { $0.state == "planned" }.count
        guard priorPassed == priorPassedCount, priorPlanned == priorPlannedCount else {
            throw MergeError.priorReportCounts(priorPassed, priorPlanned)
        }
        guard let priorTarget = priorByID[canonicalTarget.id], priorTarget.state == "planned" else {
            throw MergeError.priorTargetNotPlanned(canonicalTarget.id)
        }
        try validatePristinePrior(priorRows, targetID: canonicalTarget.id)

        let targetData = try readData(options.targetReport)
        let targetRows = try parseTargetReport(
            try decode(targetData, from: options.targetReport),
            from: options.targetReport
        )
        let targetHash = sha256(targetData)
        guard targetHash == expectedTargetReportHash else {
            throw MergeError.reportHashMismatch(options.targetReport, expectedTargetReportHash, targetHash)
        }
        guard targetRows.count == 1, let target = targetRows.first else {
            throw MergeError.invalidTarget(options.targetReport, "expected exactly one admitted row")
        }
        guard target.id == admittedTargetID else {
            throw MergeError.invalidTarget(options.targetReport, "unexpected authored shard ID")
        }
        guard target.state == "passed", target.expected == 2, target.actual == 2,
              target.matched == 2, target.divergence == nil else {
            throw MergeError.invalidTarget(options.targetReport, "expected passed|2|2|2 with no divergence")
        }

        let proofData = try readData(options.targetProof)
        let proof = try parseProof(
            try decode(proofData, from: options.targetProof),
            from: options.targetProof,
            reportHash: targetHash
        )

        let inputKeys = [options.manifest, options.priorReport, options.targetReport, options.targetProof]
            .map(pathKey)
        let artifactKeys = proof.artifactURLs.map(pathKey)
        guard Set(inputKeys + artifactKeys).count == inputKeys.count + artifactKeys.count else {
            throw MergeError.invalidProof(options.targetProof, "input and proof artifact paths must be distinct")
        }
        let outputKey = pathKey(options.output)
        guard !((inputKeys + artifactKeys).contains(outputKey)) else {
            throw MergeError.outputCollision(options.output)
        }
        guard !FileManager.default.fileExists(atPath: options.output.path) else {
            throw MergeError.outputExists(options.output)
        }

        var merged = priorRows
        guard let targetIndex = merged.firstIndex(where: { $0.id == canonicalTarget.id }) else {
            throw MergeError.outputInvalid("generated intro row disappeared from prior report")
        }
        merged[targetIndex] = ReportRow(
            id: canonicalTarget.id,
            state: "passed",
            expected: target.expected,
            actual: target.actual,
            matched: target.matched,
            divergence: nil
        )
        merged.sort { $0.id < $1.id }
        let outputText = merged.map(\.encoded).joined(separator: "\n") + "\n"
        let outputData = Data(outputText.utf8)
        try validateOutput(merged, canonicalTargetID: canonicalTarget.id)
        let outputHash = sha256(outputData)
        guard outputHash == expectedOutputHash else {
            throw MergeError.outputHashMismatch(expectedOutputHash, outputHash)
        }
        try write(outputData, to: options.output)

        let proofHash = sha256(proofData)
        print(
            "SM64 Phase85f33 intro-transition canonical merge passed "
                + "manifest_rows=7420 prior_rows=7420 prior_passed=25 prior_planned=7395 "
                + "qualified_rows=26 planned=7394 terminal=26 "
                + String(format: "admitted_target=0x%016llx canonical_target=0x%016llx ", admittedTargetID, canonicalTarget.id)
                + "target_report_sha256=\(targetHash) target_proof_sha256=\(proofHash) "
                + "manifest_sha256=\(manifestHash) prior_report_sha256=\(priorHash) "
                + "output_sha256=\(outputHash) fixture_only=0 output=\(options.output.path)"
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-intro-transition-canonical-merge --manifest MANIFEST --prior-report REPORT --target-report REPORT --target-proof PROOF --output REPORT"
        guard arguments.count == 10, arguments.count.isMultiple(of: 2) else {
            throw MergeError.invalidArguments(usage)
        }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let key = arguments[index]
            let value = arguments[index + 1]
            guard key.hasPrefix("--"), values[key] == nil else {
                throw MergeError.invalidArguments(usage)
            }
            values[key] = value
            index += 2
        }
        let known: Set<String> = ["--manifest", "--prior-report", "--target-report", "--target-proof", "--output"]
        guard values.count == known.count, values.keys.allSatisfy(known.contains) else {
            throw MergeError.invalidArguments(usage)
        }
        func url(_ key: String) -> URL {
            URL(fileURLWithPath: values[key]!).standardizedFileURL
        }
        return Options(
            manifest: url("--manifest"),
            priorReport: url("--prior-report"),
            targetReport: url("--target-report"),
            targetProof: url("--target-proof"),
            output: url("--output")
        )
    }

    private static func parseManifest(_ text: String) throws -> [ManifestRow] {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count >= 2, lines[0] == manifestHeader, lines[1] == manifestSchema else {
            throw MergeError.invalidManifest("invalid schema header")
        }
        var rows: [ManifestRow] = []
        var seen: Set<UInt64> = []
        for (offset, line) in lines.dropFirst(2).enumerated() {
            let lineNumber = offset + 3
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 9 else {
                throw MergeError.invalidManifest("line \(lineNumber) expected nine fields")
            }
            guard let id = parseHex(fields[0]) else {
                throw MergeError.invalidManifest("line \(lineNumber) has invalid shard ID")
            }
            guard seen.insert(id).inserted else {
                throw MergeError.invalidManifest(String(format: "line %d duplicates shard ID 0x%016llx", lineNumber, id))
            }
            guard fields[7] == "planned" else {
                throw MergeError.invalidManifest("line \(lineNumber) is not planned")
            }
            guard !fields[6].isEmpty else {
                throw MergeError.invalidManifest("line \(lineNumber) has no expected domains")
            }
            rows.append(ManifestRow(id: id, domain: fields[1], identity: fields[2], source: fields[3], line: lineNumber))
        }
        guard rows.count == manifestRowCount else {
            throw MergeError.invalidManifest("expected 7420 rows, got \(rows.count)")
        }
        return rows
    }

    private static func parseReport(
        _ text: String,
        from url: URL,
        manifestIDs: Set<UInt64>
    ) throws -> [ReportRow] {
        var rows: [ReportRow] = []
        var seen: Set<UInt64> = []
        for (offset, line) in text.split(whereSeparator: { $0.isNewline }).enumerated() {
            let lineNumber = offset + 1
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 6 else {
                throw MergeError.invalidReport(url, lineNumber, "expected six fields")
            }
            guard let id = parseHex(fields[0]), manifestIDs.contains(id) else {
                throw MergeError.invalidReport(url, lineNumber, "unknown shard ID")
            }
            guard seen.insert(id).inserted else {
                throw MergeError.invalidReport(url, lineNumber, "duplicate shard ID")
            }
            guard fields[1] == "planned" || fields[1] == "passed" else {
                throw MergeError.invalidReport(url, lineNumber, "unknown state")
            }
            guard let expected = UInt64(fields[2]), let actual = UInt64(fields[3]), let matched = UInt64(fields[4]) else {
                throw MergeError.invalidReport(url, lineNumber, "invalid evidence count")
            }
            rows.append(ReportRow(
                id: id,
                state: fields[1],
                expected: expected,
                actual: actual,
                matched: matched,
                divergence: fields[5].isEmpty ? nil : fields[5]
            ))
        }
        guard rows.count == manifestRowCount else {
            throw MergeError.invalidReport(url, 1, "expected 7420 rows, got \(rows.count)")
        }
        return rows
    }

    private static func parseTargetReport(_ text: String, from url: URL) throws -> [ReportRow] {
        var rows: [ReportRow] = []
        var seen: Set<UInt64> = []
        for (offset, line) in text.split(whereSeparator: { $0.isNewline }).enumerated() {
            let lineNumber = offset + 1
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 6 else {
                throw MergeError.invalidTarget(url, "line \(lineNumber) expected six fields")
            }
            guard let id = parseHex(fields[0]) else {
                throw MergeError.invalidTarget(url, "line \(lineNumber) has invalid shard ID")
            }
            guard seen.insert(id).inserted else {
                throw MergeError.duplicateTarget(url, lineNumber)
            }
            guard let expected = UInt64(fields[2]), let actual = UInt64(fields[3]), let matched = UInt64(fields[4]) else {
                throw MergeError.invalidTarget(url, "line \(lineNumber) has invalid evidence count")
            }
            rows.append(ReportRow(
                id: id,
                state: fields[1],
                expected: expected,
                actual: actual,
                matched: matched,
                divergence: fields[5].isEmpty ? nil : fields[5]
            ))
        }
        return rows
    }

    private static func validatePristinePrior(_ rows: [ReportRow], targetID: UInt64) throws {
        for row in rows {
            if row.state == "planned" {
                guard row.expected == 0, row.actual == 0, row.matched == 0, row.divergence == nil else {
                    throw MergeError.outputInvalid(String(format: "planned row 0x%016llx has terminal evidence", row.id))
                }
            } else {
                guard row.id != targetID else {
                    throw MergeError.priorTargetNotPlanned(targetID)
                }
                guard row.expected > 0, row.actual == row.expected, row.matched == row.expected, row.divergence == nil else {
                    throw MergeError.outputInvalid(String(format: "passed row 0x%016llx has incomplete evidence", row.id))
                }
            }
        }
    }

    private static func parseProof(_ text: String, from url: URL, reportHash: String) throws -> Proof {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count == 3, lines[0] == proofHeader, lines[1] == proofSchema else {
            throw MergeError.invalidProof(url, "invalid header or row count")
        }
        let fields = lines[2].split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 8 else {
            throw MergeError.invalidProof(url, "expected target and artifact fields")
        }
        guard parseHex(fields[0]) == admittedTargetID,
              fields[1] == authoredDomain,
              fields[2] == authoredIdentity else {
            throw MergeError.invalidProof(url, "authored target identity does not match Phase85f32")
        }
        guard fields[3] == "0" else {
            throw MergeError.fixtureEvidence(url)
        }
        let declaredReportHash = fields[4].lowercased()
        guard declaredReportHash == reportHash else {
            throw MergeError.invalidProof(url, "proof report SHA-256 does not match the admitted report")
        }
        guard let artifactCount = Int(fields[5]), artifactCount == expectedArtifactCount,
              fields.count == 6 + artifactCount * 2 else {
            throw MergeError.invalidProof(url, "expected exactly 16 artifact path/hash pairs")
        }

        var artifactURLs: [URL] = []
        var artifactHashes: [String] = []
        var seen: Set<String> = []
        for index in 0..<artifactCount {
            let path = URL(fileURLWithPath: fields[6 + index * 2]).standardizedFileURL
            let expectedHash = fields[7 + index * 2].lowercased()
            guard expectedHash.count == 64, isHex(expectedHash) else {
                throw MergeError.invalidProof(url, "artifact \(index) has invalid SHA-256")
            }
            guard !path.path.contains(".fixture_only") else {
                throw MergeError.fixtureEvidence(path)
            }
            guard FileManager.default.fileExists(atPath: path.path) else {
                throw MergeError.artifactMissing(path)
            }
            let key = pathKey(path)
            guard seen.insert(key).inserted else {
                throw MergeError.duplicateArtifact(path)
            }
            let actualHash = try sha256(path)
            guard actualHash == expectedHash else {
                throw MergeError.artifactHashMismatch(path, expectedHash, actualHash)
            }
            artifactURLs.append(path)
            artifactHashes.append(expectedHash)
        }
        return Proof(reportHash: declaredReportHash, artifactURLs: artifactURLs, artifactHashes: artifactHashes)
    }

    private static func validateOutput(_ rows: [ReportRow], canonicalTargetID: UInt64) throws {
        guard rows.count == manifestRowCount else {
            throw MergeError.outputInvalid("expected 7420 rows, got \(rows.count)")
        }
        let passed = rows.filter { $0.state == "passed" }
        let planned = rows.filter { $0.state == "planned" }
        guard passed.count == outputPassedCount, planned.count == outputPlannedCount else {
            throw MergeError.outputInvalid("expected passed=26 planned=7394")
        }
        guard let target = rows.first(where: { $0.id == canonicalTargetID }), target.state == "passed",
              target.expected == 2, target.actual == 2, target.matched == 2, target.divergence == nil else {
            throw MergeError.outputInvalid("canonical intro row was not promoted with 2 matched records")
        }
        try validatePristinePrior(planned + passed.filter { $0.id != canonicalTargetID }, targetID: canonicalTargetID)
    }

    private static func readData(_ url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url, options: .mappedIfSafe)
        } catch {
            throw MergeError.unreadable(url, error)
        }
    }

    private static func decode(_ data: Data, from url: URL) throws -> String {
        guard let text = String(data: data, encoding: .utf8) else {
            throw MergeError.unreadable(url, NSError(domain: "SM64IntroTransitionCanonicalMerge", code: 1, userInfo: [NSLocalizedDescriptionKey: "not UTF-8"]))
        }
        return text
    }

    private static func write(_ data: Data, to url: URL) throws {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            throw MergeError.unwritable(url, error)
        }
    }

    private static func sha256(_ url: URL) throws -> String {
        sha256(try readData(url))
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func parseHex(_ value: String) -> UInt64? {
        guard value.hasPrefix("0x") else { return nil }
        return UInt64(value.dropFirst(2), radix: 16)
    }

    private static func isHex(_ value: String) -> Bool {
        value.allSatisfy(\.isHexDigit)
    }

    private static func pathKey(_ url: URL) -> String {
        url.resolvingSymlinksInPath().standardizedFileURL.path
    }

    private static func formatID(_ id: UInt64) -> String {
        String(format: "0x%016llx", id)
    }
}
