import CryptoKit
import Foundation

/// Runs the two immutable stages needed to audit the next serial route merge.
///
/// Stage one invokes the existing 25-target canonical merge tool with every
/// retained report/proof pair. Stage two invokes the guarded intro-transition
/// merge against that fresh stage-one report. This coordinator never accepts
/// an existing output path, and it verifies all proof artifact paths before
/// either stage is started so a missing retained artifact fails closed.
@main
struct SM64SerialCanonicalMergeDryRunTool {
    private static let manifestHash = "23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715"
    private static let firstStageHash = "aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d"
    private static let finalStageHash = "4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4"
    private static let introReportHash = "6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2"
    private static let introProofHash = "c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51"
    private static let authoredIntroID = "0x9a0f7b4f7ecf6c41"
    private static let canonicalIntroID = "0xca33981b30cb7815"

    private static let pairFlags: [(name: String, report: String, proof: String)] = [
        ("input", "--input-report", "--input-proof"),
        ("mario", "--mario-report", "--mario-proof"),
        ("camera", "--camera-report", "--camera-proof"),
        ("global", "--global-report", "--global-proof"),
        ("object", "--object-report", "--object-proof"),
        ("script", "--script-report", "--script-proof"),
        ("collision", "--collision-report", "--collision-proof"),
        ("rng", "--rng-report", "--rng-proof"),
        ("audio", "--audio-report", "--audio-proof"),
        ("save", "--save-report", "--save-proof"),
        ("render", "--render-report", "--render-proof"),
        ("audio-pcm", "--audio-pcm-report", "--audio-pcm-proof"),
        ("interaction", "--interaction-report", "--interaction-proof"),
        ("effects", "--effects-report", "--effects-proof"),
        ("save-mutation", "--save-mutation-report", "--save-mutation-proof"),
        ("camera-find-floor", "--camera-find-floor-report", "--camera-find-floor-proof"),
        ("display-list", "--display-list-report", "--display-list-proof"),
        ("display-list-next", "--display-list-next-report", "--display-list-next-proof"),
        ("render-callback", "--render-callback-report", "--render-callback-proof"),
        ("rng-break-particles", "--rng-break-particles-report", "--rng-break-particles-proof"),
        ("text", "--text-report", "--text-proof"),
        ("inside-castle", "--inside-castle-report", "--inside-castle-proof"),
        ("door", "--door-report", "--door-proof"),
        ("audio-asset", "--audio-asset-report", "--audio-asset-proof"),
        ("pendulum", "--pendulum-report", "--pendulum-proof"),
    ]

    private struct Pair {
        let name: String
        let report: URL
        let proof: URL
    }

    private struct Options {
        let canonicalTool: URL
        let introTool: URL
        let manifest: URL
        let pairs: [Pair]
        let introReport: URL
        let introProof: URL
        let firstOutput: URL
        let finalOutput: URL
    }

    private enum DryRunError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case missingInput(URL)
        case nonExecutable(URL)
        case outputExists(URL)
        case outputCollision(URL)
        case duplicatePath(URL)
        case invalidProof(URL, String)
        case missingProofArtifact(URL)
        case manifestHashMismatch(String, String)
        case firstStageHashMismatch(String, String)
        case finalStageHashMismatch(String, String)
        case introReportHashMismatch(String, String)
        case introProofHashMismatch(String, String)
        case ledgerMismatch(URL, String)
        case inputMutated(URL, String, String)
        case processFailed(String, Int32, String)
        case unreadable(URL, Error)

