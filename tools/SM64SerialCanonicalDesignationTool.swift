import CryptoKit
import Foundation

/// Designates one already-qualified serial route report as a fresh local
/// retained artifact.  This tool never edits the prior retained report or
/// manifest: it writes a write-once backup and a new report under a fresh run
/// root after re-reading and validating every immutable input.
@main
struct SM64SerialCanonicalDesignationTool {
    private static let manifestHash = "23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715"
    private static let retainedReportHash = "aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d"
    private static let candidateReportHash = "4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4"
    private static let canonicalID = "0xca33981b30cb7815"
    private static let authoredPhaseLocalID = "0x9a0f7b4f7ecf6c41"
    private static let manifestCanonicalRow =
        "0xca33981b30cb7815|level_script|levels/intro/script.c|levels/intro/script.c|0xdaaafed747b604f9|0x0c89f4d300ff0986|global_state,script_events,transition|planned|deterministic route shard; execution remains an M33 gate"

    private struct Options {
        let candidateReport: URL
        let retainedReport: URL
        let manifest: URL
        let backupReport: URL
        let backupManifest: URL
        let hashSnapshot: URL
        let output: URL
    }

    private struct LedgerSummary {
        let ids: Set<UInt64>
        let rows: Int
        let passed: Int
        let planned: Int
        let canonicalFields: [String]
    }

    private enum DesignationError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case missingInput(URL)
        case unreadable(URL, Error)
        case duplicateInput(URL)
        case outputCollision(URL)
        case writeOnceViolation(URL)
        case manifestHashMismatch(String, String)
        case retainedReportHashMismatch(String, String)
        case candidateReportHashMismatch(String, String)
        case manifestInvalid(String)
        case identityValidation(URL, String)
        case countValidation(URL, String)
        case backupHashMismatch(URL, String, String)
        case outputHashMismatch(String, String)
        case sourceMutated(URL, String, String)
        case writeFailed(URL, Error)

        var description: String {
            switch self {
            case let .invalidArguments(usage):
                return usage
            case let .missingInput(url):
                return "required designation input is missing or empty: \(url.path)"
            case let .unreadable(url, error):
                return "cannot read \(url.path): \(error)"
            case let .duplicateInput(url):
                return "duplicate input path rejected: \(url.path)"
            case let .outputCollision(url):
                return "output path collides with an immutable input: \(url.path)"
            case let .writeOnceViolation(url):
                return "write-once rerun rejected; destination already exists: \(url.path)"
            case let .manifestHashMismatch(expected, actual):
                return "manifest SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .retainedReportHashMismatch(expected, actual):
                return "retained report SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .candidateReportHashMismatch(expected, actual):
                return "candidate report SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .manifestInvalid(reason):
                return "manifest identity validation failed: \(reason)"
            case let .identityValidation(url, reason):
                return "identity validation failed for \(url.path): \(reason)"
            case let .countValidation(url, reason):
                return "count validation failed for \(url.path): \(reason)"
            case let .backupHashMismatch(url, expected, actual):
                return "backup SHA-256 mismatch for \(url.path): expected \(expected), got \(actual)"
            case let .outputHashMismatch(expected, actual):
                return "designated report SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .sourceMutated(url, before, after):
                return "immutable input changed \(url.path): before \(before), after \(after)"
            case let .writeFailed(url, error):
                return "cannot write \(url.path): \(error)"
            }
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-serial-canonical-designation: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let inputData = try preflight(options)

        let retainedHash = sha256(inputData.retainedReport)
        let manifestHashActual = sha256(inputData.manifest)
        let candidateHash = sha256(inputData.candidateReport)
        let immutablePaths = [options.candidateReport, options.retainedReport, options.manifest]
        let beforeHashes = try Dictionary(uniqueKeysWithValues: immutablePaths.map { ($0.path, try sha256($0)) })

        try createFreshBackupDirectory(for: options)
        try writeOnce(data: inputData.retainedReport, to: options.backupReport)
        try writeOnce(data: inputData.manifest, to: options.backupManifest)

        let snapshot = makeHashSnapshot(
            candidate: options.candidateReport,
            candidateHash: candidateHash,
            retained: options.retainedReport,
            retainedHash: retainedHash,
            manifest: options.manifest,
            manifestHash: manifestHashActual
        )
        try writeOnce(data: Data(snapshot.utf8), to: options.hashSnapshot)
        try verifyHash(options.backupReport, expected: retainedReportHash)
        try verifyHash(options.backupManifest, expected: manifestHash)
        try verifySnapshot(snapshot, at: options.hashSnapshot)

        try writeOnce(data: inputData.candidateReport, to: options.output)
        let outputHash = try sha256(options.output)
        guard outputHash == candidateReportHash else {
            throw DesignationError.outputHashMismatch(candidateReportHash, outputHash)
        }
        let outputSummary = try validateLedger(
            options.output,
            expectedRows: 7_420,
            expectedPassed: 26,
            expectedPlanned: 7_394,
            expectedCanonicalFields: [canonicalID, "passed", "2", "2", "2", ""]
        )
        guard outputSummary.canonicalFields == [canonicalID, "passed", "2", "2", "2", ""] else {
            throw DesignationError.identityValidation(options.output, "canonical row is not passed with 2/2/2 evidence")
        }
        let outputText = try readText(options.output)
        guard !outputText.contains(authoredPhaseLocalID) else {
            throw DesignationError.identityValidation(options.output, "phase-local ID \(authoredPhaseLocalID) is present")
        }

        for path in immutablePaths {
            let before = beforeHashes[path.path]!
            let after = try sha256(path)
            guard before == after else {
                throw DesignationError.sourceMutated(path, before, after)
            }
        }

        print(
            "SM64 Modern Phase85f81 serial canonical designation passed "
                + "rows=\(outputSummary.rows) passed=\(outputSummary.passed) planned=\(outputSummary.planned) "
                + "canonical_row=\(canonicalID)|passed|2|2|2| "
                + "manifest_sha256=\(manifestHashActual) retained_report_sha256=\(retainedHash) "
                + "candidate_report_sha256=\(candidateHash) designated_report_sha256=\(outputHash) "
                + "backup_report_sha256=\(try sha256(options.backupReport)) "
                + "backup_manifest_sha256=\(try sha256(options.backupManifest)) "
                + "authored_phase_id_absent=1 old_retained_unchanged=1 "
                + "backup_report=\(options.backupReport.path) backup_manifest=\(options.backupManifest.path) "
                + "hash_snapshot=\(options.hashSnapshot.path) designated_report=\(options.output.path)"
        )
    }

