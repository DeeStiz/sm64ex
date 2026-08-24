import Foundation

/// Admits one of the two Phase 85o source-backed oracle_hook rows from
/// independent C, Swift, and ASan traces. The generated manifest is immutable
/// input; only the caller-supplied isolated execution report is written.
@main
struct SM64ObjectScriptRouteAdmissionTool {
    private static let fnvOffset: UInt64 = 1_469_598_103_934_665_603
    private static let fnvPrime: UInt64 = 1_099_511_628_211
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize
    private static let manifestCount = 7_420

    private enum Route: String {
        case objectState = "object_state"
        case scriptEvents = "script_events"

        var spec: Spec {
            switch self {
            case .objectState:
                return Spec(
                    route: self,
                    shardID: 0x862c_3d78_b60d_657c,
                    inputSeed: 0x58cc_16e4_df72_5004,
                    saveSeed: 0x18fda_13f_fd33_fa7d,
                    identity: "object_state",
                    domain: .objectState,
                    cDomain: 3,
                    recordKind: 1,
                    buildName: "sm64-modern-object-state-route-build-v1",
                    recordCount: 28,
                    ticks: [2, 3],
                    ids: Array(400...413),
                    idCounts: Dictionary(uniqueKeysWithValues: (400...413).map { ($0, 2) }),
                    valueCounts: Dictionary(uniqueKeysWithValues: (400...413).map { id in
                        (id, [405, 406, 407].contains(id) ? 3 : 1)
                    }),
                    subject: 1,
                    debugActualRecords: 2_955,
                    debugRetainedRecords: 28,
                    coverageIDs: Array(400...413)
                )
            case .scriptEvents:
                return Spec(
                    route: self,
                    shardID: 0x2b0f_6063_b546_3e9c,
                    inputSeed: 0xb349_4e3c_2c19_d924,
                    saveSeed: 0xccca_d169_f65f_541d,
                    identity: "script_events",
                    domain: .scriptEvents,
                    cDomain: 6,
                    recordKind: 3,
                    buildName: "sm64-modern-script-events-route-build-v1",
                    recordCount: 1_272,
                    ticks: [2, 3],
                    ids: [1, 2, 3, 4, 5],
                    idCounts: [1: 212, 2: 788, 3: 0, 4: 75, 5: 197],
                    valueCounts: [1: 7, 2: 6, 3: 5, 4: 5, 5: 3],
                    subject: nil,
                    debugActualRecords: 1_789,
                    debugRetainedRecords: 1_272,
                    coverageIDs: [1, 2, 4, 5]
                )
            }
        }
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
        let buildName: String
        let recordCount: Int
        let ticks: [UInt64]
        let ids: [UInt64]
        let idCounts: [UInt64: Int]
        let valueCounts: [UInt64: Int]
        let subject: UInt64?
        let debugActualRecords: Int
        let debugRetainedRecords: Int
        let coverageIDs: [UInt64]

        var expectedTotalRecords: Int { recordCount }

        var canonicalCoverageFingerprint: UInt64 {
            var hash = SM64ObjectScriptRouteAdmissionTool.fnvOffset
            for id in coverageIDs {
                hash = hashUInt64(hash, UInt64(cDomain))
                hash = hashUInt64(hash, 0)
                hash = hashUInt64(hash, id)
            }
            return hashUInt64(hash, UInt64(coverageIDs.count))
        }

        private func hashUInt64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
            var hash = initial
            for byte in 0..<8 {
                hash ^= (value >> UInt64(byte * 8)) & 0xff
                hash &*= SM64ObjectScriptRouteAdmissionTool.fnvPrime
            }
            return hash
        }
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
        case wrongRecordCount(String, Int, Int)
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
        case outputCollision(URL)
        case unwritable(URL, Error)

