import CryptoKit
import Foundation

/// Phase 85f0 isolated admission for the source-authored audio_asset route.
///
/// This tool consumes the already-produced Phase 85ef native artifacts and
/// writes only a new report/proof pair. It never mutates the route manifest,
/// cumulative ledger, source files, or shared documentation. The native
/// traces are Debug/ASan/Release/rerun; Swift evidence is the independent
/// Swift 6 decoder audit log produced by the Phase 85ef verifier.
@main
struct SM64AudioAssetRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    // Keep the shared evidence envelope used by the cumulative merge tool so
    // Phase 85f1 can consume this isolated proof without rewriting it.
    private static let proofHeader = "# sm64-modern-phase85h-evidence-v1"
    private static let proofSchema = "# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256..."
    private static let manifestRowCount = 7_420
    private static let shardID: UInt64 = 0x0334_5fc5_60c6_5b75
    private static let inputSeed: UInt64 = 0x014f_93c6_ae7e_2e59
    private static let saveSeed: UInt64 = 0x2a35_82ec_4861_4066
    private static let expectedRecords = 1_084
    private static let expectedCoverage: UInt64 = 0x553a_b8ef_4927_5722
    private static let sourcePath = "sound/sequences/us/12_event_high_score.m64"
    private static let sourceSHA256 = "2e0170f20353d6ba772af9df92f2d53e8b8d807e2b5bca24ac87bc022f08fade"
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize

    private struct ManifestRow {
        let shard: SM64RouteShard
        let line: Int
    }

    private struct RawTrace {
        let url: URL
        let bytes: Data
        let configuration: SM64OracleTraceConfiguration
        let records: [SM64OracleTraceRecord]
    }

    private struct Options {
        let manifest: URL
        let debugTrace: URL
        let asanTrace: URL
        let releaseTrace: URL
        let rerunTrace: URL
        let tamperedTrace: URL
        let partialTrace: URL
        let debugPCM: URL
        let asanPCM: URL
        let releasePCM: URL
        let rerunPCM: URL
        let debugReceipts: URL
        let asanReceipts: URL
        let releaseReceipts: URL
        let rerunReceipts: URL
        let debugLog: URL
        let swiftLog: URL
        let asanLog: URL
        let releaseLog: URL
        let rerunLog: URL
        let report: URL
        let proof: URL
    }

    private enum ToolError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case unreadable(URL, Error)
        case missingEvidence(URL)
        case invalidManifest(String)
        case wrongManifestRow(String)
        case invalidTrace(URL, Error)
        case invalidHeader(URL, String)
        case headerMismatch(String)
        case wrongRecordCount(String, Int)
        case wrongRecord(String, Int, String)
        case wrongCoverage(String, UInt64)
        case traceBytesMismatch
        case sidecarBytesMismatch(String)
        case singleArtifactEvidence
        case tamperAccepted(URL)
        case tamperNotCanonical(URL, Error)
        case partialAccepted(URL)
        case partialNotCanonical(URL, Error)
        case missingMarker(URL, String)
        case sanitizerFinding(URL)
        case fixtureOnly(URL)
        case reportAlreadyExists(URL)
        case reportCollision(URL)
        case reportInvalid(String)
        case proofInvalid(String)
        case unwritable(URL, Error)

        var description: String {
            switch self {
            case let .invalidArguments(message): return message
            case let .unreadable(url, error): return "cannot read \(url.path): \(error)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidManifest(reason): return "invalid route manifest: \(reason)"
            case let .wrongManifestRow(reason): return "audio_asset manifest row mismatch: \(reason)"
            case let .invalidTrace(url, error): return "invalid trace \(url.path): \(error)"
            case let .invalidHeader(url, reason): return "invalid trace header \(url.path): \(reason)"
            case let .headerMismatch(field): return "Debug/ASan/Release/rerun header mismatch: \(field)"
            case let .wrongRecordCount(label, count): return "\(label) record count \(count) is not \(expectedRecords)"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case let .wrongCoverage(label, value):
                return String(format: "%@ coverage fingerprint 0x%016llx is not the source-backed nonzero value", label, value)
            case .traceBytesMismatch: return "Debug, ASan, Release, and rerun trace bytes differ"
            case let .sidecarBytesMismatch(kind): return "Debug, ASan, Release, and rerun \(kind) bytes differ"
            case .singleArtifactEvidence: return "single-artifact evidence is not admissible; independent paths are required"
            case let .tamperAccepted(url): return "tampered trace was accepted: \(url.path)"
            case let .tamperNotCanonical(url, error): return "tampered trace did not fail canonical decoding \(url.path): \(error)"
            case let .partialAccepted(url): return "partial trace was accepted: \(url.path)"
            case let .partialNotCanonical(url, error): return "partial trace did not fail canonical decoding \(url.path): \(error)"
            case let .missingMarker(url, marker): return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .fixtureOnly(url): return "fixture_only evidence is not allowed: \(url.path)"
            case let .reportAlreadyExists(url): return "isolated admission report/proof already exists; terminal rerun rejected: \(url.path)"
            case let .reportCollision(url): return "isolated report/proof collides with immutable evidence: \(url.path)"
            case let .reportInvalid(reason): return "isolated report validation failed: \(reason)"
            case let .proofInvalid(reason): return "isolated proof validation failed: \(reason)"
            case let .unwritable(url, error): return "cannot write \(url.path): \(error)"
            }
        }
    }

    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            if arguments.first == "single" {
                try rejectSingle(arguments: Array(arguments.dropFirst()))
            } else if arguments.first == "fixture" {
                try rejectFixture(arguments: Array(arguments.dropFirst()))
            } else {
                try admit(arguments: arguments)
            }
        } catch {
            FileHandle.standardError.write(Data(("sm64-audio-asset-route-admit: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func admit(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctEvidence(options)
        try requireFreshOutputs(options)

        let manifestText = try read(options.manifest)
        let rows = try parseManifest(manifestText)
        guard rows.count == manifestRowCount else {
            throw ToolError.invalidManifest("expected \(manifestRowCount) rows, got \(rows.count)")
        }
        let target = try resolveTarget(rows)
        try requireNoFixtureMarkers(options)
        try requireMarkers(options)

        let debug = try loadTrace(options.debugTrace)
        let asan = try loadTrace(options.asanTrace)
        let release = try loadTrace(options.releaseTrace)
        let rerun = try loadTrace(options.rerunTrace)
        let traces = [("Debug", debug), ("ASan", asan), ("Release", release), ("rerun", rerun)]
        for (label, trace) in traces {
            try validateHeader(trace.configuration, label: label)
            try validateRecords(trace, label: label)
        }
        for (label, trace) in traces.dropFirst() where trace.configuration != debug.configuration {
            throw ToolError.headerMismatch(label)
        }
        guard traces.dropFirst().allSatisfy({ $0.1.bytes == debug.bytes }) else {
            throw ToolError.traceBytesMismatch
        }

        let pcm = try loadSidecars([options.debugPCM, options.asanPCM, options.releasePCM, options.rerunPCM], kind: "PCM trace")
        let receipts = try loadSidecars([options.debugReceipts, options.asanReceipts, options.releaseReceipts, options.rerunReceipts], kind: "receipt")
        _ = pcm
        _ = receipts
        try rejectTamperedTrace(options.tamperedTrace)
        try rejectPartialTrace(options.partialTrace)

        var ledger = try SM64RouteShardExecutionLedger(manifest: manifestText)
        try ledger.begin(id: target.shard.id)
        try ledger.finish(
            id: target.shard.id,
            state: .passed,
            evidence: SM64RouteShardExecutionEvidence(
                expectedRecords: UInt64(expectedRecords),
                actualRecords: UInt64(expectedRecords),
                matchedRecords: UInt64(expectedRecords)
            )
        )
        let report = ledger.report()
        try validateReport(report, manifestText: manifestText, target: target.shard)
        let reportHash = sha256(Data(report.utf8))
        let artifactURLs = [
            options.debugTrace, options.asanTrace, options.releaseTrace, options.rerunTrace,
            options.debugPCM, options.asanPCM, options.releasePCM, options.rerunPCM,
            options.debugReceipts, options.asanReceipts, options.releaseReceipts, options.rerunReceipts,
            options.debugLog, options.swiftLog, options.asanLog, options.releaseLog, options.rerunLog,
            options.tamperedTrace, options.partialTrace,
        ]
        let proof = try makeProof(target: target.shard, reportHash: reportHash, artifacts: artifactURLs)
        try write(report, to: options.report)
        try write(proof, to: options.proof)
        try validateProof(proof, reportHash: reportHash, target: target.shard, artifacts: artifactURLs)

        let manifestHash = sha256(Data(manifestText.utf8))
        let traceHash = sha256(debug.bytes)
        let pcmHash = try sha256(options.debugPCM)
        let receiptHash = try sha256(options.debugReceipts)
        let proofHash = sha256(Data(proof.utf8))
        print(
            "SM64 audio_asset route isolated admission passed "
                + "shard=\(formatID(shardID)) identity=\(target.shard.identity) source=\(target.shard.source) "
                + "records=\(expectedRecords) ticks=1,720 domain=9 expected_domains=audio_pcm,audio_sequence "
                + "audio_sequence_records=3 audio_pcm_records=720 sequence12_tick=63 "
                + "coverage=0x\(String(expectedCoverage, radix: 16)) schema=4 "
                + "c_asan_release_rerun_byte_match=1 pcm_c_asan_release_rerun_byte_match=1 "
                + "receipts_c_asan_release_rerun_byte_match=1 swift_decoder_audit=1 "
                + "tamper_rejected=1 partial_rejected=1 distinct_inputs=1 fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 "
                + "history_mutated=0 rerun_fence=1 manifest_rows=\(rows.count) report_rows=\(rows.count) "
                + "passed_rows=1 planned_rows=\(rows.count - 1) "
                + "manifest_sha256=\(manifestHash) report_sha256=\(reportHash) proof_sha256=\(proofHash) "
                + "trace_sha256=\(traceHash) pcm_sha256=\(pcmHash) receipts_sha256=\(receiptHash) "
                + "report=\(options.report.path) proof=\(options.proof.path)"
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-audio-asset-route-admit --manifest MANIFEST --debug-trace TRACE --asan-trace TRACE --release-trace TRACE --rerun-trace TRACE --tampered-trace TRACE --partial-trace TRACE --debug-pcm TRACE --asan-pcm TRACE --release-pcm TRACE --rerun-pcm TRACE --debug-receipts RECEIPTS --asan-receipts RECEIPTS --release-receipts RECEIPTS --rerun-receipts RECEIPTS --debug-log LOG --swift-log LOG --asan-log LOG --release-log LOG --rerun-log LOG --report REPORT --proof PROOF"
        guard arguments.count == 44, arguments.count.isMultiple(of: 2) else {
            throw ToolError.invalidArguments(usage)
        }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let key = arguments[index]
            let value = arguments[index + 1]
            guard key.hasPrefix("--"), values[key] == nil else { throw ToolError.invalidArguments(usage) }
            values[key] = value
            index += 2
        }
        let known: Set<String> = [
            "--manifest", "--debug-trace", "--asan-trace", "--release-trace", "--rerun-trace",
            "--tampered-trace", "--partial-trace", "--debug-pcm", "--asan-pcm", "--release-pcm", "--rerun-pcm",
            "--debug-receipts", "--asan-receipts", "--release-receipts", "--rerun-receipts",
            "--debug-log", "--swift-log", "--asan-log", "--release-log", "--rerun-log", "--report", "--proof",
        ]
        guard values.count == known.count, values.keys.allSatisfy(known.contains) else { throw ToolError.invalidArguments(usage) }
        func url(_ key: String) -> URL { URL(fileURLWithPath: values[key]!).standardizedFileURL }
        return Options(
            manifest: url("--manifest"), debugTrace: url("--debug-trace"), asanTrace: url("--asan-trace"),
            releaseTrace: url("--release-trace"), rerunTrace: url("--rerun-trace"), tamperedTrace: url("--tampered-trace"),
            partialTrace: url("--partial-trace"), debugPCM: url("--debug-pcm"), asanPCM: url("--asan-pcm"),
            releasePCM: url("--release-pcm"), rerunPCM: url("--rerun-pcm"), debugReceipts: url("--debug-receipts"),
            asanReceipts: url("--asan-receipts"), releaseReceipts: url("--release-receipts"), rerunReceipts: url("--rerun-receipts"),
            debugLog: url("--debug-log"), swiftLog: url("--swift-log"), asanLog: url("--asan-log"),
            releaseLog: url("--release-log"), rerunLog: url("--rerun-log"), report: url("--report"), proof: url("--proof")
        )
    }

    private static func rejectSingle(arguments: [String]) throws {
        guard arguments.count == 2 else { throw ToolError.invalidArguments("usage: ... single FIRST SECOND") }
        let first = URL(fileURLWithPath: arguments[0]).resolvingSymlinksInPath().standardizedFileURL.path
        let second = URL(fileURLWithPath: arguments[1]).resolvingSymlinksInPath().standardizedFileURL.path
        guard first != second else { throw ToolError.singleArtifactEvidence }
        print("phase85f0_single_artifact_distinct=1")
    }

    private static func rejectFixture(arguments: [String]) throws {
        guard arguments.count == 1 else { throw ToolError.invalidArguments("usage: ... fixture MARKER") }
        let marker = URL(fileURLWithPath: arguments[0]).standardizedFileURL
        guard !FileManager.default.fileExists(atPath: marker.path) else { throw ToolError.fixtureOnly(marker) }
        print("phase85f0_fixture_only_absent=1")
    }

    private static func requireDistinctEvidence(_ options: Options) throws {
        let evidence = [
            options.debugTrace, options.asanTrace, options.releaseTrace, options.rerunTrace,
            options.tamperedTrace, options.partialTrace, options.debugPCM, options.asanPCM,
            options.releasePCM, options.rerunPCM, options.debugReceipts, options.asanReceipts,
            options.releaseReceipts, options.rerunReceipts,
        ].map(pathKey)
        guard Set(evidence).count == evidence.count else { throw ToolError.singleArtifactEvidence }
        let immutable = Set(evidence + [pathKey(options.manifest)])
        let outputs = [options.report, options.proof, options.debugLog, options.swiftLog, options.asanLog, options.releaseLog, options.rerunLog].map(pathKey)
        guard outputs.allSatisfy({ !immutable.contains($0) }) else { throw ToolError.reportCollision(options.report) }
    }

    private static func requireFreshOutputs(_ options: Options) throws {
        if FileManager.default.fileExists(atPath: options.report.path) { throw ToolError.reportAlreadyExists(options.report) }
        if FileManager.default.fileExists(atPath: options.proof.path) { throw ToolError.reportAlreadyExists(options.proof) }
    }

    private static func read(_ url: URL) throws -> String {
        do { return try String(contentsOf: url, encoding: .utf8) }
        catch { throw ToolError.unreadable(url, error) }
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
            } catch let error as ToolError { throw error }
            catch { throw ToolError.invalidManifest("line \(lineNumber): \(error)") }
        }
        guard !rows.isEmpty else { throw ToolError.invalidManifest("manifest has no rows") }
        return rows
    }

    private static func resolveTarget(_ rows: [ManifestRow]) throws -> ManifestRow {
        let matches = rows.filter { $0.shard.id == shardID }
        guard matches.count == 1, let target = matches.first else {
            throw ToolError.wrongManifestRow("expected one \(formatID(shardID)) row, found \(matches.count)")
        }
        let shard = target.shard
        guard shard.domain == "audio_asset",
              shard.identity == sourcePath,
              shard.source == sourcePath,
              shard.inputSeed == inputSeed,
              shard.saveSeed == saveSeed,
              shard.expectedDomains == [.audioPCM, .audioSequence],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("identity/source/seeds/exact expected domains/status do not match")
        }
        return target
    }

    private static func loadTrace(_ url: URL) throws -> RawTrace {
        guard FileManager.default.fileExists(atPath: url.path) else { throw ToolError.missingEvidence(url) }
        do {
            let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
            guard bytes.count >= traceHeaderSize,
                  (bytes.count - traceHeaderSize).isMultiple(of: traceRecordSize) else {
                throw ToolError.invalidHeader(url, "size is not 72 + N*128")
            }
            let trace = try SM64OracleTraceFile.read(from: url)
            return RawTrace(url: url, bytes: bytes, configuration: trace.configuration, records: trace.records)
        } catch let error as ToolError { throw error }
        catch { throw ToolError.invalidTrace(url, error) }
    }

    private static func validateHeader(_ configuration: SM64OracleTraceConfiguration, label: String) throws {
        let expectedContent = fnvString("\(sourcePath)|sha256=\(sourceSHA256)")
        let expectedConfiguration = fnvString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "input_seed=0x014f93c6ae7e2e59;save_seed=0x2a3582ec48614066;"
                + "shard=0x03345fc560c65b75;asset=\(sourcePath);asset_sha256=\(sourceSHA256)"
        )
        guard configuration.regionCode == 0x5553, configuration.mode == .record else {
            throw ToolError.headerMismatch("\(label).schema4_record")
        }
        guard configuration.contentFingerprint == expectedContent else {
            throw ToolError.headerMismatch("\(label).content_fingerprint")
        }
        guard configuration.configurationFingerprint == expectedConfiguration else {
            throw ToolError.headerMismatch("\(label).configuration_fingerprint")
        }
        guard configuration.coverageFingerprint == expectedCoverage else {
            throw ToolError.wrongCoverage(label, configuration.coverageFingerprint)
        }
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        guard trace.records.count == expectedRecords else { throw ToolError.wrongRecordCount(label, trace.records.count) }
        let allowed: Set<String> = ["3:1", "3:2", "3:3", "5:5"]
        var counts: [String: Int] = [:]
        for (index, record) in trace.records.enumerated() {
            guard record.domain == 9 else { throw ToolError.wrongRecord(label, index, "unrelated domain \(record.domain)") }
            let key = "\(record.recordKind):\(record.recordID)"
            guard allowed.contains(key) else { throw ToolError.wrongRecord(label, index, "unexpected audio key \(key)") }
            counts[key, default: 0] += 1
        }
        // The source-owned tick receipt is emitted once per odd simulation
        // tick (360 observations across the 720-step window). Sequence 12 is
        // observed three times, the queue transition once, and PCM once per
        // step. The route contract therefore admits the full 1,084-record
        // stream rather than collapsing repeated tick receipts.
        guard counts["3:1"] == 360, counts["3:2"] == 3, counts["3:3"] == 1, counts["5:5"] == 720,
              counts.count == allowed.count else {
            throw ToolError.wrongRecord(label, 0, "expected audio inventory counts 3:1=360,3:2=3,3:3=1,5:5=720")
        }
        let sequence12 = trace.records.filter {
            $0.recordKind == 3 && $0.recordID == 2 && $0.values.count >= 2 && $0.values[1] == 0x12
        }
        guard sequence12.count == 1, sequence12[0].simulationTick == 63,
              sequence12[0].values == [1, 0x12, 0, 0, 0] else {
            throw ToolError.wrongRecord(label, 0, "source sequence 12 record/tick/payload changed")
        }
        let ticks = Set(trace.records.map(\.simulationTick))
        guard ticks.contains(1), ticks.contains(720) else {
            throw ToolError.wrongRecord(label, 0, "expected tick window 1...720")
        }
    }

    private static func loadSidecars(_ urls: [URL], kind: String) throws -> [Data] {
        let data = try urls.map { url -> Data in
            guard FileManager.default.fileExists(atPath: url.path) else { throw ToolError.missingEvidence(url) }
            do { return try Data(contentsOf: url, options: .mappedIfSafe) }
            catch { throw ToolError.unreadable(url, error) }
        }
        guard data.allSatisfy({ !$0.isEmpty }) else { throw ToolError.sidecarBytesMismatch(kind) }
        guard data.dropFirst().allSatisfy({ $0 == data[0] }) else { throw ToolError.sidecarBytesMismatch(kind) }
        return data
    }

    private static func requireMarkers(_ options: Options) throws {
        let routeMarker = "audio_asset_route_probe shard=0x03345fc560c65b75 source=\(sourcePath) source_sha256=\(sourceSHA256) input_seed=0x014f93c6ae7e2e59 save_seed=0x2a3582ec48614066 steps=720 records=1084 audio_sequence=3 audio_pcm=720"
        for url in [options.debugLog, options.asanLog, options.releaseLog, options.rerunLog] {
            try requireMarker(url, routeMarker)
            try rejectSanitizerFindings(in: url)
        }
        let swift = try read(options.swiftLog)
        guard swift.components(separatedBy: "phase85ef_audio_coverage_audit records=1084").count == 5,
              swift.contains("coverage=0x553ab8ef49275722 audio_only=1 unrelated_domains=0") else {
            throw ToolError.missingMarker(options.swiftLog, "four independent Swift decoder audits")
        }
    }

    private static func requireNoFixtureMarkers(_ options: Options) throws {
        let traces = [options.debugTrace, options.asanTrace, options.releaseTrace, options.rerunTrace]
        for trace in traces {
            let marker = URL(fileURLWithPath: trace.path + ".fixture_only")
            if FileManager.default.fileExists(atPath: marker.path) { throw ToolError.fixtureOnly(marker) }
        }
    }

    private static func requireMarker(_ url: URL, _ marker: String) throws {
        let contents = try read(url)
        guard contents.contains(marker) else { throw ToolError.missingMarker(url, marker) }
    }

    private static func rejectSanitizerFindings(in url: URL) throws {
        let contents = try read(url)
        if contents.contains("ERROR: AddressSanitizer")
            || contents.contains("AddressSanitizer: heap-")
            || contents.contains("AddressSanitizer: stack-")
            || contents.contains("AddressSanitizer: global-") {
            throw ToolError.sanitizerFinding(url)
        }
    }

    private static func rejectTamperedTrace(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { throw ToolError.missingEvidence(url) }
        do {
            _ = try SM64OracleTraceFile.read(from: url)
            throw ToolError.tamperAccepted(url)
        } catch ToolError.tamperAccepted { throw ToolError.tamperAccepted(url) }
        catch SM64OracleTraceCodecError.nonCanonicalHash { return }
        catch { throw ToolError.tamperNotCanonical(url, error) }
    }

    private static func rejectPartialTrace(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { throw ToolError.missingEvidence(url) }
        do {
            _ = try SM64OracleTraceFile.read(from: url)
            throw ToolError.partialAccepted(url)
        } catch ToolError.partialAccepted { throw ToolError.partialAccepted(url) }
        catch SM64OracleTraceCodecError.trailingBytes, SM64OracleTraceCodecError.truncated { return }
        catch { throw ToolError.partialNotCanonical(url, error) }
    }

    private static func validateReport(_ report: String, manifestText: String, target: SM64RouteShard) throws {
        do {
            let ledger = try SM64RouteShardExecutionLedger(manifest: manifestText, report: report)
            guard ledger.count == manifestRowCount, ledger.plannedCount == manifestRowCount - 1,
                  ledger.terminalCount == 1, try ledger.state(for: target.id) == .passed,
                  try ledger.evidence(for: target.id)?.expectedRecords == UInt64(expectedRecords),
                  try ledger.evidence(for: target.id)?.actualRecords == UInt64(expectedRecords),
                  try ledger.evidence(for: target.id)?.matchedRecords == UInt64(expectedRecords) else {
                throw ToolError.reportInvalid("target/ledger counts are not an exact single-row promotion")
            }
        } catch let error as ToolError { throw error }
        catch { throw ToolError.reportInvalid(String(describing: error)) }
    }

    private static func makeProof(target: SM64RouteShard, reportHash: String, artifacts: [URL]) throws -> String {
        guard artifacts.count > 0 else { throw ToolError.proofInvalid("no artifacts") }
        var fields = [formatID(target.id), target.domain, target.identity, "0", reportHash, String(artifacts.count)]
        for artifact in artifacts {
            guard FileManager.default.fileExists(atPath: artifact.path) else { throw ToolError.missingEvidence(artifact) }
            fields.append(artifact.standardizedFileURL.path)
            fields.append(try sha256(artifact))
        }
        return [proofHeader, proofSchema, fields.joined(separator: "|")].joined(separator: "\n") + "\n"
    }

    private static func validateProof(_ proof: String, reportHash: String, target: SM64RouteShard, artifacts: [URL]) throws {
        let lines = proof.split(whereSeparator: { $0.isNewline })
        guard lines.count == 3, lines[0] == proofHeader, lines[1] == proofSchema else {
            throw ToolError.proofInvalid("invalid proof header")
        }
        let fields = lines[2].split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard fields.count == 6 + artifacts.count * 2,
              parseHex(fields[0]) == target.id,
              fields[1] == target.domain,
              fields[2] == target.identity,
              fields[3] == "0",
              fields[4] == reportHash,
              Int(fields[5]) == artifacts.count else {
            throw ToolError.proofInvalid("target/report/artifact metadata mismatch")
        }
    }

    private static func write(_ text: String, to url: URL) throws {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(text.utf8).write(to: url, options: .atomic)
        } catch { throw ToolError.unwritable(url, error) }
    }

    private static func fnvString(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64(1_469_598_103_934_665_603)) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
    }

    private static func sha256(_ url: URL) throws -> String {
        do { return sha256(try Data(contentsOf: url, options: .mappedIfSafe)) }
        catch { throw ToolError.unreadable(url, error) }
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

    private static func formatID(_ id: UInt64) -> String {
        String(format: "0x%016llx", id)
    }
}
