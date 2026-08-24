import CryptoKit
import Foundation

/// Admits the source-backed save_mutation row only from a complete, independent
/// C/Swift/ASan/Release route pair.  The generated route manifest is immutable
/// input; this tool writes one fresh isolated report and never advances the
/// checked-in route ledger or touches a user save directory.
@main
struct SM64SaveMutationRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let manifestRowCount = 7_420
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize
    private static let saveImageByteCount = 512
    private static let snapshotByteCount = 48

    private static let shardID: UInt64 = 0x022f_bda0_ff7f_2dd1
    private static let inputSeed: UInt64 = 0x0c83_cf28_590d_4915
    private static let saveSeed: UInt64 = 0xaaac_c83c_b4eb_46a2
    private static let identity = "save_file_set_sound_mode"
    private static let source = "src/game/save_file.c"
    private static let expectedDomains: [SM64RouteShardTraceDomain] = [.globalState, .saveBytes]
    private static let fingerprints = (
        build: UInt64(0x5836_83e4_aa12_b842),
        content: UInt64(0x5c1c_3e13_eca5_1ec6),
        timebase: UInt64(0xccc1_9787_cd09_f0c2),
        configuration: UInt64(0x7370_5a13_068d_c342),
        initialSave: UInt64(0xfdfc_d8ca_c940_62c9),
        coverage: UInt64(0x4fde_2498_6374_c66a)
    )

    private struct Options {
        let manifest: URL
        let cTrace: URL
        let swiftTrace: URL
        let asanTrace: URL
        let releaseTrace: URL
        let tamperedTrace: URL
        let cSidecar: URL
        let asanSidecar: URL
        let releaseSidecar: URL
        let cSnapshots: URL
        let asanSnapshots: URL
        let releaseSnapshots: URL
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

    private struct SaveSidecar: Equatable {
        let tick: UInt64
        let recordID: UInt64
        let subjectID: UInt64
        let byteCount: UInt64
        let imageHash: UInt64
        let modifiedFlags: UInt64
        let image: [UInt8]
    }

    private struct GlobalSnapshot: Equatable {
        let simulationTick: UInt64
        let fields: [UInt32]
    }

    private enum ToolError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case unreadable(URL, Error)
        case invalidManifest(String)
        case wrongManifestRow(String)
        case missingEvidence(URL)
        case invalidTrace(URL, String)
        case headerMismatch(String)
        case wrongFingerprint(String, UInt64, UInt64)
        case wrongRecordCount(String, Int, Int)
        case wrongRecord(String, Int, String)
        case recordBytesMismatch
        case sidecarMismatch(String)
        case snapshotMismatch(String)
        case snapshotBytesMismatch
        case singleEvidence
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
            case let .wrongManifestRow(reason): return "canonical save-mutation manifest row mismatch: \(reason)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidTrace(url, reason): return "invalid trace \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift/ASan/Release header mismatch: \(field)"
            case let .wrongFingerprint(field, expected, actual):
                return String(format: "wrong canonical fingerprint %@: expected 0x%016llx got 0x%016llx", field, expected, actual)
            case let .wrongRecordCount(label, actual, expected):
                return "\(label) record count \(actual) is not \(expected)"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch: return "independent C/Swift/ASan/Release trace bytes differ"
            case let .sidecarMismatch(reason): return "save sidecar mismatch: \(reason)"
            case let .snapshotMismatch(reason): return "global snapshot mismatch: \(reason)"
            case .snapshotBytesMismatch: return "independent C/ASan/Release global snapshot bytes differ"
            case .singleEvidence: return "C, Swift, ASan, Release, tampered, sidecar, and snapshot evidence must be distinct artifacts"
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

    private struct Cursor {
        let bytes: [UInt8]
        var offset: Int = 0

        init(_ data: Data) { bytes = Array(data) }

        mutating func readUInt32() throws -> UInt32 {
            guard offset + 4 <= bytes.count else { throw ToolError.snapshotMismatch("truncated snapshot") }
            var value: UInt32 = 0
            for byte in 0..<4 { value |= UInt32(bytes[offset + byte]) << UInt32(byte * 8) }
            offset += 4
            return value
        }

        mutating func readUInt64() throws -> UInt64 {
            guard offset + 8 <= bytes.count else { throw ToolError.snapshotMismatch("truncated snapshot") }
            var value: UInt64 = 0
            for byte in 0..<8 { value |= UInt64(bytes[offset + byte]) << UInt64(byte * 8) }
            offset += 8
            return value
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-save-mutation-route-admit: \(error)\n").utf8))
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

        let cSidecarData = try readData(options.cSidecar)
        let asanSidecarData = try readData(options.asanSidecar)
        let releaseSidecarData = try readData(options.releaseSidecar)
        guard cSidecarData == asanSidecarData,
              cSidecarData == releaseSidecarData else {
            throw ToolError.sidecarMismatch("C, ASan, and Release sidecar bytes differ")
        }
        let cSidecar = try readSidecar(options.cSidecar)
        try validateSidecar(cSidecar, against: cTrace, label: "C")
        try validateSidecar(try readSidecar(options.asanSidecar), against: asanTrace, label: "ASan")
        try validateSidecar(try readSidecar(options.releaseSidecar), against: releaseTrace, label: "Release")

        let cSnapshotData = try readData(options.cSnapshots)
        let asanSnapshotData = try readData(options.asanSnapshots)
        let releaseSnapshotData = try readData(options.releaseSnapshots)
        guard cSnapshotData == asanSnapshotData,
              cSnapshotData == releaseSnapshotData else {
            throw ToolError.snapshotBytesMismatch
        }
        let snapshots = try decodeSnapshots(cSnapshotData)
        try validateSnapshots(snapshots, against: cTrace)
        try validateSnapshots(try decodeSnapshots(asanSnapshotData), against: asanTrace)
        try validateSnapshots(try decodeSnapshots(releaseSnapshotData), against: releaseTrace)
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

        let reportSHA = sha256(Data(reportText.utf8))
        let manifestSHA = sha256(Data(manifestText.utf8))
        print(
            String(
                format: "SM64 save_mutation route isolated admission passed shard=0x%016llx records=%d ticks=2,3 domains=global_state,save_bytes manifest_rows=%d report_rows=%d passed_rows=1 planned_rows=%d report=%@ c_trace=%@ swift_trace=%@ asan_trace=%@ release_trace=%@ c_swift_asan_release_byte_match=1 sidecar_c_asan_release_byte_match=1 snapshots_c_asan_release_byte_match=1 canonical_hash_tamper_rejected=1 fixture_only=0 manifest_mutated=0 ledger_mutated=0 history_mutated=0 rerun_fence=1 report_sha256=%@ manifest_sha256=%@ input_seed=0x%016llx save_seed=0x%016llx",
                shardID, cTrace.records.count, rows.count, rows.count, rows.count - 1,
                options.report.path, options.cTrace.path, options.swiftTrace.path,
                options.asanTrace.path, options.releaseTrace.path, reportSHA,
                manifestSHA, target.shard.inputSeed, target.shard.saveSeed
            )
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-save-mutation-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --release-trace RELEASE_TRACE --tampered-trace TAMPERED_TRACE --c-sidecar C_SIDECAR --asan-sidecar ASAN_SIDECAR --release-sidecar RELEASE_SIDECAR --c-snapshots C_SNAPSHOTS --asan-snapshots ASAN_SNAPSHOTS --release-snapshots RELEASE_SNAPSHOTS --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --release-log RELEASE_LOG --report REPORT"
        guard arguments.count == 34, arguments.count.isMultiple(of: 2) else { throw ToolError.invalidArguments(usage) }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let key = arguments[index]
            let value = arguments[index + 1]
            guard key.hasPrefix("--"), values[key] == nil else { throw ToolError.invalidArguments(usage) }
            values[key] = value
            index += 2
        }
        let keys: Set<String> = [
            "--manifest", "--c-trace", "--swift-trace", "--asan-trace", "--release-trace",
            "--tampered-trace", "--c-sidecar", "--asan-sidecar", "--release-sidecar",
            "--c-snapshots", "--asan-snapshots", "--release-snapshots", "--debug-log",
            "--swift-log", "--asan-log", "--release-log", "--report",
        ]
        guard values.count == keys.count, values.keys.allSatisfy(keys.contains) else { throw ToolError.invalidArguments(usage) }
        func url(_ key: String) -> URL { URL(fileURLWithPath: values[key]!).standardizedFileURL }
        return Options(
            manifest: url("--manifest"), cTrace: url("--c-trace"), swiftTrace: url("--swift-trace"),
            asanTrace: url("--asan-trace"), releaseTrace: url("--release-trace"), tamperedTrace: url("--tampered-trace"),
            cSidecar: url("--c-sidecar"), asanSidecar: url("--asan-sidecar"), releaseSidecar: url("--release-sidecar"),
            cSnapshots: url("--c-snapshots"), asanSnapshots: url("--asan-snapshots"), releaseSnapshots: url("--release-snapshots"),
            debugLog: url("--debug-log"), swiftLog: url("--swift-log"), asanLog: url("--asan-log"), releaseLog: url("--release-log"),
            report: url("--report")
        )
    }

    private static func requireDistinctEvidence(_ options: Options) throws {
        let paths = [
            options.cTrace, options.swiftTrace, options.asanTrace, options.releaseTrace, options.tamperedTrace,
            options.cSidecar, options.asanSidecar, options.releaseSidecar,
            options.cSnapshots, options.asanSnapshots, options.releaseSnapshots,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard Set(paths).count == paths.count else { throw ToolError.singleEvidence }
        let reportPath = options.report.resolvingSymlinksInPath().standardizedFileURL.path
        let immutablePaths = paths + [
            options.manifest, options.debugLog, options.swiftLog, options.asanLog, options.releaseLog,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
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
        return rows
    }

    private static func resolveTarget(_ rows: [ManifestRow]) throws -> ManifestRow {
        let matches = rows.filter { $0.shard.id == shardID }
        guard matches.count == 1, let target = matches.first else {
            throw ToolError.wrongManifestRow(String(format: "expected one shard 0x%016llx, found %d", shardID, matches.count))
        }
        let shard = target.shard
        guard shard.domain == "save_mutation", shard.identity == identity, shard.source == source,
              shard.inputSeed == inputSeed, shard.saveSeed == saveSeed,
              shard.expectedDomains == expectedDomains, shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("identity/source/seeds/expected domains/status do not match")
        }
        return target
    }

    private static func requireMarkers(_ options: Options) throws {
        let debugMarkers = [
            "save_mutation_route_init status=0 oracle=0 parity=0",
            "save_mutation_route_step index=0 status=0 oracle=0 parity=0",
            "save_mutation_route_step index=1 status=0 oracle=0 parity=0",
            "save_mutation_route_debug oracle_end=0 result_status=0 actual=",
            "save_records=4 global_records=12 snapshots=2 failures=0",
            "c_save_mutation_route_recorded shard=0x022fbda0ff7f2dd1",
            "sound_mode=0x4321",
        ]
        for marker in debugMarkers { try requireMarker(options.debugLog, marker) }
        for marker in [
            "swift_save_mutation_route_recorded shard=0x22fbda0ff7f2dd1 save_records=4 global_records=12 snapshots=2 sound_mode=0x4321",
            "save_mutation_pairing_audit admitted=1 c_records=16 swift_records=16 blockers= first_divergence=none",
            "save_mutation_pairing_tamper_rejected=1",
        ] { try requireMarker(options.swiftLog, marker) }
        for log in [options.asanLog, options.releaseLog] {
            try requireMarker(log, "save_mutation_route_debug oracle_end=0 result_status=0 actual=")
            try requireMarker(log, "save_records=4 global_records=12 snapshots=2 failures=0")
            try requireMarker(log, "c_save_mutation_route_recorded shard=0x022fbda0ff7f2dd1")
            try requireMarker(log, "sound_mode=0x4321")
        }
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

    private static func validateCanonicalHeader(_ configuration: SM64OracleTraceConfiguration, label: String) throws {
        guard configuration.regionCode == 0x5553 else { throw ToolError.invalidTrace(URL(fileURLWithPath: label), "region code is not 0x5553") }
        guard configuration.mode == .record else { throw ToolError.invalidTrace(URL(fileURLWithPath: label), "mode is not record") }
        let actual: [(String, UInt64, UInt64)] = [
            ("\(label).build", fingerprints.build, configuration.buildFingerprint),
            ("\(label).content", fingerprints.content, configuration.contentFingerprint),
            ("\(label).timebase", fingerprints.timebase, configuration.timebaseFingerprint),
            ("\(label).configuration", fingerprints.configuration, configuration.configurationFingerprint),
            ("\(label).initial_save", fingerprints.initialSave, configuration.initialSaveFingerprint),
            ("\(label).coverage", fingerprints.coverage, configuration.coverageFingerprint),
        ]
        for field in actual where field.1 != field.2 { throw ToolError.wrongFingerprint(field.0, field.1, field.2) }
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        guard trace.records.count == 16 else { throw ToolError.wrongRecordCount(label, trace.records.count, 16) }
        for (index, record) in trace.records.enumerated() {
            let isSave = index < 3 || index == 9
            let expectedTick: UInt64 = index < 9 ? 2 : 3
            let expectedDomain: UInt32 = isSave ? 10 : 0
            let expectedKind: UInt32 = isSave ? 6 : 1
            let expectedID: UInt64
            let expectedSequence: UInt32
            if index < 3 { expectedID = UInt64(index + 1); expectedSequence = UInt32(index) }
            else if index == 9 { expectedID = 4; expectedSequence = 0 }
            else if index < 9 { expectedID = UInt64(index - 2); expectedSequence = UInt32(index - 3) }
            else { expectedID = UInt64(index - 9); expectedSequence = UInt32(index - 10) }
            guard record.simulationTick == expectedTick else { throw ToolError.wrongRecord(label, index, "tick \(record.simulationTick) is not \(expectedTick)") }
            guard record.domain == expectedDomain, record.recordKind == expectedKind else {
                throw ToolError.wrongRecord(label, index, "domain/kind \(record.domain)/\(record.recordKind) is not \(expectedDomain)/\(expectedKind)")
            }
            guard record.subjectID == 0, record.flags == 0, record.recordID == expectedID,
                  record.sequence == expectedSequence else {
                throw ToolError.wrongRecord(label, index, "subject/ID/sequence is not canonical")
            }
            if isSave {
                guard record.values.count == 3, record.values[0] == UInt64(saveImageByteCount) else {
                    throw ToolError.wrongRecord(label, index, "save record must carry three values and 512 bytes")
                }
            } else {
                guard record.values.count == 1 else { throw ToolError.wrongRecord(label, index, "global record must carry one value") }
            }
        }
    }

    private static func readSidecar(_ url: URL) throws -> [SaveSidecar] {
        let text = try read(url)
        let lines = text.split(whereSeparator: \.isNewline)
        guard lines.count == 4 else { throw ToolError.sidecarMismatch("expected four save records, got \(lines.count)") }
        return try lines.enumerated().map { offset, line in
            let fields = line.split(separator: "|", omittingEmptySubsequences: false)
            guard fields.count == 7, let tick = UInt64(fields[0]), let recordID = UInt64(fields[1]),
                  let subjectID = UInt64(fields[2]), let byteCount = UInt64(fields[3]),
                  fields[4].hasPrefix("0x"), let imageHash = UInt64(fields[4].dropFirst(2), radix: 16),
                  let modifiedFlags = UInt64(fields[5]) else {
                throw ToolError.sidecarMismatch("line \(offset + 1) has invalid fields")
            }
            let hex = String(fields[6])
            guard byteCount == UInt64(saveImageByteCount), hex.count == saveImageByteCount * 2,
                  hex.allSatisfy(\.isHexDigit) else {
                throw ToolError.sidecarMismatch("line \(offset + 1) does not contain 512 image bytes")
            }
            var image: [UInt8] = []
            image.reserveCapacity(saveImageByteCount)
            var cursor = hex.startIndex
            for _ in 0..<saveImageByteCount {
                let end = hex.index(cursor, offsetBy: 2)
                guard let byte = UInt8(hex[cursor..<end], radix: 16) else { throw ToolError.sidecarMismatch("line \(offset + 1) has invalid image hex") }
                image.append(byte)
                cursor = end
            }
            return SaveSidecar(tick: tick, recordID: recordID, subjectID: subjectID, byteCount: byteCount, imageHash: imageHash, modifiedFlags: modifiedFlags, image: image)
        }
    }

    private static func hash(_ bytes: [UInt8]) -> UInt64 {
        bytes.reduce(SM64OracleTraceHash.offset) { ($0 ^ UInt64($1)) &* SM64OracleTraceHash.prime }
    }

    private static func validateSidecar(_ sidecar: [SaveSidecar], against trace: RawTrace, label: String) throws {
        let records = trace.records.filter { $0.domain == 10 && $0.recordKind == 6 }
        guard sidecar.count == records.count else { throw ToolError.sidecarMismatch("\(label) row count \(sidecar.count) is not \(records.count)") }
        for (index, pair) in zip(records, sidecar).enumerated() {
            let record = pair.0
            let image = pair.1
            guard image.tick == record.simulationTick, image.recordID == record.recordID,
                  image.subjectID == record.subjectID, image.byteCount == record.values[0],
                  image.imageHash == record.values[1], image.modifiedFlags == record.values[2],
                  hash(image.image) == image.imageHash else {
                throw ToolError.sidecarMismatch("\(label) line \(index + 1) does not match trace record/image hash")
            }
        }
    }

    private static func decodeSnapshots(_ data: Data) throws -> [GlobalSnapshot] {
        guard data.count == snapshotByteCount * 2 else { throw ToolError.snapshotMismatch("expected 96 snapshot bytes, got \(data.count)") }
        var cursor = Cursor(data)
        var snapshots: [GlobalSnapshot] = []
        for _ in 0..<2 {
            guard try cursor.readUInt32() == 1, try cursor.readUInt32() == UInt32(snapshotByteCount) else { throw ToolError.snapshotMismatch("invalid ABI header") }
            let tick = try cursor.readUInt64()
            let fields = try (0..<6).map { _ in try cursor.readUInt32() }
            guard try cursor.readUInt32() == 0, try cursor.readUInt32() == 0 else { throw ToolError.snapshotMismatch("reserved snapshot bytes are nonzero") }
            snapshots.append(GlobalSnapshot(simulationTick: tick, fields: fields))
        }
        return snapshots
    }

    private static func validateSnapshots(_ snapshots: [GlobalSnapshot], against trace: RawTrace) throws {
        guard snapshots.map(\.simulationTick) == [2, 3] else { throw ToolError.snapshotMismatch("tick window is not [2, 3]") }
        let records = trace.records.filter { $0.domain == 0 && $0.recordKind == 1 }
        guard records.count == 12 else { throw ToolError.snapshotMismatch("global record count is not 12") }
        for snapshotIndex in 0..<2 {
            let base = snapshotIndex * 6
            for field in 0..<6 {
                let record = records[base + field]
                guard record.simulationTick == snapshots[snapshotIndex].simulationTick,
                      record.recordID == UInt64(field + 1), record.values.count == 1,
                      record.values[0] == UInt64(snapshots[snapshotIndex].fields[field]) else {
                    throw ToolError.snapshotMismatch("snapshot field \(field + 1) does not match global trace")
                }
            }
        }
    }

    private static func rejectTamperedTrace(_ url: URL) throws {
        do {
            _ = try SM64OracleTraceFile.read(from: url)
            throw ToolError.tamperAccepted(url)
        } catch ToolError.tamperAccepted { throw ToolError.tamperAccepted(url) }
        catch SM64OracleTraceCodecError.nonCanonicalHash { return }
        catch { throw ToolError.invalidTrace(url, String(describing: error)) }
    }

    private static func makeReport(rows: [ManifestRow], target: ManifestRow) -> String {
        rows.sorted { $0.shard.id < $1.shard.id }.map { row in
            if row.shard.id == target.shard.id { return [formatID(row.shard.id), "passed", "16", "16", "16", ""].joined(separator: "|") }
            return [formatID(row.shard.id), "planned", "0", "0", "0", ""].joined(separator: "|")
        }.joined(separator: "\n") + "\n"
    }

    private static func validateReport(_ text: String, manifest: String) throws {
        do {
            let ledger = try SM64RouteShardExecutionLedger(manifest: manifest, report: text)
            guard ledger.count == manifestRowCount, ledger.plannedCount == manifestRowCount - 1,
                  ledger.terminalCount == 1, try ledger.state(for: shardID) == .passed else {
                throw ToolError.reportInvalid("expected one passed row and 7419 planned rows")
            }
            guard try ledger.evidence(for: shardID)?.actualRecords == 16 else {
                throw ToolError.reportInvalid("target evidence count is not 16")
            }
        } catch let error as ToolError { throw error }
        catch { throw ToolError.reportInvalid(String(describing: error)) }
    }

    private static func formatID(_ id: UInt64) -> String { String(format: "0x%016llx", id) }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
