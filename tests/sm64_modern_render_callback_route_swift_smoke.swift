import Foundation

private let routeShardID: UInt64 = 0xd5a4_3d53_7c37_e833
private let routeInputSeed: UInt64 = 0xff27_9352_7bb5_fb03
private let routeSaveSeed: UInt64 = 0xc57d_3aed_0830_0d60
private let routeSubjectID: UInt64 = 0x5243_4c42_4746_5855
private let routeFlag: UInt32 = 0x5243_4c42
private let routeEventID: UInt64 = 6
private let routeTicks: [UInt64] = [2, 3]
private let routeIdentity = "src/pc/gfx/gfx_pc.c:1783:gfx_run"
private let renderDomain: UInt32 = 11
private let eventRecordKind: UInt32 = 3

private func hashString(_ value: String) -> UInt64 {
    value.utf8.reduce(SM64OracleTraceHash.offset) { hash, byte in
        (hash ^ UInt64(byte)) &* SM64OracleTraceHash.prime
    }
}

private func update(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= SM64OracleTraceHash.prime
    }
    return hash
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
    hash = update(hash, UInt64(renderDomain))
    hash = update(hash, 0)
    hash = update(hash, routeEventID)
    return update(hash, 1)
}

private func configuration() -> SM64OracleTraceConfiguration {
    SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: hashString("sm64-modern-render-callback-route-build-v1"),
        contentFingerprint: hashString(routeIdentity),
        timebaseFingerprint: timebaseFingerprint(),
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "input_seed=0xff2793527bb5fb03;save_seed=0xc57d3aed08300d60;"
                + "shard=0xd5a43d537c37e833;callback=gfx_run"
        ),
        initialSaveFingerprint: hashString(
            "save=empty-us-slot-0;seed=0xc57d3aed08300d60"
        ),
        coverageFingerprint: coverageFingerprint()
    )
}

private func records() throws -> [SM64OracleTraceRecord] {
    try routeTicks.enumerated().map { index, tick in
        try SM64OracleTraceRecord(
            simulationTick: tick,
            domain: renderDomain,
            recordKind: eventRecordKind,
            subjectID: routeSubjectID,
            recordID: routeEventID,
            sequence: 0,
            flags: routeFlag,
            values: [UInt64(index + 1), 1, routeSubjectID, tick]
        )
    }
}

private func validOrdering(_ values: [SM64OracleTraceRecord]) -> Bool {
    guard values.count == routeTicks.count else { return false }
    for (index, record) in values.enumerated() {
        guard record.simulationTick == routeTicks[index],
              record.domain == renderDomain,
              record.recordKind == eventRecordKind,
              record.subjectID == routeSubjectID,
              record.recordID == routeEventID,
              record.sequence == 0,
              record.flags == routeFlag,
              record.values == [UInt64(index + 1), 1, routeSubjectID, routeTicks[index]]
        else { return false }
    }
    return true
}

private func writeTrace(to url: URL) throws {
    let generated = try records()
    try SM64OracleTraceFile.write(
        configuration: configuration(), records: generated, to: url
    )
    print(
        "swift_render_callback_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "identity=\(routeIdentity) records=\(generated.count) ticks=2,3 "
            + "commands_present=1 coverage=0x\(String(coverageFingerprint(), radix: 16)) "
            + "input_seed=0x\(String(routeInputSeed, radix: 16)) "
            + "save_seed=0x\(String(routeSaveSeed, radix: 16))"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    let expectedRecords = try records()
    var blockers: [String] = []
    if cURL.standardizedFileURL == swiftURL.standardizedFileURL {
        blockers.append("single_artifact")
    }
    if cTrace.configuration != configuration() { blockers.append("c_header") }
    if swiftTrace.configuration != configuration() { blockers.append("swift_header") }
    if !validOrdering(cTrace.records) || !validOrdering(swiftTrace.records) {
        blockers.append("ordering")
    }
    if cTrace.records != expectedRecords { blockers.append("c_records") }
    if swiftTrace.records != expectedRecords { blockers.append("swift_records") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "render_callback_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
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
        print("render_callback_pairing_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("render_callback_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernRenderCallbackRouteSwiftSmoke {
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
