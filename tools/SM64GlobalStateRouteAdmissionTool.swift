import Foundation

/// Admits the generated oracle_hook|global_state shard only from the complete
/// independent C/Swift/ASan artifacts produced by the owner-thread route pair.
/// This tool never creates route records, never consumes SM64RouteShardFixture,
/// never edits the generated manifest, and writes only the caller's isolated
/// execution report after all evidence fences pass.
@main
struct SM64GlobalStateRouteAdmissionTool {
    private static let routeShardID: UInt64 = 0xb123_ff3e_997b_dc78
    private static let routeInputSeed: UInt64 = 0x0554_d9be_e9d4_fbe0
    private static let routeSaveSeed: UInt64 = 0x939f_f6a6_efd6_7889
    private static let routeRecordFirst: UInt64 = 1
    private static let routeRecordLast: UInt64 = 6
    private static let routeRecordCount = Int(routeRecordLast - routeRecordFirst + 1)
    private static let routeTickValues: [UInt64] = [2, 3]
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize
    private static let snapshotSize = 48
    private static let snapshotCount = 2
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
        case snapshotMismatch(String)
        case snapshotBytesMismatch
        case reportAlreadyAdvanced(UInt64, SM64RouteShardExecutionState)
        case reportNotPristine(Int, Int)
        case ledgerMutation(Error)
        case outputCollision(URL)
        case unwritable(URL, Error)

