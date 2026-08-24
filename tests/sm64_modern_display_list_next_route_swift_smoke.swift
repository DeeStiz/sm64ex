import Foundation

private let routeShardID: UInt64 = 0x00a5_aebe_3689_7ac4
private let routeDomain: UInt32 = 11
private let routeRecordKind: UInt32 = 7
private let routeEvent: UInt64 = 0xd2
private let routeFNVOffset: UInt64 = 1_469_598_103_934_665_603
private let routeFNVPrime: UInt64 = 1_099_511_628_211

private struct RoutePacket {
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

private func parseHex(_ raw: String) throws -> UInt64 {
    guard raw.hasPrefix("0x"), let value = UInt64(raw.dropFirst(2), radix: 16) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    return value
}

private func parseU32List(_ raw: String) throws -> [UInt32] {
    try raw.split(separator: ",", omittingEmptySubsequences: false).map { value in
        guard let parsed = UInt32(value, radix: 16) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        return parsed
    }
}

private func readPacket(_ url: URL) throws -> RoutePacket {
    let lines = try String(contentsOf: url, encoding: .utf8)
        .split(whereSeparator: \.isNewline)
    guard lines.count == 1 else { throw SM64OracleTraceCodecError.invalidHeader }
    var fields = [String: String]()
    for field in lines[0].split(separator: "|", omittingEmptySubsequences: false) {
        let pair = field.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        guard pair.count == 2 else { throw SM64OracleTraceCodecError.invalidHeader }
        fields[String(pair[0])] = String(pair[1])
    }
    guard let source = fields["source_identity"].flatMap({ try? parseHex($0) }),
          let owner = fields["owner_identity"].flatMap({ try? parseHex($0) }),
          let wordCount = fields["word_count"].flatMap(UInt32.init),
          let layer = fields["drawing_layer"].flatMap(UInt32.init),
          let triangles = fields["triangle_count"].flatMap(UInt32.init),
          let flags = fields["flags"].flatMap(UInt32.init),
          let packetFingerprint = fields["packet_fingerprint"].flatMap({ try? parseHex($0) }),
          let wordsRaw = fields["words"],
          let resourcesRaw = fields["resources"] else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let words = try parseU32List(wordsRaw)
    let resources = try parseU32List(resourcesRaw)
    let expectedWords: [UInt32] = [
        0xfd10_0000, 0x0900_1000,
        0xe600_0000, 0x0000_0000,
        0xf300_0000, 0x077f_f080,
        0xdc08_060a, 0x0702_4020,
        0xdc08_090a, 0x0702_4010,
        0x0100_8010, 0x0702_6108,
        0x0600_0204, 0x0000_0602,
        0x0608_0a0c, 0x0008_0c0e,
    ]
    let expectedResources: [UInt32] = [
        0x0900_1000, 0, 0, 0x0702_4020,
        0x0702_4010, 0x0702_6108, 0, 0,
    ]
    guard source == 0xea26_0066_b29e_ce0c,
          owner == 0xad52_4f68_d4a5_8ea8,
          wordCount == 8,
          layer == 1,
          triangles == 4,
          flags == 3,
          words == expectedWords,
          resources == expectedResources else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    var packetHash = routeFNVOffset
    for word in words { packetHash = hashU32(packetHash, word) }
    guard packetHash == packetFingerprint else {
        throw SM64OracleTraceCodecError.nonCanonicalHash
    }
    return RoutePacket(
        sourceIdentity: source,
        ownerIdentity: owner,
        wordCount: wordCount,
        drawingLayer: layer,
        triangleCount: triangles,
        flags: flags,
        packetFingerprint: packetFingerprint,
        words: words,
        resources: resources
    )
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for byte in 0..<4 {
        hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
        hash &*= routeFNVPrime
    }
    return hash
}

private func hashString(_ value: String) -> UInt64 {
    value.utf8.reduce(routeFNVOffset) { hash, byte in
        (hash ^ UInt64(byte)) &* routeFNVPrime
    }
}

private func resourceFingerprint(_ resources: [UInt32]) -> UInt64 {
    resources.reduce(routeFNVOffset, hashU32)
}

private func routeConfiguration() -> SM64OracleTraceConfiguration {
    SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: hashString("sm64-modern-display-list-next-route-build-v1"),
        contentFingerprint: hashString(
            "levels/castle_inside/areas/1/2/model.inc.c|"
                + "inside_castle_seg7_dl_070287C0|render_packet"
        ),
        timebaseFingerprint: hashU32(hashU32(routeFNVOffset, 60), 30),
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;"
                + "shard=0x00a5aebe36897ac4;parent=inside_castle_seg7_dl_07028FD0;layer=1"
        ),
        initialSaveFingerprint: hashString(
            "save=empty-us-slot-0;seed=0x7684a9567f71ff45"
        ),
        coverageFingerprint: 0
    )
}

