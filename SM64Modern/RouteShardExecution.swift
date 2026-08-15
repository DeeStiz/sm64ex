import Foundation

private let routeShardFNVOffset: UInt64 = 1_469_598_103_934_665_603
private let routeShardFNVPrime: UInt64 = 1_099_511_628_211

enum SM64RouteShardExecutionState: String, Sendable {
    case planned
    case running
    case passed
    case failed
    case blocked

    var isTerminal: Bool {
        switch self {
        case .planned, .running: return false
        case .passed, .failed, .blocked: return true
        }
    }
}

enum SM64RouteShardTraceDomain: String, CaseIterable, Sendable {
    case globalState = "global_state"
    case input
    case marioState = "mario_state"
    case objectState = "object_state"
    case interactionState = "interaction_state"
    case cameraState = "camera_state"
    case scriptEvents = "script_events"
    case transition
    case collisionQueries = "collision_queries"
    case rngDraws = "rng_draws"
    case audioSequence = "audio_sequence"
    case audioPCM = "audio_pcm"
    case saveBytes = "save_bytes"
    case renderPacket = "render_packet"
    case effects

    var cDomain: UInt32 {
        switch self {
        case .globalState: return 0
        case .input: return 1
        case .marioState: return 2
        case .objectState: return 3
        case .interactionState: return 4
        case .cameraState: return 5
        case .scriptEvents, .transition: return 6
        case .collisionQueries: return 7
        case .rngDraws: return 8
        case .audioSequence, .audioPCM: return 9
        case .saveBytes: return 10
        case .renderPacket: return 11
        case .effects: return 12
        }
    }

    var cRecordKind: UInt32 {
        switch self {
        case .input: return 2 // SM64_MODERN_ORACLE_RECORD_INPUT
        case .scriptEvents, .transition: return 3 // SM64_MODERN_ORACLE_RECORD_EVENT
        case .effects: return 4 // SM64_MODERN_ORACLE_RECORD_EFFECT
        case .audioPCM: return 5 // SM64_MODERN_ORACLE_RECORD_AUDIO_PCM
        case .saveBytes: return 6 // SM64_MODERN_ORACLE_RECORD_SAVE_BYTES
        case .renderPacket: return 7 // SM64_MODERN_ORACLE_RECORD_RENDER_PACKET
        default: return 1 // SM64_MODERN_ORACLE_RECORD_STATE
        }
    }
}

enum SM64RouteShardExecutionError: Error, Equatable, CustomStringConvertible {
    case invalidManifestHeader
    case malformedManifestLine(Int, String)
    case duplicateShard(UInt64)
    case emptyManifest
    case unknownShard(UInt64)
    case invalidTransition(UInt64, from: SM64RouteShardExecutionState, to: SM64RouteShardExecutionState)
    case invalidTerminalState(SM64RouteShardExecutionState)
    case invalidHex(String)
    case invalidExpectedDomain(String)
    case invalidReport(String)

    var description: String {
        switch self {
        case .invalidManifestHeader:
            return "invalid route-shard manifest header"
        case let .malformedManifestLine(line, reason):
            return "route-shard manifest line \(line): \(reason)"
        case let .duplicateShard(id):
            return String(format: "duplicate route shard 0x%016llx", id)
        case .emptyManifest:
            return "route-shard manifest is empty"
        case let .unknownShard(id):
            return String(format: "unknown route shard 0x%016llx", id)
        case let .invalidTransition(id, from, to):
            return "invalid route-shard transition \(id): \(from.rawValue) -> \(to.rawValue)"
        case let .invalidTerminalState(state):
            return "route-shard state is not terminal: \(state.rawValue)"
        case let .invalidHex(value):
            return "invalid hexadecimal value: \(value)"
        case let .invalidExpectedDomain(value):
            return "invalid expected trace domain: \(value)"
        case let .invalidReport(reason):
            return "invalid route-shard report: \(reason)"
        }
    }
}

struct SM64RouteShard: Sendable, Equatable, Identifiable {
    let id: UInt64
    let domain: String
    let identity: String
    let source: String
    let inputSeed: UInt64
    let saveSeed: UInt64
    let expectedDomains: [SM64RouteShardTraceDomain]
    let manifestState: SM64RouteShardExecutionState
    let notes: String