        var description: String {
            switch self {
            case let .invalidArguments(usage): return usage
            case let .missingInput(url): return "required retained input is missing: \(url.path)"
            case let .nonExecutable(url): return "merge tool is not executable: \(url.path)"
            case let .outputExists(url): return "terminal rerun rejected; isolated output already exists: \(url.path)"
            case let .outputCollision(url): return "output path collides with an immutable input or proof artifact: \(url.path)"
            case let .duplicatePath(url): return "duplicate immutable input or proof artifact path: \(url.path)"
            case let .invalidProof(url, reason): return "invalid retained proof \(url.path): \(reason)"
            case let .missingProofArtifact(url): return "missing retained proof artifact: \(url.path)"
            case let .manifestHashMismatch(expected, actual):
                return "manifest SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .firstStageHashMismatch(expected, actual):
                return "first-stage output SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .finalStageHashMismatch(expected, actual):
                return "final output SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .introReportHashMismatch(expected, actual):
                return "Phase85f32 report SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .introProofHashMismatch(expected, actual):
                return "Phase85f32 proof SHA-256 mismatch: expected \(expected), got \(actual)"
            case let .ledgerMismatch(url, reason): return "ledger validation failed for \(url.path): \(reason)"
            case let .inputMutated(url, before, after):
                return "immutable input mutated \(url.path): before \(before), after \(after)"
            case let .processFailed(label, status, output):
                return "\(label) failed with exit \(status):\n\(output)"
            case let .unreadable(url, error): return "cannot read \(url.path): \(error)"
            }
        }
    }

    private struct ProofArtifactSet {
        let artifacts: [URL]
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-serial-canonical-merge-dryrun: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let proofArtifacts = try preflight(options)

        let immutablePaths = [options.manifest]
            + options.pairs.flatMap { [$0.report, $0.proof] }
            + [options.introReport, options.introProof]
            + proofArtifacts
        let beforeHashes = try Dictionary(uniqueKeysWithValues: immutablePaths.map { ($0.path, try sha256($0)) })

        var firstArguments: [String] = ["--manifest", options.manifest.path]
        for pairSpec in pairFlags {
            guard let pair = options.pairs.first(where: { $0.name == pairSpec.name }) else {
                throw DryRunError.invalidArguments(usage)
            }
            firstArguments += [pairSpec.report, pair.report.path, pairSpec.proof, pair.proof.path]
        }
        firstArguments += ["--output", options.firstOutput.path]
        let firstResult = try runProcess(options.canonicalTool, arguments: firstArguments, label: "25-target first-stage merge")
        print(firstResult.output, terminator: firstResult.output.hasSuffix("\n") ? "" : "\n")

        let firstHash = try sha256(options.firstOutput)
        guard firstHash == firstStageHash else {
            throw DryRunError.firstStageHashMismatch(firstStageHash, firstHash)
        }
        try validateLedger(options.firstOutput, passed: 25, planned: 7_395, expectedCanonicalState: "planned")

        let introReportHashActual = try sha256(options.introReport)
        guard introReportHashActual == introReportHash else {
            throw DryRunError.introReportHashMismatch(introReportHash, introReportHashActual)
        }
        let introProofHashActual = try sha256(options.introProof)
        guard introProofHashActual == introProofHash else {
            throw DryRunError.introProofHashMismatch(introProofHash, introProofHashActual)
        }

        let finalArguments = [
            "--manifest", options.manifest.path,
            "--prior-report", options.firstOutput.path,
            "--target-report", options.introReport.path,
            "--target-proof", options.introProof.path,
            "--output", options.finalOutput.path,
        ]
        let finalResult = try runProcess(options.introTool, arguments: finalArguments, label: "Phase85f33 guarded intro-transition merge")
        print(finalResult.output, terminator: finalResult.output.hasSuffix("\n") ? "" : "\n")

        let finalHash = try sha256(options.finalOutput)
        guard finalHash == finalStageHash else {
            throw DryRunError.finalStageHashMismatch(finalStageHash, finalHash)
        }
        try validateLedger(options.finalOutput, passed: 26, planned: 7_394, expectedCanonicalState: "passed")
        let finalText = try read(options.finalOutput)
        guard finalText.contains("\(canonicalIntroID)|passed|2|2|2|") else {
            throw DryRunError.ledgerMismatch(options.finalOutput, "canonical intro row is not passed")
        }
        guard !finalText.contains("\(authoredIntroID)|") else {
            throw DryRunError.ledgerMismatch(options.finalOutput, "authored phase-local intro ID was emitted")
        }

        for path in immutablePaths {
            let before = beforeHashes[path.path]!
            let after = try sha256(path)
            guard before == after else {
                throw DryRunError.inputMutated(path, before, after)
            }
        }

        let reportSummary = options.pairs.map { pair in
            "\(pair.name):report=\(beforeHashes[pair.report.path]!) proof=\(beforeHashes[pair.proof.path]!)"
        }.joined(separator: " ")
        print(
            "SM64 Modern Phase85f64 serial canonical merge dry-run passed "
                + "manifest_rows=7420 first_stage_passed=25 first_stage_planned=7395 "
                + "final_stage_passed=26 final_stage_planned=7394 "
                + "manifest_sha256=\(try sha256(options.manifest)) "
                + "first_stage_sha256=\(firstHash) final_stage_sha256=\(finalHash) "
                + "intro_report_sha256=\(introReportHashActual) intro_proof_sha256=\(introProofHashActual) "
                + "immutable_inputs_unchanged=1 fixture_only=0 "
                + "first_output=\(options.firstOutput.path) final_output=\(options.finalOutput.path)"
        )
        print("retained_pair_hashes \(reportSummary)")
    }

    private static func preflight(_ options: Options) throws -> [URL] {
        for tool in [options.canonicalTool, options.introTool] {
            guard FileManager.default.fileExists(atPath: tool.path) else { throw DryRunError.missingInput(tool) }
            guard FileManager.default.isExecutableFile(atPath: tool.path) else { throw DryRunError.nonExecutable(tool) }
        }
        let inputPaths = [options.manifest]
            + options.pairs.flatMap { [$0.report, $0.proof] }
            + [options.introReport, options.introProof]
        for path in inputPaths {
            guard FileManager.default.fileExists(atPath: path.path), (try? Data(contentsOf: path))?.isEmpty == false else {
                throw DryRunError.missingInput(path)
            }
        }
        for output in [options.firstOutput, options.finalOutput] where FileManager.default.fileExists(atPath: output.path) {
            throw DryRunError.outputExists(output)
        }

        let proofArtifacts = try inputPaths
            .filter { $0.path.hasSuffix("-proof.tsv") || $0.lastPathComponent == "audio-asset-proof.tsv" || $0.lastPathComponent == "pendulum-proof.tsv" }
            .flatMap { try parseProofArtifacts($0).artifacts }
        let immutableKeys = inputPaths.map(pathKey)
        let artifactKeys = proofArtifacts.map(pathKey)
        guard Set(immutableKeys).count == immutableKeys.count else {
            throw DryRunError.duplicatePath(inputPaths[0])
        }
        guard Set(artifactKeys).count == artifactKeys.count else {
            throw DryRunError.duplicatePath(proofArtifacts[0])
        }
        guard Set(immutableKeys + artifactKeys).count == immutableKeys.count + artifactKeys.count else {
            throw DryRunError.duplicatePath(proofArtifacts[0])
        }
        for artifact in proofArtifacts {
            guard FileManager.default.fileExists(atPath: artifact.path) else {
                throw DryRunError.missingProofArtifact(artifact)
            }
        }
        let outputKeys = [options.firstOutput, options.finalOutput].map(pathKey)
        guard Set(outputKeys).count == outputKeys.count else {
            throw DryRunError.outputCollision(options.firstOutput)
        }
        for output in [options.firstOutput, options.finalOutput] {
            guard !(immutableKeys + artifactKeys).contains(pathKey(output)) else {
                throw DryRunError.outputCollision(output)
            }
        }

        let actualManifestHash = try sha256(options.manifest)
        guard actualManifestHash == manifestHash else {
            throw DryRunError.manifestHashMismatch(manifestHash, actualManifestHash)
        }
        return proofArtifacts
    }

    private static func parse(arguments: [String]) throws -> Options {
        guard arguments.count >= 16 else { throw DryRunError.invalidArguments(usage) }
        var scalar: [String: String] = [:]
        var pairs: [Pair] = []
        var index = 0
        while index < arguments.count {
            let key = arguments[index]
            if key == "--pair" {
                guard index + 3 < arguments.count else { throw DryRunError.invalidArguments(usage) }
                let name = arguments[index + 1]
                guard !pairs.contains(where: { $0.name == name }), pairFlags.contains(where: { $0.name == name }) else {
                    throw DryRunError.invalidArguments(usage)
                }
                pairs.append(Pair(
                    name: name,
                    report: URL(fileURLWithPath: arguments[index + 2]).standardizedFileURL,
                    proof: URL(fileURLWithPath: arguments[index + 3]).standardizedFileURL
                ))
                index += 4
            } else {
                guard index + 1 < arguments.count, key.hasPrefix("--"), scalar[key] == nil else {
                    throw DryRunError.invalidArguments(usage)
                }
                scalar[key] = arguments[index + 1]
                index += 2
            }
        }
        let expectedScalar: Set<String> = [
            "--canonical-tool", "--intro-tool", "--manifest", "--intro-report", "--intro-proof",
            "--first-output", "--final-output",
        ]
        guard Set(scalar.keys) == expectedScalar,
              pairs.count == pairFlags.count,
              Set(pairs.map(\.name)) == Set(pairFlags.map(\.name)) else {
            throw DryRunError.invalidArguments(usage)
        }
        func url(_ key: String) -> URL { URL(fileURLWithPath: scalar[key]!).standardizedFileURL }
        return Options(
            canonicalTool: url("--canonical-tool"),
            introTool: url("--intro-tool"),
            manifest: url("--manifest"),
            pairs: pairs,
            introReport: url("--intro-report"),
            introProof: url("--intro-proof"),
            firstOutput: url("--first-output"),
            finalOutput: url("--final-output")
        )
    }

    private static func runProcess(_ executable: URL, arguments: [String], label: String) throws -> (output: String, status: Int32) {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        do {
            try process.run()
        } catch {
            throw DryRunError.processFailed(label, -1, String(describing: error))
        }
        process.waitUntilExit()
        let stdout = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let combined = stdout + stderr
        guard process.terminationStatus == 0 else {
            throw DryRunError.processFailed(label, process.terminationStatus, combined)
        }
        return (combined, process.terminationStatus)
    }

    private static func validateLedger(_ url: URL, passed: Int, planned: Int, expectedCanonicalState: String) throws {
        let text = try read(url)
        var rows = 0
        var passedCount = 0
        var plannedCount = 0
        var canonicalState: String?
        for line in text.split(whereSeparator: { $0.isNewline }) {
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 6 else { throw DryRunError.ledgerMismatch(url, "row does not have six fields") }
            rows += 1
            if fields[1] == "passed" { passedCount += 1 }
            if fields[1] == "planned" { plannedCount += 1 }
            if fields[0] == canonicalIntroID { canonicalState = fields[1] }
        }
        guard rows == 7_420, passedCount == passed, plannedCount == planned else {
            throw DryRunError.ledgerMismatch(url, "expected rows=7420 passed=\(passed) planned=\(planned), got rows=\(rows) passed=\(passedCount) planned=\(plannedCount)")
        }
        if expectedCanonicalState == "planned" {
            guard canonicalState == "planned" else {
                throw DryRunError.ledgerMismatch(url, "canonical intro row is not pristine planned in first stage")
            }
        } else {
            guard canonicalState == expectedCanonicalState else {
                throw DryRunError.ledgerMismatch(url, "canonical intro row state mismatch")
            }
        }
    }

    private static func parseProofArtifacts(_ url: URL) throws -> ProofArtifactSet {
        let text = try read(url)
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count == 3 else { throw DryRunError.invalidProof(url, "expected exactly three lines") }
        let fields = lines[2].split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 8, let count = Int(fields[5]), count > 0, fields.count == 6 + count * 2 else {
            throw DryRunError.invalidProof(url, "artifact count does not match path/hash pairs")
        }
        var artifacts: [URL] = []
        for index in 0..<count {
            let path = URL(fileURLWithPath: fields[6 + index * 2]).standardizedFileURL
            guard !path.path.isEmpty else { throw DryRunError.invalidProof(url, "empty artifact path") }
            artifacts.append(path)
        }
        return ProofArtifactSet(artifacts: artifacts)
    }

    private static func read(_ url: URL) throws -> String {
        do { return try String(contentsOf: url, encoding: .utf8) }
        catch { throw DryRunError.unreadable(url, error) }
    }

    private static func sha256(_ url: URL) throws -> String {
        do { return SHA256.hash(data: try Data(contentsOf: url, options: .mappedIfSafe)).map { String(format: "%02x", $0) }.joined() }
        catch { throw DryRunError.unreadable(url, error) }
    }

    private static func pathKey(_ url: URL) -> String {
        url.resolvingSymlinksInPath().standardizedFileURL.path
    }

    private static var usage: String {
        "usage: sm64-serial-canonical-merge-dryrun --canonical-tool TOOL --intro-tool TOOL --manifest MANIFEST --pair NAME REPORT PROOF (25 pairs) --intro-report REPORT --intro-proof PROOF --first-output REPORT --final-output REPORT"
    }
}
