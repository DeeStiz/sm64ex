import Foundation

private let pairingFNVOffset: UInt64 = 1_469_598_103_934_665_603
private let pairingFNVPrime: UInt64 = 1_099_511_628_211
private let pairingRecordCount = 1
private let pairingDomain: UInt32 = 1
private let pairingRecordKind: UInt32 = 2
private let pairingRecordID: UInt64 = 1
private let pairingSimulationTick: UInt64 = 1
private let pairingRawButtons: UInt16 = 1
private let pairingRawStickX: Int16 = 16
private let pairingRawStickY: Int16 = 0
private let pairingRawExtStickX: Int16 = 0
private let pairingRawExtStickY: Int16 = 0

private enum PairingSmokeError: Error, CustomStringConvertible {
    case usage
    case noAdmissionExpected
    case pairingMismatch(String)
    case tamperAccepted

    var description: String {
        switch self {
        case .usage: return "invalid pairing smoke arguments"
        case .noAdmissionExpected: return "current C/Swift traces were unexpectedly admitted"
        case let .pairingMismatch(reason): return "pairing mismatch: \(reason)"
        case .tamperAccepted: return "tampered trace unexpectedly decoded"
        }
    }
}

private func update(_ startingHash: UInt64, _ value: UInt64) -> UInt64 {
    var hash = startingHash
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= pairingFNVPrime
    }
    return hash
}

private func hashString(_ value: String) -> UInt64 {
    Data(value.utf8).reduce(pairingFNVOffset) { hash, byte in
        (hash ^ UInt64(byte)) &* pairingFNVPrime
    }
}

private func timebaseFingerprint() -> UInt64 {
    // Matches the C timebase fingerprint for the explicit 60/30, ratio-two,
    // max-catch-up-two configuration used by this bounded probe.
    [UInt32(3), 60, 1, 30, 1, 2, 2].reduce(pairingFNVOffset) { hash, value in
        var next = hash
        for byte in 0..<4 {
            next ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
            next &*= pairingFNVPrime
        }
        return next
    }
}

private func coverageFingerprint() -> UInt64 {
    [UInt64(pairingDomain), 0, pairingRecordID, UInt64(pairingRecordCount)]
        .reduce(pairingFNVOffset, update)
}

private func pairingConfiguration() -> SM64OracleTraceConfiguration {
    SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: hashString("sm64-modern-c-swift-pairing-build-v1"),
        contentFingerprint: hashString("sm64-modern-c-swift-pairing-content-v1"),
        timebaseFingerprint: timebaseFingerprint(),
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1"
        ),
        initialSaveFingerprint: hashString("save=empty-us-slot-0;seed=0x00000001"),
        coverageFingerprint: coverageFingerprint()
    )
}

private func pairingRecord() throws -> SM64OracleTraceRecord {
    let adjustedStickX = Float(pairingRawStickX - 6).bitPattern
    return try SM64OracleTraceRecord(
        simulationTick: pairingSimulationTick,
        domain: pairingDomain,
        recordKind: pairingRecordKind,
        recordID: pairingRecordID,
        sequence: 0,
        values: [
            UInt64(pairingRawButtons),
            0, // held native step: no newly delivered legacy edge
            UInt64(adjustedStickX),
            0,
            UInt64(UInt16(bitPattern: pairingRawStickX)),
            UInt64(UInt16(bitPattern: pairingRawStickY)),
            UInt64(UInt16(bitPattern: pairingRawExtStickX)),
            UInt64(UInt16(bitPattern: pairingRawExtStickY))
        ]
    )
}

private func writePairingTrace(to url: URL) throws {
    try SM64OracleTraceFile.write(
        configuration: pairingConfiguration(),
        records: [pairingRecord()],
        to: url
    )
}

private func ticks(in records: [SM64OracleTraceRecord]) -> UInt64 {
    records.map(\.simulationTick).max() ?? 0
}

private func orderingValid(_ records: [SM64OracleTraceRecord]) -> Bool {
    var ticksByDomain = [UInt64?](repeating: nil, count: 14)
    var sequencesByDomain = [UInt32](repeating: 0, count: 14)
    for record in records {
        guard record.domain < 14 else { return false }
        let domain = Int(record.domain)
        if let previousTick = ticksByDomain[domain] {
            if record.simulationTick < previousTick {
                return false
            }
            if record.simulationTick == previousTick
                && record.sequence != sequencesByDomain[domain] &+ 1 {
                return false
            }
            if record.simulationTick > previousTick && record.sequence != 0 {
                return false
            }
        } else if record.sequence != 0 {
            return false
        }
        ticksByDomain[domain] = record.simulationTick
        sequencesByDomain[domain] = record.sequence
    }
    return !records.isEmpty
}

private func configurationMismatches(
    _ c: SM64OracleTraceConfiguration,
    _ swift: SM64OracleTraceConfiguration
) -> [String] {
    var mismatches: [String] = []
    if c.regionCode != swift.regionCode { mismatches.append("region_code") }
    if c.buildFingerprint != swift.buildFingerprint { mismatches.append("build_fingerprint") }
    if c.contentFingerprint != swift.contentFingerprint { mismatches.append("content_fingerprint") }
    if c.timebaseFingerprint != swift.timebaseFingerprint { mismatches.append("timebase_fingerprint") }
    if c.configurationFingerprint != swift.configurationFingerprint {
        mismatches.append("configuration_fingerprint")
    }
    if c.initialSaveFingerprint != swift.initialSaveFingerprint {
        mismatches.append("initial_save_fingerprint")
    }
    if c.coverageFingerprint != swift.coverageFingerprint {
        mismatches.append("coverage_fingerprint")
    }
    return mismatches
}

