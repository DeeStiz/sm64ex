import Foundation

/// Isolated, source-bound admission for the authored wooden-door display-list
/// leaf.  The canonical manifest and cumulative ledger are immutable inputs;
/// this tool writes only a new 7,420-row isolated report.
@main
struct SM64DisplayListDoorRouteAdmissionTool {
    private static let target: UInt64 = 0x01b4_72aa_e4c4_277d
    private static let source: UInt64 = 0x1b9a_2dff_3b0b_a55f
    private static let owner: UInt64 = 0x2e56_48d8_a494_e1a1
    private static let event: UInt64 = 0xd3
    private static let packetFingerprint: UInt64 = 0x1602_0358_6e39_755f
    private static let resourceFingerprint: UInt64 = 0x03b0_a126_306e_4a54
    private static let words: [UInt32] = [
        0xdc08_060a, 0x0300_9ce0, 0xdc08_090a, 0x0300_9ce8,
        0x0100_8010, 0x0301_4df0, 0x0600_0204, 0x0000_0602,
        0x0608_0a0c, 0x0008_0e0a, 0xdf00_0000, 0x0000_0000,
    ]
    private static let resources: [UInt32] = [
        0x0300_9ce0, 0x0300_9ce8, 0x0301_4df0, 0, 0, 0,
    ]

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
        let tamperLog: URL
        let asanLog: URL
        let releaseLog: URL
        let rerunLog: URL
        let partialLog: URL
        let singleLog: URL
        let report: URL
    }

    private enum AdmissionError: Error, CustomStringConvertible {
        case usage
        case invalid(String)
        case reportExists(URL)
        case tamperAccepted

        var description: String {
            switch self {
            case .usage: return "usage: sm64-display-list-door-route-admit --manifest PATH --c-trace PATH --swift-trace PATH --asan-trace PATH --release-trace PATH --rerun-trace PATH --tampered-trace PATH --c-packet PATH --asan-packet PATH --release-packet PATH --rerun-packet PATH --debug-log PATH --swift-log PATH --tamper-log PATH --asan-log PATH --release-log PATH --rerun-log PATH --partial-log PATH --single-log PATH --report PATH"
            case let .invalid(reason): return reason
            case let .reportExists(url): return "isolated report already exists: \(url.path)"
            case .tamperAccepted: return "tampered trace was accepted"
            }
        }
    }

    static func main() {
        do { try run(Array(CommandLine.arguments.dropFirst())) }
        catch {
            fputs("sm64-display-list-door-route-admit: \(error)\n", stderr)
            exit(2)
        }
    }

    private static func run(_ arguments: [String]) throws {
        let options = try parse(arguments)
        guard !FileManager.default.fileExists(atPath: options.report.path) else {
            throw AdmissionError.reportExists(options.report)
        }
        let manifest = try String(contentsOf: options.manifest, encoding: .utf8)
        let manifestRows = manifest.split(whereSeparator: \.isNewline).filter { !$0.hasPrefix("#") }
        guard manifestRows.count == 7420 else { throw AdmissionError.invalid("manifest rows=\(manifestRows.count), expected 7420") }
        guard manifestRows.contains(where: { String($0.split(separator: "|", omittingEmptySubsequences: false).first ?? "") == String(format: "0x%016llx", target) && $0.contains("|planned|") }) else {
            throw AdmissionError.invalid("target is not a planned manifest row")
        }

        let traceURLs = [options.cTrace, options.swiftTrace, options.asanTrace, options.releaseTrace, options.rerunTrace]
        let traceBytes = try traceURLs.map { try Data(contentsOf: $0) }
        guard Set(traceBytes).count == 1 else { throw AdmissionError.invalid("C/Swift/ASan/Release/rerun trace bytes differ") }
        let traces = try traceURLs.map { try SM64OracleTraceFile.read(from: $0) }
        guard traces.allSatisfy({ $0.configuration.mode == .record && $0.records.count == 2 }) else {
            throw AdmissionError.invalid("trace configuration or record count mismatch")
        }
        for trace in traces {
            guard trace.records.map(\.simulationTick) == [1, 2] else { throw AdmissionError.invalid("tick window is not [1,2]") }
            for record in trace.records {
                guard record.domain == 11, record.recordKind == 7,
                      record.subjectID == target, record.recordID == event,
                      record.sequence == 0, record.flags == 3,
                      record.values.count == 8 else {
                    throw AdmissionError.invalid("door record identity or shape mismatch")
                }
            }
        }
        guard traces.dropFirst().allSatisfy({ $0.configuration == traces[0].configuration && $0.records == traces[0].records }) else {
            throw AdmissionError.invalid("C/Swift/ASan/Release/rerun records differ")
        }

        let packetURLs = [options.cPacket, options.asanPacket, options.releasePacket, options.rerunPacket]
        let packetBytes = try packetURLs.map { try Data(contentsOf: $0) }
        guard Set(packetBytes).count == 1 else { throw AdmissionError.invalid("packet sidecar bytes differ") }
        let packetText = try String(data: packetBytes[0], encoding: .utf8) ?? ""
        let fields = Dictionary(uniqueKeysWithValues: packetText.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "|", omittingEmptySubsequences: false).compactMap { field -> (String, String)? in
            let pair = field.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            return pair.count == 2 ? (String(pair[0]), String(pair[1])) : nil
        })
        guard parseHex(fields["source_identity"]) == source,
              parseHex(fields["owner_identity"]) == owner,
              fields["word_count"] == "6", fields["drawing_layer"] == "1",
              fields["triangle_count"] == "4", fields["flags"] == "3",
              parseHex(fields["packet_fingerprint"]) == packetFingerprint,
              parseWords(fields["words"]) == words,
              parseWords(fields["resources"]) == resources,
              hashWords(resources) == resourceFingerprint else {
            throw AdmissionError.invalid("door packet identity, words, or resource fingerprint mismatch")
        }
        let expectedValues: [UInt64] = [source, owner, packetFingerprint, 6, 4, resourceFingerprint, 1, 3]
        guard traces[0].records.allSatisfy({ $0.values == expectedValues }) else {
            throw AdmissionError.invalid("trace packet values differ from the authored packet")
        }

        do {
            _ = try SM64OracleTraceFile.read(from: options.tamperedTrace)
            throw AdmissionError.tamperAccepted
        } catch let error as AdmissionError {
            throw error
        } catch {
            // Canonical decoding must reject the tampered trace.
        }
        try require(options.debugLog, "status=0 trace_status=0 records=2 invocations=2 matches=2 failures=0")
        try require(options.swiftLog, "display_list_door_pairing_audit admitted=1 c_records=2 swift_records=2 blockers= first_divergence=none")
        try require(options.tamperLog, "display_list_door_pairing_tamper_rejected=1")
        try require(options.asanLog, "records=2 invocations=2 matches=2 failures=0")
        try require(options.releaseLog, "records=2 invocations=2 matches=2 failures=0")
        try require(options.rerunLog, "records=2 invocations=2 matches=2 failures=0")
        try require(options.partialLog, "invalidHeader")
        try require(options.singleLog, "invalidHeader")

        let targetText = String(format: "0x%016llx|passed|2|2|2|", target)
        let report = manifestRows.map { row -> String in
            let fields = row.split(separator: "|", omittingEmptySubsequences: false)
            let id = String(fields[0])
            return id == String(format: "0x%016llx", target) ? targetText : "\(id)|planned|0|0|0|"
        }.joined(separator: "\n") + "\n"
        try FileManager.default.createDirectory(at: options.report.deletingLastPathComponent(), withIntermediateDirectories: true)
        try report.write(to: options.report, atomically: true, encoding: .utf8)
        print("SM64 door display-list route isolated admission passed shard=0x\(String(target, radix: 16)) identity=door_seg3_dl_03014EF0 source=actors/door/model.inc.c records=2 ticks=1,2 domain=11 kind=7 schema=4 manifest_rows=7420 report_rows=7420 passed_rows=1 planned_rows=7419 fixture_only=0 manifest_mutated=0 canonical_ledger_mutation=0 history_mutated=0 tamper_rejected=1 rerun_fence=1 packet=0x\(String(packetFingerprint, radix: 16)) resource=0x\(String(resourceFingerprint, radix: 16)) report=\(options.report.path)")
    }

    private static func parse(_ arguments: [String]) throws -> Options {
        let keys = ["manifest", "c-trace", "swift-trace", "asan-trace", "release-trace", "rerun-trace", "tampered-trace", "c-packet", "asan-packet", "release-packet", "rerun-packet", "debug-log", "swift-log", "tamper-log", "asan-log", "release-log", "rerun-log", "partial-log", "single-log", "report"]
        guard arguments.count == keys.count * 2 else { throw AdmissionError.usage }
        var values = [String: String](); var index = 0
        while index < arguments.count {
            let key = String(arguments[index]).replacingOccurrences(of: "--", with: "")
            guard keys.contains(key), values[key] == nil else { throw AdmissionError.usage }
            values[key] = arguments[index + 1]; index += 2
        }
        guard values.count == keys.count else { throw AdmissionError.usage }
        func url(_ key: String) -> URL { URL(fileURLWithPath: values[key]!) }
        return Options(manifest: url("manifest"), cTrace: url("c-trace"), swiftTrace: url("swift-trace"), asanTrace: url("asan-trace"), releaseTrace: url("release-trace"), rerunTrace: url("rerun-trace"), tamperedTrace: url("tampered-trace"), cPacket: url("c-packet"), asanPacket: url("asan-packet"), releasePacket: url("release-packet"), rerunPacket: url("rerun-packet"), debugLog: url("debug-log"), swiftLog: url("swift-log"), tamperLog: url("tamper-log"), asanLog: url("asan-log"), releaseLog: url("release-log"), rerunLog: url("rerun-log"), partialLog: url("partial-log"), singleLog: url("single-log"), report: url("report"))
    }

    private static func parseHex(_ value: String?) -> UInt64? { guard let value, value.hasPrefix("0x") else { return nil }; return UInt64(value.dropFirst(2), radix: 16) }
    private static func parseWords(_ value: String?) -> [UInt32]? { value?.split(separator: ",", omittingEmptySubsequences: false).compactMap { UInt32($0, radix: 16) } }
    private static func hashWords(_ values: [UInt32]) -> UInt64 {
        values.reduce(UInt64(1_469_598_103_934_665_603)) { partial, value in
            (0..<4).reduce(partial) { hash, byte in (hash ^ UInt64((value >> UInt32(byte * 8)) & 0xff)) &* 1_099_511_628_211 }
        }
    }
    private static func require(_ url: URL, _ marker: String) throws {
        let text = try String(contentsOf: url, encoding: .utf8)
        guard text.contains(marker) else { throw AdmissionError.invalid("missing marker \(marker) in \(url.path)") }
    }
}
