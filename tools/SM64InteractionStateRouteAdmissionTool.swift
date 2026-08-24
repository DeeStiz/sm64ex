import Foundation

/// Admits only the generated oracle_hook|interaction_state row from the
/// independent C, Swift, ASan, and Release route artifacts. The interaction
/// snapshot remains a native C value boundary: this gate does not run
/// collision queries, dispatch interaction handlers, or admit effects. It
/// consumes an immutable generated manifest and writes one fresh isolated
/// report; it never changes the canonical manifest, history, or ledger.
@main
struct SM64InteractionStateRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let manifestRowCount = 7_420
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize
    private static let shardID: UInt64 = 0x3e1c_daca_08b2_1f54
    private static let recordFirst: UInt64 = 200
    private static let recordLast: UInt64 = 206
    private static let recordCount = Int(recordLast - recordFirst + 1)
    private static let ticks: [UInt64] = [2, 3]
    private static let cDomain: UInt32 = 4
    private static let recordKind: UInt32 = 1

    private struct Fingerprints: Equatable {
        let build: UInt64
        let content: UInt64
        let timebase: UInt64
        let configuration: UInt64
        let initialSave: UInt64
        let coverage: UInt64
    }

    private static let fingerprints = Fingerprints(
        build: 0x9527_779b_f7d0_d65b,
        content: 0xb5f4_50d6_340f_1a68,
        timebase: 0xccc1_9787_cd09_f0c2,
        configuration: 0xfa26_dd46_2356_68c4,
        initialSave: 0x6e3c_fef5_f30a_b26a,
        coverage: 0x7975_fa8a_fdbc_6bcf
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
                return String(
                    format: "wrong canonical fingerprint %@: expected 0x%016llx got 0x%016llx",
                    field, expected, actual
                )
            case let .wrongRecordCount(label, actual, expected):
                return "\(label) record count \(actual) is not \(expected)"
            case let .wrongTickWindow(label, actual, expected):
                return "\(label) tick window \(actual) is not exactly \(expected)"
            case let .wrongRecord(label, index, reason):
                return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch:
                return "independent C/Swift/ASan/Release trace bytes differ"
            case .singleTraceEvidence:
                return "C, Swift, ASan, Release, and tampered traces must be distinct artifacts"
            case let .tamperAccepted(url): return "tampered trace was accepted: \(url.path)"
            case let .missingMarker(url, marker):
                return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .reportAlreadyExists(url):
                return "isolated admission report already exists; rerun rejected: \(url.path)"
            case let .reportCollision(url):
                return "isolated report collides with immutable evidence: \(url.path)"
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
                Data(("sm64-interaction-state-route-admit: \(error)\n").utf8)
            )
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
            throw ToolError.invalidManifest(
                "expected \(manifestRowCount) rows, got \(rows.count)"
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
            "SM64 interaction_state route isolated admission passed "
                + "shard=\(formatID(shardID)) records=14 ticks=2,3 domain=4 kind=1 ids=200..206 "
                + "manifest_rows=\(rows.count) report_rows=\(rows.count) passed_rows=1 "
                + "planned_rows=\(rows.count - 1) report=\(options.report.path) "
                + "c_trace=\(options.cTrace.path) swift_trace=\(options.swiftTrace.path) "
                + "asan_trace=\(options.asanTrace.path) release_trace=\(options.releaseTrace.path) "
                + "c_swift_asan_release_byte_match=1 canonical_hash_tamper_rejected=1 "
                + "collision_authority=c effects_admitted=0 fixture_only=0 "
                + "manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1"
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-interaction-state-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --release-trace RELEASE_TRACE --tampered-trace TAMPERED_TRACE --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --release-log RELEASE_LOG --report REPORT"
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
        guard Set(paths).count == paths.count else {
            throw ToolError.singleTraceEvidence
        }
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
        guard !rows.isEmpty else {
            throw ToolError.invalidManifest("manifest has no rows")
        }
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
        let inventoryCanonical = [
            shard.domain, shard.identity, shard.source,
            "hooked", "interaction snapshot boundary",
        ].joined(separator: "|")
        guard shard.domain == "oracle_hook",
              shard.identity == "interaction_state",
              shard.source == "src/pc/sm64_modern_gameplay_parity.c",
              shard.id == hashString(inventoryCanonical),
              shard.inputSeed == hashString(inventoryCanonical + "|input"),
              shard.saveSeed == hashString(inventoryCanonical + "|save"),
              shard.expectedDomains == [.interactionState],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow(
                "identity/source/seeds/expected domain/status do not match interaction-state route"
            )
        }
        return target
    }

    private static func loadTrace(_ url: URL) throws -> RawTrace {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ToolError.missingEvidence(url)
        }
        do {
            let bytes = try readData(url)
            guard bytes.count >= traceHeaderSize,
                  (bytes.count - traceHeaderSize).isMultiple(of: traceRecordSize) else {
                throw ToolError.invalidHeader(url, "size is not 72 + N*128")
            }
            let trace = try SM64OracleTraceFile.read(from: url)
            guard bytes.count == traceHeaderSize + trace.records.count * traceRecordSize else {
                throw ToolError.invalidHeader(
                    url, "decoded record count does not cover complete artifact"
                )
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
        guard first.regionCode == other.regionCode else {
            throw ToolError.headerMismatch("\(label).region_code")
        }
        guard first.mode == other.mode else {
            throw ToolError.headerMismatch("\(label).mode")
        }
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
        let fields: [(String, UInt64, UInt64)] = [
            ("\(label).build", fingerprints.build, actual.build),
            ("\(label).content", fingerprints.content, actual.content),
            ("\(label).timebase", fingerprints.timebase, actual.timebase),
            ("\(label).configuration", fingerprints.configuration, actual.configuration),
            ("\(label).initial_save", fingerprints.initialSave, actual.initialSave),
            ("\(label).coverage", fingerprints.coverage, actual.coverage),
        ]
        for (field, expected, value) in fields where expected != value {
            throw ToolError.wrongFingerprint(field, expected, value)
        }
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        guard trace.records.count == recordCount * ticks.count else {
            throw ToolError.wrongRecordCount(label, trace.records.count, recordCount * ticks.count)
        }
        let observedTicks = Array(Set(trace.records.map(\.simulationTick)).sorted())
        guard observedTicks == ticks else {
            throw ToolError.wrongTickWindow(label, observedTicks, ticks)
        }
        var observedIDs: Set<UInt64> = []
        var observedKeys: Set<String> = []
        for (index, record) in trace.records.enumerated() {
            let tickIndex = index / recordCount
            let offset = index % recordCount
            let expectedTick = ticks[tickIndex]
            let expectedID = recordFirst + UInt64(offset)
            guard record.simulationTick == expectedTick else {
                throw ToolError.wrongRecord(label, index, "tick \(record.simulationTick) != \(expectedTick)")
            }
            guard record.domain == cDomain, record.recordKind == recordKind else {
                throw ToolError.wrongRecord(
                    label, index,
                    "domain/kind \(record.domain)/\(record.recordKind) is not 4/1"
                )
            }
            guard record.subjectID == 0, record.flags == 0 else {
                throw ToolError.wrongRecord(label, index, "subject/flags are not 0/0")
            }
            guard record.recordID == expectedID else {
                throw ToolError.wrongRecord(label, index, "record ID \(record.recordID) != \(expectedID)")
            }
            guard record.sequence == UInt32(offset) else {
                throw ToolError.wrongRecord(label, index, "sequence \(record.sequence) != \(offset)")
            }
            guard record.values.count == 1 else {
                throw ToolError.wrongRecord(label, index, "value count \(record.values.count) != 1")
            }
            observedIDs.insert(record.recordID)
            observedKeys.insert("\(record.domain):\(record.recordKind)")
        }
        guard observedIDs == Set(recordFirst...recordLast) else {
            throw ToolError.wrongRecord(label, 0, "record-ID coverage is incomplete")
        }
        guard observedKeys == ["4:1"] else {
            throw ToolError.wrongRecord(label, 0, "domain/record-kind coverage is \(observedKeys)")
        }
    }

    private static func requireMarkers(_ options: Options) throws {
        let debugMarkers = [
            "interaction_state_route_init status=0 oracle=0",
            "interaction_state_route_step index=0 status=0 oracle=0 parity=0",
            "interaction_state_route_step index=1 status=0 oracle=0 parity=0",
            "interaction_state_route_debug oracle_end=0 result_status=0 actual=",
            "retained=14 failures=0 ticks=2",
            "c_interaction_state_route_recorded shard=0x3e1cdaca08b21f54",
            "records=14 ticks=3 coverage=0x7975fa8afdbc6bcf",
        ]
        for marker in debugMarkers { try requireMarker(options.debugLog, marker) }
        let swiftMarkers = [
            "swift_interaction_state_route_recorded shard=0x3e1cdaca08b21f54",
            "records=14 ticks=2,3 coverage=0x7975fa8afdbc6bcf source_state=SM64MarioState",
            "interaction_state_pairing_audit admitted=1 c_records=14 swift_records=14 blockers= first_divergence=none",
            "interaction_state_pairing_tamper_rejected=1",
        ]
        for marker in swiftMarkers { try requireMarker(options.swiftLog, marker) }
        let nativeMarkers = [
            "interaction_state_route_init status=0 oracle=0",
            "interaction_state_route_step index=0 status=0 oracle=0 parity=0",
            "interaction_state_route_step index=1 status=0 oracle=0 parity=0",
            "interaction_state_route_debug oracle_end=0 result_status=0 actual=",
            "retained=14 failures=0 ticks=2",
            "c_interaction_state_route_recorded shard=0x3e1cdaca08b21f54",
            "records=14 ticks=3 coverage=0x7975fa8afdbc6bcf",
        ]
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
        rows: [ManifestRow], target: ManifestRow
    ) -> String {
        rows.sorted { $0.shard.id < $1.shard.id }.map { row in
            if row.shard.id == target.shard.id {
                return [
                    formatID(row.shard.id), "passed", "14", "14", "14", "",
                ].joined(separator: "|")
            }
            return [formatID(row.shard.id), "planned", "0", "0", "0", ""].joined(separator: "|")
        }.joined(separator: "\n") + "\n"
    }

    private static func validateIsolatedReport(
        _ text: String, rows: [ManifestRow], target: ManifestRow
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
                  let matched = UInt64(fields[4]),
                  fields[5].isEmpty else {
                throw ToolError.reportInvalid("line \(index + 1) has invalid evidence fields")
            }
            if id == target.shard.id {
                guard fields[1] == "passed",
                      expected == 14, actual == 14, matched == 14 else {
                    throw ToolError.reportInvalid("target row is not passed with 14/14/14 evidence")
                }
                passed += 1
            } else {
                guard fields[1] == "planned", expected == 0, actual == 0, matched == 0 else {
                    throw ToolError.reportInvalid("non-target row contains terminal evidence")
                }
            }
        }
        guard seen == expectedIDs, passed == 1 else {
            throw ToolError.reportInvalid("report does not contain exactly one passed target row")
        }
    }

    private static func parseHex(_ value: String) -> UInt64? {
        guard value.hasPrefix("0x") else { return nil }
        return UInt64(value.dropFirst(2), radix: 16)
    }

    private static func formatID(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }

    private static func hashString(_ value: String) -> UInt64 {
        value.utf8.reduce(1_469_598_103_934_665_603) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }
}