    private static func preflight(_ options: Options) throws -> (candidateReport: Data, retainedReport: Data, manifest: Data) {
        let inputPaths = [options.candidateReport, options.retainedReport, options.manifest]
        for path in inputPaths {
            guard FileManager.default.fileExists(atPath: path.path),
                  let data = try? Data(contentsOf: path), !data.isEmpty else {
                throw DesignationError.missingInput(path)
            }
        }
        let inputKeys = inputPaths.map(pathKey)
        guard Set(inputKeys).count == inputKeys.count else {
            throw DesignationError.duplicateInput(inputPaths[0])
        }

        let destinationPaths = [options.backupReport, options.backupManifest, options.hashSnapshot, options.output]
        let destinationKeys = destinationPaths.map(pathKey)
        guard Set(destinationKeys).count == destinationKeys.count else {
            throw DesignationError.outputCollision(destinationPaths[0])
        }
        for destination in destinationPaths {
            guard !inputKeys.contains(pathKey(destination)) else {
                throw DesignationError.outputCollision(destination)
            }
            guard !FileManager.default.fileExists(atPath: destination.path) else {
                throw DesignationError.writeOnceViolation(destination)
            }
        }

        let outputRoot = options.output.deletingLastPathComponent()
        let backupRoot = options.backupReport.deletingLastPathComponent()
        guard FileManager.default.fileExists(atPath: outputRoot.path) else {
            throw DesignationError.missingInput(outputRoot)
        }
        guard !FileManager.default.fileExists(atPath: backupRoot.path) else {
            throw DesignationError.writeOnceViolation(backupRoot)
        }
        guard options.backupManifest.deletingLastPathComponent() == backupRoot,
              options.hashSnapshot.deletingLastPathComponent() == backupRoot else {
            throw DesignationError.outputCollision(backupRoot)
        }

        let candidateData = try readData(options.candidateReport)
        let retainedData = try readData(options.retainedReport)
        let manifestData = try readData(options.manifest)

        let manifestActualHash = sha256(manifestData)
        guard manifestActualHash == manifestHash else {
            throw DesignationError.manifestHashMismatch(manifestHash, manifestActualHash)
        }
        let manifestIDs = try validateManifest(manifestData)
        let retainedSummary = try validateLedger(
            options.retainedReport,
            data: retainedData,
            manifestIDs: manifestIDs,
            expectedRows: 7_420,
            expectedPassed: 25,
            expectedPlanned: 7_395,
            expectedCanonicalFields: [canonicalID, "planned", "0", "0", "0", ""]
        )
        let candidateSummary = try validateLedger(
            options.candidateReport,
            data: candidateData,
            manifestIDs: manifestIDs,
            expectedRows: 7_420,
            expectedPassed: 26,
            expectedPlanned: 7_394,
            expectedCanonicalFields: [canonicalID, "passed", "2", "2", "2", ""]
        )
        guard retainedSummary.ids == candidateSummary.ids else {
            throw DesignationError.identityValidation(options.candidateReport, "candidate and retained report ID sets differ")
        }

        let retainedActualHash = sha256(retainedData)
        guard retainedActualHash == retainedReportHash else {
            throw DesignationError.retainedReportHashMismatch(retainedReportHash, retainedActualHash)
        }
        let candidateActualHash = sha256(candidateData)
        guard candidateActualHash == candidateReportHash else {
            throw DesignationError.candidateReportHashMismatch(candidateReportHash, candidateActualHash)
        }

        return (candidateData, retainedData, manifestData)
    }

