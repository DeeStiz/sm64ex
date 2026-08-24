import Foundation

private let routeShardID: UInt64 = 0x022f_bda0_ff7f_2dd1
private let routeInputSeed: UInt64 = 0x0c83_cf28_590d_4915
private let routeSaveSeed: UInt64 = 0xaaac_c83c_b4eb_46a2
private let saveDomain: UInt32 = 10
private let globalDomain: UInt32 = 0
private let saveRecordKind: UInt32 = 6
private let globalRecordKind: UInt32 = 1
private let soundMode: UInt16 = 0x4321
private let imageByteCount = 512
private let globalSnapshotByteCount = 48

private struct SidecarRecord: Equatable {
    let tick: UInt64
    let recordID: UInt64
    let subjectID: UInt64
    let byteCount: UInt64
    let imageHash: UInt64
    let modifiedFlags: UInt64
    let image: [UInt8]
}

private func parseHex(_ value: Substring) throws -> UInt64 {
    guard value.hasPrefix("0x"), let parsed = UInt64(value.dropFirst(2), radix: 16) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    return parsed
}

private func readSidecar(_ url: URL) throws -> [SidecarRecord] {
    let text = try String(contentsOf: url, encoding: .utf8)
    return try text.split(whereSeparator: \.isNewline).map { line in
        let fields = line.split(separator: "|", omittingEmptySubsequences: false)
        guard fields.count == 7,
              let tick = UInt64(fields[0]),
              let recordID = UInt64(fields[1]),
              let subjectID = UInt64(fields[2]),
              let byteCount = UInt64(fields[3]),
              let modifiedFlags = UInt64(fields[5]) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        let imageHash = try parseHex(fields[4])
        let hex = String(fields[6])
        guard hex.count == imageByteCount * 2,
              hex.allSatisfy(\.isHexDigit) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        var image = [UInt8]()
        image.reserveCapacity(imageByteCount)
        var cursor = hex.startIndex
        for _ in 0..<imageByteCount {
            let end = hex.index(cursor, offsetBy: 2)
            guard let byte = UInt8(hex[cursor..<end], radix: 16) else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
            image.append(byte)
            cursor = end
        }
        return SidecarRecord(
            tick: tick, recordID: recordID, subjectID: subjectID,
            byteCount: byteCount, imageHash: imageHash,
            modifiedFlags: modifiedFlags, image: image
        )
    }
}

private func normalizedImage(_ bytes: [UInt8]) -> SM64PersistenceImage? {
    guard bytes.count == imageByteCount else { return nil }
    let saveBytes = SM64SaveFileSnapshot.byteCount
    var primary = [[UInt8]]()
    var backup = [[UInt8]]()
    for file in 0..<SM64PersistenceImage.fileCount {
        let offset = file * saveBytes * 2
        primary.append(Array(bytes[offset..<(offset + saveBytes)]))
        backup.append(Array(bytes[(offset + saveBytes)..<(offset + saveBytes * 2)]))
    }
    let menuOffset = saveBytes * SM64PersistenceImage.fileCount * 2
    return SM64PersistenceImage(
        savePrimary: primary,
        saveBackup: backup,
        menuPrimary: Array(bytes[menuOffset..<(menuOffset + SM64MenuDataSnapshot.byteCount)]),
        menuBackup: Array(bytes[(menuOffset + SM64MenuDataSnapshot.byteCount)..<bytes.count])
    )
}

private func fnv(_ string: String) -> UInt64 {
    string.utf8.reduce(UInt64(1_469_598_103_934_665_603)) { hash, byte in
        (hash ^ UInt64(byte)) &* UInt64(1_099_511_628_211)
    }
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= UInt64(1_099_511_628_211)
    }
    return hash
}

private func coverageFingerprint() -> UInt64 {
    var hash = UInt64(1_469_598_103_934_665_603)
    for id in 1...4 {
        hash = hashU64(hash, UInt64(saveDomain))
        hash = hashU64(hash, UInt64(saveRecordKind))
        hash = hashU64(hash, UInt64(id))
    }
    for id in 1...6 {
        hash = hashU64(hash, UInt64(globalDomain))
        hash = hashU64(hash, UInt64(globalRecordKind))
        hash = hashU64(hash, UInt64(id))
    }
    return hashU64(hash, 10)
}

private struct SnapshotCursor {
    let data: Data
    var offset: Int = 0