    var encodedIdentity: String {
        [domain, identity, source].joined(separator: "|")
    }

    init(manifestLine: Substring, lineNumber: Int) throws {
        let fields = manifestLine.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard fields.count == 9 else {
            throw SM64RouteShardExecutionError.malformedManifestLine(
                lineNumber,
                "expected nine pipe-delimited fields"
            )
        }
        self.id = try Self.parseHex(fields[0])
        self.domain = fields[1]
        self.identity = fields[2]
        self.source = fields[3]
        self.inputSeed = try Self.parseHex(fields[4])
        self.saveSeed = try Self.parseHex(fields[5])
        let domainValues = fields[6].split(separator: ",", omittingEmptySubsequences: true)
        guard !domainValues.isEmpty else {
            throw SM64RouteShardExecutionError.malformedManifestLine(
                lineNumber,
                "expected trace domain set is empty"
            )
        }
        self.expectedDomains = try domainValues.map { value in
            guard let domain = SM64RouteShardTraceDomain(rawValue: String(value)) else {
                throw SM64RouteShardExecutionError.invalidExpectedDomain(String(value))
            }
            return domain
        }.sorted { $0.rawValue < $1.rawValue }
        guard Set(self.expectedDomains).count == self.expectedDomains.count else {
            throw SM64RouteShardExecutionError.malformedManifestLine(
                lineNumber,
                "expected trace domain set contains duplicates"
            )
        }
        guard let state = SM64RouteShardExecutionState(rawValue: fields[7]) else {
            throw SM64RouteShardExecutionError.malformedManifestLine(
                lineNumber,
                "unknown execution state \(fields[7])"
            )
        }
        self.manifestState = state
        self.notes = fields[8]
        guard state == .planned else {
            throw SM64RouteShardExecutionError.malformedManifestLine(
                lineNumber,
                "manifest rows must enter the ledger as planned"
            )
        }
    }

    private static func parseHex(_ value: String) throws -> UInt64 {
        guard value.hasPrefix("0x"), let parsed = UInt64(value.dropFirst(2), radix: 16) else {
            throw SM64RouteShardExecutionError.invalidHex(value)
        }
        return parsed
    }
}

struct SM64RouteShardExecutionEvidence: Sendable, Equatable {
    let expectedRecords: UInt64
    let actualRecords: UInt64
    let matchedRecords: UInt64
    let firstDivergence: String?

    init(expectedRecords: UInt64, actualRecords: UInt64, matchedRecords: UInt64, firstDivergence: String? = nil) {
        self.expectedRecords = expectedRecords
        self.actualRecords = actualRecords
        self.matchedRecords = matchedRecords
        self.firstDivergence = firstDivergence
    }
}

struct SM64RouteShardCoverage: Sendable, Equatable {
    let expectedKeys: Set<String>
    let observedKeys: Set<String>
    let missingDomains: Set<String>
    let unexpectedKeys: Set<String>
    let recordCountMatches: Bool

    var isComplete: Bool {
        recordCountMatches && missingDomains.isEmpty && unexpectedKeys.isEmpty
    }
}

private struct RouteShardLedgerEntry: Sendable, Equatable {
    let shard: SM64RouteShard
    var state: SM64RouteShardExecutionState
    var evidence: SM64RouteShardExecutionEvidence?
}

/// Owner-thread/value-only execution ledger for the M33 route-shard runner.
/// A manifest is immutable input; only this ledger may advance a shard. Every
/// terminal transition carries record counts, and a passed shard is rejected
/// unless all observed records matched. This prevents a runner from turning a
/// missing/partial replay into qualification evidence.
struct SM64RouteShardExecutionLedger: Sendable {
    private var entries: [UInt64: RouteShardLedgerEntry]

