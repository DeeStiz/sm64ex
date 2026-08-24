import Foundation

/// Validates the source-bound camera/find_floor route pair and emits a
/// merge-ready isolated report.  The generated manifest and canonical route
/// ledger are read-only inputs; this tool never advances either one.
@main
struct SM64CameraFindFloorRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let manifestRowCount = 7_420
    private static let routeShardID: UInt64 = 0x1e35_00f9_eb2b_95d4
    private static let routeInputSeed: UInt64 = 0xe5c3_d109_a64f_58ac
    private static let routeSaveSeed: UInt64 = 0xb647_ca90_16af_2cd5
    private static let routeRecordCount = 30
    private static let routeTicks: [UInt64] = [92, 93]
    private static let sourceSubject: UInt64 = 0x6d42_14ff_e9a9_8a9a
    private static let sourceFlag: UInt32 = 0x4341_4d37
    private static let objectSubject: UInt64 = 1
    private static let routeCoverage: UInt64 = 0x1c41_224c_64ab_005f
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize
    private static let fnvOffset: UInt64 = 1_469_598_103_934_665_603
    private static let fnvPrime: UInt64 = 1_099_511_628_211

    private struct Fingerprints: Equatable {
        let build: UInt64
        let content: UInt64
        let timebase: UInt64
        let configuration: UInt64
        let initialSave: UInt64
        let coverage: UInt64

        init(_ configuration: SM64OracleTraceConfiguration) {
            build = configuration.buildFingerprint
            content = configuration.contentFingerprint
            timebase = configuration.timebaseFingerprint
            self.configuration = configuration.configurationFingerprint
            initialSave = configuration.initialSaveFingerprint
            coverage = configuration.coverageFingerprint
        }
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
            case let .invalidManifest(reason): return "invalid canonical route manifest: \(reason)"
            case let .wrongManifestRow(reason): return "camera/find_floor manifest row mismatch: \(reason)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidTrace(url, error): return "invalid trace \(url.path): \(error)"
            case let .invalidHeader(url, reason): return "invalid trace header \(url.path): \(reason)"
            case let .headerMismatch(field): return "trace header mismatch: \(field)"
            case let .wrongFingerprint(field, expected, actual):
                return String(format: "wrong canonical fingerprint %@: expected 0x%016llx got 0x%016llx", field, expected, actual)
            case let .wrongRecordCount(label, count):
                return "\(label) record count \(count) is not \(routeRecordCount)"
            case let .wrongTickWindow(label, ticks):
                return "\(label) tick window \(ticks) is not exactly [92, 93]"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch: return "C, Swift, ASan, Release, and persistent-rerun trace bytes differ"
            case .singleTraceEvidence: return "C, Swift, ASan, Release, tamper, and rerun evidence must be distinct artifacts"
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
            FileHandle.standardError.write(Data(("sm64-camera-find-floor-route-admit: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctEvidence(options)
        try requireFreshReport(options)

        let manifest = try read(options.manifest)
        let rows = try parseManifest(manifest)
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
        for (label, trace) in [("C", cTrace), ("Swift", swiftTrace), ("ASan", asanTrace), ("Release", releaseTrace), ("rerun", rerunTrace)] {
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

        let report = makeIsolatedReport(rows: rows, target: target)
        try validateIsolatedReport(report, rows: rows, target: target)
        do {
            try FileManager.default.createDirectory(
                at: options.report.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(report.utf8).write(to: options.report, options: .atomic)
        } catch {
            throw ToolError.unwritable(options.report, error)
        }

        print(
            String(
                format: "SM64 camera/find_floor route isolated admission passed shard=0x%016llx "
                    + "records=%d ticks=92,93 domains=collision_queries,object_state "
                    + "schema=4 manifest_rows=%d report_rows=%d passed_rows=1 planned_rows=%d "
                    + "report=%@ c_swift_asan_release_rerun=matched tamper_rejected=1 "
                    + "persistent_rerun=1 fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 "
                    + "history_mutated=0 rerun_fence=1",
                routeShardID, cTrace.records.count, rows.count, rows.count,
                rows.count - 1,
                options.report.path
            )
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-camera-find-floor-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --release-trace RELEASE_TRACE --rerun-trace RERUN_TRACE --tampered-trace TAMPERED_TRACE --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --release-log RELEASE_LOG --rerun-log RERUN_LOG --report REPORT"
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
        let paths = [options.cTrace, options.swiftTrace, options.asanTrace,
                     options.releaseTrace, options.rerunTrace, options.tamperedTrace]
            .map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard Set(paths).count == paths.count else { throw ToolError.singleTraceEvidence }
        let allImmutable = Set(paths + [options.manifest.path])
        let outputs = [options.report, options.debugLog, options.swiftLog,
                       options.asanLog, options.releaseLog, options.rerunLog]
            .map { $0.standardizedFileURL.path }
        guard outputs.allSatisfy({ !allImmutable.contains($0) }) else {
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
            throw ToolError.wrongManifestRow(String(format: "expected one shard 0x%016llx, found %d", routeShardID, matches.count))
        }
        let shard = target.shard
        guard shard.domain == "collision", shard.identity == "find_floor",
              shard.source == "src/game/camera.c",
              shard.inputSeed == routeInputSeed, shard.saveSeed == routeSaveSeed,
              shard.expectedDomains == [.collisionQueries, .objectState],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("identity/source/seeds/expected domains/status do not match selected route")
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
            return RawTrace(url: url, bytes: bytes, configuration: trace.configuration, records: trace.records)
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
        guard first.regionCode == other.regionCode else { throw ToolError.headerMismatch("\(label).region_code") }
        guard first.mode == other.mode else { throw ToolError.headerMismatch("\(label).mode") }
        let expected = Fingerprints(first)
        let actual = Fingerprints(other)
        let fields: [(String, UInt64, UInt64)] = [
            ("build", expected.build, actual.build),
            ("content", expected.content, actual.content),
            ("timebase", expected.timebase, actual.timebase),
            ("configuration", expected.configuration, actual.configuration),
            ("initial_save", expected.initialSave, actual.initialSave),
            ("coverage", expected.coverage, actual.coverage),
        ]
        guard let mismatch = fields.first(where: { $0.1 != $0.2 }) else { return }
        throw ToolError.headerMismatch("\(label).\(mismatch.0)")
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
        let expected = Fingerprints(
            SM64OracleTraceConfiguration(
                regionCode: 0x5553,
                mode: .record,
                buildFingerprint: hashString("sm64-modern-camera-find-floor-route-pair-build-v1"),
                contentFingerprint: hashString("src/game/camera.c:788:set_camera_height:find_floor;recipe=bobomb-area1"),
                timebaseFingerprint: 0xccc1_9787_cd09_f0c2,
                configurationFingerprint: hashString(
                    "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                        + "input_seed=0xe5c3d109a64f58ac;save_seed=0xb647ca9016af2cd5;"
                        + "shard=0x1e3500f9eb2b95d4"
                ),
                initialSaveFingerprint: hashString("save=empty-us-slot-0;seed=0xb647ca9016af2cd5"),
                coverageFingerprint: routeCoverage
            )
        )
        let actual = Fingerprints(configuration)
        let fields: [(String, UInt64, UInt64)] = [
            ("\(label).build", expected.build, actual.build),
            ("\(label).content", expected.content, actual.content),
            ("\(label).timebase", expected.timebase, actual.timebase),
            ("\(label).configuration", expected.configuration, actual.configuration),
            ("\(label).initial_save", expected.initialSave, actual.initialSave),
            ("\(label).coverage", expected.coverage, actual.coverage),
        ]
        for (field, expectedValue, actualValue) in fields where expectedValue != actualValue {
            throw ToolError.wrongFingerprint(field, expectedValue, actualValue)
        }
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        guard trace.records.count == routeRecordCount else {
            throw ToolError.wrongRecordCount(label, trace.records.count)
        }
        let ticks = Array(Set(trace.records.map(\.simulationTick)).sorted())
        guard ticks == routeTicks else { throw ToolError.wrongTickWindow(label, ticks) }
        let treeFields: [(UInt64, [UInt64])] = [
            (400, [0x3afc_6f8e_18e8_f545]),
            (401, [0x101]), (402, [0]), (403, [0]), (404, [1]),
            (405, [0xc5b5_0000, 0x4480_0000, 0xc591_7000]),
            (406, [0, 0, 0]), (407, [0, 0, 0]), (408, [0]), (409, [0]),
            (410, [0]), (411, [1]), (412, [0]), (413, [0x25]),
        ]
        for (tickIndex, tick) in routeTicks.enumerated() {
            let base = tickIndex * 15
            let camera = trace.records[base]
            let expectedYBits: UInt64 = tick == 92 ? 0x4361_0000 : 0x43b6_11d6
            let expectedCameraValues: [UInt64] = [
                0xc5e1_421b, expectedYBits, 0x45dc_5000, 0x424d_0003,
                1, 42, 0x3f1f_ec03, 0x45ae_e3e4,
            ]
            try requireRecord(
                camera, label: label, index: base, tick: tick, domain: 7,
                kind: 3, subject: sourceSubject, recordID: 1,
                sequence: tick == 92 ? 156 : 45, flags: sourceFlag,
                values: expectedCameraValues
            )
            for (fieldIndex, field) in treeFields.enumerated() {
                try requireRecord(
                    trace.records[base + fieldIndex + 1], label: label,
                    index: base + fieldIndex + 1, tick: tick, domain: 3, kind: 1,
                    subject: objectSubject, recordID: field.0,
                    sequence: UInt32(fieldIndex), flags: 0, values: field.1
                )
            }
        }
    }

    private static func requireRecord(
        _ record: SM64OracleTraceRecord,
        label: String,
        index: Int,
        tick: UInt64,
        domain: UInt32,
        kind: UInt32,
        subject: UInt64,
        recordID: UInt64,
        sequence: UInt32,
        flags: UInt32,
        values: [UInt64]
    ) throws {
        guard record.simulationTick == tick else { throw ToolError.wrongRecord(label, index, "tick \(record.simulationTick) != \(tick)") }
        guard record.domain == domain, record.recordKind == kind else { throw ToolError.wrongRecord(label, index, "domain/kind mismatch") }
        guard record.subjectID == subject, record.recordID == recordID else { throw ToolError.wrongRecord(label, index, "source identity mismatch") }
        guard record.sequence == sequence else { throw ToolError.wrongRecord(label, index, "sequence \(record.sequence) != \(sequence)") }
        guard record.flags == flags else { throw ToolError.wrongRecord(label, index, "flags mismatch") }
        guard record.values == values else { throw ToolError.wrongRecord(label, index, "source/value receipt mismatch") }
    }

    private static func requireMarkers(_ options: Options) throws {
        let debugMarkers = [
            "camera_find_floor_route_init variant=debug status=0 oracle=0 parity=0",
            "camera_find_floor_route_step variant=debug index=0 status=0 oracle=0 parity=0",
            "camera_find_floor_route_step variant=debug index=1 status=0 oracle=0 parity=0",
            "camera_find_floor_route_debug variant=debug oracle_end=0 result_status=0 actual=11391 all_records=11391",
            "identity_records=2 object_state=5796 retained=30 retained_object=28 retained_identity=2",
            "first_tick=92 last_tick=93 coverage=0x1c41224c64ab005f",
            "c_camera_find_floor_route_recorded shard=0x1e3500f9eb2b95d4",
        ]
        for marker in debugMarkers { try requireMarker(options.debugLog, marker) }
        let rerunMarkers = [
            "camera_find_floor_route_init variant=debug-rerun status=0 oracle=0 parity=0",
            "camera_find_floor_route_debug variant=debug-rerun oracle_end=0 result_status=0 actual=11391 all_records=11391",
            "first_tick=92 last_tick=93 coverage=0x1c41224c64ab005f",
        ]
        for marker in rerunMarkers { try requireMarker(options.rerunLog, marker) }
        for marker in [
            "camera_find_floor_route_debug variant=asan oracle_end=0 result_status=0",
            "first_tick=92 last_tick=93 coverage=0x1c41224c64ab005f",
            "c_camera_find_floor_route_recorded shard=0x1e3500f9eb2b95d4",
        ] { try requireMarker(options.asanLog, marker) }
        for marker in [
            "camera_find_floor_route_debug variant=release oracle_end=0 result_status=0",
            "first_tick=92 last_tick=93 coverage=0x1c41224c64ab005f",
        ] { try requireMarker(options.releaseLog, marker) }
        for marker in [
            "swift_camera_find_floor_route_recorded shard=0x1e3500f9eb2b95d4 records=30 object_records=28 identity_records=2 subject=0x1 ticks=92,93 coverage=0x1c41224c64ab005f",
            "camera_find_floor_pairing_audit admitted=1 c_records=30 swift_records=30 blockers= first_divergence=none",
            "camera_find_floor_pairing_tamper_rejected=1",
        ] { try requireMarker(options.swiftLog, marker) }
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

    private static func makeIsolatedReport(rows: [ManifestRow], target: ManifestRow) -> String {
        rows.sorted { $0.shard.id < $1.shard.id }.map { row in
            if row.shard.id == target.shard.id {
                return [formatID(row.shard.id), "passed", String(routeRecordCount), String(routeRecordCount), String(routeRecordCount), ""].joined(separator: "|")
            }
            return [formatID(row.shard.id), "planned", "0", "0", "0", ""].joined(separator: "|")
        }.joined(separator: "\n") + "\n"
    }

    private static func validateIsolatedReport(_ report: String, rows: [ManifestRow], target: ManifestRow) throws {
        let lines = report.split(whereSeparator: { $0.isNewline })
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
                guard fields[1] == "passed", expected == UInt64(routeRecordCount), actual == expected, matched == expected, fields[5].isEmpty else {
                    throw ToolError.reportInvalid("target row is not an exact passed receipt")
                }
                passed += 1
            } else if fields[1] != "planned" || expected != 0 || actual != 0 || matched != 0 || !fields[5].isEmpty {
                throw ToolError.reportInvalid("non-target row was admitted or carried evidence")
            }
        }
        guard seen == expectedIDs, passed == 1 else { throw ToolError.reportInvalid("report does not contain exactly one selected passed row") }
    }

    private static func hashString(_ value: String) -> UInt64 {
        value.utf8.reduce(fnvOffset) { ($0 ^ UInt64($1)) &* fnvPrime }
    }

    private static func parseHex(_ value: String) -> UInt64? {
        guard value.hasPrefix("0x") else { return nil }
        return UInt64(value.dropFirst(2), radix: 16)
    }

    private static func formatID(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }
}