private func makeRecords(_ packet: RoutePacket) throws -> [SM64OracleTraceRecord] {
    let values: [UInt64] = [
        packet.sourceIdentity,
        packet.ownerIdentity,
        packet.packetFingerprint,
        UInt64(packet.wordCount),
        UInt64(packet.triangleCount),
        resourceFingerprint(packet.resources),
        UInt64(packet.drawingLayer),
        UInt64(packet.flags),
    ]
    return try (1...2).map { tick in
        try SM64OracleTraceRecord(
            simulationTick: UInt64(tick),
            domain: routeDomain,
            recordKind: routeRecordKind,
            subjectID: routeShardID,
            recordID: routeEvent,
            sequence: 0,
            flags: packet.flags,
            values: values
        )
    }
}

private func makeRoute(cTrace: URL, packetURL: URL) throws -> (
    configuration: SM64OracleTraceConfiguration,
    records: [SM64OracleTraceRecord]
) {
    let c = try SM64OracleTraceFile.read(from: cTrace)
    let packet = try readPacket(packetURL)
    let records = try makeRecords(packet)
    guard c.configuration == routeConfiguration(),
          c.records.count == records.count,
          c.records == records else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    return (routeConfiguration(), records)
}

private func writeRoute(cTrace: URL, packetURL: URL, swiftTrace: URL) throws {
    let route = try makeRoute(cTrace: cTrace, packetURL: packetURL)
    try SM64OracleTraceFile.write(
        configuration: route.configuration,
        records: route.records,
        to: swiftTrace
    )
    print(
        "swift_display_list_next_route_recorded shard=0x\(String(routeShardID, radix: 16))"
            + " records=\(route.records.count) ticks=1,2 words=8 triangles=4"
            + " source=0x\(String(route.records[0].values[0], radix: 16))"
            + " owner=0x\(String(route.records[0].values[1], radix: 16))"
            + " packet=0x\(String(route.records[0].values[2], radix: 16))"
    )
}

private func audit(cTrace: URL, swiftTrace: URL) throws {
    guard cTrace.resolvingSymlinksInPath().standardizedFileURL
            != swiftTrace.resolvingSymlinksInPath().standardizedFileURL else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let c = try SM64OracleTraceFile.read(from: cTrace)
    let swift = try SM64OracleTraceFile.read(from: swiftTrace)
    guard c.configuration == swift.configuration else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let firstDivergence = zip(c.records, swift.records).enumerated()
        .first(where: { $0.element.0 != $0.element.1 })?.offset
        ?? (c.records.count == swift.records.count ? nil : min(c.records.count, swift.records.count))
    guard firstDivergence == nil else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    print(
        "display_list_next_pairing_audit admitted=1 c_records=\(c.records.count)"
            + " swift_records=\(swift.records.count) blockers= first_divergence=none"
    )
}

private func tamper(input: URL, output: URL) throws {
    var data = try Data(contentsOf: input)
    guard data.count >= 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    data[72 + 64] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("display_list_next_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernDisplayListNextRouteSmoke {
    static func main() {
        do {
            let args = Array(CommandLine.arguments.dropFirst())
            guard let command = args.first else { throw SM64OracleTraceCodecError.invalidHeader }
            switch command {
            case "write":
                guard args.count == 4 else { throw SM64OracleTraceCodecError.invalidHeader }
                try writeRoute(
                    cTrace: URL(fileURLWithPath: args[1]),
                    packetURL: URL(fileURLWithPath: args[2]),
                    swiftTrace: URL(fileURLWithPath: args[3])
                )
            case "audit":
                guard args.count == 3 else { throw SM64OracleTraceCodecError.invalidHeader }
                try audit(
                    cTrace: URL(fileURLWithPath: args[1]),
                    swiftTrace: URL(fileURLWithPath: args[2])
                )
            case "tamper":
                guard args.count == 3 else { throw SM64OracleTraceCodecError.invalidHeader }
                try tamper(
                    input: URL(fileURLWithPath: args[1]),
                    output: URL(fileURLWithPath: args[2])
                )
            default:
                throw SM64OracleTraceCodecError.invalidHeader
            }
        } catch {
            fputs("display_list_next_route_swift_error=\(error)\n", stderr)
            exit(1)
        }
    }
}
