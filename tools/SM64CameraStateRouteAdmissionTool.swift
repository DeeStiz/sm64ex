import Foundation

/// Admits the generated oracle_hook|camera_state shard only from the complete
/// independent C/Swift/ASan camera artifacts.  The tool deliberately reads
/// evidence; it does not construct records, use SM64RouteShardFixture, or
/// rewrite the generated manifest.
@main
struct SM64CameraStateRouteAdmissionTool {
    private static let routeShardID: UInt64 = 0x4eb1_9b71_d76b_e0d4
    private static let routeInputSeed: UInt64 = 0xb572_8a6c_95a2_0bac
    private static let routeSaveSeed: UInt64 = 0x06d7_c939_379a_2dd5
    private static let routeRecordFirst: UInt64 = 300
    private static let routeRecordLast: UInt64 = 306
    private static let routeRecordCount = Int(routeRecordLast - routeRecordFirst + 1)
    private static let routeTickValues: [UInt64] = [2, 3]
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize
    private static let fnvOffset: UInt64 = 1_469_598_103_934_665_603
    private static let fnvPrime: UInt64 = 1_099_511_628_211

    private enum ToolError: Error, CustomStringConvertible {
        case invalidArguments(String)
        case unreadable(URL, Error)
        case invalidManifest(String)
        case wrongManifestRow(String)
        case missingEvidence(URL)
        case invalidTrace(URL, Error)
        case invalidHeader(URL, String)
        case headerMismatch(String)
        case fingerprintMismatch(String, UInt64, UInt64)
        case wrongFingerprint(String, UInt64, UInt64)
        case wrongRecordCount(String, Int)
        case wrongTickWindow(String, [UInt64])
        case wrongRecord(String, Int, String)
        case recordBytesMismatch
        case singleTraceEvidence
        case tamperAccepted(URL)
        case missingMarker(URL, String)
        case sanitizerFinding(URL)
        case reportAlreadyAdvanced(UInt64, SM64RouteShardExecutionState)
        case reportNotPristine(Int, Int)
        case ledgerMutation(Error)
        case unwritable(URL, Error)

        var description: String {
            switch self {
            case let .invalidArguments(message): return message
            case let .unreadable(url, error): return "cannot read \(url.path): \(error)"
            case let .invalidManifest(reason): return "invalid route-shard manifest: \(reason)"
            case let .wrongManifestRow(reason): return "camera-state manifest row mismatch: \(reason)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidTrace(url, error): return "invalid trace \(url.path): \(error)"
            case let .invalidHeader(url, reason): return "invalid trace header \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift header mismatch: \(field)"
            case let .fingerprintMismatch(field, expected, actual):
                return String(
                    format: "C/Swift fingerprint mismatch %@: 0x%016llx != 0x%016llx",
                    field, expected, actual
                )
            case let .wrongFingerprint(field, expected, actual):
                return String(
                    format: "wrong canonical fingerprint %@: expected 0x%016llx got 0x%016llx",
                    field, expected, actual
                )
            case let .wrongRecordCount(label, count):
                return "\(label) record count \(count) is not \(routeRecordCount * routeTickValues.count)"
            case let .wrongTickWindow(label, ticks):
                return "\(label) tick window \(ticks) is not exactly [2, 3]"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch: return "independent C/Swift/ASan trace bytes differ"
            case .singleTraceEvidence: return "C, Swift, and ASan evidence must be distinct artifacts"
            case let .tamperAccepted(url): return "tampered trace was accepted: \(url.path)"
            case let .missingMarker(url, marker): return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .reportAlreadyAdvanced(id, state):
                return String(format: "route shard 0x%016llx is already \(state.rawValue); rerun rejected", id)
            case let .reportNotPristine(planned, terminal):
                return "admission report is not pristine (planned=\(planned) terminal=\(terminal)); partial or mismatched report rejected"
            case let .ledgerMutation(error): return "route-shard ledger mutation rejected: \(error)"
            case let .unwritable(url, error): return "cannot write \(url.path): \(error)"
            }
        }
    }

    private struct Options {
        let manifest: URL
        let cTrace: URL
        let swiftTrace: URL
        let tamperedTrace: URL
        let debugLog: URL
        let swiftLog: URL
        let asanTrace: URL
        let asanLog: URL
        let report: URL
    }

    private struct RawTrace {
        let url: URL
        let bytes: Data
        let configuration: SM64OracleTraceConfiguration
        let records: [SM64OracleTraceRecord]
    }

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

    private struct CanonicalFingerprintNames {
        let build = "build"
        let content = "content"
        let timebase = "timebase"
        let configuration = "configuration"
        let initialSave = "initial_save"
        let coverage = "coverage"
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-camera-state-route-admit: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctEvidence(options)

