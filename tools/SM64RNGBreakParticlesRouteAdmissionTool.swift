import CryptoKit
import Foundation

/// Admits the source-authored JRB break-particle RNG row into one isolated
/// report.  The native C owner and the independent Swift mirror remain
/// separate evidence producers; this validator never mutates the manifest,
/// cumulative route ledger, or history.
@main
struct SM64RNGBreakParticlesRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let minimumManifestRowCount = 7_420
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize

    private static let shardID: UInt64 = 0x0057_6356_a427_dbc2
    private static let inputSeed: UInt64 = 0x7f28_9fd4_1270_636e
    private static let saveSeed: UInt64 = 0x3e05_c8a6_a9f4_1727
    private static let identity = "random_u16"
    private static let source = "src/game/behaviors/break_particles.inc.c"
    private static let sourceIdentity: UInt64 = 0xcb90_922e_394c_3a9b
    private static let moveYawCallSite: UInt32 = 0xf2f9_30d7
    private static let facePitchCallSite: UInt32 = 0x4648_c6c9
    private static let routeTick: UInt64 = 2_084
    private static let expectedRecordCount = 40
    private static let expectedValues: [UInt64] = [
        59_787, 42_318, 511, 40_820, 12_109, 50_824, 19_551, 20_950,
        28_388, 37_589, 63_923, 47_458, 36_145, 63_643, 27_904, 32_310,
        27_162, 60_758, 5_834, 34_256, 714, 34_266, 55_666, 18_215,
        61_356, 10_381, 2_226, 47_515, 60_360, 6_873, 21_131, 15_207,
        57_194, 19_248, 48_300, 46_800, 29_198, 59_204, 9_811, 22_505,
    ]
    private static let fingerprints = (
        build: UInt64(0x910c_1cd7_081c_2ed4),
        content: UInt64(0xa9df_7b72_b123_7724),
        timebase: UInt64(0xccc1_9787_cd09_f0c2),
        configuration: UInt64(0x247f_0789_0065_ae07),
        initialSave: UInt64(0xd892_fd06_f5c7_301a),
        coverage: UInt64(0x8c58_9d77_6cc2_cdf9)
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
        case missingEvidence(URL)
        case invalidManifest(String)
        case wrongManifestRow(String)
        case invalidTrace(URL, String)
        case headerMismatch(String)
        case wrongFingerprint(String, UInt64, UInt64)
        case wrongRecordCount(String, Int, Int)
        case wrongRecord(String, Int, String)
        case recordBytesMismatch
        case singleArtifact
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
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidManifest(reason): return "invalid canonical route manifest: \(reason)"
            case let .wrongManifestRow(reason): return "canonical RNG manifest row mismatch: \(reason)"
            case let .invalidTrace(url, reason): return "invalid trace \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift/ASan/Release header mismatch: \(field)"
            case let .wrongFingerprint(field, expected, actual):
                return String(format: "wrong canonical fingerprint %@: expected 0x%016llx got 0x%016llx", field, expected, actual)
            case let .wrongRecordCount(label, actual, expected):
                return "\(label) record count \(actual) is not \(expected)"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch: return "independent C/Swift/ASan/Release trace bytes differ"
            case .singleArtifact: return "C, Swift, ASan, Release, and tampered traces must be distinct artifacts"
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
            FileHandle.standardError.write(
                Data(("sm64-rng-break-particles-route-admit: \(error)\n").utf8)
            )
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctEvidence(options)
        try requireFreshReport(options)

        let manifestText = try read(options.manifest)
        let rows = try parseManifest(manifestText)
        guard rows.count >= minimumManifestRowCount else {
            throw ToolError.invalidManifest(
                "expected at least \(minimumManifestRowCount) rows, got \(rows.count)"
            )
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

        let reportText = makeReport(rows: rows, target: target)
        try validateReport(reportText, manifest: manifestText)
        do {
            try FileManager.default.createDirectory(
                at: options.report.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(reportText.utf8).write(to: options.report, options: .atomic)
        } catch {
            throw ToolError.unwritable(options.report, error)
        }

        let traceSHA = sha256(cTrace.bytes)
        let reportSHA = sha256(Data(reportText.utf8))
        let manifestSHA = sha256(Data(manifestText.utf8))
        print(
            String(
                format: "SM64 RNG break-particles route isolated admission passed "
                    + "shard=0x%016llx identity=%@ source=%@ records=%d tick=%llu "
                    + "domain=8 kind=3 schema=4 source_identity=0x%016llx "
                    + "input_seed=0x%016llx save_seed=0x%016llx manifest_rows=%d "
                    + "report_rows=%d passed_rows=1 planned_rows=%d report=%@ "
                    + "c_swift_asan_release_byte_match=1 trace_sha256=%@ "
                    + "tamper_rejected=1 fixture_only=0 manifest_mutated=0 "
                    + "canonical_ledger_mutation=0 history_mutated=0 rerun_fence=1 "
                    + "report_sha256=%@ manifest_sha256=%@",
                shardID, identity, source, cTrace.records.count, routeTick,
                sourceIdentity, inputSeed, saveSeed, rows.count, rows.count,
                rows.count - 1, options.report.path, traceSHA, reportSHA, manifestSHA
            )
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-rng-break-particles-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --release-trace RELEASE_TRACE --tampered-trace TAMPERED_TRACE --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --release-log RELEASE_LOG --report REPORT"
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
        let keys: Set<String> = [
            "--manifest", "--c-trace", "--swift-trace", "--asan-trace",
            "--release-trace", "--tampered-trace", "--debug-log", "--swift-log",
            "--asan-log", "--release-log", "--report",
        ]
        guard values.count == keys.count, values.keys.allSatisfy(keys.contains) else {
            throw ToolError.invalidArguments(usage)
        }
        func url(_ key: String) -> URL {
            URL(fileURLWithPath: values[key]!).standardizedFileURL
        }
        return Options(
            manifest: url("--manifest"), cTrace: url("--c-trace"),
            swiftTrace: url("--swift-trace"), asanTrace: url("--asan-trace"),
            releaseTrace: url("--release-trace"), tamperedTrace: url("--tampered-trace"),
            debugLog: url("--debug-log"), swiftLog: url("--swift-log"),
            asanLog: url("--asan-log"), releaseLog: url("--release-log"),
            report: url("--report")
        )
    }

    private static func requireDistinctEvidence(_ options: Options) throws {
        let evidence = [
            options.cTrace, options.swiftTrace, options.asanTrace,
            options.releaseTrace, options.tamperedTrace,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard Set(evidence).count == evidence.count else {
            throw ToolError.singleArtifact
        }
        let reportPath = options.report.resolvingSymlinksInPath().standardizedFileURL.path
        let immutable = [options.manifest, options.debugLog, options.swiftLog,
                         options.asanLog, options.releaseLog]
            .map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard !evidence.contains(reportPath), !immutable.contains(reportPath) else {
            throw ToolError.reportCollision(options.report)
        }
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
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ToolError.missingEvidence(url)
        }
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
        let matches = rows.filter { $0.shard.id == shardID }
        guard matches.count == 1, let target = matches.first else {
            throw ToolError.wrongManifestRow(
                String(format: "expected one shard 0x%016llx, found %d", shardID, matches.count)
            )
        }
        let shard = target.shard
        guard shard.domain == "rng", shard.identity == identity,
              shard.source == source, shard.inputSeed == inputSeed,
              shard.saveSeed == saveSeed, shard.expectedDomains == [.rngDraws],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow(
                "identity/source/seeds/expected domain/status do not match JRB route"
            )
        }
        return target
    }

    private static func requireMarkers(_ options: Options) throws {
        let nativeMarkers = [
            "rng_break_particles_route_init status=0 oracle=0 parity=0",
            "rng_break_particles_route_debug oracle_end=0 result_status=0",
            "retained=40 failures=0 tick=2084",
            "c_rng_break_particles_route_recorded shard=0x00576356a427dbc2",
            "records=40 tick=2084 callsites=20,20 source=0xcb90922e394c3a9b",
            "fixture_only=0",
        ]
        for log in [options.debugLog, options.asanLog, options.releaseLog] {
            for marker in nativeMarkers { try requireMarker(log, marker) }
        }
        for marker in [
            "swift_rng_break_particles_route_recorded records=40 tick=2084",
            "rng_break_particles_pairing_audit admitted=1 c_records=40 swift_records=40 blockers= first_divergence=none fixture_only=0",
            "rng_break_particles_pairing_tamper_rejected=1",
        ] { try requireMarker(options.swiftLog, marker) }
        try rejectSanitizerFindings(in: options.asanLog)
    }

    private static func requireMarker(_ url: URL, _ marker: String) throws {
        guard try read(url).contains(marker) else { throw ToolError.missingMarker(url, marker) }
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
        let bytes = try readData(url)
        guard bytes.count >= traceHeaderSize,
              (bytes.count - traceHeaderSize).isMultiple(of: traceRecordSize) else {
            throw ToolError.invalidTrace(url, "size is not 72 + N*128")
        }
        do {
            let trace = try SM64OracleTraceFile.read(from: url)
            guard bytes.count == traceHeaderSize + trace.records.count * traceRecordSize else {
                throw ToolError.invalidTrace(url, "decoded records do not cover complete artifact")
            }
            return RawTrace(url: url, bytes: bytes, configuration: trace.configuration, records: trace.records)
        } catch let error as ToolError { throw error }
        catch { throw ToolError.invalidTrace(url, String(describing: error)) }
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
            throw ToolError.invalidTrace(URL(fileURLWithPath: label), "region code is not 0x5553")
        }
        guard configuration.mode == .record else {
            throw ToolError.invalidTrace(URL(fileURLWithPath: label), "mode is not record")
        }
        let fields: [(String, UInt64, UInt64)] = [
            ("\(label).build", fingerprints.build, configuration.buildFingerprint),
            ("\(label).content", fingerprints.content, configuration.contentFingerprint),
            ("\(label).timebase", fingerprints.timebase, configuration.timebaseFingerprint),
            ("\(label).configuration", fingerprints.configuration, configuration.configurationFingerprint),
            ("\(label).initial_save", fingerprints.initialSave, configuration.initialSaveFingerprint),
            ("\(label).coverage", fingerprints.coverage, configuration.coverageFingerprint),
        ]
        for field in fields where field.1 != field.2 {
            throw ToolError.wrongFingerprint(field.0, field.1, field.2)
        }
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        guard trace.records.count == expectedRecordCount else {
            throw ToolError.wrongRecordCount(label, trace.records.count, expectedRecordCount)
        }
        for (index, record) in trace.records.enumerated() {
            let expectedSequence = 71 + UInt32(index / 2) * 8
                + (index.isMultiple(of: 2) ? 0 : 2)
            let expectedFlags = index.isMultiple(of: 2) ? moveYawCallSite : facePitchCallSite
            guard record.simulationTick == routeTick else {
                throw ToolError.wrongRecord(label, index, "tick \(record.simulationTick) is not 2084")
            }
            guard record.domain == 8, record.recordKind == 3 else {
                throw ToolError.wrongRecord(label, index, "domain/kind is not 8/3")
            }
            guard record.subjectID == sourceIdentity, record.recordID == 1,
                  record.sequence == expectedSequence, record.flags == expectedFlags else {
                throw ToolError.wrongRecord(label, index, "source identity/record ID/sequence/call-site is not canonical")
            }
            guard record.values.count == 2,
                  record.values[0] == expectedValues[index],
                  record.values[1] == expectedValues[index],
                  record.values[0] <= UInt64(UInt16.max) else {
                throw ToolError.wrongRecord(label, index, "value/seed pair is not the authored u16 receipt")
            }
        }
    }

    private static func rejectTamperedTrace(_ url: URL) throws {
        _ = try readData(url)
        do {
            _ = try SM64OracleTraceFile.read(from: url)
            throw ToolError.tamperAccepted(url)
        } catch ToolError.tamperAccepted {
            throw ToolError.tamperAccepted(url)
        } catch SM64OracleTraceCodecError.nonCanonicalHash {
            return
        } catch {
            throw ToolError.invalidTrace(url, "tampered artifact did not fail canonical-hash decoding: \(error)")
        }
    }

    private static func makeReport(rows: [ManifestRow], target: ManifestRow) -> String {
        rows.sorted { $0.shard.id < $1.shard.id }.map { row in
            if row.shard.id == target.shard.id {
                return [formatID(row.shard.id), "passed", "40", "40", "40", ""].joined(separator: "|")
            }
            return [formatID(row.shard.id), "planned", "0", "0", "0", ""].joined(separator: "|")
        }.joined(separator: "\n") + "\n"
    }

    private static func validateReport(_ text: String, manifest: String) throws {
        do {
            let ledger = try SM64RouteShardExecutionLedger(manifest: manifest, report: text)
                guard ledger.count >= minimumManifestRowCount,
                  ledger.plannedCount == ledger.count - 1,
                  ledger.terminalCount == 1,
                  try ledger.state(for: shardID) == .passed,
                  try ledger.evidence(for: shardID)?.actualRecords == UInt64(expectedRecordCount),
                  try ledger.evidence(for: shardID)?.matchedRecords == UInt64(expectedRecordCount) else {
                throw ToolError.reportInvalid(
                    "expected one passed row and one planned row for every other manifest shard"
                )
            }
        } catch let error as ToolError { throw error }
        catch { throw ToolError.reportInvalid(String(describing: error)) }
    }

    private static func parseHex(_ value: String) -> UInt64? {
        guard value.hasPrefix("0x") else { return nil }
        return UInt64(value.dropFirst(2), radix: 16)
    }

    private static func formatID(_ id: UInt64) -> String {
        String(format: "0x%016llx", id)
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