    private static func validateManifest(_ data: Data) throws -> Set<UInt64> {
        guard let text = String(data: data, encoding: .utf8) else {
            throw DesignationError.manifestInvalid("manifest is not UTF-8")
        }
        var IDs = Set<UInt64>()
        var rows = 0
        var canonicalRows = 0
        for line in text.split(whereSeparator: { $0.isNewline }) {
            let lineText = String(line)
            if lineText.isEmpty || lineText.hasPrefix("#") { continue }
            let fields = lineText.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 9 else {
                throw DesignationError.manifestInvalid("manifest row does not have nine fields")
            }
            guard let id = parseHex(fields[0]), IDs.insert(id).inserted else {
                throw DesignationError.manifestInvalid("manifest row has a duplicate or invalid shard ID")
            }
            rows += 1
            if lineText == manifestCanonicalRow { canonicalRows += 1 }
            if lineText.contains(authoredPhaseLocalID) {
                throw DesignationError.manifestInvalid("phase-local ID \(authoredPhaseLocalID) is present")
            }
        }
        guard rows == 7_420 else {
            throw DesignationError.manifestInvalid("expected 7420 rows, got \(rows)")
        }
        guard canonicalRows == 1 else {
            throw DesignationError.manifestInvalid("expected exactly one canonical intro source-identity row, got \(canonicalRows)")
        }
        return IDs
    }

    private static func validateLedger(
        _ url: URL,
        data: Data? = nil,
        manifestIDs: Set<UInt64>? = nil,
        expectedRows: Int,
        expectedPassed: Int,
        expectedPlanned: Int,
        expectedCanonicalFields: [String]
    ) throws -> LedgerSummary {
        let bytes = try data ?? readData(url)
        guard let text = String(data: bytes, encoding: .utf8) else {
            throw DesignationError.identityValidation(url, "report is not UTF-8")
        }
        guard !text.contains(authoredPhaseLocalID) else {
            throw DesignationError.identityValidation(url, "phase-local ID \(authoredPhaseLocalID) is present")
        }

        var IDs = Set<UInt64>()
        var rows = 0
        var passed = 0
        var planned = 0
        var canonicalFields: [String] = []
        for line in text.split(whereSeparator: { $0.isNewline }) {
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 6 else {
                throw DesignationError.identityValidation(url, "report row does not have six fields")
            }
            guard let id = parseHex(fields[0]) else {
                throw DesignationError.identityValidation(url, "report row has an invalid shard ID")
            }
            guard IDs.insert(id).inserted else {
                throw DesignationError.identityValidation(url, "duplicate shard ID \(fields[0])")
            }
            if let manifestIDs, !manifestIDs.contains(id) {
                throw DesignationError.identityValidation(url, "shard ID \(fields[0]) is absent from the manifest")
            }
            rows += 1
            switch fields[1] {
            case "passed":
                passed += 1
                guard UInt64(fields[2]) ?? 0 > 0,
                      fields[2] == fields[3], fields[3] == fields[4], fields[5].isEmpty else {
                    throw DesignationError.identityValidation(url, "passed row \(fields[0]) has incomplete evidence")
                }
            case "planned":
                planned += 1
                guard fields[2] == "0", fields[3] == "0", fields[4] == "0", fields[5].isEmpty else {
                    throw DesignationError.identityValidation(url, "planned row \(fields[0]) has terminal evidence")
                }
            default:
                throw DesignationError.identityValidation(url, "row \(fields[0]) has unsupported state \(fields[1])")
            }
            if fields[0] == canonicalID {
                canonicalFields = fields
            }
        }
        guard rows == expectedRows, passed == expectedPassed, planned == expectedPlanned else {
            throw DesignationError.countValidation(
                url,
                "expected rows=\(expectedRows) passed=\(expectedPassed) planned=\(expectedPlanned), got rows=\(rows) passed=\(passed) planned=\(planned)"
            )
        }
        guard canonicalFields == expectedCanonicalFields else {
            throw DesignationError.identityValidation(
                url,
                "expected canonical row \(expectedCanonicalFields.joined(separator: "|")), got \(canonicalFields.joined(separator: "|"))"
            )
        }
        guard IDs.count == expectedRows else {
            throw DesignationError.identityValidation(url, "report does not contain one unique row for every manifest shard")
        }
        return LedgerSummary(ids: IDs, rows: rows, passed: passed, planned: planned, canonicalFields: canonicalFields)
    }

