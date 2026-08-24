import Foundation

/// Extracts the source-backed Castle Inside area-2 pendulum records from a
/// real schema-4 C lifecycle trace and the Phase 46 Swift source trace.  The
/// extractor intentionally keeps only the supplied native object-pool slot,
/// the source pendulum subject, and the one collision query at the canonical
/// pendulum position.  Collision/effect records from Mario or other objects
/// are not accepted as pendulum evidence.
@main
struct SM64PendulumTracePairTool {
    private static let requiredDomains: Set<UInt32> = [3, 6, 7, 12]
    private static let pendulumPositionBits: [UInt64] = [
        0x0000_0000_c34d_0000,
        0x0000_0000_4523_3000,
        0x0000_0000_45df_2000,
    ]
    private static let semanticBehaviorIdentity: UInt64 = 0x0062_6876_5f64_7065
    private static let authoredTickWindow = 64

    private enum PairError: Error, CustomStringConvertible {
        case usage
        case missing(String)
        case invalid(String)
        case rerun(URL)
        case decode(URL, Error)
        case write(URL, Error)

        var description: String {
            switch self {
            case .usage:
                return "usage: sm64-pendulum-pair --c-trace TRACE --swift-trace TRACE --pendulum-slot N --output REPORT"
            case let .missing(value): return "missing argument \(value)"
            case let .invalid(value): return value
            case let .rerun(url): return "persistent rerun fence: output already exists at \(url.path)"
            case let .decode(url, error): return "cannot decode \(url.path): \(error)"
            case let .write(url, error): return "cannot write \(url.path): \(error)"
            }
        }
    }

    private struct Options {
        let cTrace: URL
        let swiftTrace: URL
        let slot: UInt64
        let output: URL
    }

    private struct Key: Hashable, Comparable {
        let tick: UInt64
        let domain: UInt32
        let sequence: UInt32

        static func < (lhs: Key, rhs: Key) -> Bool {
            if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
            if lhs.domain != rhs.domain { return lhs.domain < rhs.domain }
            return lhs.sequence < rhs.sequence
        }
    }

    private struct CanonicalRecord: Equatable {
        let key: Key
        let kind: UInt32
        let subject: UInt64
        let recordID: UInt64
        let flags: UInt32
        let values: [UInt64]

        var summary: String {
            let valuesText = values.map { String(format: "0x%016llx", $0) }.joined(separator: ",")
            return "tick=\(key.tick) domain=\(key.domain) sequence=\(key.sequence) kind=\(kind) subject=\(subject) record=\(recordID) flags=\(flags) values=[\(valuesText)]"
        }
    }

    private struct TracePair {
        let c: (configuration: SM64OracleTraceConfiguration, records: [SM64OracleTraceRecord])
        let swift: (configuration: SM64OracleTraceConfiguration, records: [SM64OracleTraceRecord])
        let nativeSlot: UInt64
        let swiftSubject: UInt64
        let cRelevant: [SM64OracleTraceRecord]
        let swiftRelevant: [SM64OracleTraceRecord]
        let cCanonical: [Key: CanonicalRecord]
        let swiftCanonical: [Key: CanonicalRecord]
        let headerDivergences: [String]
        let firstDivergence: String?