    init(manifest: String, report: String? = nil) throws {
        let lines = manifest.split(whereSeparator: { $0.isNewline })
        guard lines.count >= 2,
              lines[0] == "# sm64-modern-route-shards-v1",
              lines[1] == "# shard_id|domain|identity|source|input_seed|save_seed|expected_domains|status|notes" else {
            throw SM64RouteShardExecutionError.invalidManifestHeader
        }
        var parsed: [UInt64: RouteShardLedgerEntry] = [:]
        for (offset, line) in lines.dropFirst(2).enumerated() {
            let lineNumber = offset + 3
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let shard = try SM64RouteShard(manifestLine: line, lineNumber: lineNumber)
            guard parsed[shard.id] == nil else {
                throw SM64RouteShardExecutionError.duplicateShard(shard.id)
            }
            parsed[shard.id] = RouteShardLedgerEntry(
                shard: shard,
                state: .planned,
                evidence: nil
            )
        }
        guard !parsed.isEmpty else { throw SM64RouteShardExecutionError.emptyManifest }
        self.entries = parsed
        if let report {
            try apply(report: report)
        }
    }

    var count: Int { entries.count }

    var plannedCount: Int { entries.values.filter { $0.state == .planned }.count }

    var terminalCount: Int { entries.values.filter { $0.state.isTerminal }.count }

    var allTerminal: Bool { entries.values.allSatisfy { $0.state.isTerminal } }

    func shard(id: UInt64) throws -> SM64RouteShard {
        guard let entry = entries[id] else {
            throw SM64RouteShardExecutionError.unknownShard(id)
        }
        return entry.shard
    }

    func state(for id: UInt64) throws -> SM64RouteShardExecutionState {
        guard let entry = entries[id] else {
            throw SM64RouteShardExecutionError.unknownShard(id)
        }
        return entry.state
    }

    func evidence(for id: UInt64) throws -> SM64RouteShardExecutionEvidence? {
        guard let entry = entries[id] else {
            throw SM64RouteShardExecutionError.unknownShard(id)
        }
        return entry.evidence
    }

    mutating func begin(id: UInt64) throws {
        try transition(id: id, to: .running, evidence: nil)
    }

    mutating func finish(id: UInt64, state: SM64RouteShardExecutionState, evidence: SM64RouteShardExecutionEvidence) throws {
        guard state.isTerminal else {
            throw SM64RouteShardExecutionError.invalidTerminalState(state)
        }
        if state == .passed {
            guard evidence.expectedRecords > 0,
                  evidence.actualRecords == evidence.expectedRecords,
                  evidence.matchedRecords == evidence.expectedRecords,
                  evidence.firstDivergence == nil else {
                throw SM64RouteShardExecutionError.invalidTransition(
                    id,
                    from: .running,
                    to: .failed
                )
            }
        }
        try transition(id: id, to: state, evidence: evidence)
    }

    private mutating func apply(report: String) throws {
        var seen: Set<UInt64> = []
        for (offset, line) in report.split(whereSeparator: { $0.isNewline }).enumerated() {
            let lineNumber = offset + 1
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 6 else {
                throw SM64RouteShardExecutionError.invalidReport(
                    "line \(lineNumber) expected six fields"
                )
            }
            guard let id = try? Self.parseReportHex(fields[0]), entries[id] != nil else {
                throw SM64RouteShardExecutionError.invalidReport(
                    "line \(lineNumber) has unknown shard ID"
                )
            }
            guard seen.insert(id).inserted else {
                throw SM64RouteShardExecutionError.invalidReport(
                    "line \(lineNumber) duplicates shard ID"
                )
            }
            guard let state = SM64RouteShardExecutionState(rawValue: fields[1]) else {
                throw SM64RouteShardExecutionError.invalidReport(
                    "line \(lineNumber) has unknown state"
                )
            }
            guard let expected = UInt64(fields[2]),
                  let actual = UInt64(fields[3]),
                  let matched = UInt64(fields[4]) else {
                throw SM64RouteShardExecutionError.invalidReport(
                    "line \(lineNumber) has invalid evidence counts"
                )
            }
            let divergence = fields[5].isEmpty ? nil : fields[5]
            if state == .planned {
                guard expected == 0, actual == 0, matched == 0, divergence == nil else {
                    throw SM64RouteShardExecutionError.invalidReport(
                        "planned row has terminal evidence"
                    )
                }
                continue
            }
            guard state.isTerminal else {
                throw SM64RouteShardExecutionError.invalidReport(
                    "running rows cannot be persisted"
                )
            }
            let evidence = SM64RouteShardExecutionEvidence(
                expectedRecords: expected,
                actualRecords: actual,
                matchedRecords: matched,
                firstDivergence: divergence
            )
            try transition(id: id, to: .running, evidence: nil)
            try transition(id: id, to: state, evidence: evidence)
        }
        guard seen.count == entries.count else {
            throw SM64RouteShardExecutionError.invalidReport(
                "report does not contain every manifest shard"
            )
        }
    }