        let manifest = try read(options.manifest)
        let shard = try resolveShard(manifest)
        guard shard.id == routeShardID,
              shard.inputSeed == routeInputSeed, shard.saveSeed == routeSaveSeed,
              shard.expectedDomains == [.cameraState], shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("camera row ID, seeds, domain, or planned state do not match")
        }

        let existingReport: String?
        if FileManager.default.fileExists(atPath: options.report.path) {
            existingReport = try read(options.report)
        } else {
            existingReport = nil
        }
        var ledger: SM64RouteShardExecutionLedger
        do {
            ledger = try SM64RouteShardExecutionLedger(manifest: manifest, report: existingReport)
        } catch {
            throw ToolError.ledgerMutation(error)
        }
        let beforePlanned = ledger.plannedCount
        let beforeTerminal = ledger.terminalCount
        let beforeState: SM64RouteShardExecutionState
        do {
            beforeState = try ledger.state(for: shard.id)
        } catch {
            throw ToolError.ledgerMutation(error)
        }
        guard beforeState == .planned else {
            throw ToolError.reportAlreadyAdvanced(shard.id, beforeState)
        }
        guard beforePlanned == ledger.count, beforeTerminal == 0 else {
            throw ToolError.reportNotPristine(beforePlanned, beforeTerminal)
        }

        try requireMarker(options.debugLog, "camera_state_route_header mode=1 schema=4")
        try requireMarker(options.debugLog, "camera_state_route_init status=0 oracle=0")
        try requireMarker(options.debugLog, "camera_state_route_step index=0 status=0 oracle=0 parity=0")
        try requireMarker(options.debugLog, "camera_state_route_step index=1 status=0 oracle=0 parity=0")
        try requireMarker(options.debugLog, "camera_state_route_debug oracle_end=0 result_status=0")
        try requireMarker(options.debugLog, "c_camera_state_route_recorded shard=0x4eb19b71d76be0d4")
        try requireMarker(options.debugLog, "records=14 ticks=3 coverage=0x14ba7a692ee1c471")
        try requireMarker(options.swiftLog, "camera_state_pairing_audit admitted=1")
        try requireMarker(options.swiftLog, "c_records=14 swift_records=14 blockers= first_divergence=none")
        try requireMarker(options.swiftLog, "camera_position_pairing matched=1")
        try requireMarker(options.swiftLog, "camera_focus_pairing matched=1")
        try requireMarker(options.swiftLog, "camera_state_pairing_tamper_rejected=1")
        try requireMarker(options.asanLog, "camera_state_route_debug oracle_end=0 result_status=0")
        try requireMarker(options.asanLog, "c_camera_state_route_recorded shard=0x4eb19b71d76be0d4")
        try requireMarker(options.asanLog, "records=14 ticks=3 coverage=0x14ba7a692ee1c471")
        try rejectSanitizerFindings(in: options.asanLog)

        let cTrace = try loadTrace(options.cTrace)
        let swiftTrace = try loadTrace(options.swiftTrace)
        let asanTrace = try loadTrace(options.asanTrace)
        try validateHeaders(cTrace.configuration, swiftTrace.configuration)
        try validateHeaders(cTrace.configuration, asanTrace.configuration)
        try validateCanonicalHeader(cTrace.configuration, label: "C")
        try validateCanonicalHeader(swiftTrace.configuration, label: "Swift")
        try validateCanonicalHeader(asanTrace.configuration, label: "ASan")
        try validateRecords(cTrace, label: "C")
        try validateRecords(swiftTrace, label: "Swift")
        try validateRecords(asanTrace, label: "ASan")
        guard cTrace.bytes == swiftTrace.bytes, cTrace.bytes == asanTrace.bytes else {
            throw ToolError.recordBytesMismatch
        }
        try rejectTamperedTrace(options.tamperedTrace)

