import Foundation

/// Validates the two Phase 85q source-backed oracle-hook receipt pairs and
/// emits a full, isolated route report for exactly one selected target.
///
/// The generated route manifest is immutable input.  This tool never creates
/// an execution ledger, changes a manifest row, or writes a cumulative
/// history.  Its report is intentionally compatible with the route-ledger
/// merge format so a later serial merge can consume the independently checked
/// result.
@main
struct SM64CollisionRNGRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let manifestRowCount = 7_420
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize

    private enum Route: String {
        case collisionQueries = "collision_queries"
        case rngDraws = "rng_draws"

        var spec: Spec {
            switch self {
            case .collisionQueries:
                return Spec(
                    route: self,
                    shardID: 0xc329_4578_ae77_bee8,
                    inputSeed: 0x90d1_525c_63a8_4e50,
                    saveSeed: 0xce79_3ba4_90fd_0739,
                    identity: "collision_queries",
                    domain: .collisionQueries,
                    cDomain: 7,
                    recordKind: 3,
                    recordCount: 204,
                    ticks: [2, 3],
                    ids: [1, 2, 3, 4],
                    idCounts: [1: 128, 2: 10, 3: 22, 4: 44],
                    valueCounts: [1: 7, 2: 7, 3: 8, 4: 4],
                    fingerprints: Fingerprints(
                        build: 0x96ef_9713_e6b5_d9c4,
                        content: 0x0457_d892_b196_b311,
                        timebase: 0xccc1_9787_cd09_f0c2,
                        configuration: 0x8c5f_c6de_7cd6_d352,
                        initialSave: 0x8919_2900_bd15_12c8,
                        coverage: 0xb4a7_b103_652d_83e3
                    ),
                    debugMarkers: [
                        "collision_queries_route_init status=0 oracle=0 parity=0",
                        "collision_queries_route_step index=0 status=0 oracle=0 parity=0",
                        "collision_queries_route_step index=1 status=0 oracle=0 parity=0",
                        "collision_queries_route_debug oracle_end=0 result_status=0 actual=",
                        "retained=204 failures=0 ticks=2 event_kinds=4",
                        "c_collision_queries_route_recorded shard=0xc3294578ae77bee8 path=",
                        "records=204 ticks=3 event_counts=128,10,22,44 coverage=0xb4a7b103652d83e3 fingerprints=build:0x96ef9713e6b5d9c4,content:0x0457d892b196b311,timebase:0xccc19787cd09f0c2,config:0x8c5fc6de7cd6d352,save:0x89192900bd1512c8"
                    ],
                    swiftMarkers: [
                        "swift_collision_queries_route_recorded records=204 ticks=2,3 event_ids=1,2,3,4 coverage=0xb4a7b103652d83e3",
                        "collision_queries_pairing_audit admitted=1 c_records=204 swift_records=204 blockers= first_divergence=none",
                        "collision_queries_pairing_tamper_rejected=1"
                    ],
                    asanMarkers: [
                        "collision_queries_route_debug oracle_end=0 result_status=0",
                        "retained=204",
                        "failures=0"
                    ]
                )
            case .rngDraws:
                return Spec(
                    route: self,
                    shardID: 0x7632_df13_5b85_e448,
                    inputSeed: 0xd900_50c2_81a6_31b0,
                    saveSeed: 0x1af0_8c30_daac_fe19,
                    identity: "rng_draws",
                    domain: .rngDraws,
                    cDomain: 8,
                    recordKind: 3,
                    recordCount: 168,
                    ticks: [2, 3],
                    ids: [1, 2, 3],
                    idCounts: [1: 84, 2: 84, 3: 0],
                    valueCounts: [1: 2, 2: 2, 3: 2],
                    fingerprints: Fingerprints(
                        build: 0x0137_4ff6_ca5d_055e,
                        content: 0x9dbb_07bb_d1a3_507b,
                        timebase: 0xccc1_9787_cd09_f0c2,
                        configuration: 0xe029_514c_35b4_1128,
                        initialSave: 0xf2f8_8b12_6e89_767c,
                        coverage: 0xf2f4_42e9_acdd_c042
                    ),
                    debugMarkers: [
                        "rng_draw_route_init status=0 oracle=0 parity=0 seed16=0x31b0",
                        "rng_draw_route_step index=0 status=0 oracle=0 parity=0",
                        "rng_draw_route_step index=1 status=0 oracle=0 parity=0",
                        "rng_draw_route_debug oracle_end=0 result_status=0 actual=",
                        "retained=168 failures=0 ticks=2",
                        "c_rng_draws_route_recorded shard=0x7632df135b85e448 path=",
                        "records=168 last_tick=3 event_counts=84,84,0 coverage=0xf2f442e9acddc042 seed16=0x31b0"
                    ],
                    swiftMarkers: [
                        "swift_rng_draws_route_recorded records=168 ticks=2,3 events=2 seed16=0x31b0 coverage=0xf2f442e9acddc042",
                        "rng_draws_pairing_audit admitted=1 c_records=168 swift_records=168 blockers= first_divergence=none",
                        "rng_draws_pairing_tamper_rejected=1"
                    ],
                    asanMarkers: [
                        "rng_draw_route_debug oracle_end=0 result_status=0",
                        "retained=168",
                        "failures=0"
                    ]
                )
            }
        }
    }

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
        let domain: SM64RouteShardTraceDomain
        let cDomain: UInt32
        let recordKind: UInt32
        let recordCount: Int
        let ticks: [UInt64]
        let ids: [UInt64]
        let idCounts: [UInt64: Int]
        let valueCounts: [UInt64: Int]
        let fingerprints: Fingerprints
        let debugMarkers: [String]
        let swiftMarkers: [String]
        let asanMarkers: [String]
    }

    private struct Options {
        let spec: Spec
        let manifest: URL
        let cTrace: URL
        let swiftTrace: URL
        let asanTrace: URL
        let tamperedTrace: URL
        let debugLog: URL
        let swiftLog: URL
        let asanLog: URL
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
            case let .wrongManifestRow(reason): return "canonical manifest row mismatch: \(reason)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidTrace(url, error): return "invalid trace \(url.path): \(error)"
            case let .invalidHeader(url, reason): return "invalid trace header \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift/ASan header mismatch: \(field)"
            case let .wrongFingerprint(field, expected, actual):
                return String(format: "wrong canonical fingerprint %@: expected 0x%016llx got 0x%016llx", field, expected, actual)
            case let .wrongRecordCount(label, actual, expected):
                return "\(label) record count \(actual) is not \(expected)"
            case let .wrongTickWindow(label, ticks):
                return "\(label) tick window \(ticks) is not exactly [2, 3]"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch: return "independent C/Swift/ASan trace bytes differ"
            case .singleTraceEvidence: return "C, Swift, ASan, and tamper evidence must be distinct artifacts"
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
            FileHandle.standardError.write(Data(("sm64-collision-rng-route-admit: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctEvidence(options)
        try requireFreshReport(options)

        let manifestText = try read(options.manifest)
        let rows = try parseManifest(manifestText)
        let target = try resolveTarget(rows, spec: options.spec)
        guard rows.count == manifestRowCount else {
            throw ToolError.invalidManifest("expected \(manifestRowCount) rows, got \(rows.count)")
        }

        try requireMarkers(options, spec: options.spec)
        let cTrace = try loadTrace(options.cTrace)
        let swiftTrace = try loadTrace(options.swiftTrace)
        let asanTrace = try loadTrace(options.asanTrace)
        try validateHeaders(cTrace.configuration, swiftTrace.configuration, label: "C/Swift")
        try validateHeaders(cTrace.configuration, asanTrace.configuration, label: "C/ASan")
        try validateCanonicalHeader(cTrace.configuration, spec: options.spec, label: "C")
        try validateCanonicalHeader(swiftTrace.configuration, spec: options.spec, label: "Swift")
        try validateCanonicalHeader(asanTrace.configuration, spec: options.spec, label: "ASan")
        try validateRecords(cTrace, spec: options.spec, label: "C")
        try validateRecords(swiftTrace, spec: options.spec, label: "Swift")
        try validateRecords(asanTrace, spec: options.spec, label: "ASan")
        guard cTrace.bytes == swiftTrace.bytes, cTrace.bytes == asanTrace.bytes else {
            throw ToolError.recordBytesMismatch
        }
        try rejectTamperedTrace(options.tamperedTrace)

        let reportText = try makeIsolatedReport(rows: rows, target: target, spec: options.spec)
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
                format: "SM64 %@ route isolated admission passed shard=0x%016llx "
                    + "records=%d ticks=2,3 domain=%u kind=%u manifest_rows=%d "
                    + "report_rows=%d passed_rows=1 planned_rows=%d report=%@ "
                    + "tamper_rejected=1 fixture_only=0 effects_admitted=0 "
                    + "unpaired_rows_admitted=0 manifest_mutated=0 ledger_mutated=0 "
                    + "history_mutated=0 rerun_fence=1",
                options.spec.route.rawValue,
                options.spec.shardID,
                cTrace.records.count,
                options.spec.cDomain,
                options.spec.recordKind,
                rows.count,
                rows.count,
                rows.count - 1,
                options.report.path
            )
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-collision-rng-route-admit --route collision_queries|rng_draws --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --tampered-trace TAMPERED_TRACE --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --report REPORT"
        guard arguments.count == 20, arguments.count.isMultiple(of: 2) else {
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
            "--route", "--manifest", "--c-trace", "--swift-trace", "--asan-trace",
            "--tampered-trace", "--debug-log", "--swift-log", "--asan-log", "--report"
        ]
        guard values.count == known.count, values.keys.allSatisfy(known.contains),
              let routeValue = values["--route"], let route = Route(rawValue: routeValue) else {
            throw ToolError.invalidArguments(usage)
        }
        func url(_ key: String) -> URL {
            URL(fileURLWithPath: values[key]!).standardizedFileURL
        }
        return Options(
            spec: route.spec,
            manifest: url("--manifest"),
            cTrace: url("--c-trace"),
            swiftTrace: url("--swift-trace"),
            asanTrace: url("--asan-trace"),
            tamperedTrace: url("--tampered-trace"),
            debugLog: url("--debug-log"),
            swiftLog: url("--swift-log"),
            asanLog: url("--asan-log"),
            report: url("--report")
        )
    }

    private static func requireDistinctEvidence(_ options: Options) throws {
        let paths = [options.cTrace, options.swiftTrace, options.asanTrace, options.tamperedTrace]
            .map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard Set(paths).count == paths.count else { throw ToolError.singleTraceEvidence }
        let evidencePaths = Set(paths + [options.manifest.path])
        guard !evidencePaths.contains(options.report.path),
              ![options.debugLog, options.swiftLog, options.asanLog]
                .map({ $0.standardizedFileURL.path }).contains(options.report.path) else {
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

    private static func resolveTarget(_ rows: [ManifestRow], spec: Spec) throws -> ManifestRow {
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
                "identity/source/seeds/expected domain/status do not match selected route"
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
        let expected = Fingerprints(
            build: first.buildFingerprint,
            content: first.contentFingerprint,
            timebase: first.timebaseFingerprint,
            configuration: first.configurationFingerprint,
            initialSave: first.initialSaveFingerprint,
            coverage: first.coverageFingerprint
        )
        let actual = Fingerprints(
            build: other.buildFingerprint,
            content: other.contentFingerprint,
            timebase: other.timebaseFingerprint,
            configuration: other.configurationFingerprint,
            initialSave: other.initialSaveFingerprint,
            coverage: other.coverageFingerprint
        )
        guard expected == actual else {
            let fields: [(String, UInt64, UInt64)] = [
                ("build", expected.build, actual.build),
                ("content", expected.content, actual.content),
                ("timebase", expected.timebase, actual.timebase),
                ("configuration", expected.configuration, actual.configuration),
                ("initial_save", expected.initialSave, actual.initialSave),
                ("coverage", expected.coverage, actual.coverage)
            ]
            if let mismatch = fields.first(where: { $0.1 != $0.2 }) {
                throw ToolError.headerMismatch("\(label).\(mismatch.0)")
            }
            throw ToolError.headerMismatch(label)
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
            ("\(label).coverage", expected.coverage, actual.coverage)
        ]
        for field in fields where field.1 != field.2 {
            throw ToolError.wrongFingerprint(field.0, field.1, field.2)
        }
    }

    private static func validateRecords(_ trace: RawTrace, spec: Spec, label: String) throws {
        guard trace.records.count == spec.recordCount else {
            throw ToolError.wrongRecordCount(label, trace.records.count, spec.recordCount)
        }
        let ticks = Array(Set(trace.records.map(\.simulationTick)).sorted())
        guard ticks == spec.ticks else { throw ToolError.wrongTickWindow(label, ticks) }

        var counts: [UInt64: Int] = [:]
        var previousTick: UInt64?
        var previousSequence: UInt32 = 0
        for (index, record) in trace.records.enumerated() {
            guard record.domain == spec.cDomain, record.recordKind == spec.recordKind else {
                throw ToolError.wrongRecord(label, index, "expected domain=\(spec.cDomain) kind=\(spec.recordKind)")
            }
            if let previousTick {
                if record.simulationTick == previousTick {
                    guard record.sequence == previousSequence &+ 1 else {
                        throw ToolError.wrongRecord(label, index, "sequence is not contiguous")
                    }
                } else {
                    guard record.simulationTick == previousTick + 1, record.sequence == 0 else {
                        throw ToolError.wrongRecord(label, index, "tick transition did not reset sequence")
                    }
                }
            } else {
                guard record.simulationTick == spec.ticks[0], record.sequence == 0 else {
                    throw ToolError.wrongRecord(label, index, "first record is not tick 2 sequence 0")
                }
            }
            previousTick = record.simulationTick
            previousSequence = record.sequence
            guard spec.ids.contains(record.recordID) else {
                throw ToolError.wrongRecord(label, index, "unexpected record ID \(record.recordID)")
            }
            guard let expectedValues = spec.valueCounts[record.recordID],
                  record.values.count == expectedValues else {
                throw ToolError.wrongRecord(
                    label,
                    index,
                    "ID \(record.recordID) value count \(record.values.count) is not \(spec.valueCounts[record.recordID] ?? -1)"
                )
            }
            counts[record.recordID, default: 0] += 1
        }
        let expectedCounts = spec.idCounts.filter { $0.value > 0 }
        guard counts == expectedCounts else {
            throw ToolError.wrongRecord(label, 0, "ID counts \(counts) != \(expectedCounts)")
        }
        guard Set(counts.keys) == Set(expectedCounts.keys) else {
            throw ToolError.wrongRecord(label, 0, "retained ID coverage is incomplete")
        }
    }

    private static func requireMarkers(_ options: Options, spec: Spec) throws {
        for marker in spec.debugMarkers { try requireMarker(options.debugLog, marker) }
        for marker in spec.swiftMarkers { try requireMarker(options.swiftLog, marker) }
        for marker in spec.asanMarkers { try requireMarker(options.asanLog, marker) }
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
        target: ManifestRow,
        spec: Spec
    ) throws -> String {
        var output: [String] = []
        output.reserveCapacity(rows.count)
        for row in rows.sorted(by: { $0.shard.id < $1.shard.id }) {
            if row.shard.id == target.shard.id {
                output.append(
                    [formatID(row.shard.id), "passed", String(spec.recordCount),
                     String(spec.recordCount), String(spec.recordCount), ""].joined(separator: "|")
                )
            } else {
                output.append([formatID(row.shard.id), "planned", "0", "0", "0", ""].joined(separator: "|"))
            }
        }
        return output.joined(separator: "\n") + "\n"
    }

    private static func validateIsolatedReport(
        _ text: String,
        rows: [ManifestRow],
        target: ManifestRow,
        spec: Spec
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
            guard fields.count == 6, let id = parseHex(fields[0]), expectedIDs.contains(id), seen.insert(id).inserted else {
                throw ToolError.reportInvalid("line \(index + 1) has invalid or duplicate shard row")
            }
            guard let expected = UInt64(fields[2]), let actual = UInt64(fields[3]),
                  let matched = UInt64(fields[4]) else {
                throw ToolError.reportInvalid("line \(index + 1) has invalid evidence counts")
            }
            if id == target.shard.id {
                guard fields[1] == "passed", expected == UInt64(spec.recordCount),
                      actual == expected, matched == expected, fields[5].isEmpty else {
                    throw ToolError.reportInvalid("target row is not an exact passed receipt")
                }
                passed += 1
            } else {
                guard fields[1] == "planned", expected == 0, actual == 0, matched == 0, fields[5].isEmpty else {
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