    private static func createFreshBackupDirectory(for options: Options) throws {
        let backupRoot = options.backupReport.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: backupRoot, withIntermediateDirectories: false)
        } catch {
            throw DesignationError.writeFailed(backupRoot, error)
        }
    }

    private static func writeOnce(data: Data, to url: URL) throws {
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw DesignationError.writeOnceViolation(url)
        }
        let directory = url.deletingLastPathComponent()
        let temporary = directory.appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).tmp")
        do {
            try data.write(to: temporary, options: .atomic)
            guard !FileManager.default.fileExists(atPath: url.path) else {
                try? FileManager.default.removeItem(at: temporary)
                throw DesignationError.writeOnceViolation(url)
            }
            try FileManager.default.moveItem(at: temporary, to: url)
        } catch let error as DesignationError {
            throw error
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw DesignationError.writeFailed(url, error)
        }
    }

    private static func verifyHash(_ url: URL, expected: String) throws {
        let actual = try sha256(url)
        guard actual == expected else {
            throw DesignationError.backupHashMismatch(url, expected, actual)
        }
    }

    private static func verifySnapshot(_ expected: String, at url: URL) throws {
        let actual = try readText(url)
        guard actual == expected else {
            throw DesignationError.identityValidation(url, "hash snapshot bytes changed after write")
        }
    }

    private static func makeHashSnapshot(
        candidate: URL,
        candidateHash: String,
        retained: URL,
        retainedHash: String,
        manifest: URL,
        manifestHash: String
    ) -> String {
        [
            "# sm64-modern-phase85f81-designation-hash-snapshot-v1",
            "retained_report|\(retained.path)|\(retainedHash)|rows=7420|passed=25|planned=7395",
            "manifest|\(manifest.path)|\(manifestHash)|rows=7420",
            "candidate_report|\(candidate.path)|\(candidateHash)|rows=7420|passed=26|planned=7394",
        ].joined(separator: "\n") + "\n"
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-serial-canonical-designation --candidate-report REPORT --retained-report REPORT --manifest MANIFEST --backup-report REPORT --backup-manifest MANIFEST --hash-snapshot SNAPSHOT --output REPORT"
        let expected: Set<String> = [
            "--candidate-report", "--retained-report", "--manifest", "--backup-report",
            "--backup-manifest", "--hash-snapshot", "--output",
        ]
        guard arguments.count == expected.count * 2 else {
            throw DesignationError.invalidArguments(usage)
        }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let key = arguments[index]
            guard expected.contains(key), index + 1 < arguments.count, values[key] == nil else {
                throw DesignationError.invalidArguments(usage)
            }
            values[key] = arguments[index + 1]
            index += 2
        }
        guard Set(values.keys) == expected else {
            throw DesignationError.invalidArguments(usage)
        }
        func url(_ key: String) -> URL {
            URL(fileURLWithPath: values[key]!).standardizedFileURL
        }
        return Options(
            candidateReport: url("--candidate-report"),
            retainedReport: url("--retained-report"),
            manifest: url("--manifest"),
            backupReport: url("--backup-report"),
            backupManifest: url("--backup-manifest"),
            hashSnapshot: url("--hash-snapshot"),
            output: url("--output")
        )
    }

    private static func readData(_ url: URL) throws -> Data {
        do { return try Data(contentsOf: url, options: .mappedIfSafe) }
        catch { throw DesignationError.unreadable(url, error) }
    }

    private static func readText(_ url: URL) throws -> String {
        do { return try String(contentsOf: url, encoding: .utf8) }
        catch { throw DesignationError.unreadable(url, error) }
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

    private static func pathKey(_ url: URL) -> String {
        url.resolvingSymlinksInPath().standardizedFileURL.path
    }
}
