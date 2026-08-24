import Foundation

/// Admits the independent Phase 85z render-packet pair into a fresh,
/// isolated report.  The generated route manifest is immutable input; this
/// tool never mutates the manifest, cumulative history, or execution ledger.
/// GPU capture, attachment inspection, pixels, and visual acceptance remain
/// separate gates.
@main
struct SM64RenderPacketRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let manifestRowCount = 7_420
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize

    private struct Fingerprints: Equatable {
        let build: UInt64
        let content: UInt64
        let timebase: UInt64
        let configuration: UInt64
        let initialSave: UInt64
        let coverage: UInt64
    }

    private struct Spec {
        let shardID: UInt64
        let inputSeed: UInt64
        let saveSeed: UInt64
        let identity: String
        let domain: SM64RouteShardTraceDomain
        let cDomain: UInt32
        let recordKind: UInt32
        let ticks: [UInt64]
        let recordIDs: [UInt64]
        let sequences: [UInt32]
        let valueCounts: [Int]
        let fingerprints: Fingerprints

        var recordCount: Int { recordIDs.count }
    }

    private static let spec = Spec(
        shardID: 0x149f_e4b1_ab8a_36a5,
        inputSeed: 0x2cc8_dc5a_b422_8549,
        saveSeed: 0xbb82_f731_3b3d_4f96,
        identity: "render_packet",
        domain: .renderPacket,
        cDomain: 11,
        recordKind: 7,
        ticks: [1, 2],
        recordIDs: [2, 1, 3, 4, 2, 1, 3, 4],
        sequences: [0, 1, 2, 3, 0, 1, 2, 3],
        valueCounts: [5, 8, 5, 4, 5, 8, 5, 4],
        fingerprints: Fingerprints(
            build: 0x9f56_1a47_524b_e20a,
            content: 0xbedc_9ef1_ea15_f5b7,
            timebase: 0xccc1_9787_cd09_f0c2,
            configuration: 0x9bf5_b314_90c9_985b,
            initialSave: 0x00f3_f3d3_e3f6_0c24,
            coverage: 0x9ed3_bc93_9829_76e3
        )
    )

    private struct Options {
        let manifest: URL
        let cTrace: URL
        let swiftTrace: URL
        let asanTrace: URL
        let releaseTrace: URL
        let tamperedTrace: URL
        let debugLog: URL
        let swiftLog: URL
        let asanLog: URL
        let releaseLog: URL
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
        case wrongFingerprint(String, UInt64, UInt64)
        case wrongRecordCount(String, Int, Int)
        case wrongTickWindow(String, [UInt64], [UInt64])
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
            case let .invalidManifest(reason): return "invalid canonical route manifest: \(reason)"
            case let .wrongManifestRow(reason): return "canonical manifest row mismatch: \(reason)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidTrace(url, error): return "invalid trace \(url.path): \(error)"
            case let .invalidHeader(url, reason): return "invalid trace header \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift/ASan/Release header mismatch: \(field)"
            case let .wrongFingerprint(field, expected, actual):
                return String(format: "wrong canonical fingerprint %@: expected 0x%016llx got 0x%016llx", field, expected, actual)
            case let .wrongRecordCount(label, actual, expected):
                return "\(label) record count \(actual) is not \(expected)"
            case let .wrongTickWindow(label, actual, expected):
                return "\(label) tick window \(actual) is not exactly \(expected)"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch: return "independent C/Swift/ASan/Release trace bytes differ"
            case .singleTraceEvidence: return "C, Swift, ASan, Release, and tamper evidence must be distinct artifacts"
            case let .tamperAccepted(url): return "tampered trace was accepted: \(url.path)"
            case let .missingMarker(url, marker): return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .reportAlreadyExists(url): return "isolated admission report already exists; rerun rejected: \(url.path)"
            case let .reportCollision(url): return "isolated report collides with immutable evidence: \(url.path)"
            case let .reportInvalid(reason): return "isolated report validation failed: \(reason)"
            case let .unwritable(url, error): return "cannot write \(url.path): \(error)"
            }
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-render-packet-route-admit: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctEvidence(options)
        try requireFreshReport(options)

        let manifestText = try read(options.manifest)
        let rows = try parseManifest(manifestText)
        guard rows.count == manifestRowCount else {
            throw ToolError.invalidManifest("expected \(manifestRowCount) rows, got \(rows.count)")
        }
        let target = try resolveTarget(rows)

        try requireMarkers(options)
        let cTrace = try loadTrace(options.cTrace)
        let swiftTrace = try loadTrace(options.swiftTrace)
        let asanTrace = try loadTrace(options.asanTrace)
        let releaseTrace = try loadTrace(options.releaseTrace)
        try validateHeaders(cTrace.configuration, swiftTrace.configuration, label: "C/Swift")
        try validateHeaders(cTrace.configuration, asanTrace.configuration, label: "C/ASan")
        try validateHeaders(cTrace.configuration, releaseTrace.configuration, label: "C/Release")
        try validateCanonicalHeader(cTrace.configuration, label: "C")
        try validateCanonicalHeader(swiftTrace.configuration, label: "Swift")
        try validateCanonicalHeader(asanTrace.configuration, label: "ASan")
        try validateCanonicalHeader(releaseTrace.configuration, label: "Release")
        try validateRecords(cTrace, label: "C")
        try validateRecords(swiftTrace, label: "Swift")
        try validateRecords(asanTrace, label: "ASan")
        try validateRecords(releaseTrace, label: "Release")
        guard cTrace.bytes == swiftTrace.bytes,
              cTrace.bytes == asanTrace.bytes,
              cTrace.bytes == releaseTrace.bytes else {
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

        let reportLine = "SM64 render-packet route isolated admission passed "
            + "shard=\(formatID(spec.shardID)) records=\(spec.recordCount) "
            + "ticks=1,2 domain=\(spec.cDomain) kind=\(spec.recordKind) "
            + "manifest_rows=\(rows.count) report_rows=\(rows.count) passed_rows=1 "
            + "planned_rows=\(rows.count - 1) report=\(options.report.path) "
            + "c_trace=\(options.cTrace.path) swift_trace=\(options.swiftTrace.path) "
            + "asan_trace=\(options.asanTrace.path) release_trace=\(options.releaseTrace.path) "
            + "c_swift_asan_release_byte_match=1 tamper_rejected=1 "
            + "gpu_capture=separate pixel_acceptance=unverified visual_acceptance=unverified "
            + "fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1"
        print(reportLine)
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-render-packet-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --release-trace RELEASE_TRACE --tampered-trace TAMPERED_TRACE --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --release-log RELEASE_LOG --report REPORT"
        guard arguments.count == 22, arguments.count.isMultiple(of: 2) else {
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
            "--release-trace", "--tampered-trace", "--debug-log", "--swift-log",
            "--asan-log", "--release-log", "--report",
        ]
        guard values.count == known.count, values.keys.allSatisfy(known.contains) else {
            throw ToolError.invalidArguments(usage)
        }
        func url(_ key: String) -> URL {
            URL(fileURLWithPath: values[key]!).standardizedFileURL
        }
        return Options(
            manifest: url("--manifest"),
            cTrace: url("--c-trace"),
            swiftTrace: url("--swift-trace"),
            asanTrace: url("--asan-trace"),
            releaseTrace: url("--release-trace"),
            tamperedTrace: url("--tampered-trace"),
            debugLog: url("--debug-log"),
            swiftLog: url("--swift-log"),
            asanLog: url("--asan-log"),
            releaseLog: url("--release-log"),
            report: url("--report")
        )
    }

    private static func requireDistinctEvidence(_ options: Options) throws {
        let paths = [
            options.cTrace, options.swiftTrace, options.asanTrace,
            options.releaseTrace, options.tamperedTrace,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard Set(paths).count == paths.count else { throw ToolError.singleTraceEvidence }
        let reportPath = options.report.resolvingSymlinksInPath().standardizedFileURL.path
        let immutablePaths = [
            options.manifest, options.debugLog, options.swiftLog,
            options.asanLog, options.releaseLog,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard !paths.contains(reportPath), !immutablePaths.contains(reportPath) else {
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
        let matches = rows.filter { $0.shard.id == spec.shardID }
        guard matches.count == 1, let target = matches.first else {
            throw ToolError.wrongManifestRow(
                String(format: "expected one shard 0x%016llx, found %d", spec.shardID, matches.count)
            )
        }
        let shard = target.shard
        guard shard.domain == "oracle_hook",
              shard.identity == spec.identity,
              shard.source == "src/pc/sm64_modern_gameplay_parity.c",
              shard.inputSeed == spec.inputSeed,
              shard.saveSeed == spec.saveSeed,
              shard.expectedDomains == [spec.domain],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow(
                "identity/source/seeds/expected domain/status do not match render-packet route"
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

    private static func validateHeaders(
        _ first: SM64OracleTraceConfiguration,
        _ other: SM64OracleTraceConfiguration,
        label: String
    ) throws {
        guard first == other else {
            let fields: [(String, UInt64, UInt64)] = [
                ("build", first.buildFingerprint, other.buildFingerprint),
                ("content", first.contentFingerprint, other.contentFingerprint),
                ("timebase", first.timebaseFingerprint, other.timebaseFingerprint),
                ("configuration", first.configurationFingerprint, other.configurationFingerprint),
                ("initial_save", first.initialSaveFingerprint, other.initialSaveFingerprint),
                ("coverage", first.coverageFingerprint, other.coverageFingerprint),
            ]
            if let mismatch = fields.first(where: { $0.1 != $0.2 }) {
                throw ToolError.headerMismatch("\(label).\(mismatch.0)")
            }
            throw ToolError.headerMismatch("\(label).region_or_mode")
        }
    }

    private static func validateCanonicalHeader(
        _ configuration: SM64OracleTraceConfiguration,
        label: String
    ) throws {
        guard configuration.regionCode == 0x5553 else {
            throw ToolError.invalidHeader(URL(fileURLWithPath: label), "region code is not 0x5553")
        }
        guard configuration.mode == .record else {
            throw ToolError.invalidHeader(URL(fileURLWithPath: label), "mode is not record")
        }
        let actual = Fingerprints(
            build: configuration.buildFingerprint,
            content: configuration.contentFingerprint,
            timebase: configuration.timebaseFingerprint,
            configuration: configuration.configurationFingerprint,
            initialSave: configuration.initialSaveFingerprint,
            coverage: configuration.coverageFingerprint
        )
        let expected = spec.fingerprints
        let fields: [(String, UInt64, UInt64)] = [
            ("\(label).build", expected.build, actual.build),
            ("\(label).content", expected.content, actual.content),
            ("\(label).timebase", expected.timebase, actual.timebase),
            ("\(label).configuration", expected.configuration, actual.configuration),
            ("\(label).initial_save", expected.initialSave, actual.initialSave),
            ("\(label).coverage", expected.coverage, actual.coverage),
        ]
        for field in fields where field.1 != field.2 {
            throw ToolError.wrongFingerprint(field.0, field.1, field.2)
        }
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        guard trace.records.count == spec.recordCount else {
            throw ToolError.wrongRecordCount(label, trace.records.count, spec.recordCount)
        }
        let ticks = Array(Set(trace.records.map(\.simulationTick)).sorted())
        guard ticks == spec.ticks else {
            throw ToolError.wrongTickWindow(label, ticks, spec.ticks)
        }
        for (index, record) in trace.records.enumerated() {
            let expectedTick = index < 4 ? spec.ticks[0] : spec.ticks[1]
            guard record.simulationTick == expectedTick else {
                throw ToolError.wrongRecord(label, index, "tick \(record.simulationTick) is not \(expectedTick)")
            }
            guard record.domain == spec.cDomain, record.recordKind == spec.recordKind else {
                throw ToolError.wrongRecord(
                    label,
                    index,
                    "domain/kind \(record.domain)/\(record.recordKind) is not \(spec.cDomain)/\(spec.recordKind)"
                )
            }
            guard record.subjectID == 0, record.flags == 0 else {
                throw ToolError.wrongRecord(label, index, "subject/flags are not 0/0")
            }
            guard record.recordID == spec.recordIDs[index] else {
                throw ToolError.wrongRecord(
                    label,
                    index,
                    "record ID \(record.recordID) is not \(spec.recordIDs[index])"
                )
            }
            guard record.sequence == spec.sequences[index] else {
                throw ToolError.wrongRecord(
                    label,
                    index,
                    "sequence \(record.sequence) is not \(spec.sequences[index])"
                )
            }
            guard record.values.count == spec.valueCounts[index] else {
                throw ToolError.wrongRecord(
                    label,
                    index,
                    "value count \(record.values.count) is not \(spec.valueCounts[index])"
                )
            }
        }
    }

    private static func requireMarkers(_ options: Options) throws {
        let debugMarkers = [
            "c_render_packet_route_recorded shard=0x149fe4b1ab8a36a5 records=8 ticks=1,2 coverage=0x9ed3bc93982976e3 trace_fingerprint=0xbe06aea756ec0b08",
            "render_packet_route_debug oracle_end=0 result_status=0 failures=0 initialize=1 shutdown=1",
        ]
        let swiftMarkers = [
            "swift_render_packet_route_recorded shard=0x149fe4b1ab8a36a5 records=8 ticks=1,2 events=draw,frame_begin,frame_end,finish packets=2 coverage=0x9ed3bc93982976e3 trace_fingerprint=0xbe06aea756ec0b08",
            "render_packet_pairing_audit admitted=1 c_records=8 swift_records=8 blockers= first_divergence=none",
            "render_packet_pairing_tamper_rejected=1",
        ]
        let nativeMarkers = [
            "c_render_packet_route_recorded shard=0x149fe4b1ab8a36a5 records=8 ticks=1,2 coverage=0x9ed3bc93982976e3 trace_fingerprint=0xbe06aea756ec0b08",
            "render_packet_route_debug oracle_end=0 result_status=0 failures=0 initialize=1 shutdown=1",
        ]
        for marker in debugMarkers { try requireMarker(options.debugLog, marker) }
        for marker in swiftMarkers { try requireMarker(options.swiftLog, marker) }
        for marker in nativeMarkers {
            try requireMarker(options.asanLog, marker)
            try requireMarker(options.releaseLog, marker)
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
                return [
                    formatID(row.shard.id), "passed",
                    String(spec.recordCount), String(spec.recordCount),
                    String(spec.recordCount), "",
                ].joined(separator: "|")
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
                  seen.insert(id).inserted else {
                throw ToolError.reportInvalid("line \(index + 1) has invalid or duplicate shard row")
            }
            guard let expected = UInt64(fields[2]),
                  let actual = UInt64(fields[3]),
                  let matched = UInt64(fields[4]) else {
                throw ToolError.reportInvalid("line \(index + 1) has invalid evidence counts")
            }
            if id == target.shard.id {
                guard fields[1] == "passed",
                      expected == UInt64(spec.recordCount),
                      actual == expected,
                      matched == expected,
                      fields[5].isEmpty else {
                    throw ToolError.reportInvalid("target row is not an exact passed receipt")
                }
                passed += 1
            } else {
                guard fields[1] == "planned",
                      expected == 0,
                      actual == 0,
                      matched == 0,
                      fields[5].isEmpty else {
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