        var description: String {
            switch self {
            case let .invalidArguments(message): return message
            case let .unreadable(url, error): return "cannot read \(url.path): \(error)"
            case let .invalidManifest(reason): return "invalid route-shard manifest: \(reason)"
            case let .wrongManifestRow(reason): return "canonical manifest row mismatch: \(reason)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidTrace(url, error): return "invalid trace \(url.path): \(error)"
            case let .invalidHeader(url, reason): return "invalid artifact header \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift/ASan header mismatch: \(field)"
            case let .fingerprintMismatch(field, expected, actual):
                return String(format: "independent fingerprint mismatch %@: 0x%016llx != 0x%016llx",
                              field, expected, actual)
            case let .wrongFingerprint(field, expected, actual):
                return String(format: "wrong canonical fingerprint %@: expected 0x%016llx got 0x%016llx",
                              field, expected, actual)
            case let .wrongRecordCount(label, actual, expected):
                return "\(label) record count \(actual) is not \(expected)"
            case let .wrongTickWindow(label, ticks):
                return "\(label) tick window \(ticks) is not exactly [2, 3]"
            case let .wrongRecord(label, index, reason):
                return "\(label) record \(index): \(reason)"
            case .recordBytesMismatch:
                return "independent C/Swift/ASan trace bytes differ"
            case .singleTraceEvidence:
                return "C, Swift, ASan, and tamper evidence must be distinct artifacts"
            case let .tamperAccepted(url): return "tampered trace was accepted: \(url.path)"
            case let .missingMarker(url, marker):
                return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .reportAlreadyAdvanced(id, state):
                return String(format: "route shard 0x%016llx is already %@; rerun rejected",
                              id, state.rawValue)
            case let .reportNotPristine(planned, terminal):
                return "admission report is not pristine (planned=\(planned) terminal=\(terminal))"
            case let .ledgerMutation(error): return "route-shard ledger mutation rejected: \(error)"
            case let .outputCollision(url): return "isolated report collides with manifest: \(url.path)"
            case let .unwritable(url, error): return "cannot write \(url.path): \(error)"
            }
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(
                Data(("sm64-object-script-route-admit: \(error)\n").utf8)
            )
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let spec = options.spec
        try requireDistinctEvidence(options)
        guard options.report.resolvingSymlinksInPath().standardizedFileURL.path
            != options.manifest.resolvingSymlinksInPath().standardizedFileURL.path else {
            throw ToolError.outputCollision(options.report)
        }

        let manifestText = try read(options.manifest)
        let shard = try resolveShard(manifestText, spec: spec)
        guard shard.id == spec.shardID,
              shard.inputSeed == spec.inputSeed,
              shard.saveSeed == spec.saveSeed,
              shard.expectedDomains == [spec.domain],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("identity, source, seeds, domains, or planned status differs")
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
            beforeState = try ledger.state(for: spec.shardID)
        } catch {
            throw ToolError.ledgerMutation(error)
        }
        guard beforeState == .planned else {
            throw ToolError.reportAlreadyAdvanced(spec.shardID, beforeState)
        }
        guard ledger.count == manifestCount,
              beforePlanned == manifestCount,
              beforeTerminal == 0 else {
            throw ToolError.reportNotPristine(beforePlanned, beforeTerminal)
        }

        try requireMarkers(options, spec: spec)
        let cTrace = try loadTrace(options.cTrace)
        let swiftTrace = try loadTrace(options.swiftTrace)
        let asanTrace = try loadTrace(options.asanTrace)
        try validateHeaders(cTrace.configuration, swiftTrace.configuration)
        try validateHeaders(cTrace.configuration, asanTrace.configuration)
        try validateCanonicalHeader(cTrace.configuration, spec: spec, label: "C")
        try validateCanonicalHeader(swiftTrace.configuration, spec: spec, label: "Swift")
        try validateCanonicalHeader(asanTrace.configuration, spec: spec, label: "ASan")
        try validateRecords(cTrace, spec: spec, label: "C")
        try validateRecords(swiftTrace, spec: spec, label: "Swift")
        try validateRecords(asanTrace, spec: spec, label: "ASan")
        guard cTrace.bytes == swiftTrace.bytes,
              cTrace.bytes == asanTrace.bytes else {
            throw ToolError.recordBytesMismatch
        }
        try rejectTamperedTrace(options.tamperedTrace)