        var cDomains: [UInt32] { Set(cRelevant.map(\.domain)).sorted() }
        var swiftDomains: [UInt32] { Set(swiftRelevant.map(\.domain)).sorted() }
        var matchedCount: Int {
            cCanonical.keys.filter { key in
                guard let lhs = cCanonical[key], let rhs = swiftCanonical[key] else { return false }
                return lhs == rhs
            }.count
        }
    }

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(("sm64-pendulum-pair: \(error)\n").utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        guard !FileManager.default.fileExists(atPath: options.output.path) else {
            throw PairError.rerun(options.output)
        }
        let c = try read(options.cTrace)
        let swift = try read(options.swiftTrace)
        let pair = try makePair(c: c, swift: swift, slot: options.slot)
        let tamperRejected = try tamperRejected(options.swiftTrace)
        let replayRoundTrip = try replayRoundTrip(options.cTrace, trace: c)
        let report = makeReport(pair: pair, tamperRejected: tamperRejected, replayRoundTrip: replayRoundTrip)
        do {
            try FileManager.default.createDirectory(
                at: options.output.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(report.utf8).write(to: options.output, options: .atomic)
        } catch {
            throw PairError.write(options.output, error)
        }
        print(report.trimmingCharacters(in: .newlines))
    }

    private static func parse(arguments: [String]) throws -> Options {
        guard arguments.count == 8 else { throw PairError.usage }
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            guard arguments[index].hasPrefix("--"), values[arguments[index]] == nil else {
                throw PairError.usage
            }
            values[arguments[index]] = arguments[index + 1]
            index += 2
        }
        guard let c = values["--c-trace"], let swift = values["--swift-trace"],
              let rawSlot = values["--pendulum-slot"], let output = values["--output"] else {
            throw PairError.missing("--c-trace, --swift-trace, --pendulum-slot, or --output")
        }
        guard let slot = UInt64(rawSlot), slot > 0 else {
            throw PairError.invalid("pendulum slot must be a positive decimal pool slot")
        }
        return Options(
            cTrace: URL(fileURLWithPath: c).standardizedFileURL,
            swiftTrace: URL(fileURLWithPath: swift).standardizedFileURL,
            slot: slot,
            output: URL(fileURLWithPath: output).standardizedFileURL
        )
    }

    private static func read(_ url: URL) throws -> (configuration: SM64OracleTraceConfiguration, records: [SM64OracleTraceRecord]) {
        do {
            return try SM64OracleTraceFile.read(from: url)
        } catch {
            throw PairError.decode(url, error)
        }
    }

    private static func makePair(
        c: (configuration: SM64OracleTraceConfiguration, records: [SM64OracleTraceRecord]),
        swift: (configuration: SM64OracleTraceConfiguration, records: [SM64OracleTraceRecord]),
        slot: UInt64
    ) throws -> TracePair {
        guard c.configuration.mode == .record, swift.configuration.mode == .record else {
            throw PairError.invalid("both traces must be schema-4 record traces")
        }

        let cPendulumScript = c.records.filter { $0.domain == 6 && $0.subjectID == slot }
        guard cPendulumScript.contains(where: { $0.recordID == 4 }) else {
            throw PairError.invalid("native trace has no script native-behavior record for pendulum slot \(slot)")
        }

        // The native lifecycle performs three warm-up ticks before the
        // authored area-2 object owns the pool slot, and one trailing redraw
        // remains after the 64-tick source window.  Establish the route
        // boundary from the source semantic behavior record itself rather
        // than comparing those unrelated slot occupants.  This is a
        // source-authored lifecycle fence, not a post-hoc value rewrite.
        let nativeBehaviorRecords = c.records.filter {
            $0.domain == 3
                && $0.recordKind == 1
                && $0.subjectID == slot
                && $0.recordID == 400
                && $0.values.first == semanticBehaviorIdentity
        }
        let semanticTicks = nativeBehaviorRecords.map(\.simulationTick).sorted()
        guard let authoredStart = semanticTicks.first else {
            throw PairError.invalid("native pendulum slot never published the source semantic behavior identity")
        }
        let authoredEnd = authoredStart + UInt64(authoredTickWindow - 1)
        let authoredTickSet = Set(semanticTicks)
        guard semanticTicks.count >= authoredTickWindow,
              (authoredStart...authoredEnd).allSatisfy({ authoredTickSet.contains($0) }) else {
            throw PairError.invalid(
                "native pendulum semantic behavior window is not the authored 64-tick interval"
            )
        }

        let sourceSubjects = Set(swift.records.filter {
            requiredDomains.contains($0.domain) && $0.domain != 7
        }.map(\.subjectID))
        guard sourceSubjects.count == 1, let sourceSubject = sourceSubjects.first else {
            throw PairError.invalid("Swift source trace must contain exactly one non-collision pendulum subject")
        }

        let cRelevant = c.records.filter { record in
            switch record.domain {
            case 3, 6:
                return record.subjectID == slot
                    && record.simulationTick >= authoredStart
                    && record.simulationTick <= authoredEnd
            case 12:
                return record.subjectID == slot
                    && record.recordID == 1
                    && record.simulationTick >= authoredStart
                    && record.simulationTick <= authoredEnd
            case 7:
                return record.recordID == 1
                    && record.simulationTick >= authoredStart
                    && record.simulationTick <= authoredEnd
                    && Array(record.values.prefix(3)) == pendulumPositionBits
            default:
                return false
            }
        }
        let swiftRelevant = swift.records.filter { record in
            switch record.domain {
            case 3, 6, 12:
                return record.subjectID == sourceSubject
            case 7:
                return record.recordID == 1
                    && Array(record.values.prefix(3)) == pendulumPositionBits
            default:
                return false
            }
        }

        let cCanonical = canonicalize(cRelevant, subject: slot, source: .native)
        let swiftCanonical = canonicalize(swiftRelevant, subject: slot, source: .swift)
        let headerDivergences = compareHeaders(c.configuration, swift.configuration)
        let firstDivergence = firstDivergence(c: cCanonical, swift: swiftCanonical)
        return TracePair(
            c: c,
            swift: swift,
            nativeSlot: slot,
            swiftSubject: sourceSubject,
            cRelevant: cRelevant,
            swiftRelevant: swiftRelevant,
            cCanonical: cCanonical,
            swiftCanonical: swiftCanonical,
            headerDivergences: headerDivergences,
            firstDivergence: firstDivergence
        )
    }

