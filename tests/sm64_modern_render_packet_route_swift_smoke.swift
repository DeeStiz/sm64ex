import Foundation

struct MetalTextureUpload: Sendable, Equatable {
    let generation: UInt64
    let textureID: UInt32
    let width: Int
    let height: Int
    let pixels: Data
}

private let routeShardID: UInt64 = 0x149f_e4b1_ab8a_36a5
private let routeInputSeed: UInt64 = 0x2cc8_dc5a_b422_8549
private let routeSaveSeed: UInt64 = 0xbb82_f731_3b3d_4f96
private let routeShaderID: UInt32 = 0x0120_0200
private let routeFloatCount = 6
private let routeTriangleCount: UInt32 = 1
private let routeShaderProgramCount: UInt64 = 26
private let routeDomain: UInt32 = 11
private let routeRecordKind: UInt32 = 7
private let eventFrameBegin: UInt64 = 2
private let eventDraw: UInt64 = 1
private let eventFrameEnd: UInt64 = 3
private let eventFinish: UInt64 = 4

private func hashString(_ value: String) -> UInt64 {
    value.utf8.reduce(SM64OracleTraceHash.offset) { hash, byte in
        (hash ^ UInt64(byte)) &* SM64OracleTraceHash.prime
    }
}

private func hashU32(_ initial: UInt64, _ value: UInt32) -> UInt64 {
    var hash = initial
    for shift in stride(from: 0, through: 24, by: 8) {
        hash ^= UInt64((value >> UInt32(shift)) & 0xff)
        hash &*= SM64OracleTraceHash.prime
    }
    return hash
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for shift in stride(from: 0, through: 56, by: 8) {
        hash ^= (value >> UInt64(shift)) & 0xff
        hash &*= SM64OracleTraceHash.prime
    }
    return hash
}

private func routeVertexBits(tick: UInt32, index: UInt32) -> UInt32 {
    let shift = (tick * 13 + index * 7) % 48
    let rotated = (routeInputSeed >> UInt64(shift))
        ^ (routeInputSeed << UInt64((64 - shift) % 64))
        ^ (routeSaveSeed >> UInt64((index * 5 + tick * 3) % 48))
    let sign: UInt32 = index & 1 == 1 ? 0x8000_0000 : 0
    let exponent: UInt32 = 0x3f00_0000 + (((index + tick) % 3) << 23)
    return sign | exponent | UInt32(truncatingIfNeeded: rotated & 0x7fff) << 8
}

private func routeVertices(tick: UInt32) -> [Float] {
    (0..<routeFloatCount).map { index in
        Float(bitPattern: routeVertexBits(tick: tick, index: UInt32(index)))
    }
}

private func vertexHash(_ vertices: ArraySlice<Float>) -> UInt64 {
    vertices.reduce(SM64OracleTraceHash.offset) { hash, vertex in
        hashU32(hash, vertex.bitPattern)
    }
}

private func rectHash(_ rect: MetalRect) -> UInt64 {
    var hash = SM64OracleTraceHash.offset
    hash = hashU32(hash, UInt32(bitPattern: rect.x))
    hash = hashU32(hash, UInt32(bitPattern: rect.y))
    hash = hashU32(hash, UInt32(bitPattern: rect.width))
    return hashU32(hash, UInt32(bitPattern: rect.height))
}

private func timebaseFingerprint() -> UInt64 {
    [UInt32(3), 60, 1, 30, 1, 2, 2].reduce(SM64OracleTraceHash.offset) {
        hashU32($0, $1)
    }
}

private func coverageFingerprint() -> UInt64 {
    var hash = SM64OracleTraceHash.offset
    for event in [eventDraw, eventFrameBegin, eventFrameEnd, eventFinish].sorted() {
        hash = hashU64(hash, UInt64(routeDomain))
        hash = hashU64(hash, 0)
        hash = hashU64(hash, event)
    }
    return hashU64(hash, 4)
}

private func routeConfiguration() -> SM64OracleTraceConfiguration {
    SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: hashString("sm64-modern-render-packet-route-build-v1"),
        contentFingerprint: hashString(
            "src/pc/sm64_modern_gameplay_parity.c|oracle_hook|render_packet"
        ),
        timebaseFingerprint: timebaseFingerprint(),
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "shard=0x149fe4b1ab8a36a5;renderer=metal4-scene-packet;size=640x480"
        ),
        initialSaveFingerprint: hashString(
            "save=empty-us-slot-0;seed=0xbb82f7313b3d4f96"
        ),
        coverageFingerprint: coverageFingerprint()
    )
}

