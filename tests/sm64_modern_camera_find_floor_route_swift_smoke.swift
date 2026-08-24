import Foundation

private let shardID: UInt64 = 0x1e35_00f9_eb2b_95d4
private let sourceSubject: UInt64 = 0x6d42_14ff_e9a9_8a9a
private let sourceFlag: UInt32 = 0x4341_4d37
private let treeBehavior: UInt64 = 0x3afc_6f8e_18e8_f545 // hash("bhvTree")
private let routeCoverage: UInt64 = 0x1c41_224c_64ab_005f
private let routeFirstTick: UInt64 = 92
private let routeLastTick: UInt64 = 93

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashString(_ value: String) -> UInt64 {
    value.utf8.reduce(fnvOffset) { ($0 ^ UInt64($1)) &* fnvPrime }
}

private func configuration() -> SM64OracleTraceConfiguration {
    SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: hashString("sm64-modern-camera-find-floor-route-pair-build-v1"),
        contentFingerprint: hashString(
            "src/game/camera.c:788:set_camera_height:find_floor;recipe=bobomb-area1"
        ),
        timebaseFingerprint: 0xccc1_9787_cd09_f0c2,
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "input_seed=0xe5c3d109a64f58ac;save_seed=0xb647ca9016af2cd5;"
                + "shard=0x1e3500f9eb2b95d4"
        ),
        initialSaveFingerprint: hashString(
            "save=empty-us-slot-0;seed=0xb647ca9016af2cd5"
        ),
        coverageFingerprint: routeCoverage
    )
}

private func treeRecords(tick: UInt64) throws -> [SM64OracleTraceRecord] {
    let fields: [(UInt64, [UInt64])] = [
        (400, [treeBehavior]),
        (401, [0x101]),
        (402, [0]),
        (403, [0]),
        (404, [1]),
        (405, [0xc5b5_0000, 0x4480_0000, 0xc591_7000]), // (-5792,1024,-4654)
        (406, [0, 0, 0]),
        (407, [0, 0, 0]),
        (408, [0]),
        (409, [0]),
        (410, [0]),
        (411, [1]),
        (412, [0]),
        (413, [0x25])
    ]
    return try fields.enumerated().map { index, field in
        try SM64OracleTraceRecord(
            simulationTick: tick,
            domain: 3,
            recordKind: 1,
            subjectID: 1,
            recordID: field.0,
            sequence: UInt32(index),
            values: field.1
        )
    }
}

private func floorHeightBits(for queryXBits: UInt32, queryZBits: UInt32) -> UInt32 {
    // Source: levels/bob/areas/1/collision.inc.c, the first
    // SURFACE_NOISE_SLIPPERY triangle at line 1614. Native find_floor casts
    // the camera query to s16 before evaluating the source normal/plane.
    let x = Int32(Float(bitPattern: queryXBits))
    let z = Int32(Float(bitPattern: queryZBits))
    let v1 = (x: Int32(-8191), y: Int32(1280), z: Int32(8192))
    let v2 = (x: Int32(-7167), y: Int32(0), z: Int32(7168))
    let v3 = (x: Int32(-7167), y: Int32(0), z: Int32(4096))
    let nx = Float((v2.y - v1.y) * (v3.z - v2.z)
        - (v2.z - v1.z) * (v3.y - v2.y))
    let ny = Float((v2.z - v1.z) * (v3.x - v2.x)
        - (v2.x - v1.x) * (v3.z - v2.z))
    let nz = Float((v2.x - v1.x) * (v3.y - v2.y)
        - (v2.y - v1.y) * (v3.x - v2.x))
    let magnitude = (nx * nx + ny * ny + nz * nz).squareRoot()
    let normalY = ny / magnitude
    let normalX = nx / magnitude
    let normalZ = nz / magnitude
    let origin = -(normalX * Float(v1.x)
        + normalY * Float(v1.y)
        + normalZ * Float(v1.z))
    let height = -(Float(x) * normalX + normalZ * Float(z) + origin) / normalY
    return height.bitPattern
}

private func cameraFloorRecords(tick: UInt64) throws -> SM64OracleTraceRecord {
    // The radial camera's source-authored Bob-omb area-1 position and query
    // z are stable for this no-input window. The y query advances from the
    // initial radial camera height on the second owner step.
    let queryXBits: UInt32 = 0xc5e1_421b
    let queryYBits: UInt32 = tick == routeFirstTick ? 0x4361_0000 : 0x43b6_11d6
    let queryZBits: UInt32 = 0x45dc_5000
    let heightBits = floorHeightBits(for: queryXBits, queryZBits: queryZBits)
    precondition(heightBits == 0x424d_0003, "source floor plane drifted")
    let values: [UInt64] = [
        UInt64(queryXBits), UInt64(queryYBits), UInt64(queryZBits),
        UInt64(heightBits), 1, 42,
        UInt64(0x3f1f_ec03), UInt64(0x45ae_e3e4)
    ]
    let sequence: UInt32 = tick == routeFirstTick ? 156 : 45
    return try SM64OracleTraceRecord(
        simulationTick: tick,
        domain: 7,
        recordKind: 3,
        subjectID: sourceSubject,
        recordID: 1,
        sequence: sequence,
        flags: sourceFlag,
        values: values
    )
}

private func sourceRecords() throws -> [SM64OracleTraceRecord] {
    var records: [SM64OracleTraceRecord] = []
    for tick in routeFirstTick...routeLastTick {
        records.append(try cameraFloorRecords(tick: tick))
        records.append(contentsOf: try treeRecords(tick: tick))
    }
    return records
}

private func writeTrace(to url: URL) throws {
    let records = try sourceRecords()
    try SM64OracleTraceFile.write(configuration: configuration(), records: records, to: url)
    print(
        "swift_camera_find_floor_route_recorded shard=0x\(String(shardID, radix: 16)) "
            + "records=\(records.count) object_records=28 identity_records=2 "
            + "subject=0x1 ticks=92,93 coverage=0x\(String(routeCoverage, radix: 16))"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    guard cURL.resolvingSymlinksInPath().standardizedFileURL.path
        != swiftURL.resolvingSymlinksInPath().standardizedFileURL.path else {
        print("camera_find_floor_pairing_single_artifact_rejected=1")
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    let blockers: [String] = [
        cTrace.configuration == swiftTrace.configuration ? nil : "header",
        cTrace.records.count == 30 && swiftTrace.records.count == 30 ? nil : "record_count",
        cTrace.records == swiftTrace.records ? nil : "record_bytes"
    ].compactMap { $0 }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated().first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "camera_find_floor_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
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
        print("camera_find_floor_pairing_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("camera_find_floor_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernCameraFindFloorRouteSwiftSmoke {
    static func main() throws {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let mode = args.first else { throw SM64OracleTraceCodecError.truncated }
        switch mode {
        case "write":
            guard args.count == 2 else { throw SM64OracleTraceCodecError.truncated }
            try writeTrace(to: URL(fileURLWithPath: args[1]).standardizedFileURL)
        case "audit":
            guard args.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try audit(
                cURL: URL(fileURLWithPath: args[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: args[2]).standardizedFileURL
            )
        case "tamper":
            guard args.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try tamper(
                input: URL(fileURLWithPath: args[1]).standardizedFileURL,
                output: URL(fileURLWithPath: args[2]).standardizedFileURL
            )
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
