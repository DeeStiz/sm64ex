import Foundation

/// Admits the source-bound inside-castle display-list route into a new,
/// isolated report.  The route manifest and all second-pair artifacts are immutable
/// inputs.  This tool never changes the manifest, cumulative ledger, or
/// history; GPU attachment, pixels, and physical acceptance remain separate
/// gates.
@main
struct SM64DisplayListNextRouteAdmissionTool {
    private static let manifestHeader = "# sm64-modern-route-shards-v1"
    private static let manifestSchema = "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes"
    private static let routeShardID: UInt64 = 0x00a5_aebe_3689_7ac4
    private static let routeInputSeed: UInt64 = 0x38ed_06da_4fa1_b69c
    private static let routeSaveSeed: UInt64 = 0x7684_a956_7f71_ff45
    private static let routeEvent: UInt64 = 0xd2
    private static let routeDomain: UInt32 = 11
    private static let routeRecordKind: UInt32 = 7
    private static let routeTicks: [UInt64] = [1, 2]
    private static let sourceIdentity: UInt64 = 0xea26_0066_b29e_ce0c
    private static let ownerIdentity: UInt64 = 0xad52_4f68_d4a5_8ea8
    private static let routeLayer: UInt32 = 1
    private static let routeWordCount: UInt32 = 8
    private static let routeTriangleCount: UInt32 = 4
    private static let routeFlags: UInt32 = 3
    private static let routePacketFingerprint: UInt64 = 0x8ffa_117b_4fac_4bd6
    private static let routeWords: [UInt32] = [
        0xfd10_0000, 0x0900_1000,
        0xe600_0000, 0x0000_0000,
        0xf300_0000, 0x077f_f080,
        0xdc08_060a, 0x0702_4020,
        0xdc08_090a, 0x0702_4010,
        0x0100_8010, 0x0702_6108,
        0x0600_0204, 0x0000_0602,
        0x0608_0a0c, 0x0008_0c0e,
    ]
    private static let routeResources: [UInt32] = [
        0x0900_1000, 0, 0, 0x0702_4020,
        0x0702_4010, 0x0702_6108, 0, 0,
    ]
    private static let routeResourceFingerprint: UInt64 = 0x64ed_5e12_bb6a_e628
    private static let traceHeaderSize = 72
    private static let traceRecordSize = SM64OracleTraceRecord.encodedSize
    private static let fnvOffset: UInt64 = 1_469_598_103_934_665_603
    private static let fnvPrime: UInt64 = 1_099_511_628_211

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

    private struct Packet: Equatable {
        let sourceIdentity: UInt64
        let ownerIdentity: UInt64
        let wordCount: UInt32
        let drawingLayer: UInt32
        let triangleCount: UInt32
        let flags: UInt32
        let packetFingerprint: UInt64
        let words: [UInt32]
        let resources: [UInt32]
    }

    private struct RawPacket {
        let url: URL
        let bytes: Data
        let packet: Packet
    }

    private struct Options {
        let manifest: URL
        let cTrace: URL
        let swiftTrace: URL
        let asanTrace: URL
        let releaseTrace: URL
        let rerunTrace: URL
        let tamperedTrace: URL
        let cPacket: URL
        let asanPacket: URL
        let releasePacket: URL
        let rerunPacket: URL
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
        case wrongRecordCount(String, Int)
        case wrongTickWindow(String, [UInt64])
        case wrongRecord(String, Int, String)
        case invalidPacket(URL, String)
        case traceBytesMismatch
        case packetBytesMismatch
        case singleArtifactEvidence
        case tamperAccepted(URL)
        case tamperNotCanonical(URL, Error)
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
            case let .wrongManifestRow(reason): return "display-list-next manifest row mismatch: \(reason)"
            case let .missingEvidence(url): return "missing required evidence: \(url.path)"
            case let .invalidTrace(url, error): return "invalid trace \(url.path): \(error)"
            case let .invalidHeader(url, reason): return "invalid trace header \(url.path): \(reason)"
            case let .headerMismatch(field): return "C/Swift/ASan/Release/rerun header mismatch: \(field)"
            case let .wrongRecordCount(label, count): return "\(label) record count \(count) is not 2"
            case let .wrongTickWindow(label, ticks): return "\(label) tick window \(ticks) is not exactly [1, 2]"
            case let .wrongRecord(label, index, reason): return "\(label) record \(index): \(reason)"
            case let .invalidPacket(url, reason): return "invalid display-list packet \(url.path): \(reason)"
            case .traceBytesMismatch: return "C, Swift, ASan, Release, and rerun trace bytes differ"
            case .packetBytesMismatch: return "C, ASan, Release, and rerun packet sidecar bytes differ"
            case .singleArtifactEvidence: return "trace and packet evidence must be distinct artifacts"
            case let .tamperAccepted(url): return "tampered trace was accepted: \(url.path)"
            case let .tamperNotCanonical(url, error): return "tampered trace did not fail canonical decoding \(url.path): \(error)"
            case let .missingMarker(url, marker): return "missing evidence marker in \(url.path): \(marker)"
            case let .sanitizerFinding(url): return "AddressSanitizer finding in \(url.path)"
            case let .reportAlreadyExists(url): return "isolated admission report already exists; rerun rejected: \(url.path)"
            case .reportCollision: return "isolated report collides with immutable evidence"
            case let .reportInvalid(reason): return "isolated report validation failed: \(reason)"
            case let .unwritable(url, error): return "cannot write \(url.path): \(error)"
            }
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-display-list-next-route-admit: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        try requireDistinctEvidence(options)
        try requireFreshReport(options)