    private enum TraceSide { case native, swift }

    private static func canonicalize(
        _ records: [SM64OracleTraceRecord],
        subject: UInt64,
        source: TraceSide
    ) -> [Key: CanonicalRecord] {
        let origin = records.filter { $0.domain == 6 && $0.recordID == 5 }
            .map(\.simulationTick).min() ?? records.map(\.simulationTick).min() ?? 0
        var nextSequence: [UInt64: UInt32] = [:]
        var result: [Key: CanonicalRecord] = [:]
        for record in records.sorted(by: { lhs, rhs in
            if lhs.simulationTick != rhs.simulationTick { return lhs.simulationTick < rhs.simulationTick }
            if lhs.domain != rhs.domain { return lhs.domain < rhs.domain }
            return lhs.sequence < rhs.sequence
        }) {
            let relativeTick = record.simulationTick >= origin
                ? record.simulationTick - origin + 1
                : 0
            let sequenceKey = (relativeTick << 8) | UInt64(record.domain)
            let sequence = nextSequence[sequenceKey, default: 0]
            nextSequence[sequenceKey] = sequence + 1
            let key = Key(tick: relativeTick, domain: record.domain, sequence: sequence)
            result[key] = CanonicalRecord(
                key: key,
                kind: record.recordKind,
                subject: subject,
                recordID: record.recordID,
                flags: record.flags,
                values: record.values
            )
        }
        _ = source
        return result
    }

    private static func compareHeaders(
        _ c: SM64OracleTraceConfiguration,
        _ swift: SM64OracleTraceConfiguration
    ) -> [String] {
        let values: [(String, UInt64, UInt64)] = [
            ("build", c.buildFingerprint, swift.buildFingerprint),
            ("content", c.contentFingerprint, swift.contentFingerprint),
            ("timebase", c.timebaseFingerprint, swift.timebaseFingerprint),
            ("configuration", c.configurationFingerprint, swift.configurationFingerprint),
            ("initial_save", c.initialSaveFingerprint, swift.initialSaveFingerprint),
            ("coverage", c.coverageFingerprint, swift.coverageFingerprint),
        ]
        return values.compactMap { name, lhs, rhs in
            lhs == rhs ? nil : "\(name): c=\(format(lhs)) swift=\(format(rhs))"
        }
    }

