import Foundation

/// Admits the canonical oracle_hook|effects row from independent C, Swift,
/// ASan, and optimized schema-4 artifacts.  The generated manifest is
/// immutable input; this tool writes one isolated report only.  The result is
/// source/value evidence for the native effect receipt seam, not device,
/// haptic, audible, visual, or human acceptance.
@main
struct SM64EffectsReceiptRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let manifestRowCount = 7_420
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize
    private static let receiptSize = 120

    private struct Fingerprints: Equatable {
        let build: UInt64
        let content: UInt64
        let timebase: UInt64
        let configuration: UInt64
        let initialSave: UInt64
        let coverage: UInt64
    }

    private static let shardID: UInt64 = 0x3951_f033_3dc3_c5da
    private static let inputSeed: UInt64 = 0x5ab4_08e5_e404_b1d6
    private static let saveSeed: UInt64 = 0x5543_fe1d_f61f_7e9f
    private static let identity = "effects"
    private static let cDomain: UInt32 = 12
    private static let recordKind: UInt32 = 4
    private static let ticks: [UInt64] = [2, 3]
    private static let expectedRecordCount = 58
    private static let expectedIDCounts: [UInt64: Int] = [
        1: 5, 3: 2, 4: 49, 5: 2,
    ]
    private static let fingerprints = Fingerprints(
        build: 0x82f6_29ab_59f0_1865,
        content: 0x2c1b_d3b6_2dcf_5a74,
        timebase: 0xccc1_9787_cd09_f0c2,
        configuration: 0xc120_d19f_b080_bb1f,
        initialSave: 0x8747_5c08_5edb_9309,
        coverage: 0x1275_6c2d_e89c_fbc4
    )

    private struct Options {
        let manifest: URL
        let cTrace: URL
        let swiftTrace: URL
        let asanTrace: URL
        let releaseTrace: URL
        let tamperedTrace: URL
        let cReceipts: URL
        let asanReceipts: URL
        let releaseReceipts: URL
        let tamperedReceipts: URL
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
        let bytes: Data
        let configuration: SM64OracleTraceConfiguration
        let records: [SM64OracleTraceRecord]
    }

    private struct EffectReceipt: Equatable {
        let simulationTick: UInt64
        let subjectID: UInt64
        let effectID: UInt64
        let sequence: UInt32
        let valueCount: UInt32
        let flags: UInt32
        let reserved: UInt32
        let values: [UInt64]
        let canonicalHash: UInt64

        var traceRecord: SM64OracleTraceRecord? {
            try? SM64OracleTraceRecord(
                simulationTick: simulationTick,
                domain: cDomain,
                recordKind: recordKind,
                subjectID: subjectID,
                recordID: effectID,
                sequence: sequence,
                flags: flags,
                values: values
            )
        }
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
        case receiptBytesMismatch
        case invalidReceipts(URL, String)
        case receiptMismatch(String)
        case singleTraceEvidence
        case tamperAccepted(URL)
        case receiptTamperAccepted(URL)
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
            case .receiptBytesMismatch:
                return "independent C/ASan/Release receipt bytes differ"
            case let .invalidReceipts(url, reason):
                return "invalid effect receipts \(url.path): \(reason)"
            case let .receiptMismatch(reason):
                return "effect receipt/trace mismatch: \(reason)"
            case .singleTraceEvidence:
                return "C, Swift, ASan, Release, tampered traces and receipts must be distinct artifacts"
            case let .tamperAccepted(url): return "tampered trace was accepted: \(url.path)"
            case let .receiptTamperAccepted(url):
                return "tampered effect receipt was accepted: \(url.path)"
            case let .missingMarker(url, marker):
                return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .reportAlreadyExists(url):
                return "isolated admission report already exists; rerun rejected: \(url.path)"
            case let .reportCollision(url):
                return "isolated report collides with immutable evidence: \(url.path)"
            case let .reportInvalid(reason):
                return "isolated report validation failed: \(reason)"
            case let .unwritable(url, error):
                return "cannot write \(url.path): \(error)"
            }
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(
                Data(("sm64-effects-receipt-route-admit: \(error)\n").utf8)
            )
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctEvidence(options)
        try requireFreshReport(options)

        let rows = try parseManifest(try read(options.manifest))
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

        let cReceiptData = try readData(options.cReceipts)
        let asanReceiptData = try readData(options.asanReceipts)
        let releaseReceiptData = try readData(options.releaseReceipts)
        guard cReceiptData == asanReceiptData,
              cReceiptData == releaseReceiptData else {
            throw ToolError.receiptBytesMismatch
        }
        let cReceipts = try decodeReceipts(options.cReceipts)
        let asanReceipts = try decodeReceipts(options.asanReceipts)
        let releaseReceipts = try decodeReceipts(options.releaseReceipts)
        try validateReceipts(cReceipts, against: cTrace, label: "C")
        try validateReceipts(asanReceipts, against: asanTrace, label: "ASan")
        try validateReceipts(releaseReceipts, against: releaseTrace, label: "Release")
        try rejectTamperedTrace(options.tamperedTrace)
        try rejectTamperedReceipts(
            options.tamperedReceipts,
            expectedData: cReceiptData
        )

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
            "SM64 effects receipt route isolated admission passed "
                + "shard=\(formatID(shardID)) records=58 ticks=2,3 domain=12 kind=4 "
                + "ids=1:5,3:2,4:49,5:2 manifest_rows=\(rows.count) "
                + "report_rows=\(rows.count) passed_rows=1 planned_rows=\(rows.count - 1) "
                + "report=\(options.report.path) "
                + "c_swift_asan_release_byte_match=1 "
                + "receipts_c_asan_release_byte_match=1 "
                + "canonical_hash_tamper_rejected=1 receipt_tamper_rejected=1 "
                + "effects_source_admitted=1 device_effects=unverified "
                + "human_acceptance=unverified fixture_only=0 manifest_mutated=0 "
                + "ledger_mutated=0 history_mutated=0 rerun_fence=1"
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-effects-receipt-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --release-trace RELEASE_TRACE --tampered-trace TAMPERED_TRACE --c-receipts C_RECEIPTS --asan-receipts ASAN_RECEIPTS --release-receipts RELEASE_RECEIPTS --tampered-receipts TAMPERED_RECEIPTS --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --release-log RELEASE_LOG --report REPORT"
        guard arguments.count == 30, arguments.count.isMultiple(of: 2) else {
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
            "--release-trace", "--tampered-trace", "--c-receipts",
            "--asan-receipts", "--release-receipts", "--tampered-receipts",
            "--debug-log", "--swift-log", "--asan-log", "--release-log",
            "--report",
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
            cReceipts: url("--c-receipts"),
            asanReceipts: url("--asan-receipts"),
            releaseReceipts: url("--release-receipts"),
            tamperedReceipts: url("--tampered-receipts"),
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
            options.releaseTrace, options.tamperedTrace, options.cReceipts,
            options.asanReceipts, options.releaseReceipts, options.tamperedReceipts,
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
        guard shard.domain == "oracle_hook",
              shard.identity == identity,
              shard.source == "src/pc/sm64_modern_gameplay_parity.c",
              shard.inputSeed == inputSeed,
              shard.saveSeed == saveSeed,
              shard.expectedDomains == [.effects],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow(
                "identity/source/seeds/expected domain/status do not match effects route"
            )
        }
        return target
    }

    private static func loadTrace(_ url: URL) throws -> RawTrace {
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
            throw ToolError.invalidHeader(
                URL(fileURLWithPath: label), "region code is not 0x5553"
            )
        }
        guard configuration.mode == .record else {
            throw ToolError.invalidHeader(
                URL(fileURLWithPath: label), "mode is not record"
            )
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
        for field in fields where field.1 != field.2 {
            throw ToolError.wrongFingerprint(field.0, field.1, field.2)
        }
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        guard trace.records.count == expectedRecordCount else {
            throw ToolError.wrongRecordCount(label, trace.records.count, expectedRecordCount)
        }
        var lastTick: UInt64?
        var lastSequence: UInt32 = 0
        var idCounts: [UInt64: Int] = [:]
        for (index, record) in trace.records.enumerated() {
            guard record.domain == cDomain, record.recordKind == recordKind else {
                throw ToolError.wrongRecord(
                    label, index,
                    "domain/kind \(record.domain)/\(record.recordKind) is not 12/4"
                )
            }
            guard expectedIDCounts.keys.contains(record.recordID) else {
                throw ToolError.wrongRecord(
                    label, index, "effect ID \(record.recordID) is outside canonical IDs"
                )
            }
            idCounts[record.recordID, default: 0] += 1
            if let lastTick {
                guard record.simulationTick >= lastTick else {
                    throw ToolError.wrongRecord(label, index, "tick order regressed")
                }
                if record.simulationTick == lastTick {
                    guard record.sequence == lastSequence &+ 1 else {
                        throw ToolError.wrongRecord(label, index, "sequence is not contiguous")
                    }
                } else {
                    guard record.sequence == 0 else {
                        throw ToolError.wrongRecord(label, index, "new tick did not reset sequence")
                    }
                }
            } else {
                guard record.sequence == 0 else {
                    throw ToolError.wrongRecord(label, index, "first sequence is not zero")
                }
            }
            lastTick = record.simulationTick
            lastSequence = record.sequence
        }
        let observedTicks = Array(Set(trace.records.map(\.simulationTick)).sorted())
        guard observedTicks == ticks else {
            throw ToolError.wrongTickWindow(label, observedTicks, ticks)
        }
        guard idCounts == expectedIDCounts else {
            throw ToolError.wrongRecord(
                label, 0, "effect ID counts \(idCounts) do not equal \(expectedIDCounts)"
            )
        }
    }

    private static func requireMarkers(_ options: Options) throws {
        let nativeMarkers = [
            "effects_route_debug oracle_end=0 result_status=0 actual=1789 retained=58 failures=0",
            "effects_route_recorded path=",
            "records=58 receipts=58 ticks=3 coverage=0x12756c2de89cfbc4 owner_thread=1",
        ]
        for marker in nativeMarkers {
            try requireMarker(options.debugLog, marker)
            try requireMarker(options.asanLog, marker)
            try requireMarker(options.releaseLog, marker)
        }
        let swiftMarkers = [
            "swift_effects_route_recorded records=58 ticks=2,3 ids=1:5,3:2,4:49,5:2 owner_thread_receipts=1",
            "effects_canonical_hash_tamper_rejected=1",
            "effects_receipt_hash_tamper_rejected=1",
        ]
        for marker in swiftMarkers {
            try requireMarker(options.swiftLog, marker)
        }
        try rejectSanitizerFindings(in: options.asanLog)
    }

    private static func requireMarker(_ url: URL, _ marker: String) throws {
        guard try read(url).contains(marker) else {
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

    private static func decodeReceipts(_ url: URL) throws -> [EffectReceipt] {
        let data = try readData(url)
        guard !data.isEmpty, data.count.isMultiple(of: receiptSize) else {
            throw ToolError.invalidReceipts(url, "size is not a positive multiple of 120")
        }
        var receipts: [EffectReceipt] = []
        receipts.reserveCapacity(data.count / receiptSize)
        var offset = 0
        while offset < data.count {
            guard let abi = readUInt32(data, offset: &offset),
                  let structSize = readUInt32(data, offset: &offset),
                  let tick = readUInt64(data, offset: &offset),
                  let subject = readUInt64(data, offset: &offset),
                  let effectID = readUInt64(data, offset: &offset),
                  let sequence = readUInt32(data, offset: &offset),
                  let valueCount = readUInt32(data, offset: &offset),
                  let flags = readUInt32(data, offset: &offset),
                  let reserved = readUInt32(data, offset: &offset) else {
                throw ToolError.invalidReceipts(url, "truncated fixed-width record")
            }
            var allValues: [UInt64] = []
            allValues.reserveCapacity(8)
            for _ in 0..<8 {
                guard let value = readUInt64(data, offset: &offset) else {
                    throw ToolError.invalidReceipts(url, "truncated values")
                }
                allValues.append(value)
            }
            guard let canonicalHash = readUInt64(data, offset: &offset) else {
                throw ToolError.invalidReceipts(url, "truncated canonical hash")
            }
            guard abi == 1, structSize >= UInt32(receiptSize),
                  valueCount <= 8, reserved == 0,
                  expectedIDCounts.keys.contains(effectID) else {
                throw ToolError.invalidReceipts(url, "ABI, value count, reserved, or effect ID mismatch")
            }
            let values = Array(allValues.prefix(Int(valueCount)))
            guard let record = try? SM64OracleTraceRecord(
                simulationTick: tick,
                domain: cDomain,
                recordKind: recordKind,
                subjectID: subject,
                recordID: effectID,
                sequence: sequence,
                flags: flags,
                values: values
            ), record.canonicalHash == canonicalHash else {
                throw ToolError.invalidReceipts(url, "canonical hash mismatch")
            }
            receipts.append(
                EffectReceipt(
                    simulationTick: tick,
                    subjectID: subject,
                    effectID: effectID,
                    sequence: sequence,
                    valueCount: valueCount,
                    flags: flags,
                    reserved: reserved,
                    values: values,
                    canonicalHash: canonicalHash
                )
            )
        }
        return receipts
    }

    private static func readUInt32(_ data: Data, offset: inout Int) -> UInt32? {
        guard offset + 4 <= data.count else { return nil }
        var value: UInt32 = 0
        for index in 0..<4 {
            value |= UInt32(data[offset + index]) << UInt32(index * 8)
        }
        offset += 4
        return value
    }

    private static func readUInt64(_ data: Data, offset: inout Int) -> UInt64? {
        guard offset + 8 <= data.count else { return nil }
        var value: UInt64 = 0
        for index in 0..<8 {
            value |= UInt64(data[offset + index]) << UInt64(index * 8)
        }
        offset += 8
        return value
    }

    private static func validateReceipts(
        _ receipts: [EffectReceipt],
        against trace: RawTrace,
        label: String
    ) throws {
        guard receipts.count == expectedRecordCount else {
            throw ToolError.receiptMismatch(
                "\(label) receipt count \(receipts.count) is not \(expectedRecordCount)"
            )
        }
        for (index, receipt) in receipts.enumerated() {
            guard let record = receipt.traceRecord,
                  record == trace.records[index],
                  receipt.canonicalHash == record.canonicalHash else {
                throw ToolError.receiptMismatch(
                    "\(label) receipt \(index) does not equal the schema-4 trace record"
                )
            }
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

    private static func rejectTamperedReceipts(
        _ url: URL,
        expectedData: Data
    ) throws {
        let data = try readData(url)
        guard data != expectedData else {
            throw ToolError.receiptTamperAccepted(url)
        }
        do {
            _ = try decodeReceipts(url)
            throw ToolError.receiptTamperAccepted(url)
        } catch ToolError.receiptTamperAccepted {
            throw ToolError.receiptTamperAccepted(url)
        } catch ToolError.invalidReceipts {
            return
        } catch {
            throw ToolError.invalidReceipts(url, "tampered receipt could not be classified")
        }
    }

    private static func makeIsolatedReport(
        rows: [ManifestRow],
        target: ManifestRow
    ) -> String {
        rows.sorted { $0.shard.id < $1.shard.id }.map { row in
            if row.shard.id == target.shard.id {
                return [formatID(row.shard.id), "passed", "58", "58", "58", ""]
                    .joined(separator: "|")
            }
            return [formatID(row.shard.id), "planned", "0", "0", "0", ""]
                .joined(separator: "|")
        }.joined(separator: "\n") + "\n"
    }

    private static func validateIsolatedReport(
        _ text: String,
        rows: [ManifestRow],
        target: ManifestRow
    ) throws {
        let lines = text.split(whereSeparator: { $0.isNewline })
        guard lines.count == rows.count else {
            throw ToolError.reportInvalid(
                "expected \(rows.count) rows, got \(lines.count)"
            )
        }
        let expectedIDs = Set(rows.map { $0.shard.id })
        var seen: Set<UInt64> = []
        var passed = 0
        for (index, line) in lines.enumerated() {
            let fields = line.split(separator: "|", omittingEmptySubsequences: false)
                .map(String.init)
            guard fields.count == 6,
                  let id = parseHex(fields[0]),
                  expectedIDs.contains(id),
                  seen.insert(id).inserted else {
                throw ToolError.reportInvalid(
                    "line \(index + 1) has invalid or duplicate shard row"
                )
            }
            guard let expected = UInt64(fields[2]),
                  let actual = UInt64(fields[3]),
                  let matched = UInt64(fields[4]) else {
                throw ToolError.reportInvalid(
                    "line \(index + 1) has invalid evidence counts"
                )
            }
            if id == target.shard.id {
                guard fields[1] == "passed",
                      expected == UInt64(expectedRecordCount),
                      actual == expected,
                      matched == expected,
                      fields[5].isEmpty else {
                    throw ToolError.reportInvalid(
                        "target row is not an exact passed effects receipt"
                    )
                }
                passed += 1
            } else {
                guard fields[1] == "planned",
                      expected == 0,
                      actual == 0,
                      matched == 0,
                      fields[5].isEmpty else {
                    throw ToolError.reportInvalid(
                        "non-target row was admitted or carried evidence"
                    )
                }
            }
        }
        guard seen == expectedIDs, passed == 1 else {
            throw ToolError.reportInvalid(
                "report does not contain exactly one selected passed row"
            )
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