    mutating func readUInt32() throws -> UInt32 {
        guard offset + 4 <= data.count else { throw SM64OracleTraceCodecError.truncated }
        var value: UInt32 = 0
        for byte in 0..<4 { value |= UInt32(data[offset + byte]) << UInt32(byte * 8) }
        offset += 4
        return value
    }

    mutating func readUInt64() throws -> UInt64 {
        guard offset + 8 <= data.count else { throw SM64OracleTraceCodecError.truncated }
        var value: UInt64 = 0
        for byte in 0..<8 { value |= UInt64(data[offset + byte]) << UInt64(byte * 8) }
        offset += 8
        return value
    }

    mutating func skip(_ count: Int) throws {
        guard offset + count <= data.count else { throw SM64OracleTraceCodecError.truncated }
        offset += count
    }
}

private func readSnapshots(_ url: URL) throws -> [SM64ModernGlobalStateSnapshotV1] {
    guard MemoryLayout<SM64ModernGlobalStateSnapshotV1>.size == globalSnapshotByteCount else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    guard data.count == globalSnapshotByteCount * 2 else {
        throw SM64OracleTraceCodecError.truncated
    }
    var cursor = SnapshotCursor(data: data)
    var snapshots = [SM64ModernGlobalStateSnapshotV1]()
    for _ in 0..<2 {
        var snapshot = SM64ModernGlobalStateSnapshotV1()
        snapshot.header.abi_version = try cursor.readUInt32()
        snapshot.header.struct_size = try cursor.readUInt32()
        snapshot.simulation_tick = try cursor.readUInt64()
        snapshot.global_timer = try cursor.readUInt32()
        snapshot.level_number = try cursor.readUInt32()
        snapshot.area_index = try cursor.readUInt32()
        snapshot.act_number = try cursor.readUInt32()
        snapshot.course_number = try cursor.readUInt32()
        snapshot.random_seed = try cursor.readUInt32()
        snapshot.reserved = try cursor.readUInt32()
        try cursor.skip(4)
        snapshots.append(snapshot)
    }
    return snapshots
}

private func validateImages(_ sidecar: [SidecarRecord], records: [SM64OracleTraceRecord]) throws {
    let saveRecords = records.filter {
        $0.domain == saveDomain && $0.recordKind == saveRecordKind
    }
    guard saveRecords.count == 4, sidecar.count == saveRecords.count else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let expectedMenu = SM64MenuDataCodec.encode(
        SM64SaveFileMutator.setSoundMode(soundMode, in: SM64MenuDataSnapshot())
    )
    let expectedSave = SM64SaveFileCodec.encode(SM64SaveFileSnapshot())
    for (record, sidecarRecord) in zip(saveRecords, sidecar) {
        guard sidecarRecord.tick == record.simulationTick,
              sidecarRecord.recordID == record.recordID,
              sidecarRecord.subjectID == record.subjectID,
              sidecarRecord.byteCount == record.values[0],
              sidecarRecord.imageHash == record.values[1],
              sidecarRecord.modifiedFlags == record.values[2],
              sidecarRecord.byteCount == UInt64(imageByteCount) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        let imageHash = sidecarRecord.image.reduce(
            UInt64(1_469_598_103_934_665_603)
        ) { hash, byte in
            (hash ^ UInt64(byte)) &* UInt64(1_099_511_628_211)
        }
        guard imageHash == sidecarRecord.imageHash,
              let image = normalizedImage(sidecarRecord.image),
              image.savePrimary.allSatisfy(SM64SaveFileCodec.verify),
              image.saveBackup.allSatisfy(SM64SaveFileCodec.verify),
              SM64MenuDataCodec.verify(image.menuPrimary),
              SM64MenuDataCodec.verify(image.menuBackup),
              image.savePrimary == image.saveBackup,
              image.menuPrimary == image.menuBackup,
              image.savePrimary.allSatisfy({ $0 == expectedSave }),
              image.menuPrimary == expectedMenu else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
    }
}