    private static func firstDivergence(
        c: [Key: CanonicalRecord],
        swift: [Key: CanonicalRecord]
    ) -> String? {
        for key in Set(c.keys).union(swift.keys).sorted() {
            guard let lhs = c[key] else { return "missing_c \(swift[key]!.summary)" }
            guard let rhs = swift[key] else { return "missing_swift \(lhs.summary)" }
            if lhs != rhs {
                return "record_mismatch c={\(lhs.summary)} swift={\(rhs.summary)}"
            }
        }
        return nil
    }

    private static func tamperRejected(_ url: URL) throws -> Bool {
        var bytes = try Data(contentsOf: url)
        guard !bytes.isEmpty else { return false }
        bytes[bytes.count - 1] ^= 1
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-pendulum-tamper-\(UUID().uuidString).trace")
        defer { try? FileManager.default.removeItem(at: temp) }
        try bytes.write(to: temp, options: .atomic)
        do {
            _ = try SM64OracleTraceFile.read(from: temp)
            return false
        } catch {
            return true
        }
    }

    private static func replayRoundTrip(
        _ url: URL,
        trace: (configuration: SM64OracleTraceConfiguration, records: [SM64OracleTraceRecord])
    ) throws -> Bool {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("sm64-pendulum-replay-\(UUID().uuidString).trace")
        defer { try? FileManager.default.removeItem(at: temp) }
        try SM64OracleTraceFile.write(configuration: trace.configuration, records: trace.records, to: temp)
        let decoded = try SM64OracleTraceFile.read(from: temp)
        let sourceBytes = try Data(contentsOf: URL(fileURLWithPath: url.path), options: [.mappedIfSafe])
        let roundTripBytes = try Data(contentsOf: temp, options: [.mappedIfSafe])
        return decoded.configuration == trace.configuration
            && decoded.records == trace.records
            && sourceBytes == roundTripBytes
    }

    private static func makeReport(
        pair: TracePair,
        tamperRejected: Bool,
        replayRoundTrip: Bool
    ) -> String {
        let cTicks = Set(pair.cRelevant.map(\.simulationTick)).sorted()
        let swiftTicks = Set(pair.swiftRelevant.map(\.simulationTick)).sorted()
        let cDomains = pair.cDomains.map(String.init).joined(separator: ",")
        let swiftDomains = pair.swiftDomains.map(String.init).joined(separator: ",")
        let missingC = requiredDomains.subtracting(pair.cDomains).sorted().map(String.init).joined(separator: ",")
        let missingSwift = requiredDomains.subtracting(pair.swiftDomains).sorted().map(String.init).joined(separator: ",")
        let lines = [
            "# sm64-modern-pendulum-pair-v1",
            "native_slot=\(pair.nativeSlot) swift_subject=\(pair.swiftSubject)",
            "native_records=\(pair.cRelevant.count) swift_records=\(pair.swiftRelevant.count)",
            "native_ticks=\(cTicks.map(String.init).joined(separator: ",")) swift_ticks=\(swiftTicks.map(String.init).joined(separator: ","))",
            "native_domains=\(cDomains) swift_domains=\(swiftDomains)",
            "required_domains=3,6,7,12 missing_native=\(missingC) missing_swift=\(missingSwift)",
            "header_divergences=\(pair.headerDivergences.isEmpty ? "none" : pair.headerDivergences.joined(separator: ";"))",
            "matched_records=\(pair.matchedCount) canonical_records_native=\(pair.cCanonical.count) canonical_records_swift=\(pair.swiftCanonical.count)",
            "tamper_rejected=\(tamperRejected ? 1 : 0) schema4_replay_round_trip=\(replayRoundTrip ? 1 : 0)",
            "independent_c_swift_pair=0 exact_bytes=0 promotion=not_attempted canonical_route_admission=0",
            "first_divergence=\(pair.firstDivergence ?? "none")",
        ]
        return lines.joined(separator: "\n") + "\n"
    }

    private static func format(_ value: UInt64) -> String {
        String(format: "0x%016llx", value)
    }
}