private func record(
    tick: UInt64,
    id: UInt64,
    sequence: UInt32,
    values: [UInt64]
) throws -> SM64OracleTraceRecord {
    try SM64OracleTraceRecord(
        simulationTick: tick,
        domain: routeDomain,
        recordKind: routeRecordKind,
        recordID: id,
        sequence: sequence,
        values: values
    )
}

private struct IndependentRoute {
    let records: [SM64OracleTraceRecord]
    let packets: [MetalScenePacket]
    let aggregateFingerprint: UInt64
}

private func makeIndependentRoute() throws -> IndependentRoute {
    let recorder = MetalSceneRecorder()
    recorder.registerShader(id: routeShaderID, filteringMode: 0, inputCount: 2, textureMask: 3)
    recorder.selectShader(routeShaderID)

    var nextTextureID: UInt32 = 0
    var selectedTextureIDs = [UInt32](repeating: 0, count: 2)
    var currentTextureTile: UInt32 = 0
    var records: [SM64OracleTraceRecord] = []
    var packets: [MetalScenePacket] = []
    records.reserveCapacity(8)
    packets.reserveCapacity(2)

    for tick in 0..<2 {
        let simulationTick = UInt64(tick + 1)
        let beginValues = [
            routeShaderProgramCount,
            UInt64(nextTextureID),
            UInt64(selectedTextureIDs[0]),
            UInt64(selectedTextureIDs[1]),
            UInt64(currentTextureTile),
        ]
        records.append(try record(
            tick: simulationTick, id: eventFrameBegin, sequence: 0,
            values: beginValues
        ))

        recorder.startFrame(width: 640, height: 480)
        if tick == 0 {
            selectedTextureIDs[0] = nextTextureID
            nextTextureID &+= 1
            recorder.selectTexture(tile: 0, id: selectedTextureIDs[0])
            currentTextureTile = 0

            selectedTextureIDs[1] = nextTextureID
            nextTextureID &+= 1
            recorder.selectTexture(tile: 1, id: selectedTextureIDs[1])
            currentTextureTile = 1
        } else {
            selectedTextureIDs[0] = nextTextureID
            nextTextureID &+= 1
            recorder.selectTexture(tile: 0, id: selectedTextureIDs[0])
            currentTextureTile = 0
        }
        recorder.setSampler(tile: 0, linear: true, wrapS: 1, wrapT: 2)
        recorder.setSampler(tile: 1, linear: false, wrapS: 3, wrapT: 4)
        recorder.setDepthTest(true)
        recorder.setDepthWrite(tick == 0)
        recorder.setDecal(tick != 0)
        recorder.setAlphaBlend(tick != 0)
        recorder.setViewport(MetalRect(x: -2 + Int32(tick), y: 3, width: 640, height: 480))
        recorder.setScissor(MetalRect(x: 1, y: 4 + Int32(tick), width: 632, height: 470))

        let vertices = routeVertices(tick: UInt32(tick))
        let appended = vertices.withUnsafeBufferPointer { buffer in
            recorder.append(
                vertices: buffer.baseAddress!,
                floatCount: UInt32(buffer.count),
                triangleCount: routeTriangleCount,
                textureUpload0: nil,
                textureUpload1: nil
            )
        }
        precondition(appended)
        recorder.endFrame()
        guard let packet = recorder.latestPacket,
              packet.sequence == simulationTick,
              packet.draws.count == 1,
              packet.vertices == vertices else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        packets.append(packet)
        let draw = packet.draws[0]
        precondition(draw.currentTextureTile == currentTextureTile)
        precondition(draw.shader.shaderID == routeShaderID)
        precondition(draw.textureID0 == selectedTextureIDs[0])
        precondition(draw.textureID1 == selectedTextureIDs[1])
        let vertexSlice = packet.vertices[draw.vertexOffset..<(draw.vertexOffset + draw.floatCount)]
        let stateBits = (UInt64(draw.currentTextureTile & 3)
            | (UInt64(draw.textureID0) << 2) ^ (UInt64(draw.textureID1) << 5))
            | 0x8000_0000
        let rectFingerprint = rectHash(draw.viewport) ^ rectHash(draw.scissor)
        records.append(try record(
            tick: simulationTick, id: eventDraw, sequence: 1,
            values: [
                UInt64(draw.shader.shaderID),
                UInt64(draw.floatCount),
                UInt64(draw.triangleCount),
                vertexHash(vertexSlice),
                UInt64(draw.textureID0),
                UInt64(draw.textureID1),
                stateBits,
                rectFingerprint,
            ]
        ))
        records.append(try record(
            tick: simulationTick, id: eventFrameEnd, sequence: 2,
            values: [
                routeShaderProgramCount,
                UInt64(nextTextureID),
                UInt64(selectedTextureIDs[0]),
                UInt64(selectedTextureIDs[1]),
                UInt64(currentTextureTile),
            ]
        ))
        records.append(try record(
            tick: simulationTick, id: eventFinish, sequence: 3,
            values: [0, 0, routeShaderProgramCount, UInt64(nextTextureID)]
        ))
    }

    var aggregate = SM64OracleTraceHash.offset
    for value in records { aggregate = hashU64(aggregate, value.canonicalHash) }
    return IndependentRoute(records: records, packets: packets, aggregateFingerprint: aggregate)
}