private func validateRoute(
    trace: (configuration: SM64OracleTraceConfiguration,
            records: [SM64OracleTraceRecord]),
    sidecar: [SidecarRecord], snapshotsURL: URL
) throws -> [SM64OracleTraceRecord] {
    let config = trace.configuration
    guard config.mode == .record,
          config.regionCode == 0x5553,
          config.buildFingerprint == fnv("sm64-modern-save-mutation-route-build-v1"),
          config.contentFingerprint == fnv(
              "src/game/save_file.c|save_mutation|save_file_set_sound_mode"),
          config.configurationFingerprint == fnv(
              String(format: "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;input_seed=0x%016llx;save_seed=0x%016llx;shard=0x%016llx", routeInputSeed, routeSaveSeed, routeShardID)),
          config.initialSaveFingerprint == fnv(
              String(format: "save=empty-us-slot-0;seed=0x%016llx", routeSaveSeed)),
          config.coverageFingerprint == coverageFingerprint() else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let saveRecords = trace.records.filter {
        $0.domain == saveDomain && $0.recordKind == saveRecordKind
    }
    let globalRecords = trace.records.filter {
        $0.domain == globalDomain && $0.recordKind == globalRecordKind
    }
    guard trace.records.count == 16,
          saveRecords.count == 4,
          globalRecords.count == 12,
          saveRecords.map(\.recordID) == [1, 2, 3, 4],
          saveRecords.map(\.simulationTick) == [2, 2, 2, 3],
          globalRecords.map(\.recordID) == [1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6],
          globalRecords.map(\.simulationTick) == Array(repeating: 2, count: 6) + Array(repeating: 3, count: 6) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let snapshots = try readSnapshots(snapshotsURL)
    var mirror = SM64GlobalStateMirror()
    for snapshot in snapshots { try mirror.observe(native: snapshot) }
    guard mirror.snapshots.count == 2,
          mirror.traceRecords == globalRecords else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    try validateImages(sidecar, records: trace.records)

    var sidecarIndex = 0
    var globalIndex = 0
    var rebuilt = [SM64OracleTraceRecord]()
    for record in trace.records {
        if record.domain == saveDomain && record.recordKind == saveRecordKind {
            let sidecarRecord = sidecar[sidecarIndex]
            sidecarIndex += 1
            let rebuiltRecord = try SM64OracleTraceRecord(
                simulationTick: sidecarRecord.tick,
                domain: saveDomain,
                recordKind: saveRecordKind,
                subjectID: sidecarRecord.subjectID,
                recordID: sidecarRecord.recordID,
                sequence: record.sequence,
                flags: record.flags,
                values: [sidecarRecord.byteCount, sidecarRecord.imageHash,
                         sidecarRecord.modifiedFlags]
            )
            guard rebuiltRecord == record else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
            rebuilt.append(rebuiltRecord)
        } else {
            guard record == mirror.traceRecords[globalIndex] else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
            rebuilt.append(mirror.traceRecords[globalIndex])
            globalIndex += 1
        }
    }
    return rebuilt
}

private func writeTrace(
    cURL: URL, sidecarURL: URL, snapshotsURL: URL, swiftURL: URL
) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let sidecar = try readSidecar(sidecarURL)
    let rebuilt = try validateRoute(
        trace: cTrace, sidecar: sidecar, snapshotsURL: snapshotsURL
    )
    try SM64OracleTraceFile.write(
        configuration: cTrace.configuration, records: rebuilt, to: swiftURL
    )
    print(
        "swift_save_mutation_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "save_records=4 global_records=12 snapshots=2 sound_mode=0x4321 "
            + "ticks=2,3 seeds=input:0x\(String(routeInputSeed, radix: 16)),save:0x\(String(routeSaveSeed, radix: 16))"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    var blockers = [String]()
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if cTrace.records != swiftTrace.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated().first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "save_mutation_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
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
        print("save_mutation_pairing_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("save_mutation_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernSaveMutationRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else { throw SM64OracleTraceCodecError.truncated }
        switch mode {
        case "write":
            guard arguments.count == 5 else { throw SM64OracleTraceCodecError.truncated }
            try writeTrace(
                cURL: URL(fileURLWithPath: arguments[1]),
                sidecarURL: URL(fileURLWithPath: arguments[2]),
                snapshotsURL: URL(fileURLWithPath: arguments[3]),
                swiftURL: URL(fileURLWithPath: arguments[4])
            )
        case "audit":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try audit(
                cURL: URL(fileURLWithPath: arguments[1]),
                swiftURL: URL(fileURLWithPath: arguments[2])
            )
        case "tamper":
            guard arguments.count == 3 else { throw SM64OracleTraceCodecError.truncated }
            try tamper(
                input: URL(fileURLWithPath: arguments[1]),
                output: URL(fileURLWithPath: arguments[2])
            )
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