        do {
            try ledger.begin(id: shard.id)
            try ledger.finish(
                id: shard.id,
                state: .passed,
                evidence: SM64RouteShardExecutionEvidence(
                    expectedRecords: UInt64(routeRecordCount * routeTickValues.count),
                    actualRecords: UInt64(cTrace.records.count),
                    matchedRecords: UInt64(cTrace.records.count)
                )
            )
        } catch {
            throw ToolError.ledgerMutation(error)
        }
        let afterPlanned = ledger.plannedCount
        let afterTerminal = ledger.terminalCount
        guard afterPlanned == beforePlanned - 1, afterTerminal == beforeTerminal + 1 else {
            throw ToolError.ledgerMutation(ToolError.reportNotPristine(afterPlanned, afterTerminal))
        }
        do {
            try FileManager.default.createDirectory(
                at: options.report.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(ledger.report().utf8).write(to: options.report, options: .atomic)
        } catch {
            throw ToolError.unwritable(options.report, error)
        }
        guard try ledger.state(for: shard.id) == .passed else {
            throw ToolError.ledgerMutation(ToolError.reportAlreadyAdvanced(shard.id, .running))
        }

        print(
            String(
                format: "SM64 Camera-state route admission passed shard=0x%016llx "
                    + "records=%d ticks=2,3 "
                    + "before_planned=%d before_terminal=%d after_planned=%d "
                    + "after_terminal=%d report=%@ c_trace=%@ swift_trace=%@ "
                    + "asan_trace=%@ tamper_rejected=1",
                shard.id, cTrace.records.count,
                beforePlanned, beforeTerminal, afterPlanned, afterTerminal,
                options.report.path, options.cTrace.path, options.swiftTrace.path,
                options.asanTrace.path
            )
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-camera-state-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --tampered-trace TAMPERED_TRACE --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-trace ASAN_TRACE --asan-log ASAN_LOG --report REPORT"
        guard arguments.count == 18, arguments.count.isMultiple(of: 2) else {
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
            "--manifest", "--c-trace", "--swift-trace", "--tampered-trace",
            "--debug-log", "--swift-log", "--asan-trace", "--asan-log", "--report",
        ]
        guard values.keys.allSatisfy(known.contains), values.count == known.count else {
            throw ToolError.invalidArguments(usage)
        }
        func url(_ key: String) -> URL {
            URL(fileURLWithPath: values[key]!).standardizedFileURL
        }
        return Options(
            manifest: url("--manifest"), cTrace: url("--c-trace"),
            swiftTrace: url("--swift-trace"), tamperedTrace: url("--tampered-trace"),
            debugLog: url("--debug-log"), swiftLog: url("--swift-log"),
            asanTrace: url("--asan-trace"), asanLog: url("--asan-log"),
            report: url("--report")
        )
    }

    private static func requireDistinctEvidence(_ options: Options) throws {
        let urls = [options.cTrace, options.swiftTrace, options.asanTrace]
            .map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard Set(urls).count == urls.count else { throw ToolError.singleTraceEvidence }
    }

    private static func read(_ url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ToolError.unreadable(url, error)
        }
    }

