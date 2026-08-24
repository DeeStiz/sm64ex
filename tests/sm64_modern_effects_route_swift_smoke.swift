import Foundation

private let effectDomain = UInt32(SM64_MODERN_ORACLE_DOMAIN_EFFECT)
private let effectKind = UInt32(SM64_MODERN_ORACLE_RECORD_EFFECT)
private let spawnEffect = UInt64(SM64_MODERN_EFFECT_OBJECT_SPAWN)
private let despawnEffect = UInt64(SM64_MODERN_EFFECT_OBJECT_DESPAWN)
private let traceHashOffset: UInt64 = 1_469_598_103_934_665_603
private let traceHashPrime: UInt64 = 1_099_511_628_211

private func updateHash(_ hash: UInt64, _ value: UInt64) -> UInt64 {
    var result = hash
    for byte in 0..<8 {
        result ^= (value >> UInt64(byte * 8)) & 0xff
        result &*= traceHashPrime
    }
    return result
}

private func coverageFingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
    var hash = traceHashOffset
    let effectIDs = Set(records.map(\.recordID)).sorted()
    for recordID in effectIDs {
        hash = updateHash(hash, UInt64(SM64_MODERN_ORACLE_DOMAIN_EFFECT))
        hash = updateHash(hash, 0)
        hash = updateHash(hash, recordID)
    }
    return updateHash(hash, UInt64(effectIDs.count))
}

/// This sink is deliberately local to the route audit. It records only the
/// fixed-width object effects that the existing Swift owner-thread router
/// actually delivers; it does not claim that high-level Swift intents are a
/// complete replacement for the native sound/rumble/PCM effect ABI.
private struct SourceEffectTraceSink {
    private(set) var records: [SM64OracleTraceRecord] = []

    mutating func recordSpawn(
        tick: UInt64,
        parent: SM64ObjectID,
        object: SM64ObjectID,
        model: UInt32,
        behaviorIdentity: UInt64
    ) throws {
        records.append(try SM64OracleTraceRecord(
            simulationTick: tick,
            domain: effectDomain,
            recordKind: effectKind,
            subjectID: UInt64(object.traceSubject),
            recordID: spawnEffect,
            sequence: 0,
            values: [
                UInt64(model), behaviorIdentity, UInt64(parent.traceSubject),
            ]
        ))
    }

    mutating func recordDespawn(
        tick: UInt64,
        object: SM64ObjectID,
        behaviorIdentity: UInt64
    ) throws {
        records.append(try SM64OracleTraceRecord(
            simulationTick: tick,
            domain: effectDomain,
            recordKind: effectKind,
            subjectID: UInt64(object.traceSubject),
            recordID: despawnEffect,
            sequence: 0,
            values: [behaviorIdentity]
        ))
    }
}

private func validOrdering(_ records: [SM64OracleTraceRecord]) -> Bool {
    guard !records.isEmpty else { return false }
    var lastTick: UInt64?
    var lastSequence: UInt32 = 0
    for record in records {
        guard record.domain == effectDomain,
              record.recordKind == effectKind else { return false }
        if let lastTick {
            guard record.simulationTick >= lastTick else { return false }
            if record.simulationTick == lastTick {
                guard record.sequence == lastSequence &+ 1 else { return false }
            } else {
                guard record.sequence == 0 else { return false }
            }
        } else {
            guard record.sequence == 0 else { return false }
        }
        lastTick = record.simulationTick
        lastSequence = record.sequence
    }
    return true
}

private func writeTrace(cURL: URL, swiftURL: URL) throws {
    // Only the independently-produced C header is shared: the Swift owner
    // route never reads, filters, or transforms native effect records.
    let cConfiguration = try SM64OracleTraceFile.read(from: cURL).configuration
    let state = SM64SwiftEngineState(objectCapacity: 32)
    let source = try state.spawnObject(
        in: .generalActor,
        model: 0x6B,
        behaviorIdentity: 0x706F7374
    )
    let router = SM64OwnerThreadEffectRouter()
    router.beginTick()
    router.enqueue(objectID: source, kind: .spawnCoin, value: 1)
    let delivery = router.deliver(to: state.objects)
    guard delivery.spawned.count == 1,
          let child = delivery.spawned.first,
          let childRecord = state.objects.record(for: child) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }

    var sink = SourceEffectTraceSink()
    try sink.recordSpawn(
        tick: 2,
        parent: source,
        object: child,
        model: childRecord.model,
        behaviorIdentity: childRecord.behaviorIdentity
    )
    guard state.objects.despawn(child) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    try sink.recordDespawn(
        tick: 3,
        object: child,
        behaviorIdentity: childRecord.behaviorIdentity
    )

    var swiftConfiguration = cConfiguration
    swiftConfiguration.coverageFingerprint = coverageFingerprint(sink.records)
    try SM64OracleTraceFile.write(
        configuration: swiftConfiguration,
        records: sink.records,
        to: swiftURL
    )
    print(
        "swift_effects_route_recorded records=\(sink.records.count) "
            + "ticks=2,3 source_owner_router=1 native_sound_rumble_pcm=unwired "
            + String(format: "coverage=0x%016llx", swiftConfiguration.coverageFingerprint)
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    let cEffects = cTrace.records.filter {
        $0.domain == effectDomain && $0.recordKind == effectKind
    }
    let swiftEffects = swiftTrace.records.filter {
        $0.domain == effectDomain && $0.recordKind == effectKind
    }
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if !validOrdering(cEffects) || !validOrdering(swiftEffects) {
        blockers.append("ordering")
    }
    if cEffects.count != swiftEffects.count { blockers.append("record_count") }
    if cEffects != swiftEffects { blockers.append("record_bytes") }
    let firstDivergence = zip(cEffects, swiftEffects)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) }
        ?? (cEffects.count == swiftEffects.count ? "none" : String(min(cEffects.count, swiftEffects.count)))
    print(
        "effects_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cEffects.count) swift_records=\(swiftEffects.count) "
            + "blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence)"
    )
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard data.count >= 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    let byte = data.index(data.startIndex, offsetBy: 72 + 56)
    data[byte] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("effects_pairing_tamper_rejected=0")
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("effects_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernEffectsRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else {
            throw SM64OracleTraceCodecError.truncated
        }
        switch mode {
        case "write":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try writeTrace(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
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