private func validateOrdering(_ records: [SM64OracleTraceRecord]) -> Bool {
    guard records.count == 8 else { return false }
    let expectedIDs: [UInt64] = [2, 1, 3, 4, 2, 1, 3, 4]
    guard records.map(\.recordID) == expectedIDs,
          records.map(\.simulationTick) == [1, 1, 1, 1, 2, 2, 2, 2],
          records.map(\.sequence) == [0, 1, 2, 3, 0, 1, 2, 3],
          records.allSatisfy({ $0.domain == routeDomain && $0.recordKind == routeRecordKind }) else {
        return false
    }
    return records.enumerated().allSatisfy { index, record in
        record.values.count == (record.recordID == eventDraw ? 8 : record.recordID == eventFinish ? 4 : 5)
            && (try? SM64OracleTraceRecord.decode(record.encoded())) == record
            && (index == 0 || record.simulationTick >= records[index - 1].simulationTick)
    }
}

private func writeTrace(to url: URL) throws {
    let route = try makeIndependentRoute()
    guard validateOrdering(route.records) else { throw SM64OracleTraceCodecError.invalidHeader }
    let configuration = routeConfiguration()
    try SM64OracleTraceFile.write(
        configuration: configuration, records: route.records, to: url
    )
    print(
        "swift_render_packet_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "records=\(route.records.count) ticks=1,2 events=draw,frame_begin,frame_end,finish "
            + "packets=\(route.packets.count) coverage=0x\(String(coverageFingerprint(), radix: 16)) "
            + "trace_fingerprint=0x\(String(route.aggregateFingerprint, radix: 16))"
    )
    print(
        "render_packet_route_header build=0x\(String(configuration.buildFingerprint, radix: 16)) "
            + "content=0x\(String(configuration.contentFingerprint, radix: 16)) "
            + "timebase=0x\(String(configuration.timebaseFingerprint, radix: 16)) "
            + "configuration=0x\(String(configuration.configurationFingerprint, radix: 16)) "
            + "initial_save=0x\(String(configuration.initialSaveFingerprint, radix: 16))"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    let expectedConfiguration = routeConfiguration()
    var blockers: [String] = []
    if cTrace.configuration != expectedConfiguration { blockers.append("c_header") }
    if swiftTrace.configuration != expectedConfiguration { blockers.append("swift_header") }
    if !validateOrdering(cTrace.records) || !validateOrdering(swiftTrace.records) {
        blockers.append("ordering")
    }
    if cTrace.records.count != swiftTrace.records.count { blockers.append("record_count") }
    if cTrace.records != swiftTrace.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "render_packet_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cTrace.records.count) swift_records=\(swiftTrace.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) first_divergence=\(firstDivergence)"
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
        print("render_packet_pairing_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("render_packet_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernRenderPacketRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else { throw SM64OracleTraceCodecError.truncated }
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