    private static func resolveShard(_ manifest: String) throws -> SM64RouteShard {
        let lines = manifest.split(whereSeparator: { $0.isNewline })
        guard lines.count >= 2,
              lines[0] == "# sm64-modern-route-shards-v1",
              lines[1] == "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes" else {
            throw ToolError.invalidManifest("invalid header")
        }
        var matches: [SM64RouteShard] = []
        for (offset, line) in lines.dropFirst(2).enumerated() {
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            do {
                let shard = try SM64RouteShard(manifestLine: line, lineNumber: offset + 3)
                if shard.domain == "oracle_hook"
                    && shard.identity == "camera_state"
                    && shard.source == "src/pc/sm64_modern_gameplay_parity.c"
                    && shard.inputSeed == routeInputSeed
                    && shard.saveSeed == routeSaveSeed {
                    matches.append(shard)
                }
            } catch let error as ToolError {
                throw error
            } catch {
                throw ToolError.invalidManifest("line \(offset + 3): \(error)")
            }
        }
        guard matches.count == 1, let shard = matches.first else {
            throw ToolError.wrongManifestRow("expected exactly one camera row for the canonical seeds; found \(matches.count)")
        }
        guard shard.expectedDomains == [.cameraState], shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("expected camera_state domain and planned status")
        }
        return shard
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
        _ c: SM64OracleTraceConfiguration,
        _ other: SM64OracleTraceConfiguration
    ) throws {
        guard c.regionCode == other.regionCode else { throw ToolError.headerMismatch("region_code") }
        guard c.mode == other.mode else { throw ToolError.headerMismatch("mode") }
        let expected = Fingerprints(c)
        let actual = Fingerprints(other)
        let names = CanonicalFingerprintNames()
        let pairs: [(String, UInt64, UInt64)] = [
            (names.build, expected.build, actual.build),
            (names.content, expected.content, actual.content),
            (names.timebase, expected.timebase, actual.timebase),
            (names.configuration, expected.configuration, actual.configuration),
            (names.initialSave, expected.initialSave, actual.initialSave),
            (names.coverage, expected.coverage, actual.coverage),
        ]
        for (name, expectedValue, actualValue) in pairs where expectedValue != actualValue {
            throw ToolError.fingerprintMismatch(name, expectedValue, actualValue)
        }
    }

    private static func validateCanonicalHeader(
        _ configuration: SM64OracleTraceConfiguration,
        label: String
    ) throws {
        guard configuration.regionCode == 0x5553 else {
            throw ToolError.invalidHeader(URL(fileURLWithPath: label), "region code")
        }
        guard configuration.mode == .record else {
            throw ToolError.invalidHeader(URL(fileURLWithPath: label), "mode is not record")
        }
        let actual = Fingerprints(configuration)
        let expected = Fingerprints(
            SM64OracleTraceConfiguration(
                regionCode: 0x5553,
                mode: .record,
                buildFingerprint: hashString("sm64-modern-camera-state-route-build-v1"),
                contentFingerprint: hashString(
                    "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|camera_state"
                ),
                timebaseFingerprint: timebaseFingerprint(),
                configurationFingerprint: hashString(
                    "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                        + "shard=0x4eb19b71d76be0d4"
                ),
                initialSaveFingerprint: hashString(
                    "save=empty-us-slot-0;seed=0x06d7c939379a2dd5"
                ),
                coverageFingerprint: coverageFingerprint()
            )
        )
        let names = CanonicalFingerprintNames()
        let pairs: [(String, UInt64, UInt64)] = [
            (names.build, expected.build, actual.build),
            (names.content, expected.content, actual.content),
            (names.timebase, expected.timebase, actual.timebase),
            (names.configuration, expected.configuration, actual.configuration),
            (names.initialSave, expected.initialSave, actual.initialSave),
            (names.coverage, expected.coverage, actual.coverage),
        ]
        for (name, expectedValue, actualValue) in pairs where expectedValue != actualValue {
            throw ToolError.wrongFingerprint("\(label).\(name)", expectedValue, actualValue)
        }
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        let count = trace.records.count
        guard count == routeRecordCount * routeTickValues.count else {
            throw ToolError.wrongRecordCount(label, count)
        }
        let ticks = Array(Set(trace.records.map(\.simulationTick)).sorted())
        guard ticks == routeTickValues else { throw ToolError.wrongTickWindow(label, ticks) }
        var observedIDs: Set<UInt64> = []
        var observedKeys: Set<String> = []
        for (index, record) in trace.records.enumerated() {
            let tickIndex = index / routeRecordCount
            let expectedTick = routeTickValues[tickIndex]
            let expectedSequence = UInt32(index % routeRecordCount)
            let expectedRecordID = routeRecordFirst + UInt64(index % routeRecordCount)
            guard record.simulationTick == expectedTick else {
                throw ToolError.wrongRecord(label, index, "tick \(record.simulationTick) != \(expectedTick)")
            }
            guard record.domain == SM64RouteShardTraceDomain.cameraState.cDomain else {
                throw ToolError.wrongRecord(label, index, "domain \(record.domain) != 5")
            }
            guard record.recordKind == SM64RouteShardTraceDomain.cameraState.cRecordKind else {
                throw ToolError.wrongRecord(label, index, "record kind \(record.recordKind) != 1")
            }
            guard record.recordID == expectedRecordID else {
                throw ToolError.wrongRecord(label, index, "record ID \(record.recordID) != \(expectedRecordID)")
            }
            guard record.sequence == expectedSequence else {
                throw ToolError.wrongRecord(label, index, "sequence \(record.sequence) != \(expectedSequence)")
            }
            let expectedValueCount = (record.recordID == 305 || record.recordID == 306) ? 3 : 1
            guard record.values.count == expectedValueCount else {
                throw ToolError.wrongRecord(label, index, "value count \(record.values.count) != \(expectedValueCount)")
            }
            observedIDs.insert(record.recordID)
            observedKeys.insert("\(record.domain):\(record.recordKind)")
        }
        guard observedIDs == Set(routeRecordFirst...routeRecordLast) else {
            throw ToolError.wrongRecord(label, 0, "record-ID coverage is incomplete")
        }
        guard observedKeys == ["5:1"] else {
            throw ToolError.wrongRecord(label, 0, "domain/record-kind coverage is \(observedKeys)")
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

    private static func hashString(_ value: String) -> UInt64 {
        value.utf8.reduce(fnvOffset) { hash, byte in
            (hash ^ UInt64(byte)) &* fnvPrime
        }
    }

    private static func hashUInt64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var hash = initial
        for byte in 0..<8 {
            hash ^= (value >> UInt64(byte * 8)) & 0xff
            hash &*= fnvPrime
        }
        return hash
    }

    private static func hashUInt32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
        var hash = initial
        for byte in 0..<4 {
            hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
            hash &*= fnvPrime
        }
        return hash
    }

    private static func timebaseFingerprint() -> UInt64 {
        [UInt32(3), 60, 1, 30, 1, 2, 2].reduce(fnvOffset, hashUInt32)
    }

    private static func coverageFingerprint() -> UInt64 {
        var hash = fnvOffset
        for recordID in routeRecordFirst...routeRecordLast {
            hash = hashUInt64(hash, 5)
            hash = hashUInt64(hash, 0)
            hash = hashUInt64(hash, recordID)
        }
        return hashUInt64(hash, UInt64(routeRecordCount))
    }
}