        var description: String {
            switch self {
            case let .invalidArguments(message): return message
            case let .unreadable(url, error): return "cannot read \(url.path): \(error)"
            case let .invalidManifest(reason): return "invalid route-shard manifest: \(reason)"
            case let .wrongManifestRow(reason): return "global-state manifest row mismatch: \(reason)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidTrace(url, error): return "invalid trace \(url.path): \(error)"
            case let .invalidHeader(url, reason): return "invalid artifact header \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift/ASan header mismatch: \(field)"
            case let .fingerprintMismatch(field, expected, actual):
                return String(
                    format: "independent fingerprint mismatch %@: 0x%016llx != 0x%016llx",
                    field, expected, actual
                )
            case let .wrongFingerprint(field, expected, actual):
                return String(
                    format: "wrong canonical fingerprint %@: expected 0x%016llx got 0x%016llx",
                    field, expected, actual
                )
            case let .wrongRecordCount(label, count):
                return "\(label) filtered route record count \(count) is not 12"
            case let .wrongTickWindow(label, ticks):
                return "\(label) tick window \(ticks) is not exactly [2, 3]"
            case let .wrongRecord(label, index, reason):
                return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch: return "independent C/Swift/ASan trace bytes differ"
            case .singleTraceEvidence: return "C, Swift, ASan, and tamper evidence must be distinct artifacts"
            case let .tamperAccepted(url): return "tampered trace was accepted: \(url.path)"
            case let .missingMarker(url, marker): return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .snapshotMismatch(reason): return "publication snapshot mismatch: \(reason)"
            case .snapshotBytesMismatch: return "C and ASan publication snapshot bytes differ"
            case let .reportAlreadyAdvanced(id, state):
                return String(
                    format: "route shard 0x%016llx is already %@; rerun rejected",
                    id, state.rawValue
                )
            case let .reportNotPristine(planned, terminal):
                return "admission report is not pristine (planned=\(planned) terminal=\(terminal))"
            case let .ledgerMutation(error): return "route-shard ledger mutation rejected: \(error)"
            case let .outputCollision(url): return "isolated report collides with manifest: \(url.path)"
            case let .unwritable(url, error): return "cannot write \(url.path): \(error)"
            }
        }
    }

    private struct Options {
        let manifest: URL
        let cTrace: URL
        let swiftTrace: URL
        let asanTrace: URL
        let tamperedTrace: URL
        let cSnapshots: URL
        let asanSnapshots: URL
        let debugLog: URL
        let swiftLog: URL
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

    private struct Snapshot: Equatable {
        let abiVersion: UInt32
        let structSize: UInt32
        let simulationTick: UInt64
        let globalTimer: UInt32
        let levelNumber: UInt32
        let areaIndex: UInt32
        let actNumber: UInt32
        let courseNumber: UInt32
        let randomSeed: UInt32
        let reserved: UInt32

        var values: [UInt64] {
            [
                UInt64(globalTimer),
                UInt64(levelNumber),
                UInt64(areaIndex),
                UInt64(actNumber),
                UInt64(courseNumber),
                UInt64(randomSeed),
            ]
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(
                Data(("sm64-global-state-route-admit: \(error)\n").utf8)
            )
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctEvidence(options)
        guard options.report.resolvingSymlinksInPath().standardizedFileURL.path
            != options.manifest.resolvingSymlinksInPath().standardizedFileURL.path else {
            throw ToolError.outputCollision(options.report)
        }

        let manifestText = try read(options.manifest)
        let shard = try resolveShard(manifestText)
        guard shard.id == routeShardID,
              shard.inputSeed == routeInputSeed,
              shard.saveSeed == routeSaveSeed,
              shard.expectedDomains == [.globalState],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("canonical ID, seeds, domain set, or planned status does not match")
        }

        let existingReport: String?
        if FileManager.default.fileExists(atPath: options.report.path) {
            existingReport = try read(options.report)
        } else {
            existingReport = nil
        }
        var ledger: SM64RouteShardExecutionLedger
        do {
            ledger = try SM64RouteShardExecutionLedger(
                manifest: manifestText,
                report: existingReport
            )
        } catch {
            throw ToolError.ledgerMutation(error)
        }
        let beforePlanned = ledger.plannedCount
        let beforeTerminal = ledger.terminalCount
        let beforeState: SM64RouteShardExecutionState
        do {
            beforeState = try ledger.state(for: routeShardID)
        } catch {
            throw ToolError.ledgerMutation(error)
        }
        guard beforeState == .planned else {
            throw ToolError.reportAlreadyAdvanced(routeShardID, beforeState)
        }
        guard ledger.count == 7420, beforePlanned == 7420, beforeTerminal == 0 else {
            throw ToolError.reportNotPristine(beforePlanned, beforeTerminal)
        }

        try requireMarker(options.debugLog, "global_state_route_init status=0 state=2 oracle=0 parity=0")
        try requireMarker(options.debugLog, "global_state_route_step index=0 status=0 oracle=0 parity=0")
        try requireMarker(options.debugLog, "global_state_route_step index=1 status=0 oracle=0 parity=0")
        try requireMarker(options.debugLog, "global_state_route_debug oracle_end=0 result_status=0 actual=1789 retained=12 failures=0")
        try requireMarker(options.debugLog, "global_state_route_recorded")
        try requireMarker(options.debugLog, "global_state_route_publication tick=2 timer=1 level=16 area=1 act=1 course=0 seed=45572")
        try requireMarker(options.debugLog, "global_state_route_publication tick=3 timer=2 level=16 area=1 act=1 course=0 seed=45572")
        try requireMarker(options.swiftLog, "swift_global_state_route_recorded snapshots=2 records=12 ticks=2,3 timer=1,2 seed=45572")
        try requireMarker(options.swiftLog, "global_state_pairing_audit admitted=1 c_records=12 swift_records=12 blockers= first_divergence=none")
        try requireMarker(options.swiftLog, "global_state_pairing_tamper_rejected=1")
        try requireMarker(options.asanLog, "global_state_route_debug oracle_end=0 result_status=0 actual=1789 retained=12 failures=0")
        try requireMarker(options.asanLog, "global_state_route_recorded")
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

        let cSnapshotData = try readData(options.cSnapshots)
        let asanSnapshotData = try readData(options.asanSnapshots)
        guard cSnapshotData == asanSnapshotData else {
            throw ToolError.snapshotBytesMismatch
        }
        let snapshots = try decodeSnapshots(cSnapshotData, from: options.cSnapshots)
        try validateSnapshots(snapshots, against: cTrace.records)
        try rejectTamperedTrace(options.tamperedTrace)

        do {
            try ledger.begin(id: routeShardID)
            try ledger.finish(
                id: routeShardID,
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
        guard ledger.plannedCount == beforePlanned - 1,
              ledger.terminalCount == beforeTerminal + 1,
              (try ledger.state(for: routeShardID)) == .passed else {
            throw ToolError.ledgerMutation(
                ToolError.reportNotPristine(ledger.plannedCount, ledger.terminalCount)
            )
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

        print(
            String(
                format: "SM64 Global-state route admission passed shard=0x%016llx "
                    + "records=%d ticks=2,3 ids=1..6 domain=0 state=1 "
                    + "before_planned=%d before_terminal=%d after_planned=%d "
                    + "after_terminal=%d snapshots=%d host_records=1789 "
                    + "filtered_records=12 report=%@ c_trace=%@ swift_trace=%@ "
                    + "asan_trace=%@ tamper_rejected=1 publication_equal=1 "
                    + "fixture_only=0",
                routeShardID,
                cTrace.records.count,
                beforePlanned,
                beforeTerminal,
                ledger.plannedCount,
                ledger.terminalCount,
                snapshots.count,
                options.report.path,
                options.cTrace.path,
                options.swiftTrace.path,
                options.asanTrace.path
            )
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-global-state-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --tampered-trace TAMPERED_TRACE --c-snapshots C_SNAPSHOTS --asan-snapshots ASAN_SNAPSHOTS --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --report REPORT"
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
            "--tampered-trace", "--c-snapshots", "--asan-snapshots",
            "--debug-log", "--swift-log", "--asan-log", "--report",
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
            tamperedTrace: url("--tampered-trace"),
            cSnapshots: url("--c-snapshots"),
            asanSnapshots: url("--asan-snapshots"),
            debugLog: url("--debug-log"),
            swiftLog: url("--swift-log"),
            asanLog: url("--asan-log"),
            report: url("--report")
        )
    }

    private static func requireDistinctEvidence(_ options: Options) throws {
        let urls = [
            options.cTrace, options.swiftTrace, options.asanTrace, options.tamperedTrace,
            options.cSnapshots, options.asanSnapshots,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard Set(urls).count == urls.count else {
            throw ToolError.singleTraceEvidence
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
                if shard.id == routeShardID {
                    matches.append(shard)
                }
            } catch let error as SM64RouteShardExecutionError {
                throw ToolError.invalidManifest(error.description)
            } catch {
                throw ToolError.invalidManifest("line \(offset + 3): \(error)")
            }
        }
        guard matches.count == 1, let shard = matches.first else {
            throw ToolError.wrongManifestRow(
                "expected exactly one canonical row, found \(matches.count)"
            )
        }
        guard shard.domain == "oracle_hook",
              shard.identity == "global_state",
              shard.source == "src/pc/sm64_modern_gameplay_parity.c" else {
            throw ToolError.wrongManifestRow("identity/source does not match the C owner")
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
                throw ToolError.invalidHeader(url, "decoded records do not cover complete artifact")
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
        _ other: SM64OracleTraceConfiguration
    ) throws {
        guard first.regionCode == other.regionCode else {
            throw ToolError.headerMismatch("region_code")
        }
        guard first.mode == other.mode else {
            throw ToolError.headerMismatch("mode")
        }
        let expected = Fingerprints(first)
        let actual = Fingerprints(other)
        let pairs: [(String, UInt64, UInt64)] = [
            ("build", expected.build, actual.build),
            ("content", expected.content, actual.content),
            ("timebase", expected.timebase, actual.timebase),
            ("configuration", expected.configuration, actual.configuration),
            ("initial_save", expected.initialSave, actual.initialSave),
            ("coverage", expected.coverage, actual.coverage),
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
        let expectedConfiguration = String(
            format: "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;input_seed=0x%016llx;save_seed=0x%016llx;shard=0x%016llx",
            routeInputSeed, routeSaveSeed, routeShardID
        )
        let expectedSave = String(
            format: "save=empty-us-slot-0;seed=0x%016llx", routeSaveSeed
        )
        let expected = Fingerprints(
            SM64OracleTraceConfiguration(
                regionCode: 0x5553,
                mode: .record,
                buildFingerprint: hashString("sm64-modern-global-state-route-build-v1"),
                contentFingerprint: hashString(
                    "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|global_state"
                ),
                timebaseFingerprint: timebaseFingerprint(),
                configurationFingerprint: hashString(expectedConfiguration),
                initialSaveFingerprint: hashString(expectedSave),
                coverageFingerprint: coverageFingerprint()
            )
        )
        let actual = Fingerprints(configuration)
        let pairs: [(String, UInt64, UInt64)] = [
            ("\(label).build", expected.build, actual.build),
            ("\(label).content", expected.content, actual.content),
            ("\(label).timebase", expected.timebase, actual.timebase),
            ("\(label).configuration", expected.configuration, actual.configuration),
            ("\(label).initial_save", expected.initialSave, actual.initialSave),
            ("\(label).coverage", expected.coverage, actual.coverage),
        ]
        for (name, expectedValue, actualValue) in pairs where expectedValue != actualValue {
            throw ToolError.wrongFingerprint(name, expectedValue, actualValue)
        }
    }

    private static func validateRecords(
        _ trace: RawTrace,
        label: String
    ) throws {
        guard trace.records.count == routeRecordCount * routeTickValues.count else {
            throw ToolError.wrongRecordCount(label, trace.records.count)
        }
        let ticks = Array(Set(trace.records.map(\.simulationTick)).sorted())
        guard ticks == routeTickValues else {
            throw ToolError.wrongTickWindow(label, ticks)
        }
        var observedIDs: Set<UInt64> = []
        for (index, record) in trace.records.enumerated() {
            let tickIndex = index / routeRecordCount
            let expectedTick = routeTickValues[tickIndex]
            let expectedSequence = UInt32(index % routeRecordCount)
            let expectedRecordID = routeRecordFirst + UInt64(index % routeRecordCount)
            guard record.simulationTick == expectedTick else {
                throw ToolError.wrongRecord(label, index, "tick \(record.simulationTick) != \(expectedTick)")
            }
            guard record.domain == 0,
                  record.recordKind == 1,
                  record.subjectID == 0 else {
                throw ToolError.wrongRecord(label, index, "expected domain=0 kind=1 subject=0")
            }
            guard record.recordID == expectedRecordID else {
                throw ToolError.wrongRecord(label, index, "record ID \(record.recordID) != \(expectedRecordID)")
            }
            guard record.sequence == expectedSequence else {
                throw ToolError.wrongRecord(label, index, "sequence \(record.sequence) != \(expectedSequence)")
            }
            guard record.values.count == 1 else {
                throw ToolError.wrongRecord(label, index, "value count \(record.values.count) != 1")
            }
            observedIDs.insert(record.recordID)
        }
        guard observedIDs == Set(routeRecordFirst...routeRecordLast) else {
            throw ToolError.wrongRecord(label, 0, "record-ID coverage is incomplete")
        }
    }

    private static func decodeSnapshots(_ data: Data, from url: URL) throws -> [Snapshot] {
        guard data.count == snapshotCount * snapshotSize else {
            throw ToolError.invalidHeader(url, "publication bytes are not exactly 2 * 48")
        }
        let bytes = [UInt8](data)
        func u32(_ offset: Int) -> UInt32 {
            UInt32(bytes[offset])
                | UInt32(bytes[offset + 1]) << 8
                | UInt32(bytes[offset + 2]) << 16
                | UInt32(bytes[offset + 3]) << 24
        }
        func u64(_ offset: Int) -> UInt64 {
            (0..<8).reduce(UInt64(0)) { result, index in
                result | UInt64(bytes[offset + index]) << UInt64(index * 8)
            }
        }
        var snapshots: [Snapshot] = []
        for index in 0..<snapshotCount {
            let base = index * snapshotSize
            snapshots.append(
                Snapshot(
                    abiVersion: u32(base),
                    structSize: u32(base + 4),
                    simulationTick: u64(base + 8),
                    globalTimer: u32(base + 16),
                    levelNumber: u32(base + 20),
                    areaIndex: u32(base + 24),
                    actNumber: u32(base + 28),
                    courseNumber: u32(base + 32),
                    randomSeed: u32(base + 36),
                    reserved: u32(base + 40)
                )
            )
            guard snapshots[index].abiVersion == 1,
                  snapshots[index].structSize >= UInt32(snapshotSize),
                  snapshots[index].reserved == 0 else {
                throw ToolError.invalidHeader(url, "publication ABI/reserved fields")
            }
            // The final four bytes are C tail padding. The producer zeroes the
            // whole value before publication; retain that ABI invariant.
            guard bytes[base + 44..<base + snapshotSize].allSatisfy({ $0 == 0 }) else {
                throw ToolError.invalidHeader(url, "publication tail padding")
            }
        }
        return snapshots
    }

    private static func validateSnapshots(
        _ snapshots: [Snapshot],
        against records: [SM64OracleTraceRecord]
    ) throws {
        guard snapshots.count == snapshotCount else {
            throw ToolError.snapshotMismatch("snapshot count is not 2")
        }
        for (index, snapshot) in snapshots.enumerated() {
            let tick = routeTickValues[index]
            let start = index * routeRecordCount
            let window = Array(records[start..<(start + routeRecordCount)])
            guard snapshot.simulationTick == tick else {
                throw ToolError.snapshotMismatch("snapshot \(index) tick is \(snapshot.simulationTick)")
            }
            let expectedValues = window.map { $0.values[0] }
            guard snapshot.values == expectedValues else {
                throw ToolError.snapshotMismatch(
                    "snapshot \(index) values \(snapshot.values) != records \(expectedValues)"
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
            hash = hashUInt64(hash, 0)
            hash = hashUInt64(hash, 0)
            hash = hashUInt64(hash, recordID)
        }
        return hashUInt64(hash, UInt64(routeRecordCount))
    }
}
