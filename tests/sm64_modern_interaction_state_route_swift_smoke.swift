import Foundation

private let routeShardID: UInt64 = 0x3e1c_daca_08b2_1f54
private let routeInputSeed: UInt64 = 0xee18_7b29_391f_c62c
private let routeSaveSeed: UInt64 = 0x7bc4_0eed_2525_5955
private let routeTicks: [UInt64] = [2, 3]

private func update(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= SM64OracleTraceHash.prime
    }
    return hash
}

private func hashString(_ value: String) -> UInt64 {
    value.utf8.reduce(SM64OracleTraceHash.offset) { hash, byte in
        (hash ^ UInt64(byte)) &* SM64OracleTraceHash.prime
    }
}

private func timebaseFingerprint() -> UInt64 {
    [UInt32(3), 60, 1, 30, 1, 2, 2].reduce(SM64OracleTraceHash.offset) {
        hash, value in
        var next = hash
        for byte in 0..<4 {
            next ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
            next &*= SM64OracleTraceHash.prime
        }
        return next
    }
}

private func coverageFingerprint() -> UInt64 {
    var hash = SM64OracleTraceHash.offset
    for recordID in SM64InteractionStateMigration.firstRecord...SM64InteractionStateMigration.lastRecord {
        for value in [UInt64(4), 0, recordID] {
            hash = update(hash, value)
        }
    }
    return update(hash, SM64InteractionStateMigration.lastRecord
        - SM64InteractionStateMigration.firstRecord + 1)
}

private func configuration() -> SM64OracleTraceConfiguration {
    SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: hashString("sm64-modern-interaction-state-route-build-v1"),
        contentFingerprint: hashString(
            "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|interaction_state"
        ),
        timebaseFingerprint: timebaseFingerprint(),
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "shard=0x3e1cdaca08b21f54"
        ),
        initialSaveFingerprint: hashString(
            "save=empty-us-slot-0;seed=0x7bc40eed25255955"
        ),
        coverageFingerprint: coverageFingerprint()
    )
}

/// This uses the production value-state initializer and leaves all object
/// references absent.  The Swift side deliberately has no collision list or
/// interaction handler here; if a live interaction appears, this route must
/// fail closed rather than synthesize an answer.
private func sourceBackedStates() -> [SM64MarioState] {
    let state = SM64MarioState.initialized(
        save: SM64MarioSaveState(totalStars: 0),
        spawn: SM64MarioSpawnInput(
            position: .zero,
            faceAngle: .zero,
            waterLevel: -11_000
        ),
        floor: .miss,
        marioObjectID: SM64ObjectID(slot: 0, generation: 1)
    )
    return [state, state]
}

private func writeTrace(to url: URL) throws {
    let states = sourceBackedStates()
    let records = try states.enumerated().flatMap { index, state in
        try SM64InteractionStateMigration(state: state)
            .records(simulationTick: routeTicks[index])
    }
    try SM64OracleTraceFile.write(
        configuration: configuration(), records: records, to: url
    )
    print(
        "swift_interaction_state_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "input_seed=0x\(String(routeInputSeed, radix: 16)) "
            + "save_seed=0x\(String(routeSaveSeed, radix: 16)) "
            + "records=\(records.count) ticks=2,3 "
            + "coverage=0x\(String(coverageFingerprint(), radix: 16)) "
            + "source_state=SM64MarioState"
    )
}

private func validOrdering(_ records: [SM64OracleTraceRecord]) -> Bool {
    guard records.count == 14 else { return false }
    for (index, record) in records.enumerated() {
        let tick = routeTicks[index / 7]
        let offset = index % 7
        guard record.simulationTick == tick,
              record.domain == SM64InteractionStateMigration.domain,
              record.recordKind == SM64InteractionStateMigration.recordKind,
              record.subjectID == 0,
              record.recordID == SM64InteractionStateMigration.firstRecord
                + UInt64(offset),
              record.sequence == UInt32(offset),
              record.values.count == 1 else {
            return false
        }
    }
    return true
}

private func audit(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if !validOrdering(cTrace.records) || !validOrdering(swiftTrace.records) {
        blockers.append("ordering")
    }
    if cTrace.records.count != swiftTrace.records.count { blockers.append("record_count") }
    if cTrace.records != swiftTrace.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "interaction_state_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cTrace.records.count) swift_records=\(swiftTrace.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence)"
    )
    guard blockers.isEmpty else { throw SM64OracleTraceCodecError.invalidHeader }
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard data.count >= 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    data[data.index(before: data.endIndex)] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("interaction_state_pairing_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("interaction_state_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernInteractionStateRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else {
            throw SM64OracleTraceCodecError.truncated
        }
        switch mode {
        case "write":
            guard arguments.count == 2 else { throw SM64OracleTraceCodecError.truncated }
            try writeTrace(to: URL(fileURLWithPath: arguments[1]).standardizedFileURL)
        case "audit":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try audit(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "tamper":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try tamper(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