    private static func parseReportHex(_ value: String) throws -> UInt64 {
        guard value.hasPrefix("0x"), let parsed = UInt64(value.dropFirst(2), radix: 16) else {
            throw SM64RouteShardExecutionError.invalidReport("invalid shard ID \(value)")
        }
        return parsed
    }

    private mutating func transition(
        id: UInt64,
        to state: SM64RouteShardExecutionState,
        evidence: SM64RouteShardExecutionEvidence?
    ) throws {
        guard var entry = entries[id] else {
            throw SM64RouteShardExecutionError.unknownShard(id)
        }
        let allowed: Bool
        switch (entry.state, state) {
        case (.planned, .running), (.running, .passed), (.running, .failed), (.running, .blocked):
            allowed = true
        default:
            allowed = false
        }
        guard allowed else {
            throw SM64RouteShardExecutionError.invalidTransition(id, from: entry.state, to: state)
        }
        entry.state = state
        entry.evidence = evidence
        entries[id] = entry
    }

    func report() -> String {
        entries.values
            .sorted { $0.shard.id < $1.shard.id }
            .map { entry in
                let evidence = entry.evidence
                return [
                    String(format: "0x%016llx", entry.shard.id),
                    entry.state.rawValue,
                    String(evidence?.expectedRecords ?? 0),
                    String(evidence?.actualRecords ?? 0),
                    String(evidence?.matchedRecords ?? 0),
                    evidence?.firstDivergence ?? "",
                ].joined(separator: "|")
            }
            .joined(separator: "\n") + "\n"
    }
}

/// Deterministic encoding fixture used by M33b to validate the runner before
/// live engine routes are attached. It is intentionally marked as fixture
/// evidence by callers; these records do not qualify gameplay behavior.
enum SM64RouteShardFixture {
    static func configuration(for shard: SM64RouteShard) -> SM64OracleTraceConfiguration {
        SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: shard.id,
            contentFingerprint: shard.inputSeed,
            timebaseFingerprint: shard.saveSeed,
            configurationFingerprint: shard.id ^ shard.inputSeed ^ shard.saveSeed,
            initialSaveFingerprint: shard.saveSeed,
            coverageFingerprint: 0
        )
    }

    static func records(for shard: SM64RouteShard) throws -> [SM64OracleTraceRecord] {
        try shard.expectedDomains.enumerated().map { index, domain in
            let sequence = UInt32(index)
            let recordID = shard.id ^ (routeShardFNVPrime &* UInt64(index + 1))
            return try SM64OracleTraceRecord(
                simulationTick: 1,
                domain: domain.cDomain,
                recordKind: domain.cRecordKind,
                subjectID: shard.id,
                recordID: recordID,
                sequence: sequence,
                values: [shard.inputSeed, shard.saveSeed, shard.id, UInt64(index)]
            )
        }
    }

    static func coverage(
        for shard: SM64RouteShard,
        records: [SM64OracleTraceRecord]
    ) -> SM64RouteShardCoverage {
        let expectedKeys = Set(shard.expectedDomains.map { key(for: $0) })
        let observedKeys = Set(records.map { "\($0.domain):\($0.recordKind)" })
        let missingDomains = Set(
            shard.expectedDomains.filter { !observedKeys.contains(key(for: $0)) }
                .map(\.rawValue)
        )
        let unexpectedKeys = observedKeys.subtracting(expectedKeys)
        return SM64RouteShardCoverage(
            expectedKeys: expectedKeys,
            observedKeys: observedKeys,
            missingDomains: missingDomains,
            unexpectedKeys: unexpectedKeys,
            recordCountMatches: records.count == shard.expectedDomains.count
        )
    }

    private static func key(for domain: SM64RouteShardTraceDomain) -> String {
        "\(domain.cDomain):\(domain.cRecordKind)"
    }

    static func hash(_ value: String) -> UInt64 {
        value.utf8.reduce(routeShardFNVOffset) { partial, byte in
            (partial ^ UInt64(byte)) &* routeShardFNVPrime
        }
    }
}