        let manifestText = try read(options.manifest)
        let rows = try parseManifest(manifestText)
        let target = try resolveTarget(rows)

        try requireMarkers(options)
        let cTrace = try loadTrace(options.cTrace)
        let swiftTrace = try loadTrace(options.swiftTrace)
        let asanTrace = try loadTrace(options.asanTrace)
        let releaseTrace = try loadTrace(options.releaseTrace)
        let rerunTrace = try loadTrace(options.rerunTrace)
        let traces = [("C", cTrace), ("Swift", swiftTrace), ("ASan", asanTrace), ("Release", releaseTrace), ("rerun", rerunTrace)]
        for (label, trace) in traces {
            try validateCanonicalHeader(trace.configuration, label: label)
            try validateRecords(trace, label: label)
        }
        try validateHeaderEquality(cTrace.configuration, against: traces.dropFirst(), label: "trace")
        guard traces.dropFirst().allSatisfy({ $0.1.bytes == cTrace.bytes }) else {
            throw ToolError.traceBytesMismatch
        }

        let cPacket = try loadPacket(options.cPacket)
        let asanPacket = try loadPacket(options.asanPacket)
        let releasePacket = try loadPacket(options.releasePacket)
        let rerunPacket = try loadPacket(options.rerunPacket)
        let packets = [cPacket, asanPacket, releasePacket, rerunPacket]
        for raw in packets { try validatePacket(raw.packet, label: raw.url.lastPathComponent) }
        guard packets.dropFirst().allSatisfy({ $0.bytes == cPacket.bytes }) else {
            throw ToolError.packetBytesMismatch
        }
        let expectedValues = packetTraceValues(cPacket.packet)
        for (label, trace) in traces {
            for (index, record) in trace.records.enumerated() where record.values != expectedValues {
                throw ToolError.wrongRecord(label, index, "packet/resource values are not stable")
            }
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
            "SM64 display-list next route isolated admission passed "
                + "shard=\(formatID(routeShardID)) identity=inside_castle_seg7_dl_070287C0 "
                + "source=levels/castle_inside/areas/1/2/model.inc.c records=2 ticks=1,2 domain=11 kind=7 schema=4 "
                + "manifest_rows=\(rows.count) report_rows=\(rows.count) passed_rows=1 planned_rows=\(rows.count - 1) "
                + "packet=\(formatID(routePacketFingerprint)) resource=\(formatID(routeResourceFingerprint)) "
                + "c_swift_asan_release_rerun_byte_match=1 packet_resource_values=stable tamper_rejected=1 "
                + "gpu_capture=separate pixel_acceptance=unverified physical_acceptance=unverified "
                + "fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0 rerun_fence=1 "
                + "report=\(options.report.path)"
        )
    }

    private static func parse(arguments: [String]) throws -> Options {
        let usage = "usage: sm64-display-list-next-route-admit --manifest MANIFEST --c-trace C_TRACE --swift-trace SWIFT_TRACE --asan-trace ASAN_TRACE --release-trace RELEASE_TRACE --rerun-trace RERUN_TRACE --tampered-trace TAMPERED_TRACE --c-packet C_PACKET --asan-packet ASAN_PACKET --release-packet RELEASE_PACKET --rerun-packet RERUN_PACKET --debug-log DEBUG_LOG --swift-log SWIFT_LOG --asan-log ASAN_LOG --release-log RELEASE_LOG --rerun-log RERUN_LOG --report REPORT"
        guard arguments.count == 34, arguments.count.isMultiple(of: 2) else {
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
            "--c-packet", "--asan-packet", "--release-packet", "--rerun-packet",
            "--debug-log", "--swift-log", "--asan-log", "--release-log",
            "--rerun-log", "--report",
        ]
        guard values.count == known.count, values.keys.allSatisfy(known.contains) else {
            throw ToolError.invalidArguments(usage)
        }
        func url(_ key: String) -> URL { URL(fileURLWithPath: values[key]!).standardizedFileURL }
        return Options(
            manifest: url("--manifest"), cTrace: url("--c-trace"),
            swiftTrace: url("--swift-trace"), asanTrace: url("--asan-trace"),
            releaseTrace: url("--release-trace"), rerunTrace: url("--rerun-trace"),
            tamperedTrace: url("--tampered-trace"), cPacket: url("--c-packet"),
            asanPacket: url("--asan-packet"), releasePacket: url("--release-packet"),
            rerunPacket: url("--rerun-packet"), debugLog: url("--debug-log"),
            swiftLog: url("--swift-log"), asanLog: url("--asan-log"),
            releaseLog: url("--release-log"), rerunLog: url("--rerun-log"),
            report: url("--report")
        )
    }

    private static func requireDistinctEvidence(_ options: Options) throws {
        let evidence = [
            options.cTrace, options.swiftTrace, options.asanTrace,
            options.releaseTrace, options.rerunTrace, options.tamperedTrace,
            options.cPacket, options.asanPacket, options.releasePacket, options.rerunPacket,
        ].map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
        guard Set(evidence).count == evidence.count else {
            throw ToolError.singleArtifactEvidence
        }
        let immutable = Set(evidence + [options.manifest.standardizedFileURL.path])
        let outputs = [options.report, options.debugLog, options.swiftLog, options.asanLog, options.releaseLog, options.rerunLog]
            .map { $0.standardizedFileURL.path }
        guard outputs.allSatisfy({ !immutable.contains($0) }) else {
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
                    throw ToolError.invalidManifest(formatID(shard.id) + " is duplicated")
                }
                rows.append(ManifestRow(shard: shard, line: lineNumber))
            } catch let error as ToolError { throw error }
            catch { throw ToolError.invalidManifest("line \(lineNumber): \(error)") }
        }
        guard !rows.isEmpty else { throw ToolError.invalidManifest("manifest has no rows") }
        return rows
    }

    private static func resolveTarget(_ rows: [ManifestRow]) throws -> ManifestRow {
        let matches = rows.filter { $0.shard.id == routeShardID }
        guard matches.count == 1, let target = matches.first else {
            throw ToolError.wrongManifestRow("expected one \(formatID(routeShardID)) row, found \(matches.count)")
        }
        let shard = target.shard
        guard shard.domain == "display_list",
              shard.identity == "inside_castle_seg7_dl_070287C0",
              shard.source == "levels/castle_inside/areas/1/2/model.inc.c",
              shard.inputSeed == routeInputSeed,
              shard.saveSeed == routeSaveSeed,
              shard.expectedDomains == [.renderPacket],
              shard.manifestState == .planned else {
            throw ToolError.wrongManifestRow("identity/source/seeds/expected domain/status do not match")
        }
        return target
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

    private static func validateCanonicalHeader(_ configuration: SM64OracleTraceConfiguration, label: String) throws {
        let expected = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: hashString("sm64-modern-display-list-next-route-build-v1"),
            contentFingerprint: hashString("levels/castle_inside/areas/1/2/model.inc.c|inside_castle_seg7_dl_070287C0|render_packet"),
            timebaseFingerprint: hashU32(hashU32(fnvOffset, 60), 30),
            configurationFingerprint: hashString(
                "region=5553;fullscreen=off;skip_intro=1;"
                    + "shard=0x00a5aebe36897ac4;parent=inside_castle_seg7_dl_07028FD0;layer=1"
            ),
            initialSaveFingerprint: hashString("save=empty-us-slot-0;seed=0x7684a9567f71ff45"),
            coverageFingerprint: 0
        )
        guard configuration == expected else {
            throw ToolError.headerMismatch("\(label).canonical_schema4_fingerprints")
        }
    }

    private static func validateHeaderEquality(
        _ first: SM64OracleTraceConfiguration,
        against others: ArraySlice<(String, RawTrace)>,
        label: String
    ) throws {
        for (otherLabel, trace) in others where trace.configuration != first {
            throw ToolError.headerMismatch("\(label).\(otherLabel)")
        }
    }

    private static func validateRecords(_ trace: RawTrace, label: String) throws {
        guard trace.records.count == routeTicks.count else {
            throw ToolError.wrongRecordCount(label, trace.records.count)
        }
        let ticks = trace.records.map(\.simulationTick)
        guard Array(Set(ticks).sorted()) == routeTicks else {
            throw ToolError.wrongTickWindow(label, Array(Set(ticks).sorted()))
        }
        let values = packetTraceValues(Packet(
            sourceIdentity: sourceIdentity,
            ownerIdentity: ownerIdentity,
            wordCount: routeWordCount,
            drawingLayer: routeLayer,
            triangleCount: routeTriangleCount,
            flags: routeFlags,
            packetFingerprint: routePacketFingerprint,
            words: routeWords,
            resources: routeResources
        ))
        for (index, record) in trace.records.enumerated() {
            guard record.simulationTick == routeTicks[index] else {
                throw ToolError.wrongRecord(label, index, "tick \(record.simulationTick) is not \(routeTicks[index])")
            }
            guard record.domain == routeDomain, record.recordKind == routeRecordKind else {
                throw ToolError.wrongRecord(label, index, "domain/kind mismatch")
            }
            guard record.subjectID == routeShardID, record.recordID == routeEvent else {
                throw ToolError.wrongRecord(label, index, "source-bound shard/event identity mismatch")
            }
            guard record.sequence == 0, record.flags == routeFlags else {
                throw ToolError.wrongRecord(label, index, "sequence/flags mismatch")
            }
            guard record.values == values else {
                throw ToolError.wrongRecord(label, index, "packet/resource values are not canonical")
            }
        }
    }

    private static func loadPacket(_ url: URL) throws -> RawPacket {
        guard FileManager.default.fileExists(atPath: url.path) else { throw ToolError.missingEvidence(url) }
        do {
            let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
            guard let text = String(data: bytes, encoding: .utf8) else {
                throw ToolError.invalidPacket(url, "not UTF-8")
            }
            let lines = text.split(whereSeparator: { $0.isNewline })
            guard lines.count == 1 else { throw ToolError.invalidPacket(url, "expected one receipt line") }
            var fields: [String: String] = [:]
            for field in lines[0].split(separator: "|", omittingEmptySubsequences: false) {
                let pair = field.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard pair.count == 2, fields[String(pair[0])] == nil else {
                    throw ToolError.invalidPacket(url, "malformed or duplicate field")
                }
                fields[String(pair[0])] = String(pair[1])
            }
            let expectedKeys: Set<String> = [
                "source_identity", "owner_identity", "word_count", "drawing_layer",
                "triangle_count", "flags", "packet_fingerprint", "words", "resources",
            ]
            guard Set(fields.keys) == expectedKeys else { throw ToolError.invalidPacket(url, "field set mismatch") }
            guard let source = parseHex(fields["source_identity"]!),
                  let owner = parseHex(fields["owner_identity"]!),
                  let wordCount = UInt32(fields["word_count"]!),
                  let layer = UInt32(fields["drawing_layer"]!),
                  let triangles = UInt32(fields["triangle_count"]!),
                  let flags = UInt32(fields["flags"]!),
                  let packetFingerprint = parseHex(fields["packet_fingerprint"]!) else {
                throw ToolError.invalidPacket(url, "scalar value is not canonical")
            }
            let words = try parseWordList(fields["words"]!, url: url)
            let resources = try parseWordList(fields["resources"]!, url: url)
            guard words.count == Int(wordCount) * 2, resources.count == Int(wordCount) else {
                throw ToolError.invalidPacket(url, "word/resource count mismatch")
            }
            let packet = Packet(
                sourceIdentity: source, ownerIdentity: owner, wordCount: wordCount,
                drawingLayer: layer, triangleCount: triangles, flags: flags,
                packetFingerprint: packetFingerprint, words: words, resources: resources
            )
            return RawPacket(url: url, bytes: bytes, packet: packet)
        } catch let error as ToolError { throw error }
        catch { throw ToolError.invalidPacket(url, "\(error)") }
    }

    private static func validatePacket(_ packet: Packet, label: String) throws {
        guard packet.sourceIdentity == sourceIdentity,
              packet.ownerIdentity == ownerIdentity,
              packet.wordCount == routeWordCount,
              packet.drawingLayer == routeLayer,
              packet.triangleCount == routeTriangleCount,
              packet.flags == routeFlags,
              packet.packetFingerprint == routePacketFingerprint,
              packet.words == routeWords,
              packet.resources == routeResources else {
            throw ToolError.invalidPacket(URL(fileURLWithPath: label), "source/packet/resource values differ")
        }
        guard hashU32List(packet.words) == packet.packetFingerprint else {
            throw ToolError.invalidPacket(URL(fileURLWithPath: label), "packet fingerprint is not canonical")
        }
        guard hashU32List(packet.resources) == routeResourceFingerprint else {
            throw ToolError.invalidPacket(URL(fileURLWithPath: label), "resource fingerprint is not canonical")
        }
    }

    private static func packetTraceValues(_ packet: Packet) -> [UInt64] {
        [
            packet.sourceIdentity, packet.ownerIdentity, packet.packetFingerprint,
            UInt64(packet.wordCount), UInt64(packet.triangleCount),
            hashU32List(packet.resources), UInt64(packet.drawingLayer), UInt64(packet.flags),
        ]
    }

    private static func parseWordList(_ raw: String, url: URL) throws -> [UInt32] {
        let values = raw.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        guard !values.isEmpty else { throw ToolError.invalidPacket(url, "empty word list") }
        return try values.map { value in
            guard let parsed = parseHex32(value) else { throw ToolError.invalidPacket(url, "invalid word \(value)") }
            return parsed
        }
    }

    private static func requireMarkers(_ options: Options) throws {
        for marker in [
            "c_display_list_next_route_recorded shard=0x00a5aebe36897ac4 records=2 ticks=1,2",
            "display_list_next_route_debug oracle_end=0 result_status=0 records=2 invocations=2 matches=2 failures=0",
            "display_list_next_route_owner_fence=1 pointer_free_packet=1",
        ] { try requireMarker(options.debugLog, marker) }
        for marker in [
            "swift_display_list_next_route_recorded shard=0xa5aebe36897ac4 records=2 ticks=1,2 words=8 triangles=4",
            "display_list_next_pairing_audit admitted=1 c_records=2 swift_records=2 blockers= first_divergence=none",
            "display_list_next_pairing_tamper_rejected=1",
        ] { try requireMarker(options.swiftLog, marker) }
        for marker in [
            "display_list_next_route_debug oracle_end=0 result_status=0 records=2 invocations=2 matches=2 failures=0",
        ] {
            try requireMarker(options.asanLog, marker)
            try requireMarker(options.releaseLog, marker)
            try requireMarker(options.rerunLog, marker)
        }
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
            throw ToolError.tamperNotCanonical(url, error)
        }
    }

    private static func makeIsolatedReport(rows: [ManifestRow], target: ManifestRow) -> String {
        rows.sorted { $0.shard.id < $1.shard.id }.map { row in
            if row.shard.id == target.shard.id {
                return [formatID(row.shard.id), "passed", "2", "2", "2", ""].joined(separator: "|")
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
                guard fields[1] == "passed", expected == 2, actual == 2, matched == 2, fields[5].isEmpty else {
                    throw ToolError.reportInvalid("target row is not an exact two-record receipt")
                }
                passed += 1
            } else if fields[1] != "planned" || expected != 0 || actual != 0 || matched != 0 || !fields[5].isEmpty {
                throw ToolError.reportInvalid("non-target row was admitted or carried evidence")
            }
        }
        guard seen == expectedIDs, passed == 1 else {
            throw ToolError.reportInvalid("report does not contain exactly one selected passed row")
        }
    }

    private static func hashString(_ value: String) -> UInt64 {
        value.utf8.reduce(fnvOffset) { ($0 ^ UInt64($1)) &* fnvPrime }
    }

    private static func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
        var hash = initial
        for byte in 0..<4 {
            hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
            hash &*= fnvPrime
        }
        return hash
    }

    private static func hashU32List(_ values: [UInt32]) -> UInt64 {
        values.reduce(fnvOffset, hashU32)
    }

    private static func parseHex(_ value: String) -> UInt64? {
        guard value.hasPrefix("0x") else { return nil }
        return UInt64(value.dropFirst(2), radix: 16)
    }

    private static func parseHex32(_ value: String) -> UInt32? {
        let digits = value.hasPrefix("0x") ? String(value.dropFirst(2)) : value
        return UInt32(digits, radix: 16)
    }

    private static func formatID(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }
}
