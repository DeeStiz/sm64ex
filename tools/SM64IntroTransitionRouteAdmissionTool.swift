import CryptoKit
import Foundation

/// Phase 85f32 admission for the source-authored intro transition shard.
///
/// The Phase 85f30 pair remains the producer of every trace record.  This
/// process only validates the immutable pair artifacts and writes a fresh,
/// isolated report/proof pair.  It never calls a transition helper, rewrites
/// the canonical manifest, or advances a shared execution ledger.
@main
struct SM64IntroTransitionRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let proofHeader = "# sm64-modern-phase85h-evidence-v1"
    private static let proofSchema = "# target_id|domain|identity|fixture_only|report_sha256|artifact_count|artifact_path|artifact_sha256..."

    private static let routeShardID: UInt64 = 0x9a0f_7b4f_7ecf_6c41
    private static let routeInputSeed: UInt64 = 0x6c1f_8a94_3cb2_7d50
    private static let routeSaveSeed: UInt64 = 0x2e7f_db4a_0c56_89b1
    private static let routeDomain = "level_script"
    private static let routeIdentity = "levels/intro/script.c"
    private static let routeSource = "levels/intro/script.c"
    private static let routeExpectedDomains: [SM64RouteShardTraceDomain] = [.scriptEvents, .transition]

    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize
    private static let expectedTraceSize = traceHeaderSize + 2 * traceRecordSize
    private static let expectedCoverage: UInt64 = 0x8fc5_fa3c_2cd2_6867

    // These are the exact schema-4 header values emitted by the source-backed
    // Phase 85f30 owner-thread lifecycle.  Admission is intentionally bound to
    // the authored route recipe rather than accepting an arbitrary trace.
    private static let expectedHeader = SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: 0x62e7_ffdf_abb8_d5ac,
        contentFingerprint: 0x342d_6d9f_306b_17be,
        timebaseFingerprint: 0xccc1_9787_cd09_f0c2,
        configurationFingerprint: 0x123a_c550_762f_06f4,
        initialSaveFingerprint: 0xe18c_b3aa_c96a_f32d,
        coverageFingerprint: expectedCoverage
    )

    private static let expectedTicks: [UInt64] = [311, 391]
    private static let expectedSequences: [UInt32] = [2, 5]
    private static let expectedHashes: [UInt64] = [
        0xb9e7_7a79_7c34_bb9e,
        0x0eb9_1077_dbe7_2aa4,
    ]
    private static let expectedValues: [[UInt64]] = [
        [1, 16, 0, 0, 0],
        [8, 20, 0, 0, 0],
    ]

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
        let cTrace: URL
        let swiftTrace: URL
        let asanTrace: URL
        let releaseTrace: URL
        let rerunTrace: URL
        let tamperedTrace: URL
        let reorderedTrace: URL
        let missingTrace: URL
        let partialTrace: URL
        let pairReport: URL
        let pairProof: URL
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
        case traceBytesMismatch
        case singleArtifactEvidence
        case outputCollision(URL)
        case outputAlreadyExists(URL)
        case negativeAccepted(String, URL)
        case missingMarker(URL, String)
        case sanitizerFinding(URL)
        case fixtureOnly(URL)
        case invalidPairProof(String)
        case invalidReport(String)
        case invalidProof(String)
        case unwritable(URL, Error)

        var description: String {
            switch self {
            case let .invalidArguments(message): return message
            case let .unreadable(url, error): return "cannot read \(url.path): \(error)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidManifest(reason): return "invalid intro-transition manifest: \(reason)"
            case let .wrongManifestRow(reason): return "intro-transition source row mismatch: \(reason)"
            case let .invalidTrace(url, error): return "invalid trace \(url.path): \(error)"
            case let .invalidHeader(url, reason): return "invalid source-authored header \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift/ASan/Release/rerun header mismatch: \(field)"
            case let .wrongRecordCount(label, count): return "\(label) record count \(count) is not 2"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case .traceBytesMismatch: return "C, Swift, ASan, Release, and rerun trace bytes differ"
            case .singleArtifactEvidence: return "C, Swift, ASan, Release, and rerun evidence must be distinct artifacts"
            case let .outputCollision(url): return "admission output collides with immutable evidence: \(url.path)"
            case let .outputAlreadyExists(url): return "isolated admission report/proof already exists; duplicate admission rejected: \(url.path)"
            case let .negativeAccepted(kind, url): return "\(kind) negative evidence was accepted: \(url.path)"
            case let .missingMarker(url, marker): return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .fixtureOnly(url): return "fixture_only evidence is not allowed: \(url.path)"
            case let .invalidPairProof(reason): return "invalid intro-transition pair proof: \(reason)"
            case let .invalidReport(reason): return "isolated report validation failed: \(reason)"
            case let .invalidProof(reason): return "isolated proof validation failed: \(reason)"
            case let .unwritable(url, error): return "cannot write \(url.path): \(error)"
            }
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(
                Data(("sm64-intro-transition-route-admit: \(error)\n").utf8)
            )
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctInputs(options)
        try requireFreshOutputs(options)

        let manifestText = try read(options.manifest)
        let rows = try parseManifest(manifestText)
        let target = try resolveTarget(rows)

        try requireNoFixtureMarkers(options)
        try requirePairReport(options.pairReport)

        let traces = [
            ("C", try loadTrace(options.cTrace)),
            ("Swift", try loadTrace(options.swiftTrace)),
            ("ASan", try loadTrace(options.asanTrace)),
            ("Release", try loadTrace(options.releaseTrace)),
            ("rerun", try loadTrace(options.rerunTrace)),
        ]
        for (label, trace) in traces {
            try validateHeader(trace.configuration, label: label)
            try validateRecords(trace, label: label)
        }
        for (label, trace) in traces.dropFirst() where trace.configuration != traces[0].1.configuration {
            throw ToolError.headerMismatch(label)
        }
        let cTrace = traces[0].1
        guard traces.dropFirst().allSatisfy({ $0.1.bytes == cTrace.bytes }) else {
            throw ToolError.traceBytesMismatch
        }

        try requirePairProof(options.pairProof, traces: traces, pairReport: options.pairReport)
        try requireMarkers(options)
        try rejectTamperedTrace(options.tamperedTrace)
        try rejectWindowTrace(options.reorderedTrace, kind: "reordered")
        try rejectWindowTrace(options.missingTrace, kind: "missing")
        try rejectPartialTrace(options.partialTrace)

        let reportText = makeIsolatedReport(rows: rows, target: target)
        try validateIsolatedReport(reportText, rows: rows, target: target)
        let reportHash = sha256(Data(reportText.utf8))
        let artifactURLs = [
            options.cTrace, options.swiftTrace, options.asanTrace,
            options.releaseTrace, options.rerunTrace, options.tamperedTrace,
            options.reorderedTrace, options.missingTrace, options.partialTrace,
            options.pairReport, options.pairProof, options.debugLog,
            options.swiftLog, options.asanLog, options.releaseLog, options.rerunLog,
        ]
        let proofText = try makeProof(
            target: target.shard,
            reportHash: reportHash,
            artifacts: artifactURLs
        )
        try validateProof(
            proofText,
            reportHash: reportHash,
            target: target.shard,
            artifacts: artifactURLs
        )
        try write(reportText, to: options.report)
        try write(proofText, to: options.proof)

        let traceHashes = traces.map { sha256($0.1.bytes) }
        let pairReportHash = try sha256(options.pairReport)
        let pairProofHash = try sha256(options.pairProof)
        let proofHash = sha256(Data(proofText.utf8))
        print(
            "SM64 intro_transition route isolated admission passed "
                + "shard=\(formatID(routeShardID)) identity=\(routeIdentity) "
                + "source=\(routeSource) input_seed=\(formatID(routeInputSeed)) "
                + "save_seed=\(formatID(routeSaveSeed)) records=2 ticks=311,391 "
                + "domain=6 kind=3 schema=4 manifest_rows=\(rows.count) "
                + "report_rows=\(rows.count) passed_rows=1 planned_rows=\(rows.count - 1) "
                + "source_authored=1 owner_thread=1 direct_transition_call=0 synthesized_records=0 "
                + "c_swift_asan_release_rerun_byte_match=1 "
                + "c_trace_sha256=\(traceHashes[0]) swift_trace_sha256=\(traceHashes[1]) "
                + "asan_trace_sha256=\(traceHashes[2]) release_trace_sha256=\(traceHashes[3]) "
                + "rerun_trace_sha256=\(traceHashes[4]) "
                + "pair_report_sha256=\(pairReportHash) pair_proof_sha256=\(pairProofHash) "
                + "report_sha256=\(reportHash) proof_sha256=\(proofHash) "
                + "tamper_rejected=1 partial_rejected=1 reordered_rejected=1 missing_rejected=1 "
                + "single_artifact_rejected=1 fixture_only=0 manifest_mutated=0 "
                + "canonical_report_mutated=0 ledger_mutated=0 history_mutated=0 "
                + "output_distinctness=1 rerun_fence=1 report=\(options.report.path) proof=\(options.proof.path)"
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-intro-transition-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --release-trace RELEASE_TRACE --rerun-trace RERUN_TRACE --tampered-trace TAMPERED_TRACE --reordered-trace REORDERED_TRACE --missing-trace MISSING_TRACE --partial-trace PARTIAL_TRACE --pair-report PAIR_REPORT --pair-proof PAIR_PROOF --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --release-log RELEASE_LOG --rerun-log RERUN_LOG --report REPORT --proof PROOF"
        guard arguments.count == 38, arguments.count.isMultiple(of: 2) else {
            throw ToolError.invalidArguments(usage)
        }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let key = arguments[index]
            let value = arguments[index + 1]
            guard key.hasPrefix("--"), values[key] == nil else {
                throw ToolError.invalidArguments(usage)
            }
            values[key] = value
            index += 2
        }
        let known: Set<String> = [
            "--manifest", "--c-trace", "--swift-trace", "--asan-trace",
            "--release-trace", "--rerun-trace", "--tampered-trace",
            "--reordered-trace", "--missing-trace", "--partial-trace",
            "--pair-report", "--pair-proof", "--debug-log", "--swift-log",
            "--asan-log", "--release-log", "--rerun-log", "--report", "--proof",
        ]
        guard values.count == known.count, values.keys.allSatisfy(known.contains) else {
            throw ToolError.invalidArguments(usage)
        }
        func url(_ key: String) -> URL {
            URL(fileURLWithPath: values[key]!).standardizedFileURL
        }
        return Options(
            manifest: url("--manifest"), cTrace: url("--c-trace"),
            swiftTrace: url("--swift-trace"), asanTrace: url("--asan-trace"),
            releaseTrace: url("--release-trace"), rerunTrace: url("--rerun-trace"),
            tamperedTrace: url("--tampered-trace"), reorderedTrace: url("--reordered-trace"),
            missingTrace: url("--missing-trace"), partialTrace: url("--partial-trace"),
            pairReport: url("--pair-report"), pairProof: url("--pair-proof"),
            debugLog: url("--debug-log"), swiftLog: url("--swift-log"),
            asanLog: url("--asan-log"), releaseLog: url("--release-log"),
            rerunLog: url("--rerun-log"), report: url("--report"), proof: url("--proof")
        )
    }

    private static func requireDistinctInputs(_ options: Options) throws {
        let traces = [
            options.cTrace, options.swiftTrace, options.asanTrace,
            options.releaseTrace, options.rerunTrace, options.tamperedTrace,
            options.reorderedTrace, options.missingTrace, options.partialTrace,
        ].map(pathKey)
        guard Set(traces).count == traces.count else {
            throw ToolError.singleArtifactEvidence
        }
        let evidence = [
            options.manifest, options.pairReport, options.pairProof,
            options.debugLog, options.swiftLog, options.asanLog,
            options.releaseLog, options.rerunLog,
        ].map(pathKey) + traces
        let outputs = [options.report, options.proof].map(pathKey)
        guard Set(outputs).count == outputs.count,
              outputs.allSatisfy({ !evidence.contains($0) }) else {
            throw ToolError.outputCollision(options.report)
        }
    }

    private static func requireFreshOutputs(_ options: Options) throws {
        if FileManager.default.fileExists(atPath: options.report.path) {
            throw ToolError.outputAlreadyExists(options.report)
        }
        if FileManager.default.fileExists(atPath: options.proof.path) {
            throw ToolError.outputAlreadyExists(options.proof)
        }
    }

    private static func read(_ url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ToolError.unreadable(url, error)
        }
    }

    private static func readData(_ url: URL) throws -> Data {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ToolError.missingEvidence(url)
        }
        do {
            return try Data(contentsOf: url, options: .mappedIfSafe)
        } catch {
            throw ToolError.unreadable(url, error)
        }
    }

    private static func parseManifest(_ text: String) throws -> [ManifestRow] {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count >= 2,
              lines[0] == manifestHeader,
              lines[1] == manifestSchema else {
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
                    throw ToolError.invalidManifest(
                        String(format: "duplicate shard 0x%016llx", shard.id)
                    )
                }
                rows.append(ManifestRow(shard: shard, line: lineNumber))
            } catch let error as ToolError {
                throw error
            } catch {
                throw ToolError.invalidManifest("line \(lineNumber): \(error)")
            }
        }
        guard !rows.isEmpty else { throw ToolError.invalidManifest("manifest has no rows") }
        guard rows.count == 1 || rows.count == 7_420 else {
            throw ToolError.invalidManifest("expected a focused row or 7,420 rows, got \(rows.count)")
        }
        return rows
    }

    private static func resolveTarget(_ rows: [ManifestRow]) throws -> ManifestRow {
        let matches = rows.filter { $0.shard.id == routeShardID }
        guard matches.count == 1, let target = matches.first else {
            throw ToolError.wrongManifestRow(
                String(format: "expected one authored shard 0x%016llx, found %d", routeShardID, matches.count)
            )
        }
        let shard = target.shard
        guard shard.domain == routeDomain,
              shard.identity == routeIdentity,
              shard.source == routeSource,
              shard.inputSeed == routeInputSeed,
              shard.saveSeed == routeSaveSeed,
              shard.expectedDomains == routeExpectedDomains,
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("identity/source/seeds/expected domains/status do not match authored route")
        }
        return target
    }

    private static func loadTrace(_ url: URL) throws -> RawTrace {
        let bytes = try readData(url)
        guard bytes.count == expectedTraceSize else {
            throw ToolError.invalidHeader(url, "size is not 72 + 2*128")
        }
        do {
            let trace = try SM64OracleTraceFile.read(from: url)
            guard trace.records.count == 2 else {
                throw ToolError.wrongRecordCount(url.lastPathComponent, trace.records.count)
            }
            return RawTrace(
                url: url,
                bytes: bytes,
                configuration: trace.configuration,
                records: trace.records
            )
        } catch let error as ToolError {
            throw error
        } catch {
            throw ToolError.invalidTrace(url, error)
        }
    }

    private static func validateHeader(
        _ configuration: SM64OracleTraceConfiguration,
        label: String
    ) throws {
        let fields: [(String, UInt64, UInt64)] = [
            ("region_code", UInt64(expectedHeader.regionCode), UInt64(configuration.regionCode)),
            ("mode", UInt64(expectedHeader.mode.rawValue), UInt64(configuration.mode.rawValue)),
            ("build", expectedHeader.buildFingerprint, configuration.buildFingerprint),
            ("content", expectedHeader.contentFingerprint, configuration.contentFingerprint),
            ("timebase", expectedHeader.timebaseFingerprint, configuration.timebaseFingerprint),
            ("configuration", expectedHeader.configurationFingerprint, configuration.configurationFingerprint),
            ("initial_save", expectedHeader.initialSaveFingerprint, configuration.initialSaveFingerprint),
            ("coverage", expectedHeader.coverageFingerprint, configuration.coverageFingerprint),
        ]
        guard let mismatch = fields.first(where: { $0.1 != $0.2 }) else { return }
        throw ToolError.invalidHeader(
            URL(fileURLWithPath: label),
            String(format: "%@ expected 0x%016llx got 0x%016llx", mismatch.0, mismatch.1, mismatch.2)
        )
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        guard trace.records.count == 2 else {
            throw ToolError.wrongRecordCount(label, trace.records.count)
        }
        do {
            let window = try SM64IntroTransitionWindow(records: trace.records)
            guard window.traceRecords == trace.records else {
                throw ToolError.wrongRecord(label, 0, "Swift value mirror changed source bytes")
            }
        } catch let error as ToolError {
            throw error
        } catch {
            throw ToolError.wrongRecord(label, 0, String(describing: error))
        }
        for (index, record) in trace.records.enumerated() {
            guard record.simulationTick == expectedTicks[index],
                  record.sequence == expectedSequences[index],
                  record.canonicalHash == expectedHashes[index],
                  record.values == expectedValues[index] else {
                throw ToolError.wrongRecord(label, index, "source-authored tick/sequence/values/hash mismatch")
            }
        }
    }

    private static func requirePairReport(_ url: URL) throws {
        let report = try read(url)
        let markers = [
            "SM64 Modern authored intro transition route pair smoke passed exact_pair=1",
            "route_shard=0x9a0f7b4f7ecf6c41 source=levels/intro/script.c entry=level_intro_entry_1 steps=320",
            "native_transition_records=2 ticks=311,391 hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4",
            "c_swift_asan_release_rerun_byte_match=1 owner_thread=1",
            "intro_transition_debug_rerun_match=1",
            "intro_transition_asan_passed=1 debug_asan_trace_match=1",
            "intro_transition_release_passed=1 debug_release_trace_match=1",
            "intro_transition_swift_pair_bytes_match=1",
            "source_backed=1 direct_transition_call=0 synthesized_records=0 fixture_only=0",
        ]
        for marker in markers {
            guard report.contains(marker) else { throw ToolError.missingMarker(url, marker) }
        }
    }

    private static func requirePairProof(
        _ url: URL,
        traces: [(String, RawTrace)],
        pairReport: URL
    ) throws {
        let text = try read(url)
        let lines = text.split(whereSeparator: { $0.isNewline }).map(String.init)
        guard lines.first == "# sm64-intro-transition-pair-proof-v1" else {
            throw ToolError.invalidPairProof("invalid header")
        }
        var values: [String: String] = [:]
        for line in lines.dropFirst() {
            let fields = line.split(separator: "=", maxSplits: 1).map(String.init)
            guard fields.count == 2, values[fields[0]] == nil else {
                throw ToolError.invalidPairProof("malformed or duplicate field")
            }
            values[fields[0]] = fields[1]
        }
        let expected: [String: String] = [
            "route_shard": formatID(routeShardID),
            "source": routeSource,
            "input_seed": formatID(routeInputSeed),
            "save_seed": formatID(routeSaveSeed),
            "content_fingerprint": formatID(expectedHeader.contentFingerprint),
            "configuration_fingerprint": formatID(expectedHeader.configurationFingerprint),
            "coverage_fingerprint": formatID(expectedCoverage),
            "fixture_only": "0",
            "pair_report_sha256": try sha256(pairReport),
        ]
        for (key, expectedValue) in expected {
            guard values[key] == expectedValue else {
                throw ToolError.invalidPairProof("\(key) does not match source-authored pair")
            }
        }
        let hashKeys = ["c_trace_sha256", "swift_trace_sha256", "asan_trace_sha256", "release_trace_sha256", "rerun_trace_sha256"]
        let hashes = traces.map { sha256($0.1.bytes) }
        for (key, expectedHash) in zip(hashKeys, hashes) {
            guard values[key] == expectedHash else {
                throw ToolError.invalidPairProof("\(key) does not match trace bytes")
            }
        }
    }

    private static func requireMarkers(_ options: Options) throws {
        let markerPairs: [(URL, String)] = [
            (options.debugLog, "intro_transition_route_debug oracle_end=0 result_status=0"),
            (options.debugLog, "intro_transition_route_recorded shard=0x9a0f7b4f7ecf6c41"),
            (options.swiftLog, "intro_transition_pairing_audit admitted=1 c_records=2 swift_records=2"),
            (options.asanLog, "intro_transition_route_debug oracle_end=0 result_status=0"),
            (options.releaseLog, "intro_transition_route_debug oracle_end=0 result_status=0"),
            (options.rerunLog, "intro_transition_route_debug oracle_end=0 result_status=0"),
        ]
        for (url, marker) in markerPairs {
            let text = try read(url)
            guard text.contains(marker) else { throw ToolError.missingMarker(url, marker) }
        }
        let asan = try read(options.asanLog)
        if asan.contains("ERROR: AddressSanitizer")
            || asan.contains("AddressSanitizer: heap-")
            || asan.contains("AddressSanitizer: stack-")
            || asan.contains("AddressSanitizer: global-") {
            throw ToolError.sanitizerFinding(options.asanLog)
        }
    }

    private static func requireNoFixtureMarkers(_ options: Options) throws {
        let traces = [
            options.cTrace, options.swiftTrace, options.asanTrace,
            options.releaseTrace, options.rerunTrace,
        ]
        for trace in traces {
            let marker = URL(fileURLWithPath: trace.path + ".fixture_only")
            if FileManager.default.fileExists(atPath: marker.path) {
                throw ToolError.fixtureOnly(marker)
            }
        }
    }

    private static func rejectTamperedTrace(_ url: URL) throws {
        let data = try readData(url)
        do {
            _ = try SM64OracleTraceFile.read(from: url)
            _ = data
            throw ToolError.negativeAccepted("tampered", url)
        } catch ToolError.negativeAccepted {
            throw ToolError.negativeAccepted("tampered", url)
        } catch SM64OracleTraceCodecError.nonCanonicalHash {
            return
        } catch {
            throw ToolError.invalidTrace(url, error)
        }
    }

    private static func rejectWindowTrace(_ url: URL, kind: String) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ToolError.missingEvidence(url)
        }
        do {
            let trace = try loadTrace(url)
            try validateRecords(trace, label: kind)
            throw ToolError.negativeAccepted(kind, url)
        } catch ToolError.negativeAccepted {
            throw ToolError.negativeAccepted(kind, url)
        } catch {
            return
        }
    }

    private static func rejectPartialTrace(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ToolError.missingEvidence(url)
        }
        do {
            _ = try loadTrace(url)
            throw ToolError.negativeAccepted("partial", url)
        } catch ToolError.negativeAccepted {
            throw ToolError.negativeAccepted("partial", url)
        } catch {
            return
        }
    }

    private static func makeIsolatedReport(rows: [ManifestRow], target: ManifestRow) -> String {
        rows.sorted { $0.shard.id < $1.shard.id }.map { row in
            if row.shard.id == target.shard.id {
                return [formatID(row.shard.id), "passed", "2", "2", "2", ""].joined(separator: "|")
            }
            return [formatID(row.shard.id), "planned", "0", "0", "0", ""].joined(separator: "|")
        }.joined(separator: "\n") + "\n"
    }

    private static func validateIsolatedReport(
        _ report: String,
        rows: [ManifestRow],
        target: ManifestRow
    ) throws {
        let lines = report.split(whereSeparator: { $0.isNewline })
        guard lines.count == rows.count else {
            throw ToolError.invalidReport("expected \(rows.count) rows, got \(lines.count)")
        }
        let expectedIDs = Set(rows.map { $0.shard.id })
        var seen: Set<UInt64> = []
        var passed = 0
        for (index, line) in lines.enumerated() {
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 6,
                  let id = parseHex(fields[0]),
                  expectedIDs.contains(id),
                  seen.insert(id).inserted else {
                throw ToolError.invalidReport("line \(index + 1) has invalid or duplicate shard row")
            }
            guard let expected = UInt64(fields[2]),
                  let actual = UInt64(fields[3]),
                  let matched = UInt64(fields[4]) else {
                throw ToolError.invalidReport("line \(index + 1) has invalid evidence counts")
            }
            if id == target.shard.id {
                guard fields[1] == "passed", expected == 2, actual == 2, matched == 2, fields[5].isEmpty else {
                    throw ToolError.invalidReport("target row is not an exact two-record admission")
                }
                passed += 1
            } else if fields[1] != "planned" || expected != 0 || actual != 0 || matched != 0 || !fields[5].isEmpty {
                throw ToolError.invalidReport("non-target row was admitted or carried evidence")
            }
        }
        guard seen == expectedIDs, passed == 1 else {
            throw ToolError.invalidReport("report does not contain exactly one selected passed row")
        }
    }

    private static func makeProof(
        target: SM64RouteShard,
        reportHash: String,
        artifacts: [URL]
    ) throws -> String {
        guard !artifacts.isEmpty else { throw ToolError.invalidProof("no artifacts") }
        var fields = [
            formatID(target.id), target.domain, target.identity, "0", reportHash,
            String(artifacts.count),
        ]
        for artifact in artifacts {
            guard FileManager.default.fileExists(atPath: artifact.path) else {
                throw ToolError.missingEvidence(artifact)
            }
            fields.append(artifact.standardizedFileURL.path)
            fields.append(try sha256(artifact))
        }
        return [proofHeader, proofSchema, fields.joined(separator: "|")].joined(separator: "\n") + "\n"
    }

    private static func validateProof(
        _ proof: String,
        reportHash: String,
        target: SM64RouteShard,
        artifacts: [URL]
    ) throws {
        let lines = proof.split(whereSeparator: { $0.isNewline })
        guard lines.count == 3, lines[0] == proofHeader, lines[1] == proofSchema else {
            throw ToolError.invalidProof("invalid proof header")
        }
        let fields = lines[2].split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard fields.count == 6 + artifacts.count * 2,
              parseHex(fields[0]) == target.id,
              fields[1] == target.domain,
              fields[2] == target.identity,
              fields[3] == "0",
              fields[4] == reportHash,
              Int(fields[5]) == artifacts.count else {
            throw ToolError.invalidProof("target/report/artifact metadata mismatch")
        }
        for index in 0..<artifacts.count {
            let path = URL(fileURLWithPath: fields[6 + index * 2]).standardizedFileURL
            guard pathKey(path) == pathKey(artifacts[index]),
                  fields[7 + index * 2] == (try sha256(artifacts[index])) else {
                throw ToolError.invalidProof("artifact path/hash mismatch at index \(index)")
            }
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
            throw ToolError.unwritable(url, error)
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

    private static func pathKey(_ url: URL) -> String {
        url.resolvingSymlinksInPath().standardizedFileURL.path
    }

    private static func formatID(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }
}
