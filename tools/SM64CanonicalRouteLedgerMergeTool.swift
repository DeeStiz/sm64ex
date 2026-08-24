import CryptoKit
import Foundation

/// Merges the independently admitted Phase 85 route reports without
/// treating the remaining planned rows as qualified.  Every input report is
/// checked against the same immutable manifest and must contain exactly one
/// passed target row; all other rows must remain pristine planned rows.
///
/// The proof sidecars carry the fixture fence and hashes for the independent
/// route artifacts.  The tool verifies those hashes itself, so a copied or
/// fixture-only report cannot enter the cumulative ledger by filename alone.
@main
struct SM64CanonicalRouteLedgerMergeTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let proofHeader = "# sm64-modern-phase85h-evidence-v1"
    private static let proofSchema = "# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256..."
    private static let manifestRowCount = 7420
    private static let targetIDs: [UInt64] = [
        0xd944_6dfe_d10e_189e,
        0x88d0_4246_f94c_e9f8,
        0x4eb1_9b71_d76b_e0d4,
        0xb123_ff3e_997b_dc78,
        0x862c_3d78_b60d_657c,
        0x2b0f_6063_b546_3e9c,
        0xc329_4578_ae77_bee8,
        0x7632_df13_5b85_e448,
        0xbe18_4196_f54f_8216,
        0x4e55_5253_3aaa_717d,
        0x0149_fe4b_1ab8_a36a5,
        0x4aa7_5cc0_9d18_0fce,
        0x3e1c_daca_08b2_1f54,
        0x3951_f033_3dc3_c5da,
        0x022f_bda0_ff7f_2dd1,
        0x1e35_00f9_eb2b_95d4,
        0x00ca_b93b_5dd9_4425,
        0x00a5_aebe_3689_7ac4,
        0xd5a4_3d53_7c37_e833,
        0x0057_6356_a427_dbc2,
        0xdf0c_e0c6_988b_445d,
        0x009e_4310_51db_a428,
        0x01b4_72aa_e4c4_277d,
        0x0334_5fc5_60c6_5b75,
        0x0020_d8a2_54a8_93a3,
    ]

    private enum MergeError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case unreadable(URL, Error)
        case invalidManifest(String)
        case invalidReport(URL, Int, String)
        case duplicateReportPath(URL)
        case duplicateRow(UInt64, URL, Int)
        case unknownRow(UInt64, URL, Int)
        case missingRows(URL, Int)
        case unexpectedTarget(URL, UInt64)
        case wrongTargetState(URL, UInt64, String)
        case nonPristineRow(URL, UInt64, String)
        case invalidProof(URL, String)
        case fixtureEvidence(URL)
        case artifactMissing(URL)
        case artifactHashMismatch(URL, String, String)
        case reportHashMismatch(URL, String, String)
        case duplicateArtifact(URL)
        case outputExists(URL)
        case outputCollision(URL)
        case ledgerInvalid(String)
        case unwritable(URL, Error)

        var description: String {
            switch self {
            case let .invalidArguments(message): return message
            case let .unreadable(url, error): return "cannot read \(url.path): \(error)"
            case let .invalidManifest(reason): return "invalid canonical route manifest: \(reason)"
            case let .invalidReport(url, line, reason):
                return "invalid route report \(url.path) line \(line): \(reason)"
            case let .duplicateReportPath(url): return "duplicate report artifact: \(url.path)"
            case let .duplicateRow(id, url, line):
                return String(format: "duplicate report shard ID 0x%016llx in %@ line %d", id, url.path, line)
            case let .unknownRow(id, url, line):
                return String(format: "unknown report shard ID 0x%016llx in %@ line %d", id, url.path, line)
            case let .missingRows(url, count): return "report \(url.path) is missing \(count) manifest rows"
            case let .unexpectedTarget(url, id):
                return String(format: "report %@ contains a passed row for unexpected target 0x%016llx", url.path, id)
            case let .wrongTargetState(url, id, state):
                return String(format: "report %@ target 0x%016llx is %@, expected passed", url.path, id, state)
            case let .nonPristineRow(url, id, reason):
                return String(format: "report %@ non-target row 0x%016llx is not pristine planned: %@", url.path, id, reason)
            case let .invalidProof(url, reason): return "invalid evidence proof \(url.path): \(reason)"
            case let .fixtureEvidence(url): return "fixture_only evidence is not allowed: \(url.path)"
            case let .artifactMissing(url): return "missing independent evidence artifact: \(url.path)"
            case let .artifactHashMismatch(url, expected, actual):
                return "artifact hash mismatch \(url.path): expected \(expected), got \(actual)"
            case let .reportHashMismatch(url, expected, actual):
                return "report hash mismatch \(url.path): expected \(expected), got \(actual)"
            case let .duplicateArtifact(url): return "duplicate independent evidence artifact: \(url.path)"
            case let .outputExists(url): return "cumulative ledger already exists; rerun rejected: \(url.path)"
            case let .outputCollision(url): return "output paths collide: \(url.path)"
            case let .ledgerInvalid(reason): return "cumulative ledger validation failed: \(reason)"
            case let .unwritable(url, error): return "cannot write \(url.path): \(error)"
            }
        }
    }

    private struct Options {
        let manifest: URL
        let inputReport: URL
        let inputProof: URL
        let marioReport: URL
        let marioProof: URL
        let cameraReport: URL
        let cameraProof: URL
        let globalReport: URL
        let globalProof: URL
        let objectReport: URL
        let objectProof: URL
        let scriptReport: URL
        let scriptProof: URL
        let collisionReport: URL
        let collisionProof: URL
        let rngReport: URL
        let rngProof: URL
        let audioReport: URL
        let audioProof: URL
        let saveReport: URL
        let saveProof: URL
        let renderReport: URL
        let renderProof: URL
        let audioPCMReport: URL
        let audioPCMProof: URL
        let interactionReport: URL
        let interactionProof: URL
        let effectsReport: URL
        let effectsProof: URL
        let saveMutationReport: URL
        let saveMutationProof: URL
        let cameraFindFloorReport: URL
        let cameraFindFloorProof: URL
        let displayListReport: URL
        let displayListProof: URL
        let displayListNextReport: URL
        let displayListNextProof: URL
        let renderCallbackReport: URL
        let renderCallbackProof: URL
        let rngBreakParticlesReport: URL
        let rngBreakParticlesProof: URL
        let textReport: URL
        let textProof: URL
        let insideCastleReport: URL
        let insideCastleProof: URL
        let doorReport: URL
        let doorProof: URL
        let audioAssetReport: URL
        let audioAssetProof: URL
        let pendulumReport: URL
        let pendulumProof: URL
        let output: URL
    }

    private struct ManifestRow {
        let id: UInt64
        let domain: String
        let identity: String
        let source: String
        let line: Int
    }

    private struct LedgerRow {
        let id: UInt64
        let state: SM64RouteShardExecutionState
        let expected: UInt64
        let actual: UInt64
        let matched: UInt64
        let divergence: String?
    }

    private struct Proof {
        let url: URL
        let targetID: UInt64
        let domain: String
        let identity: String
        let fixtureOnly: Bool
        let reportHash: String
        let artifactURLs: [URL]
        let artifactHashes: [String]
    }

    private struct ValidatedReport {
        let reportURL: URL
        let proofURL: URL
        let targetID: UInt64
        let reportHash: String
        let proof: Proof
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-canonical-route-ledger-merge: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let reportURLs = [
            options.inputReport, options.marioReport, options.cameraReport, options.globalReport,
            options.objectReport, options.scriptReport,
            options.collisionReport, options.rngReport,
            options.audioReport, options.saveReport,
            options.renderReport,
            options.audioPCMReport,
            options.interactionReport,
            options.effectsReport,
            options.saveMutationReport,
            options.cameraFindFloorReport,
            options.displayListReport,
            options.displayListNextReport,
            options.renderCallbackReport,
            options.rngBreakParticlesReport,
            options.textReport,
            options.insideCastleReport,
            options.doorReport,
            options.audioAssetReport,
            options.pendulumReport,
        ]
        let proofURLs = [
            options.inputProof, options.marioProof, options.cameraProof, options.globalProof,
            options.objectProof, options.scriptProof,
            options.collisionProof, options.rngProof,
            options.audioProof, options.saveProof,
            options.renderProof,
            options.audioPCMProof,
            options.interactionProof,
            options.effectsProof,
            options.saveMutationProof,
            options.cameraFindFloorProof,
            options.displayListProof,
            options.displayListNextProof,
            options.renderCallbackProof,
            options.rngBreakParticlesProof,
            options.textProof,
            options.insideCastleProof,
            options.doorProof,
            options.audioAssetProof,
            options.pendulumProof,
        ]
        let expectedTargets = targetIDs

        guard Set(reportURLs.map(pathKey)).count == reportURLs.count else {
            throw MergeError.duplicateReportPath(reportURLs[0])
        }
        guard options.output.resolvingSymlinksInPath().standardizedFileURL.path
            != options.manifest.resolvingSymlinksInPath().standardizedFileURL.path else {
            throw MergeError.outputCollision(options.output)
        }
        guard !FileManager.default.fileExists(atPath: options.output.path) else {
            throw MergeError.outputExists(options.output)
        }

        let manifestText = try read(options.manifest)
        let manifestRows = try parseManifest(manifestText)
        let manifestByID = Dictionary(uniqueKeysWithValues: manifestRows.map { ($0.id, $0) })
        let manifestIDs = Set(manifestByID.keys)
        guard expectedTargets.allSatisfy({ manifestIDs.contains($0) }) else {
            throw MergeError.invalidManifest("one or more Phase 85 target IDs are absent")
        }
        let manifestHash = sha256(Data(manifestText.utf8))

        var validated: [ValidatedReport] = []
        var seenTargets: Set<UInt64> = []
        var seenArtifacts: Set<String> = []
        for (index, pair) in zip(reportURLs, proofURLs).enumerated() {
            let expectedID = expectedTargets[index]
            let reportText = try read(pair.0)
            let rows = try parseReport(reportText, from: pair.0, manifestIDs: manifestIDs)
            let proof = try parseProof(
                pair.1,
                expectedTargetID: expectedID,
                reportURL: pair.0,
                reportText: reportText,
                expectedManifestRow: manifestByID[expectedID]!,
                seenArtifacts: &seenArtifacts
            )
            guard seenTargets.insert(expectedID).inserted else {
                throw MergeError.unexpectedTarget(pair.0, expectedID)
            }
            try validateReport(
                rows,
                reportURL: pair.0,
                targetID: expectedID,
                manifestIDs: manifestIDs
            )
            guard rows.contains(where: { $0.id == expectedID && $0.state == .passed }) else {
                throw MergeError.wrongTargetState(pair.0, expectedID, "planned")
            }
            validated.append(
                ValidatedReport(
                    reportURL: pair.0,
                    proofURL: pair.1,
                    targetID: expectedID,
                    reportHash: sha256(Data(reportText.utf8)),
                    proof: proof
                )
            )
        }
        guard seenTargets == Set(expectedTargets) else {
            throw MergeError.invalidManifest("Phase 85 reports do not cover all twenty-five target IDs")
        }

        var merged: [LedgerRow] = manifestRows.map {
            LedgerRow(id: $0.id, state: .planned, expected: 0, actual: 0, matched: 0, divergence: nil)
        }
        for item in validated {
            guard let index = merged.firstIndex(where: { $0.id == item.targetID }) else {
                throw MergeError.invalidManifest("target disappeared while merging")
            }
            let sourceRows = try parseReport(try read(item.reportURL), from: item.reportURL, manifestIDs: manifestIDs)
            guard let source = sourceRows.first(where: { $0.id == item.targetID }) else {
                throw MergeError.wrongTargetState(item.reportURL, item.targetID, "missing")
            }
            merged[index] = source
        }
        let outputText = merged
            .sorted { $0.id < $1.id }
            .map(encode)
            .joined(separator: "\n") + "\n"
        try write(outputText, to: options.output)

        do {
            let ledger = try SM64RouteShardExecutionLedger(manifest: manifestText, report: outputText)
            guard ledger.count == manifestRowCount,
                  ledger.plannedCount == 7395,
                  ledger.terminalCount == 25 else {
                throw MergeError.ledgerInvalid(
                    "expected manifest_rows=7420 planned=7395 terminal=25, got "
                        + "manifest_rows=\(ledger.count) planned=\(ledger.plannedCount) terminal=\(ledger.terminalCount)"
                )
            }
            for id in expectedTargets {
                guard try ledger.state(for: id) == .passed else {
                    throw MergeError.ledgerInvalid(String(format: "target 0x%016llx is not passed", id))
                }
            }
        } catch let error as MergeError {
            throw error
        } catch {
            throw MergeError.ledgerInvalid(String(describing: error))
        }

        let outputHash = sha256(Data(outputText.utf8))
        let targetSummary = expectedTargets.map { formatID($0) }.joined(separator: ",")
        print(
            "SM64 canonical route ledger merge passed "
                + "manifest_rows=7420 qualified_rows=25 planned=7395 terminal=25 "
                + "targets=[\(targetSummary)] fixture_only=0 "
                + "manifest_sha256=\(manifestHash) output_sha256=\(outputHash) "
                + "report_sha256s=[\(validated.map(\.reportHash).joined(separator: ","))] "
                + "rerun_fence=terminal_only output=\(options.output.path)"
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-canonical-route-ledger-merge --manifest MANIFEST --input-report REPORT --input-proof PROOF --mario-report REPORT --mario-proof PROOF --camera-report REPORT --camera-proof PROOF --global-report REPORT --global-proof PROOF --object-report REPORT --object-proof PROOF --script-report REPORT --script-proof PROOF --collision-report REPORT --collision-proof PROOF --rng-report REPORT --rng-proof PROOF --audio-report REPORT --audio-proof PROOF --save-report REPORT --save-proof PROOF --render-report REPORT --render-proof PROOF --audio-pcm-report REPORT --audio-pcm-proof PROOF --interaction-report REPORT --interaction-proof PROOF --effects-report REPORT --effects-proof PROOF --save-mutation-report REPORT --save-mutation-proof PROOF --camera-find-floor-report REPORT --camera-find-floor-proof PROOF --display-list-report REPORT --display-list-proof PROOF --display-list-next-report REPORT --display-list-next-proof PROOF --render-callback-report REPORT --render-callback-proof PROOF --rng-break-particles-report REPORT --rng-break-particles-proof PROOF --text-report REPORT --text-proof PROOF --inside-castle-report REPORT --inside-castle-proof PROOF --door-report REPORT --door-proof PROOF --audio-asset-report REPORT --audio-asset-proof PROOF --pendulum-report REPORT --pendulum-proof PROOF --output REPORT"
        guard arguments.count == 104, arguments.count.isMultiple(of: 2) else {
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
        let known: Set<String> = [
            "--manifest", "--input-report", "--input-proof", "--mario-report", "--mario-proof",
            "--camera-report", "--camera-proof", "--global-report", "--global-proof",
            "--object-report", "--object-proof", "--script-report", "--script-proof",
            "--collision-report", "--collision-proof", "--rng-report", "--rng-proof",
            "--audio-report", "--audio-proof", "--save-report", "--save-proof",
            "--render-report", "--render-proof", "--audio-pcm-report", "--audio-pcm-proof",
            "--interaction-report", "--interaction-proof", "--effects-report", "--effects-proof",
            "--save-mutation-report", "--save-mutation-proof", "--output",
            "--camera-find-floor-report", "--camera-find-floor-proof",
            "--display-list-report", "--display-list-proof",
            "--display-list-next-report", "--display-list-next-proof",
            "--render-callback-report", "--render-callback-proof",
            "--rng-break-particles-report", "--rng-break-particles-proof",
            "--text-report", "--text-proof",
            "--inside-castle-report", "--inside-castle-proof",
            "--door-report", "--door-proof",
            "--audio-asset-report", "--audio-asset-proof",
            "--pendulum-report", "--pendulum-proof",
        ]
        guard values.count == known.count, values.keys.allSatisfy(known.contains) else {
            throw MergeError.invalidArguments(usage)
        }
        func url(_ key: String) -> URL {
            URL(fileURLWithPath: values[key]!).standardizedFileURL
        }
        return Options(
            manifest: url("--manifest"), inputReport: url("--input-report"), inputProof: url("--input-proof"),
            marioReport: url("--mario-report"), marioProof: url("--mario-proof"),
            cameraReport: url("--camera-report"), cameraProof: url("--camera-proof"),
            globalReport: url("--global-report"), globalProof: url("--global-proof"),
            objectReport: url("--object-report"), objectProof: url("--object-proof"),
            scriptReport: url("--script-report"), scriptProof: url("--script-proof"),
            collisionReport: url("--collision-report"), collisionProof: url("--collision-proof"),
            rngReport: url("--rng-report"), rngProof: url("--rng-proof"),
            audioReport: url("--audio-report"), audioProof: url("--audio-proof"),
            saveReport: url("--save-report"), saveProof: url("--save-proof"),
            renderReport: url("--render-report"), renderProof: url("--render-proof"),
            audioPCMReport: url("--audio-pcm-report"), audioPCMProof: url("--audio-pcm-proof"),
            interactionReport: url("--interaction-report"), interactionProof: url("--interaction-proof"),
            effectsReport: url("--effects-report"), effectsProof: url("--effects-proof"),
            saveMutationReport: url("--save-mutation-report"), saveMutationProof: url("--save-mutation-proof"),
            cameraFindFloorReport: url("--camera-find-floor-report"), cameraFindFloorProof: url("--camera-find-floor-proof"),
            displayListReport: url("--display-list-report"), displayListProof: url("--display-list-proof"),
            displayListNextReport: url("--display-list-next-report"), displayListNextProof: url("--display-list-next-proof"),
            renderCallbackReport: url("--render-callback-report"), renderCallbackProof: url("--render-callback-proof"),
            rngBreakParticlesReport: url("--rng-break-particles-report"), rngBreakParticlesProof: url("--rng-break-particles-proof"),
            textReport: url("--text-report"), textProof: url("--text-proof"),
            insideCastleReport: url("--inside-castle-report"), insideCastleProof: url("--inside-castle-proof"),
            doorReport: url("--door-report"), doorProof: url("--door-proof"),
            audioAssetReport: url("--audio-asset-report"), audioAssetProof: url("--audio-asset-proof"),
            pendulumReport: url("--pendulum-report"), pendulumProof: url("--pendulum-proof"),
            output: url("--output")
        )
    }

    private static func parseManifest(_ text: String) throws -> [ManifestRow] {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count >= 2, lines[0] == manifestHeader, lines[1] == manifestSchema else {
            throw MergeError.invalidManifest("invalid header")
        }
        var rows: [ManifestRow] = []
        var seen: Set<UInt64> = []
        for (offset, line) in lines.dropFirst(2).enumerated() {
            let lineNumber = offset + 3
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 9 else { throw MergeError.invalidManifest("line \(lineNumber) expected nine fields") }
            guard let id = parseHex(fields[0]), seen.insert(id).inserted else {
                throw MergeError.invalidManifest("line \(lineNumber) has duplicate or invalid shard ID")
            }
            guard fields[7] == "planned" else { throw MergeError.invalidManifest("line \(lineNumber) is not planned") }
            guard !fields[6].isEmpty else { throw MergeError.invalidManifest("line \(lineNumber) has no expected domain") }
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
    ) throws -> [LedgerRow] {
        var rows: [LedgerRow] = []
        var seen: Set<UInt64> = []
        for (offset, line) in text.split(whereSeparator: { $0.isNewline }).enumerated() {
            let lineNumber = offset + 1
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 6 else { throw MergeError.invalidReport(url, lineNumber, "expected six fields") }
            guard let id = parseHex(fields[0]) else { throw MergeError.invalidReport(url, lineNumber, "invalid shard ID") }
            guard manifestIDs.contains(id) else { throw MergeError.unknownRow(id, url, lineNumber) }
            guard seen.insert(id).inserted else { throw MergeError.duplicateRow(id, url, lineNumber) }
            guard let state = SM64RouteShardExecutionState(rawValue: fields[1]) else {
                throw MergeError.invalidReport(url, lineNumber, "unknown state")
            }
            guard let expected = UInt64(fields[2]), let actual = UInt64(fields[3]), let matched = UInt64(fields[4]) else {
                throw MergeError.invalidReport(url, lineNumber, "invalid evidence counts")
            }
            rows.append(LedgerRow(id: id, state: state, expected: expected, actual: actual, matched: matched, divergence: fields[5].isEmpty ? nil : fields[5]))
        }
        guard rows.count == manifestIDs.count else { throw MergeError.missingRows(url, manifestIDs.count - rows.count) }
        return rows
    }

    private static func validateReport(
        _ rows: [LedgerRow],
        reportURL: URL,
        targetID: UInt64,
        manifestIDs: Set<UInt64>
    ) throws {
        guard Set(rows.map(\.id)) == manifestIDs else { throw MergeError.missingRows(reportURL, manifestIDs.count - rows.count) }
        guard rows.filter({ $0.state == .passed }).count == 1 else {
            throw MergeError.invalidReport(reportURL, 1, "report must contain exactly one passed row")
        }
        for row in rows {
            if row.id == targetID {
                guard row.state == .passed else { throw MergeError.wrongTargetState(reportURL, targetID, row.state.rawValue) }
                guard row.expected > 0, row.actual == row.expected, row.matched == row.expected, row.divergence == nil else {
                    throw MergeError.wrongTargetState(reportURL, targetID, "passed with incomplete evidence")
                }
            } else {
                guard row.state == .planned else { throw MergeError.nonPristineRow(reportURL, row.id, "state=\(row.state.rawValue)") }
                guard row.expected == 0, row.actual == 0, row.matched == 0, row.divergence == nil else {
                    throw MergeError.nonPristineRow(reportURL, row.id, "terminal evidence on planned row")
                }
            }
        }
    }

    private static func parseProof(
        _ url: URL,
        expectedTargetID: UInt64,
        reportURL: URL,
        reportText: String,
        expectedManifestRow: ManifestRow,
        seenArtifacts: inout Set<String>
    ) throws -> Proof {
        let text = try read(url)
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count == 3, lines[0] == proofHeader, lines[1] == proofSchema else {
            throw MergeError.invalidProof(url, "invalid header or row count")
        }
        let fields = lines[2].split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 8 else { throw MergeError.invalidProof(url, "expected target and artifact fields") }
        guard let targetID = parseHex(fields[0]), targetID == expectedTargetID else {
            throw MergeError.invalidProof(url, "unexpected target ID")
        }
        guard fields[1] == expectedManifestRow.domain, fields[2] == expectedManifestRow.identity else {
            throw MergeError.invalidProof(url, "source identity does not match manifest")
        }
        guard fields[3] == "0" else { throw MergeError.fixtureEvidence(url) }
        let reportHash = fields[4].lowercased()
        guard reportHash.count == 64, isHex(reportHash) else { throw MergeError.invalidProof(url, "invalid report SHA-256") }
        let actualReportHash = sha256(Data(reportText.utf8))
        guard reportHash == actualReportHash else { throw MergeError.reportHashMismatch(reportURL, reportHash, actualReportHash) }
        guard let artifactCount = Int(fields[5]), artifactCount > 0, fields.count == 6 + artifactCount * 2 else {
            throw MergeError.invalidProof(url, "artifact count does not match path/hash pairs")
        }
        var artifactURLs: [URL] = []
        var artifactHashes: [String] = []
        for index in 0..<artifactCount {
            let path = URL(fileURLWithPath: fields[6 + index * 2]).standardizedFileURL
            let expectedHash = fields[7 + index * 2].lowercased()
            guard expectedHash.count == 64, isHex(expectedHash) else {
                throw MergeError.invalidProof(url, "invalid artifact SHA-256")
            }
            guard FileManager.default.fileExists(atPath: path.path) else { throw MergeError.artifactMissing(path) }
            let key = path.resolvingSymlinksInPath().standardizedFileURL.path
            guard seenArtifacts.insert(key).inserted else { throw MergeError.duplicateArtifact(path) }
            let actualHash = try sha256(path)
            guard expectedHash == actualHash else { throw MergeError.artifactHashMismatch(path, expectedHash, actualHash) }
            artifactURLs.append(path)
            artifactHashes.append(expectedHash)
        }
        return Proof(url: url, targetID: targetID, domain: fields[1], identity: fields[2], fixtureOnly: false, reportHash: reportHash, artifactURLs: artifactURLs, artifactHashes: artifactHashes)
    }

    private static func encode(_ row: LedgerRow) -> String {
        [formatID(row.id), row.state.rawValue, String(row.expected), String(row.actual), String(row.matched), row.divergence ?? ""].joined(separator: "|")
    }

    private static func read(_ url: URL) throws -> String {
        do { return try String(contentsOf: url, encoding: .utf8) } catch { throw MergeError.unreadable(url, error) }
    }

    private static func write(_ text: String, to url: URL) throws {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(text.utf8).write(to: url, options: .atomic)
        } catch { throw MergeError.unwritable(url, error) }
    }

    private static func sha256(_ url: URL) throws -> String {
        do { return sha256(try Data(contentsOf: url, options: .mappedIfSafe)) } catch { throw MergeError.unreadable(url, error) }
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func parseHex(_ value: String) -> UInt64? {
        guard value.hasPrefix("0x") else { return nil }
        return UInt64(value.dropFirst(2), radix: 16)
    }

    private static func isHex(_ value: String) -> Bool {
        value.allSatisfy { $0.isHexDigit }
    }

    private static func pathKey(_ url: URL) -> String {
        url.resolvingSymlinksInPath().standardizedFileURL.path
    }

    private static func formatID(_ id: UInt64) -> String {
        String(format: "0x%016llx", id)
    }
}