private func audit(cURL: URL, swiftURL: URL, expectRejected: Bool) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    var blockers = configurationMismatches(cTrace.configuration, swiftTrace.configuration)
    if cTrace.configuration.coverageFingerprint == 0
        || swiftTrace.configuration.coverageFingerprint == 0 {
        blockers.append("coverage_deferred")
    }
    if !orderingValid(cTrace.records) || !orderingValid(swiftTrace.records) {
        blockers.append("ordering")
    }
    if cTrace.records.count != swiftTrace.records.count {
        blockers.append("record_count")
    }
    if cTrace.records != swiftTrace.records {
        blockers.append("record_bytes")
    }
    if try Data(contentsOf: cURL) != Data(contentsOf: swiftURL) {
        blockers.append("trace_bytes")
    }
    var uniqueBlockers = Array(Set(blockers)).sorted()
    let admitted = uniqueBlockers.isEmpty
    if admitted { uniqueBlockers = ["none"] }
    print(
        "pairing_audit admitted=\(admitted ? 1 : 0) c_records=\(cTrace.records.count) "
            + "swift_records=\(swiftTrace.records.count) c_ticks=\(ticks(in: cTrace.records)) "
            + "swift_ticks=\(ticks(in: swiftTrace.records)) blockers=\(uniqueBlockers.joined(separator: ","))"
    )
    if expectRejected && admitted { throw PairingSmokeError.noAdmissionExpected }
}

private func comparePairing(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    guard cTrace.configuration == swiftTrace.configuration else {
        throw PairingSmokeError.pairingMismatch("configuration")
    }
    guard cTrace.configuration.coverageFingerprint != 0 else {
        throw PairingSmokeError.pairingMismatch("coverage was deferred")
    }
    guard orderingValid(cTrace.records), orderingValid(swiftTrace.records) else {
        throw PairingSmokeError.pairingMismatch("ordering")
    }
    guard cTrace.records == swiftTrace.records else {
        throw PairingSmokeError.pairingMismatch("record bytes")
    }
    guard try Data(contentsOf: cURL) == Data(contentsOf: swiftURL) else {
        throw PairingSmokeError.pairingMismatch("file bytes")
    }
    guard cTrace.records.count == pairingRecordCount,
          let record = cTrace.records.first,
          record.simulationTick == pairingSimulationTick,
          record.domain == pairingDomain,
          record.recordKind == pairingRecordKind,
          record.recordID == pairingRecordID else {
        throw PairingSmokeError.pairingMismatch("common-input window")
    }

    let tamperedURL = swiftURL.appendingPathExtension("tampered")
    var tampered = try Data(contentsOf: swiftURL)
    guard !tampered.isEmpty else { throw PairingSmokeError.pairingMismatch("empty trace") }
    tampered[tampered.index(before: tampered.endIndex)] ^= 1
    try tampered.write(to: tamperedURL, options: .atomic)
    defer { try? FileManager.default.removeItem(at: tamperedURL) }
    do {
        _ = try SM64OracleTraceFile.read(from: tamperedURL)
        throw PairingSmokeError.tamperAccepted
    } catch PairingSmokeError.tamperAccepted {
        throw PairingSmokeError.tamperAccepted
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        // Expected: the Swift decoder rejects the mutated independent bytes.
    }
    print(
        "swift_pairing_compare_passed records=\(cTrace.records.count) "
            + "coverage=0x\(String(cTrace.configuration.coverageFingerprint, radix: 16)) "
            + "replay_tamper=1"
    )
}

@main
struct SM64ModernCSwiftPairingSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else { throw PairingSmokeError.usage }
        switch mode {
        case "write":
            guard arguments.count == 2 else { throw PairingSmokeError.usage }
            let url = URL(fileURLWithPath: arguments[1]).standardizedFileURL
            try writePairingTrace(to: url)
            print(
                "swift_pairing_recorded path=\(url.path) records=\(pairingRecordCount) "
                    + "timebase=0x\(String(timebaseFingerprint(), radix: 16)) "
                    + "coverage=0x\(String(coverageFingerprint(), radix: 16))"
            )
        case "compare":
            guard arguments.count == 3 else { throw PairingSmokeError.usage }
            try comparePairing(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "tamper":
            guard arguments.count == 3 else { throw PairingSmokeError.usage }
            var data = try Data(contentsOf: URL(fileURLWithPath: arguments[1]).standardizedFileURL)
            guard !data.isEmpty else { throw PairingSmokeError.pairingMismatch("empty trace") }
            data[data.index(before: data.endIndex)] ^= 1
            let outputURL = URL(fileURLWithPath: arguments[2]).standardizedFileURL
            try data.write(to: outputURL, options: .atomic)
            print("swift_pairing_tampered path=\(outputURL.path)")
        case "audit":
            guard arguments.count == 3 || arguments.count == 4 else {
                throw PairingSmokeError.usage
            }
            try audit(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL,
                expectRejected: arguments.dropFirst(3).first == "--expect-rejected"
            )
        default:
            throw PairingSmokeError.usage
        }
    }
}