        do {
            try ledger.begin(id: spec.shardID)
            try ledger.finish(
                id: spec.shardID,
                state: .passed,
                evidence: SM64RouteShardExecutionEvidence(
                    expectedRecords: UInt64(spec.expectedTotalRecords),
                    actualRecords: UInt64(cTrace.records.count),
                    matchedRecords: UInt64(cTrace.records.count)
                )
            )
        } catch {
            throw ToolError.ledgerMutation(error)
        }
        guard ledger.plannedCount == beforePlanned - 1,
              ledger.terminalCount == beforeTerminal + 1,
              (try ledger.state(for: spec.shardID)) == .passed else {
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
                format: "SM64 %@ route admission passed shard=0x%016llx records=%d "
                    + "ticks=2,3 domain=%u kind=%u before_planned=%d before_terminal=%d "
                    + "after_planned=%d after_terminal=%d report=%@ tamper_rejected=1 "
                    + "fixture_only=0",
                spec.route.rawValue,
                spec.shardID,
                cTrace.records.count,
                spec.cDomain,
                spec.recordKind,
                beforePlanned,
                beforeTerminal,
                ledger.plannedCount,
                ledger.terminalCount,
                options.report.path
            )
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-object-script-route-admit --route object_state|script_events --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --tampered-trace TAMPERED_TRACE --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --report REPORT"
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
            "--tampered-trace", "--debug-log", "--swift-log", "--asan-log", "--report",
        ]
        guard values.count == known.count, values.keys.allSatisfy(known.contains),
              let routeValue = values["--route"],
              let route = Route(rawValue: routeValue) else {
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
        let paths = [
            options.cTrace, options.swiftTrace, options.asanTrace, options.tamperedTrace,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard Set(paths).count == paths.count else {
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

    private static func resolveShard(_ manifest: String, spec: Spec) throws -> SM64RouteShard {
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
                if shard.id == spec.shardID { matches.append(shard) }
            } catch {
                throw ToolError.invalidManifest("line \(offset + 3): \(error)")
            }
        }
        guard matches.count == 1, let shard = matches.first else {
            throw ToolError.wrongManifestRow(
                "expected one \(spec.route.rawValue) row for shard \(formatID(spec.shardID)); found \(matches.count)"
            )
        }
        guard shard.domain == "oracle_hook",
              shard.identity == spec.identity,
              shard.source == "src/pc/sm64_modern_gameplay_parity.c",
              shard.inputSeed == spec.inputSeed,
              shard.saveSeed == spec.saveSeed,
              shard.expectedDomains == [spec.domain],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("identity/source/seeds/expected domains/status do not match")
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
        spec: Spec,
        label: String
    ) throws {
        guard configuration.regionCode == 0x5553 else {
            throw ToolError.invalidHeader(URL(fileURLWithPath: label), "region code")
        }
        guard configuration.mode == .record else {
            throw ToolError.invalidHeader(URL(fileURLWithPath: label), "mode is not record")
        }
        let expectedConfiguration = String(
            format: "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;shard=0x%016llx",
            spec.shardID
        )
        let expectedSave = String(
            format: "save=empty-us-slot-0;seed=0x%016llx", spec.saveSeed
        )
        let expected = Fingerprints(
            SM64OracleTraceConfiguration(
                regionCode: 0x5553,
                mode: .record,
                buildFingerprint: hashString(spec.buildName),
                contentFingerprint: hashString(
                    "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|\(spec.identity)"
                ),
                timebaseFingerprint: timebaseFingerprint(),
                configurationFingerprint: hashString(expectedConfiguration),
                initialSaveFingerprint: hashString(expectedSave),
                coverageFingerprint: spec.canonicalCoverageFingerprint
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

    private static func validateRecords(_ trace: RawTrace, spec: Spec, label: String) throws {
        guard trace.records.count == spec.recordCount else {
            throw ToolError.wrongRecordCount(label, trace.records.count, spec.recordCount)
        }
        let ticks = Array(Set(trace.records.map(\.simulationTick)).sorted())
        guard ticks == spec.ticks else {
            throw ToolError.wrongTickWindow(label, ticks)
        }

        var counts: [UInt64: Int] = [:]
        var previousTick: UInt64?
        var previousSequence: UInt32 = 0
        for (index, record) in trace.records.enumerated() {
            guard record.domain == spec.cDomain,
                  record.recordKind == spec.recordKind else {
                throw ToolError.wrongRecord(
                    label, index,
                    "expected domain=\(spec.cDomain) kind=\(spec.recordKind)"
                )
            }
            if let previousTick {
                guard record.simulationTick >= previousTick else {
                    throw ToolError.wrongRecord(label, index, "simulation tick regressed")
                }
                if record.simulationTick == previousTick {
                    guard record.sequence == previousSequence &+ 1 else {
                        throw ToolError.wrongRecord(label, index, "sequence is not contiguous")
                    }
                } else {
                    guard record.simulationTick == previousTick + 1,
                          record.sequence == 0 else {
                        throw ToolError.wrongRecord(label, index, "tick transition did not reset sequence")
                    }
                }
            } else {
                guard record.simulationTick == spec.ticks[0],
                      record.sequence == 0 else {
                    throw ToolError.wrongRecord(label, index, "first record is not tick 2 sequence 0")
                }
            }
            previousTick = record.simulationTick
            previousSequence = record.sequence

            if let expectedSubject = spec.subject, record.subjectID != expectedSubject {
                throw ToolError.wrongRecord(
                    label, index,
                    "subject \(record.subjectID) != \(expectedSubject)"
                )
            }
            guard spec.ids.contains(record.recordID) else {
                throw ToolError.wrongRecord(label, index, "unexpected record ID \(record.recordID)")
            }
            guard let expectedValueCount = spec.valueCounts[record.recordID],
                  record.values.count == expectedValueCount else {
                throw ToolError.wrongRecord(
                    label, index,
                    "ID \(record.recordID) value count \(record.values.count) is not \(spec.valueCounts[record.recordID] ?? -1)"
                )
            }
            counts[record.recordID, default: 0] += 1
        }

        let expectedCounts = spec.idCounts.filter { $0.value > 0 }
        guard counts == expectedCounts else {
            throw ToolError.wrongRecord(label, 0, "ID counts \(counts) != \(expectedCounts)")
        }
        guard Set(counts.keys) == Set(spec.coverageIDs) else {
            throw ToolError.wrongRecord(label, 0, "retained ID coverage is incomplete")
        }
    }

    private static func requireMarkers(_ options: Options, spec: Spec) throws {
        let debugMarkers: [String]
        let swiftMarkers: [String]
        switch spec.route {
        case .objectState:
            debugMarkers = [
                "object_state_route_init status=0 oracle=0 parity=0",
                "object_state_route_step index=0 status=0 oracle=0 parity=0",
                "object_state_route_step index=1 status=0 oracle=0 parity=0",
                // Keep the current full lifecycle count explicit while this
                // shard retains only its exact 28 object-state records. The
                // count includes separately qualified schema-4 route domains.
                "object_state_route_debug oracle_end=0 result_status=0 actual=2965 retained=28 target=1 failures=0",
                "c_object_state_route_recorded shard=0x862c3d78b60d657c subject=1 records=28 ticks=2,3 coverage=0x492987af540d8c0c",
            ]
            swiftMarkers = [
                "swift_object_state_route_recorded shard=0x862c3d78b60d657c subject=1 records=28 ticks=2,3 coverage=0x492987af540d8c0c",
                "object_state_pairing_audit admitted=1 c_records=28 swift_records=28 blockers= first_divergence=none",
                "object_state_pairing_tamper_rejected=1",
            ]
        case .scriptEvents:
            debugMarkers = [
                "script_events_route_init status=0 oracle=0 parity=0",
                "script_events_route_step index=0 status=0 oracle=0 parity=0",
                "script_events_route_step index=1 status=0 oracle=0 parity=0",
                "script_events_route_debug oracle_end=0 result_status=0 actual=1789 retained=1272 failures=0 ticks=2",
                "c_script_events_route_recorded shard=0x2b0f6063b5463e9c",
                "records=1272 ticks=3 event_counts=212,788,0,75,197 coverage=0x2d25e3b9d800f545",
            ]
            swiftMarkers = [
                "swift_script_events_route_recorded records=1272 ticks=2,3",
                "coverage=0x2d25e3b9d800f545",
                "script_events_pairing_audit admitted=1 c_records=1272 swift_records=1272 blockers= first_divergence=none",
                "script_events_pairing_tamper_rejected=1",
            ]
        }
        for marker in debugMarkers { try requireMarker(options.debugLog, marker) }
        for marker in swiftMarkers { try requireMarker(options.swiftLog, marker) }
        try requireMarker(options.asanLog, "\(spec.route.rawValue)_route_debug oracle_end=0 result_status=0")
        try requireMarker(options.asanLog, "retained=\(spec.debugRetainedRecords)")
        try requireMarker(options.asanLog, "failures=0")
        try rejectSanitizerFindings(in: options.asanLog)
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
        value.utf8.reduce(fnvOffset) { ($0 ^ UInt64($1)) &* fnvPrime }
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

    private static func formatID(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }
}
