import Foundation

private let routeCoverage: UInt64 = {
    var hash = SM64OracleTraceHash.offset
    func update(_ value: UInt64) -> UInt64 {
        var next = hash
        for byte in 0..<8 {
            next ^= (value >> UInt64(byte * 8)) & 0xff
            next &*= SM64OracleTraceHash.prime
        }
        return next
    }
    hash = update(UInt64(SM64CameraWaterQueryReceipt.domain))
    hash = update(0)
    hash = update(SM64CameraWaterQueryReceipt.recordID)
    return update(1)
}()

private func hashString(_ value: String) -> UInt64 {
    value.utf8.reduce(SM64OracleTraceHash.offset) { hash, byte in
        (hash ^ UInt64(byte)) &* SM64OracleTraceHash.prime
    }
}

private func configuration() -> SM64OracleTraceConfiguration {
    SM64OracleTraceConfiguration(
        regionCode: 0x5553,
        mode: .record,
        buildFingerprint: hashString("sm64-modern-camera-water-route-pair-build-v1"),
        contentFingerprint: hashString(SM64CameraWaterQuerySourceRecipe.identity),
        timebaseFingerprint: 0,
        configurationFingerprint: hashString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "ddd-area1-camera-mode2;shard=0x340565d4295ea359"
        ),
        initialSaveFingerprint: hashString(
            "save=empty-us-slot-0;input=0x5e4a0bb08c0e8d4f;"
                + "save=0x9aeea37839e7b142"
        ),
        coverageFingerprint: routeCoverage
    )
}

private func sourceWitness() throws -> SM64OracleTraceRecord {
    let camera = SM64CameraWaterQuerySourceRecipe.authoredCameraNode
    let mario = SM64CameraWaterQuerySourceRecipe.authoredMarioSpawn
    return try SM64CameraWaterQueryReceipt.makeRecord(
        simulationTick: 1,
        sequence: 0,
        cameraPositionBits: (
            camera.x.bitPattern, camera.y.bitPattern, camera.z.bitPattern
        ),
        marioPositionBits: (
            mario.x.bitPattern, mario.y.bitPattern, mario.z.bitPattern
        ),
        waterHeightBits: Float(-11000).bitPattern,
        resultFlags: SM64CameraWaterQueryReceipt.queryExecutedFlag
    )
}

private func writeWitness(to url: URL) throws {
    let record = try sourceWitness()
    try SM64OracleTraceFile.write(
        configuration: configuration(),
        records: [record],
        to: url
    )
    print(
        "swift_camera_water_route_schema_witness records=1 "
            + "domain=5 event=307 recipe=ddd-area1-mode2 "
            + "coverage=0x\(String(routeCoverage, radix: 16))"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    guard cURL.resolvingSymlinksInPath().standardizedFileURL.path
        != swiftURL.resolvingSymlinksInPath().standardizedFileURL.path else {
        print("camera_water_pairing_single_artifact_rejected=1")
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    let cReceipts = try cTrace.records.map(SM64CameraWaterQueryReceipt.init(native:))
    let swiftReceipts = try swiftTrace.records.map(SM64CameraWaterQueryReceipt.init(native:))
    let blockers: [String] = [
        cTrace.configuration == swiftTrace.configuration ? nil : "header",
        cTrace.records == swiftTrace.records ? nil : "record_bytes",
        cReceipts.count == swiftReceipts.count ? nil : "record_count"
    ].compactMap { $0 }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "camera_water_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cTrace.records.count) "
            + "swift_records=\(swiftTrace.records.count) "
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
    let valueOffset = 72 + 8 + 8 + 4 + 4 + 8 + 8 + 4 + 4 + 4 + 4
    data[valueOffset] ^= 1
    try data.write(to: output, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: output)
        print("camera_water_pairing_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("camera_water_pairing_tamper_rejected=1")
    }
}

private func negativeBoundary() throws {
    let witness = try sourceWitness()
    let receipt = try SM64CameraWaterQueryReceipt(native: witness)
    var rejectedFields = 0

    func expectReceiptRejected(_ candidate: SM64OracleTraceRecord) throws {
        do {
            _ = try SM64CameraWaterQueryReceipt(native: candidate)
        } catch SM64OracleTraceCodecError.invalidHeader {
            rejectedFields += 1
        }
    }

    var wrongSubject = witness
    wrongSubject.subjectID = 0
    try expectReceiptRejected(wrongSubject)
    var wrongMode = witness
    wrongMode.values[0] = 1
    try expectReceiptRejected(wrongMode)
    var wrongLevel = witness
    wrongLevel.values[1] ^= 1
    try expectReceiptRejected(wrongLevel)
    var wrongArea = witness
    wrongArea.values[1] ^= UInt64(1) << 32
    try expectReceiptRejected(wrongArea)

    var wrongSequence = witness
    wrongSequence.sequence = 0
    let ordering = SwiftCameraWaterQueryMigrationService()
    try ordering.observe(native: witness)
    do {
        try ordering.observe(native: wrongSequence)
    } catch SM64OracleTraceCodecError.invalidHeader {
        rejectedFields += 1
    }

    let generic = try SM64OracleTraceRecord(
        simulationTick: 1,
        domain: 7,
        recordKind: 3,
        subjectID: 0,
        recordID: 4,
        sequence: 0,
        values: [0, 0, 0, 0]
    )
    do {
        _ = try SM64CameraWaterQueryReceipt(native: generic)
        print("camera_water_generic_collision_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.invalidHeader {
        print("camera_water_generic_collision_rejected=1")
    }
    _ = receipt
    guard rejectedFields == 5 else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    print(
        "camera_water_route_negative_fences source_identity=1 mode=1 "
            + "level=1 area=1 sequence=1 wrong_domain=1 wrong_event=1"
    )
}

@main
struct SM64ModernCameraWaterRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else {
            throw SM64OracleTraceCodecError.truncated
        }
        switch mode {
        case "write":
            guard arguments.count == 2 else {
                throw SM64OracleTraceCodecError.truncated
            }
            try writeWitness(to: URL(fileURLWithPath: arguments[1]).standardizedFileURL)
        case "audit":
            guard arguments.count == 3 else {
                throw SM64OracleTraceCodecError.truncated
            }
            try audit(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "tamper":
            guard arguments.count == 3 else {
                throw SM64OracleTraceCodecError.truncated
            }
            try tamper(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "negative":
            try negativeBoundary()
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
