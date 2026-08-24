import Foundation

/// Admits exactly one of the Phase 85v source-backed oracle-hook rows from
/// independent C, Swift, ASan, and optimized artifacts.  The generated
/// manifest is immutable input; this tool writes only a fresh, isolated
/// six-field report that a later canonical merge may consume.
@main
struct SM64AudioSaveRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let manifestRowCount = 7_420
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize
    private static let saveImageByteCount = 512

    private struct Fingerprints: Equatable {
        let build: UInt64
        let content: UInt64
        let timebase: UInt64
        let configuration: UInt64
        let initialSave: UInt64
        let coverage: UInt64
    }

    private struct Spec {
        let route: Route
        let shardID: UInt64
        let inputSeed: UInt64
        let saveSeed: UInt64
        let identity: String
        let expectedDomain: SM64RouteShardTraceDomain
        let cDomain: UInt32
        let recordKind: UInt32
        let ticks: [UInt64]
        let recordIDs: [UInt64]
        let sequences: [UInt32]
        let valueCounts: [Int]
        let fingerprints: Fingerprints
        let debugMarkers: [String]
        let swiftMarkers: [String]
        let asanMarkers: [String]
        let releaseMarkers: [String]
        let sidecarRequired: Bool

        var recordCount: Int { recordIDs.count }

        var tickDescription: String {
            ticks.map(String.init).joined(separator: ",")
        }
    }

    private enum Route: String {
        case audioSequence = "audio_sequence"
        case saveBytes = "save_bytes"

        var spec: Spec {
            switch self {
            case .audioSequence:
                return Spec(
                    route: self,
                    shardID: 0xbe18_4196_f54f_8216,
                    inputSeed: 0xd964_e1a5_4e05_5922,
                    saveSeed: 0x492d_cd21_fdb2_e9bb,
                    identity: "audio_sequence",
                    expectedDomain: .audioSequence,
                    cDomain: 9,
                    recordKind: 3,
                    ticks: [2],
                    recordIDs: [1, 2, 3, 2],
                    sequences: [0, 1, 2, 3],
                    valueCounts: [3, 5, 5, 5],
                    fingerprints: Fingerprints(
                        build: 0xbe9e_8366_e00d_1a4f,
                        content: 0x26d9_5a3e_f2b9_d004,
                        timebase: 0xccc1_9787_cd09_f0c2,
                        configuration: 0xcf27_0564_86fa_67b2,
                        initialSave: 0xeaee_1d70_b9ab_8325,
                        coverage: 0x52a4_ce92_e257_cc89
                    ),
                    debugMarkers: [
                        "audio_sequence_route_init status=0 oracle=0 parity=0",
                        "audio_sequence_route_step index=0 status=0 oracle=0 parity=0",
                        "audio_sequence_route_step index=1 status=0 oracle=0 parity=0",
                        "audio_sequence_route_debug oracle_end=0 result_status=0 actual=",
                        "retained=4 observer=4 failures=0 ticks=1",
                        "c_audio_sequence_route_recorded shard=0xbe184196f54f8216",
                        "records=4 ticks=2,2 event_counts=1,2,1,0 coverage=0x52a4ce92e257cc89",
                    ],
                    swiftMarkers: [
                        "swift_audio_sequence_route_recorded records=4 ticks=2 event_ids=1,2,3 coverage=0x52a4ce92e257cc89",
                        "audio_sequence_pairing_audit admitted=1 c_records=4 swift_records=4 blockers= first_divergence=none",
                        "audio_sequence_pairing_tamper_rejected=1",
                    ],
                    asanMarkers: [
                        "audio_sequence_route_debug oracle_end=0 result_status=0",
                        "c_audio_sequence_route_recorded shard=0xbe184196f54f8216",
                        "records=4 ticks=2,2 event_counts=1,2,1,0 coverage=0x52a4ce92e257cc89",
                    ],
                    releaseMarkers: [
                        "audio_sequence_route_debug oracle_end=0 result_status=0",
                        "c_audio_sequence_route_recorded shard=0xbe184196f54f8216",
                        "records=4 ticks=2,2 event_counts=1,2,1,0 coverage=0x52a4ce92e257cc89",
                    ],
                    sidecarRequired: false
                )
            case .saveBytes:
                return Spec(
                    route: self,
                    shardID: 0x4e55_5253_3aaa_717d,
                    inputSeed: 0x12dc_5912_6350_0891,
                    saveSeed: 0x5b8d_ebd6_6893_37ce,
                    identity: "save_bytes",
                    expectedDomain: .saveBytes,
                    cDomain: 10,
                    recordKind: 6,
                    ticks: [2, 3],
                    recordIDs: [1, 2, 3, 4],
                    sequences: [0, 1, 2, 0],
                    valueCounts: [3, 3, 3, 3],
                    fingerprints: Fingerprints(
                        build: 0xde62_ef55_29de_3212,
                        content: 0x1581_0073_75b0_60db,
                        timebase: 0xccc1_9787_cd09_f0c2,
                        configuration: 0xa58a_3850_3945_4b06,
                        initialSave: 0xdf67_c055_5ff9_92ac,
                        coverage: 0x5717_7b65_bc11_e1e3
                    ),
                    debugMarkers: [
                        "save_bytes_route_init status=0 oracle=0 parity=0",
                        "save_bytes_route_step index=0 status=0 oracle=0 parity=0",
                        "save_bytes_route_step index=1 status=0 oracle=0 parity=0",
                        "save_bytes_route_debug oracle_end=0 result_status=0 actual=",
                        "retained=4 failures=0 ticks=2 input_calls=",
                        "c_save_bytes_route_recorded shard=0x4e5552533aaa717d",
                        "records=4 ticks=3 event_counts=1,1,1,1 coverage=0x57177b65bc11e1e3",
                        "image_bytes=512",
                    ],
                    swiftMarkers: [
                        "swift_save_bytes_route_recorded shard=0x4e5552533aaa717d records=4 ticks=2,3 event_ids=1,2,3,4",
                        "save_bytes_pairing_audit admitted=1 c_records=4 swift_records=4 blockers= first_divergence=none",
                        "save_bytes_pairing_tamper_rejected=1",
                    ],
                    asanMarkers: [
                        "save_bytes_route_debug oracle_end=0 result_status=0",
                        "c_save_bytes_route_recorded shard=0x4e5552533aaa717d",
                        "records=4 ticks=3 event_counts=1,1,1,1 coverage=0x57177b65bc11e1e3",
                        "image_bytes=512",
                    ],
                    releaseMarkers: [
                        "save_bytes_route_debug oracle_end=0 result_status=0",
                        "c_save_bytes_route_recorded shard=0x4e5552533aaa717d",
                        "records=4 ticks=3 event_counts=1,1,1,1 coverage=0x57177b65bc11e1e3",
                        "image_bytes=512",
                    ],
                    sidecarRequired: true
                )
            }
        }
    }

    private struct Options {
        let spec: Spec
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
        let cSidecar: URL?
        let asanSidecar: URL?
        let releaseSidecar: URL?
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

    private struct SidecarRecord: Equatable {
        let tick: UInt64
        let recordID: UInt64
        let subjectID: UInt64
        let byteCount: UInt64
        let imageHash: UInt64
        let modifiedFlags: UInt64
        let image: [UInt8]
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
        case sidecarMismatch(String)
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
            case let .invalidHeader(url, reason): return "invalid artifact header \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift/ASan/Release header mismatch: \(field)"
            case let .wrongFingerprint(field, expected, actual):
                return String(format: "wrong canonical fingerprint %@: expected 0x%016llx got 0x%016llx", field, expected, actual)
            case let .wrongRecordCount(label, actual, expected): return "\(label) record count \(actual) is not \(expected)"
            case let .wrongTickWindow(label, actual, expected): return "\(label) tick window \(actual) is not \(expected)"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch: return "independent C/Swift/ASan/Release trace bytes differ"
            case .singleTraceEvidence: return "C, Swift, ASan, Release, and tamper evidence must be distinct artifacts"
            case let .tamperAccepted(url): return "tampered trace was accepted: \(url.path)"
            case let .missingMarker(url, marker): return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .sidecarMismatch(reason): return "save sidecar mismatch: \(reason)"
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
            FileHandle.standardError.write(Data(("sm64-audio-save-route-admit: \(error)\n").utf8))
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
        let target = try resolveTarget(rows, spec: options.spec)

        try requireMarkers(options)
        let cTrace = try loadTrace(options.cTrace)
        let swiftTrace = try loadTrace(options.swiftTrace)
        let asanTrace = try loadTrace(options.asanTrace)
        let releaseTrace = try loadTrace(options.releaseTrace)
        try validateHeaders(cTrace.configuration, swiftTrace.configuration, label: "C/Swift")
        try validateHeaders(cTrace.configuration, asanTrace.configuration, label: "C/ASan")
        try validateHeaders(cTrace.configuration, releaseTrace.configuration, label: "C/Release")
        try validateCanonicalHeader(cTrace.configuration, spec: options.spec, label: "C")
        try validateCanonicalHeader(swiftTrace.configuration, spec: options.spec, label: "Swift")
        try validateCanonicalHeader(asanTrace.configuration, spec: options.spec, label: "ASan")
        try validateCanonicalHeader(releaseTrace.configuration, spec: options.spec, label: "Release")
        try validateRecords(cTrace, spec: options.spec, label: "C")
        try validateRecords(swiftTrace, spec: options.spec, label: "Swift")
        try validateRecords(asanTrace, spec: options.spec, label: "ASan")
        try validateRecords(releaseTrace, spec: options.spec, label: "Release")
        guard cTrace.bytes == swiftTrace.bytes,
              cTrace.bytes == asanTrace.bytes,
              cTrace.bytes == releaseTrace.bytes else {
            throw ToolError.recordBytesMismatch
        }
        if options.spec.sidecarRequired {
            guard let cURL = options.cSidecar,
                  let asanURL = options.asanSidecar,
                  let releaseURL = options.releaseSidecar else {
                throw ToolError.sidecarMismatch("all three sidecars are required")
            }
            let cData = try readData(cURL)
            let asanData = try readData(asanURL)
            let releaseData = try readData(releaseURL)
            guard cData == asanData, cData == releaseData else {
                throw ToolError.sidecarMismatch("C, ASan, and Release bytes differ")
            }
            let sidecar = try readSidecar(cURL)
            try validateSidecar(sidecar, against: cTrace, label: "C")
            try validateSidecar(try readSidecar(asanURL), against: asanTrace, label: "ASan")
            try validateSidecar(try readSidecar(releaseURL), against: releaseTrace, label: "Release")
        } else if options.cSidecar != nil || options.asanSidecar != nil || options.releaseSidecar != nil {
            throw ToolError.sidecarMismatch("audio_sequence must not carry save sidecars")
        }
        try rejectTamperedTrace(options.tamperedTrace)

        let reportText = makeIsolatedReport(rows: rows, target: target, spec: options.spec)
        try validateIsolatedReport(reportText, rows: rows, target: target, spec: options.spec)
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
            String(
                format: "SM64 %@ route isolated admission passed shard=0x%016llx records=%d ticks=%@ domain=%u kind=%u manifest_rows=%d report_rows=%d passed_rows=1 planned_rows=%d report=%@ c_trace=%@ swift_trace=%@ asan_trace=%@ release_trace=%@ tamper_rejected=1 sidecar_match=%d fixture_only=0 effects_admitted=0 unpaired_rows_admitted=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1",
                options.spec.route.rawValue,
                options.spec.shardID,
                cTrace.records.count,
                options.spec.tickDescription,
                options.spec.cDomain,
                options.spec.recordKind,
                rows.count,
                rows.count,
                rows.count - 1,
                options.report.path,
                options.cTrace.path,
                options.swiftTrace.path,
                options.asanTrace.path,
                options.releaseTrace.path,
                options.spec.sidecarRequired ? 1 : 0
            )
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-audio-save-route-admit --route audio_sequence|save_bytes --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --release-trace RELEASE_TRACE --tampered-trace TAMPERED_TRACE --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --release-log RELEASE_LOG [--c-sidecar C_SIDECAR --asan-sidecar ASAN_SIDECAR --release-sidecar RELEASE_SIDECAR] --report REPORT"
        guard arguments.count.isMultiple(of: 2) else { throw ToolError.invalidArguments(usage) }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let key = arguments[index]
            let value = arguments[index + 1]
            guard key.hasPrefix("--"), values[key] == nil else { throw ToolError.invalidArguments(usage) }
            values[key] = value
            index += 2
        }
        let required: Set<String> = [
            "--route", "--manifest", "--c-trace", "--swift-trace", "--asan-trace",
            "--release-trace", "--tampered-trace", "--debug-log", "--swift-log",
            "--asan-log", "--release-log", "--report",
        ]
        let optional: Set<String> = ["--c-sidecar", "--asan-sidecar", "--release-sidecar"]
        guard required.isSubset(of: Set(values.keys)), Set(values.keys).isSubset(of: required.union(optional)),
              let routeValue = values["--route"], let route = Route(rawValue: routeValue) else {
            throw ToolError.invalidArguments(usage)
        }
        let spec = route.spec
        let sidecarValues = optional.compactMap { values[$0] }
        if spec.sidecarRequired {
            guard sidecarValues.count == optional.count else { throw ToolError.invalidArguments(usage) }
        } else {
            guard sidecarValues.isEmpty else { throw ToolError.invalidArguments(usage) }
        }
        func url(_ key: String) -> URL {
            URL(fileURLWithPath: values[key]!).standardizedFileURL
        }
        func optionalURL(_ key: String) -> URL? {
            values[key].map { URL(fileURLWithPath: $0).standardizedFileURL }
        }
        return Options(
            spec: spec,
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
            cSidecar: optionalURL("--c-sidecar"),
            asanSidecar: optionalURL("--asan-sidecar"),
            releaseSidecar: optionalURL("--release-sidecar"),
            report: url("--report")
        )
    }

    private static func requireDistinctEvidence(_ options: Options) throws {
        var paths = [
            options.cTrace, options.swiftTrace, options.asanTrace,
            options.releaseTrace, options.tamperedTrace,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        if let cSidecar = options.cSidecar { paths.append(cSidecar.resolvingSymlinksInPath().standardizedFileURL.path) }
        if let asanSidecar = options.asanSidecar { paths.append(asanSidecar.resolvingSymlinksInPath().standardizedFileURL.path) }
        if let releaseSidecar = options.releaseSidecar { paths.append(releaseSidecar.resolvingSymlinksInPath().standardizedFileURL.path) }
        guard Set(paths).count == paths.count else { throw ToolError.singleTraceEvidence }
        let reportPath = options.report.resolvingSymlinksInPath().standardizedFileURL.path
        let immutablePaths = paths + [options.manifest, options.debugLog, options.swiftLog, options.asanLog, options.releaseLog]
            .map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard !immutablePaths.contains(reportPath) else { throw ToolError.reportCollision(options.report) }
    }

    private static func requireFreshReport(_ options: Options) throws {
        guard !FileManager.default.fileExists(atPath: options.report.path) else {
            throw ToolError.reportAlreadyExists(options.report)
        }
    }

    private static func read(_ url: URL) throws -> String {
        do { return try String(contentsOf: url, encoding: .utf8) }
        catch { throw ToolError.unreadable(url, error) }
    }

    private static func readData(_ url: URL) throws -> Data {
        guard FileManager.default.fileExists(atPath: url.path) else { throw ToolError.missingEvidence(url) }
        do { return try Data(contentsOf: url, options: .mappedIfSafe) }
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

    private static func resolveTarget(_ rows: [ManifestRow], spec: Spec) throws -> ManifestRow {
        let matches = rows.filter { $0.shard.id == spec.shardID }
        guard matches.count == 1, let target = matches.first else {
            throw ToolError.wrongManifestRow(String(format: "expected one shard 0x%016llx, found %d", spec.shardID, matches.count))
        }
        let shard = target.shard
        guard shard.domain == "oracle_hook",
              shard.identity == spec.identity,
              shard.source == "src/pc/sm64_modern_gameplay_parity.c",
              shard.inputSeed == spec.inputSeed,
              shard.saveSeed == spec.saveSeed,
              shard.expectedDomains == [spec.expectedDomain],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("identity/source/seeds/expected domain/status do not match selected route")
        }
        return target
    }

    private static func requireMarkers(_ options: Options) throws {
        for marker in options.spec.debugMarkers { try requireMarker(options.debugLog, marker) }
        for marker in options.spec.swiftMarkers { try requireMarker(options.swiftLog, marker) }
        for marker in options.spec.asanMarkers { try requireMarker(options.asanLog, marker) }
        for marker in options.spec.releaseMarkers { try requireMarker(options.releaseLog, marker) }
        try rejectSanitizerFindings(in: options.asanLog)
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

    private static func loadTrace(_ url: URL) throws -> RawTrace {
        guard FileManager.default.fileExists(atPath: url.path) else { throw ToolError.missingEvidence(url) }
        do {
            let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
            guard bytes.count >= traceHeaderSize,
                  (bytes.count - traceHeaderSize).isMultiple(of: traceRecordSize) else {
                throw ToolError.invalidHeader(url, "size is not 72 + N*128")
            }
            let trace = try SM64OracleTraceFile.read(from: url)
            guard bytes.count == traceHeaderSize + trace.records.count * traceRecordSize else {
                throw ToolError.invalidHeader(url, "decoded records do not cover complete artifact")
            }
            return RawTrace(url: url, bytes: bytes, configuration: trace.configuration, records: trace.records)
        } catch let error as ToolError { throw error }
        catch { throw ToolError.invalidTrace(url, error) }
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
        spec: Spec,
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

    private static func validateRecords(_ trace: RawTrace, spec: Spec, label: String) throws {
        guard trace.records.count == spec.recordCount else {
            throw ToolError.wrongRecordCount(label, trace.records.count, spec.recordCount)
        }
        let observedTicks = Array(Set(trace.records.map(\.simulationTick)).sorted())
        guard observedTicks == spec.ticks else {
            throw ToolError.wrongTickWindow(label, observedTicks, spec.ticks)
        }
        for (index, record) in trace.records.enumerated() {
            guard record.simulationTick == expectedTick(for: index, spec: spec) else {
                throw ToolError.wrongRecord(label, index, "tick \(record.simulationTick) is not \(expectedTick(for: index, spec: spec))")
            }
            guard record.domain == spec.cDomain, record.recordKind == spec.recordKind else {
                throw ToolError.wrongRecord(label, index, "domain/kind \(record.domain)/\(record.recordKind) is not \(spec.cDomain)/\(spec.recordKind)")
            }
            guard record.subjectID == 0, record.flags == 0 else {
                throw ToolError.wrongRecord(label, index, "subject/flags \(record.subjectID)/\(record.flags) are not 0/0")
            }
            guard record.recordID == spec.recordIDs[index] else {
                throw ToolError.wrongRecord(label, index, "record ID \(record.recordID) is not \(spec.recordIDs[index])")
            }
            guard record.sequence == spec.sequences[index] else {
                throw ToolError.wrongRecord(label, index, "sequence \(record.sequence) is not \(spec.sequences[index])")
            }
            guard record.values.count == spec.valueCounts[index] else {
                throw ToolError.wrongRecord(label, index, "value count \(record.values.count) is not \(spec.valueCounts[index])")
            }
            if spec.sidecarRequired {
                guard record.values.count == 3, record.values[0] == UInt64(saveImageByteCount) else {
                    throw ToolError.wrongRecord(label, index, "save image byte count is not \(saveImageByteCount)")
                }
            }
        }
    }

    private static func expectedTick(for index: Int, spec: Spec) -> UInt64 {
        if spec.route == .audioSequence { return 2 }
        return index < 3 ? 2 : 3
    }

    private static func readSidecar(_ url: URL) throws -> [SidecarRecord] {
        let text = try read(url)
        return try text.split(whereSeparator: \.isNewline).enumerated().map { offset, line in
            let fields = line.split(separator: "|", omittingEmptySubsequences: false)
            guard fields.count == 7,
                  let tick = UInt64(fields[0]),
                  let recordID = UInt64(fields[1]),
                  let subjectID = UInt64(fields[2]),
                  let byteCount = UInt64(fields[3]),
                  fields[4].hasPrefix("0x"),
                  let imageHash = UInt64(fields[4].dropFirst(2), radix: 16),
                  let modifiedFlags = UInt64(fields[5]) else {
                throw ToolError.sidecarMismatch("line \(offset + 1) has invalid fields")
            }
            let hex = String(fields[6])
            guard byteCount == saveImageByteCount,
                  hex.count == saveImageByteCount * 2,
                  hex.allSatisfy(\.isHexDigit) else {
                throw ToolError.sidecarMismatch("line \(offset + 1) does not contain 512 image bytes")
            }
            var image: [UInt8] = []
            image.reserveCapacity(saveImageByteCount)
            var cursor = hex.startIndex
            for _ in 0..<saveImageByteCount {
                let end = hex.index(cursor, offsetBy: 2)
                guard let byte = UInt8(hex[cursor..<end], radix: 16) else {
                    throw ToolError.sidecarMismatch("line \(offset + 1) contains invalid image hex")
                }
                image.append(byte)
                cursor = end
            }
            return SidecarRecord(
                tick: tick, recordID: recordID, subjectID: subjectID,
                byteCount: byteCount, imageHash: imageHash,
                modifiedFlags: modifiedFlags, image: image
            )
        }
    }

    private static func validateSidecar(_ sidecar: [SidecarRecord], against trace: RawTrace, label: String) throws {
        guard sidecar.count == trace.records.count else {
            throw ToolError.sidecarMismatch("\(label) row count \(sidecar.count) is not \(trace.records.count)")
        }
        for (index, pair) in zip(trace.records, sidecar).enumerated() {
            let record = pair.0
            let sidecarRecord = pair.1
            guard sidecarRecord.tick == record.simulationTick,
                  sidecarRecord.recordID == record.recordID,
                  sidecarRecord.subjectID == record.subjectID,
                  sidecarRecord.byteCount == record.values[0],
                  sidecarRecord.imageHash == record.values[1],
                  sidecarRecord.modifiedFlags == record.values[2] else {
                throw ToolError.sidecarMismatch("\(label) line \(index + 1) does not match trace record")
            }
            guard fnvHash(sidecarRecord.image) == sidecarRecord.imageHash else {
                throw ToolError.sidecarMismatch("\(label) line \(index + 1) image hash does not match bytes")
            }
        }
    }

    private static func fnvHash(_ bytes: [UInt8]) -> UInt64 {
        bytes.reduce(SM64OracleTraceHash.offset) { hash, byte in
            (hash ^ UInt64(byte)) &* SM64OracleTraceHash.prime
        }
    }

    private static func rejectTamperedTrace(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { throw ToolError.missingEvidence(url) }
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

    private static func makeIsolatedReport(rows: [ManifestRow], target: ManifestRow, spec: Spec) -> String {
        rows.sorted { $0.shard.id < $1.shard.id }.map { row in
            if row.shard.id == target.shard.id {
                return [formatID(row.shard.id), "passed", String(spec.recordCount), String(spec.recordCount), String(spec.recordCount), ""].joined(separator: "|")
            }
            return [formatID(row.shard.id), "planned", "0", "0", "0", ""].joined(separator: "|")
        }.joined(separator: "\n") + "\n"
    }

    private static func validateIsolatedReport(_ text: String, rows: [ManifestRow], target: ManifestRow, spec: Spec) throws {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count == rows.count else { throw ToolError.reportInvalid("expected \(rows.count) rows, got \(lines.count)") }
        let expectedIDs = Set(rows.map { $0.shard.id })
        var seen: Set<UInt64> = []
        var passed = 0
        for (index, line) in lines.enumerated() {
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 6, let id = parseHex(fields[0]), expectedIDs.contains(id), seen.insert(id).inserted else {
                throw ToolError.reportInvalid("line \(index + 1) has invalid or duplicate shard row")
            }
            guard let expected = UInt64(fields[2]), let actual = UInt64(fields[3]), let matched = UInt64(fields[4]) else {
                throw ToolError.reportInvalid("line \(index + 1) has invalid evidence counts")
            }
            if id == target.shard.id {
                guard fields[1] == "passed", expected == UInt64(spec.recordCount), actual == expected, matched == expected, fields[5].isEmpty else {
                    throw ToolError.reportInvalid("target row is not an exact passed receipt")
                }
                passed += 1
            } else {
                guard fields[1] == "planned", expected == 0, actual == 0, matched == 0, fields[5].isEmpty else {
                    throw ToolError.reportInvalid("non-target row was admitted or carried evidence")
                }
            }
        }
        guard seen == expectedIDs, passed == 1 else { throw ToolError.reportInvalid("report does not contain exactly one selected passed row") }
    }

    private static func parseHex(_ value: String) -> UInt64? {
        guard value.hasPrefix("0x") else { return nil }
        return UInt64(value.dropFirst(2), radix: 16)
    }

    private static func formatID(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }
}
