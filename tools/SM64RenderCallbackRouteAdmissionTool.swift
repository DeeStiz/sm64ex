import Foundation

/// Admits the source-authored `render_callback|gfx_run` pair into a fresh,
/// isolated report.  The route manifest is immutable input: this tool never
/// writes the canonical manifest, execution ledger, or cumulative history.
/// GPU capture, attachment/pixel parity, physical presentation, and human
/// acceptance remain separate gates.
@main
struct SM64RenderCallbackRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let manifestRowCount = 7_420
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize

    private static let routeShardID: UInt64 = 0xd5a4_3d53_7c37_e833
    private static let routeInputSeed: UInt64 = 0xff27_9352_7bb5_fb03
    private static let routeSaveSeed: UInt64 = 0xc57d_3aed_0830_0d60
    private static let routeIdentity = "gfx_run"
    private static let sourceIdentity = "src/pc/gfx/gfx_pc.c:1783:gfx_run"
    private static let sourceFile = "src/pc/gfx/gfx_pc.c"
    private static let routeSubjectID: UInt64 = 0x5243_4c42_4746_5855
    private static let routeFlag: UInt32 = 0x5243_4c42
    private static let routeEventID: UInt64 = 6
    private static let routeDomain: UInt32 = 11
    private static let routeRecordKind: UInt32 = 3
    private static let routeTicks: [UInt64] = [2, 3]

    // Schema-4 fingerprints emitted by the independent Phase 85az pair.
    private static let expectedConfiguration = SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: 0x75f3_db98_c820_25b7,
        contentFingerprint: 0x9d10_90bd_054b_3ae8,
        timebaseFingerprint: 0xccc1_9787_cd09_f0c2,
        configurationFingerprint: 0x2562_7dd2_9fb4_e2ae,
        initialSaveFingerprint: 0x6d7f_7f58_ff6c_f325,
        coverageFingerprint: 0x2ac6_7fd8_751e_a32f
    )

    private struct Options {
        let manifest: URL
        let cTrace: URL
        let swiftTrace: URL
        let asanTrace: URL
        let releaseTrace: URL
        let rerunTrace: URL
        let tamperedTrace: URL
        let debugLog: URL
        let swiftLog: URL
        let asanLog: URL
        let releaseLog: URL
        let rerunLog: URL
        let report: URL
    }

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

    private enum ToolError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case unreadable(URL, Error)
        case invalidManifest(String)
        case wrongManifestRow(String)
        case missingEvidence(URL)
        case invalidTrace(URL, Error)
        case invalidHeader(URL, String)
        case headerMismatch(String)
        case wrongRecordCount(String, Int)
        case wrongTickWindow(String, [UInt64])
        case wrongRecord(String, Int, String)
        case recordBytesMismatch
        case singleTraceEvidence
        case tamperAccepted(URL)
        case missingMarker(URL, String)
        case sanitizerFinding(URL)
        case reportAlreadyExists(URL)
        case reportCollision(URL)
        case reportInvalid(String)
        case unwritable(URL, Error)

        var description: String {
            switch self {
            case let .invalidArguments(message): return message
            case let .unreadable(url, error): return "cannot read \(url.path): \(error)"
            case let .invalidManifest(reason): return "invalid route manifest: \(reason)"
            case let .wrongManifestRow(reason): return "render-callback manifest row mismatch: \(reason)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidTrace(url, error): return "invalid trace \(url.path): \(error)"
            case let .invalidHeader(url, reason): return "invalid trace header \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift/ASan/Release/rerun header mismatch: \(field)"
            case let .wrongRecordCount(label, count): return "\(label) record count \(count) is not 2"
            case let .wrongTickWindow(label, ticks): return "\(label) tick window \(ticks) is not exactly [2, 3]"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch: return "independent C/Swift/ASan/Release/rerun trace bytes differ"
            case .singleTraceEvidence: return "C, Swift, ASan, Release, rerun, and tamper evidence must be distinct artifacts"
            case let .tamperAccepted(url): return "tampered trace was accepted: \(url.path)"
            case let .missingMarker(url, marker): return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .reportAlreadyExists(url): return "isolated admission report already exists; rerun rejected: \(url.path)"
            case .reportCollision: return "isolated report collides with immutable evidence"
            case let .reportInvalid(reason): return "isolated report validation failed: \(reason)"
            case let .unwritable(url, error): return "cannot write \(url.path): \(error)"
            }
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-render-callback-route-admit: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctEvidence(options)
        try requireFreshReport(options)

        let rows = try parseManifest(try read(options.manifest))
        guard rows.count == manifestRowCount else {
            throw ToolError.invalidManifest("expected \(manifestRowCount) rows, got \(rows.count)")
        }
        let target = try resolveTarget(rows)
        try requireMarkers(options)

        let cTrace = try loadTrace(options.cTrace)
        let swiftTrace = try loadTrace(options.swiftTrace)
        let asanTrace = try loadTrace(options.asanTrace)
        let releaseTrace = try loadTrace(options.releaseTrace)
        let rerunTrace = try loadTrace(options.rerunTrace)
        try validateHeaders(cTrace.configuration, swiftTrace.configuration, label: "C/Swift")
        try validateHeaders(cTrace.configuration, asanTrace.configuration, label: "C/ASan")
        try validateHeaders(cTrace.configuration, releaseTrace.configuration, label: "C/Release")
        try validateHeaders(cTrace.configuration, rerunTrace.configuration, label: "C/rerun")

        for (label, trace) in [
            ("C", cTrace), ("Swift", swiftTrace), ("ASan", asanTrace),
            ("Release", releaseTrace), ("rerun", rerunTrace),
        ] {
            try validateCanonicalHeader(trace.configuration, label: label)
            try validateRecords(trace, label: label)
        }
        guard cTrace.bytes == swiftTrace.bytes,
              cTrace.bytes == asanTrace.bytes,
              cTrace.bytes == releaseTrace.bytes,
              cTrace.bytes == rerunTrace.bytes else {
            throw ToolError.recordBytesMismatch
        }
        try rejectTamperedTrace(options.tamperedTrace)

        let reportText = makeIsolatedReport(rows: rows, target: target)
        try validateIsolatedReport(reportText, rows: rows, target: target)
        do {
            try FileManager.default.createDirectory(
                at: options.report.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(reportText.utf8).write(to: options.report, options: .atomic)
        } catch {
            throw ToolError.unwritable(options.report, error)
        }

        print(
            "SM64 render-callback route isolated admission passed "
                + "shard=\(formatID(routeShardID)) identity=\(sourceIdentity) "
                + "callback=\(routeIdentity) records=2 ticks=2,3 "
                + "domain=\(routeDomain) kind=\(routeRecordKind) schema=4 "
                + "manifest_rows=\(rows.count) report_rows=\(rows.count) passed_rows=1 "
                + "planned_rows=\(rows.count - 1) report=\(options.report.path) "
                + "c_swift_asan_release_rerun_byte_match=1 tamper_rejected=1 "
                + "gpu_capture=separate pixel_acceptance=unverified "
                + "physical_presentation=unverified human_acceptance=unverified "
                + "fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 "
                + "history_mutated=0 rerun_fence=1"
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-render-callback-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --release-trace RELEASE_TRACE --rerun-trace RERUN_TRACE --tampered-trace TAMPERED_TRACE --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --release-log RELEASE_LOG --rerun-log RERUN_LOG --report REPORT"
        guard arguments.count == 26, arguments.count.isMultiple(of: 2) else {
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
            "--debug-log", "--swift-log", "--asan-log", "--release-log",
            "--rerun-log", "--report",
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
            tamperedTrace: url("--tampered-trace"), debugLog: url("--debug-log"),
            swiftLog: url("--swift-log"), asanLog: url("--asan-log"),
            releaseLog: url("--release-log"), rerunLog: url("--rerun-log"),
            report: url("--report")
        )
    }

    private static func requireDistinctEvidence(_ options: Options) throws {
        let evidence = [
            options.cTrace, options.swiftTrace, options.asanTrace,
            options.releaseTrace, options.rerunTrace, options.tamperedTrace,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard Set(evidence).count == evidence.count else {
            throw ToolError.singleTraceEvidence
        }
        let immutable = [
            options.manifest, options.debugLog, options.swiftLog,
            options.asanLog, options.releaseLog, options.rerunLog,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        let report = options.report.resolvingSymlinksInPath().standardizedFileURL.path
        guard !evidence.contains(report), !immutable.contains(report) else {
            throw ToolError.reportCollision(options.report)
        }
    }

    private static func requireFreshReport(_ options: Options) throws {
        guard !FileManager.default.fileExists(atPath: options.report.path) else {
            throw ToolError.reportAlreadyExists(options.report)
        }
    }

    private static func read(_ url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
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
        return rows
    }

    private static func resolveTarget(_ rows: [ManifestRow]) throws -> ManifestRow {
        let matches = rows.filter { $0.shard.id == routeShardID }
        guard matches.count == 1, let target = matches.first else {
            throw ToolError.wrongManifestRow(
                String(format: "expected one shard 0x%016llx, found %d", routeShardID, matches.count)
            )
        }
        let shard = target.shard
        guard shard.domain == "render_callback",
              shard.identity == routeIdentity,
              shard.source == sourceFile,
              shard.inputSeed == routeInputSeed,
              shard.saveSeed == routeSaveSeed,
              shard.expectedDomains == [.renderPacket],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow(
                "identity/source/seeds/expected domain/status do not match gfx_run"
            )
        }
        return target
    }

    private static func loadTrace(_ url: URL) throws -> RawTrace {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ToolError.missingEvidence(url)
        }
        do {
            let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
            guard bytes.count >= traceHeaderSize,
                  (bytes.count - traceHeaderSize).isMultiple(of: traceRecordSize) else {
                throw ToolError.invalidHeader(url, "size is not 72 + N*128")
            }
            let trace = try SM64OracleTraceFile.read(from: url)
            guard bytes.count == traceHeaderSize + trace.records.count * traceRecordSize else {
                throw ToolError.invalidHeader(url, "decoded record count does not cover complete artifact")
            }
            return RawTrace(
                url: url, bytes: bytes,
                configuration: trace.configuration, records: trace.records
            )
        } catch let error as ToolError {
            throw error
        } catch {
            throw ToolError.invalidTrace(url, error)
        }
    }

    private static func validateHeaders(
        _ first: SM64OracleTraceConfiguration,
        _ other: SM64OracleTraceConfiguration,
        label: String
    ) throws {
        guard first == other else {
            throw ToolError.headerMismatch(label)
        }
    }

    private static func validateCanonicalHeader(
        _ configuration: SM64OracleTraceConfiguration,
        label: String
    ) throws {
        guard configuration == expectedConfiguration else {
            throw ToolError.invalidHeader(
                URL(fileURLWithPath: label),
                "schema-4 region/mode/fingerprint tuple differs from gfx_run pair"
            )
        }
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        guard trace.records.count == 2 else {
            throw ToolError.wrongRecordCount(label, trace.records.count)
        }
        let ticks = trace.records.map(\.simulationTick)
        guard ticks == routeTicks else {
            throw ToolError.wrongTickWindow(label, ticks)
        }
        for (index, record) in trace.records.enumerated() {
            let expectedValues: [UInt64] = [
                UInt64(index + 1), 1, routeSubjectID, routeTicks[index],
            ]
            guard record.domain == routeDomain,
                  record.recordKind == routeRecordKind,
                  record.subjectID == routeSubjectID,
                  record.recordID == routeEventID,
                  record.sequence == 0,
                  record.flags == routeFlag,
                  record.values == expectedValues else {
                throw ToolError.wrongRecord(label, index, "source/callback identity or values differ")
            }
        }
    }

    private static func requireMarkers(_ options: Options) throws {
        let cRecord = "c_render_callback_route_recorded shard=0xd5a43d537c37e833 identity=\(sourceIdentity) records=2 ticks=2,3 commands_present=1 coverage=0x2ac67fd8751ea32f trace_fingerprint=0x1847d5028b4a5b02"
        let cEnd = "render_callback_route_debug oracle_end=0 result_status=0 failures=0 invocations=2 backend_starts=2 backend_finishes=2"
        let swiftRecord = "swift_render_callback_route_recorded shard=0xd5a43d537c37e833 identity=\(sourceIdentity) records=2 ticks=2,3 commands_present=1 coverage=0x2ac67fd8751ea32f input_seed=0xff2793527bb5fb03 save_seed=0xc57d3aed08300d60"
        let swiftPair = "render_callback_pairing_audit admitted=1 c_records=2 swift_records=2 blockers= first_divergence=none"
        let swiftTamper = "render_callback_pairing_tamper_rejected=1"
        try requireMarker(options.debugLog, cRecord)
        try requireMarker(options.debugLog, cEnd)
        try requireMarker(options.swiftLog, swiftRecord)
        try requireMarker(options.swiftLog, swiftPair)
        try requireMarker(options.swiftLog, swiftTamper)
        for log in [options.asanLog, options.releaseLog, options.rerunLog] {
            try requireMarker(log, cRecord)
            try requireMarker(log, cEnd)
        }
        try rejectSanitizerFindings(in: options.asanLog)
    }

    private static func requireMarker(_ url: URL, _ marker: String) throws {
        let contents = try read(url)
        guard contents.contains(marker) else {
            throw ToolError.missingMarker(url, marker)
        }
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
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ToolError.missingEvidence(url)
        }
        do {
            _ = try SM64OracleTraceFile.read(from: url)
            throw ToolError.tamperAccepted(url)
        } catch ToolError.tamperAccepted {
            throw ToolError.tamperAccepted(url)
        } catch SM64OracleTraceCodecError.nonCanonicalHash {
            return
        } catch {
            throw ToolError.invalidTrace(url, error)
        }
    }

    private static func makeIsolatedReport(
        rows: [ManifestRow],
        target: ManifestRow
    ) -> String {
        rows.sorted { $0.shard.id < $1.shard.id }.map { row in
            if row.shard.id == target.shard.id {
                return [formatID(row.shard.id), "passed", "2", "2", "2", ""].joined(separator: "|")
            }
            return [formatID(row.shard.id), "planned", "0", "0", "0", ""].joined(separator: "|")
        }.joined(separator: "\n") + "\n"
    }

    private static func validateIsolatedReport(
        _ text: String,
        rows: [ManifestRow],
        target: ManifestRow
    ) throws {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count == rows.count else {
            throw ToolError.reportInvalid("expected \(rows.count) rows, got \(lines.count)")
        }
        let expectedIDs = Set(rows.map { $0.shard.id })
        var seen: Set<UInt64> = []
        var passed = 0
        for (index, line) in lines.enumerated() {
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 6,
                  let id = parseHex(fields[0]),
                  expectedIDs.contains(id),
                  seen.insert(id).inserted,
                  let expected = UInt64(fields[2]),
                  let actual = UInt64(fields[3]),
                  let matched = UInt64(fields[4]) else {
                throw ToolError.reportInvalid("line \(index + 1) has invalid or duplicate shard row")
            }
            if id == target.shard.id {
                guard fields[1] == "passed", expected == 2,
                      actual == expected, matched == expected, fields[5].isEmpty else {
                    throw ToolError.reportInvalid("target row is not an exact passed receipt")
                }
                passed += 1
            } else {
                guard fields[1] == "planned", expected == 0,
                      actual == 0, matched == 0, fields[5].isEmpty else {
                    throw ToolError.reportInvalid("non-target row was admitted or carried evidence")
                }
            }
        }
        guard seen == expectedIDs, passed == 1 else {
            throw ToolError.reportInvalid("report does not contain exactly one selected passed row")
        }
    }

    private static func parseHex(_ value: String) -> UInt64? {
        guard value.hasPrefix("0x") else { return nil }
        return UInt64(value.dropFirst(2), radix: 16)
    }

    private static func formatID(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }
}
