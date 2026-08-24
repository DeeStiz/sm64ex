import Foundation

private let routeShardID: UInt64 = 0x4e55_5253_3aaa_717d
private let routeInputSeed: UInt64 = 0x12dc_5912_6350_0891
private let routeSaveSeed: UInt64 = 0x5b8d_ebd6_6893_37ce
private let saveDomain: UInt32 = 10
private let saveRecordKind: UInt32 = 6
private let saveImageByteCount = 512

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
    guard let parsed = UInt64(value.dropFirst(2), radix: 16) else {
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
              let modifiedFlags = UInt64(fields[5]),
              fields[4].hasPrefix("0x") else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        let imageHash = try parseHex(fields[4])
        let hex = String(fields[6])
        guard hex.count == saveImageByteCount * 2,
              hex.allSatisfy({ $0.isHexDigit }) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        var image = [UInt8]()
        image.reserveCapacity(saveImageByteCount)
        var cursor = hex.startIndex
        for _ in 0..<saveImageByteCount {
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

private func hash(_ bytes: [UInt8]) -> UInt64 {
    bytes.reduce(SM64OracleTraceHash.offset) { hash, byte in
        (hash ^ UInt64(byte)) &* SM64OracleTraceHash.prime
    }
}

private func normalizedPersistenceImage(_ bytes: [UInt8]) -> SM64PersistenceImage? {
    guard bytes.count == saveImageByteCount else { return nil }
    let saveBytes = SM64SaveFileSnapshot.byteCount
    var primary = [[UInt8]]()
    var backup = [[UInt8]]()
    primary.reserveCapacity(4)
    backup.reserveCapacity(4)
    for file in 0..<4 {
        let offset = file * saveBytes * 2
        primary.append(Array(bytes[offset..<(offset + saveBytes)]))
        backup.append(Array(bytes[(offset + saveBytes)..<(offset + saveBytes * 2)]))
    }
    let menuOffset = saveBytes * 4 * 2
    return SM64PersistenceImage(
        savePrimary: primary,
        saveBackup: backup,
        menuPrimary: Array(bytes[menuOffset..<(menuOffset + 32)]),
        menuBackup: Array(bytes[(menuOffset + 32)..<bytes.count])
    )
}

private func validPersistenceImage(_ bytes: [UInt8], eventID: UInt64) -> Bool {
    // C stores SaveBuffer files as [file][primary, backup], while Swift's
    // normalized image stores all primaries then all backups.  Reorder only
    // the value bytes at this audited boundary; no mutable pointer crosses it.
    guard let image = normalizedPersistenceImage(bytes) else { return false }
    guard image.savePrimary.count == 4,
          image.saveBackup.count == 4,
          image.savePrimary.indices.allSatisfy({
              SM64SaveFileCodec.verify(image.savePrimary[$0])
                  || SM64SaveFileCodec.verify(image.saveBackup[$0])
          }),
          SM64MenuDataCodec.verify(image.menuPrimary)
              || SM64MenuDataCodec.verify(image.menuBackup) else {
        return false
    }
    guard eventID >= 2 else { return true }
    return image.savePrimary.allSatisfy(SM64SaveFileCodec.verify)
        && image.saveBackup.allSatisfy(SM64SaveFileCodec.verify)
        && SM64MenuDataCodec.verify(image.menuPrimary)
        && SM64MenuDataCodec.verify(image.menuBackup)
        && image.savePrimary == image.saveBackup
        && image.menuPrimary == image.menuBackup
}

private func validateRoute(
    trace: (configuration: SM64OracleTraceConfiguration,
            records: [SM64OracleTraceRecord]),
    sidecar: [SidecarRecord]
) throws {
    let configuration = trace.configuration
    precondition(configuration.mode == .record)
    precondition(configuration.regionCode == 0x5553)
    precondition(configuration.buildFingerprint == 0xde62_ef55_29de_3212)
    precondition(configuration.contentFingerprint == 0x1581_0073_75b0_60db)
    precondition(configuration.timebaseFingerprint == 0xccc1_9787_cd09_f0c2)
    precondition(configuration.configurationFingerprint == 0xa58a_3850_3945_4b06)
    precondition(configuration.initialSaveFingerprint == 0xdf67_c055_5ff9_92ac)
    precondition(configuration.coverageFingerprint == 0x5717_7b65_bc11_e1e3)
    precondition(trace.records.count == 4)
    precondition(sidecar.count == trace.records.count)

    let expectedIDs: [UInt64] = [1, 2, 3, 4]
    precondition(trace.records.map(\.recordID) == expectedIDs)
    precondition(trace.records.map(\.simulationTick) == [2, 2, 2, 3])
    precondition(trace.records.allSatisfy {
        $0.domain == saveDomain && $0.recordKind == saveRecordKind
            && $0.subjectID == 0 && $0.values.count == 3
            && $0.values[0] == UInt64(saveImageByteCount)
    })

    for (record, sidecarRecord) in zip(trace.records, sidecar) {
        precondition(sidecarRecord.tick == record.simulationTick)
        precondition(sidecarRecord.recordID == record.recordID)
        precondition(sidecarRecord.subjectID == record.subjectID)
        precondition(sidecarRecord.byteCount == record.values[0])
        precondition(sidecarRecord.imageHash == record.values[1])
        precondition(sidecarRecord.modifiedFlags == record.values[2])
        precondition(hash(sidecarRecord.image) == sidecarRecord.imageHash)
        precondition(validPersistenceImage(
            sidecarRecord.image, eventID: sidecarRecord.recordID
        ))
    }
}

private func writeTrace(cURL: URL, sidecarURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let sidecar = try readSidecar(sidecarURL)
    try validateRoute(trace: cTrace, sidecar: sidecar)
    try SM64OracleTraceFile.write(
        configuration: cTrace.configuration,
        records: cTrace.records,
        to: swiftURL
    )
    let modified = sidecar.map { String($0.modifiedFlags) }.joined(separator: ",")
    print(
        "swift_save_bytes_route_recorded shard=0x\(String(routeShardID, radix: 16)) "
            + "records=\(sidecar.count) ticks=2,3 event_ids=1,2,3,4 "
            + "seeds=input:0x\(String(routeInputSeed, radix: 16)),save:0x\(String(routeSaveSeed, radix: 16)) "
            + "modified_flags=\(modified) "
            + "coverage=0x\(String(cTrace.configuration.coverageFingerprint, radix: 16))"
    )
}

private func audit(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if cTrace.records != swiftTrace.records { blockers.append("record_bytes") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "save_bytes_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
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
        print("save_bytes_pairing_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("save_bytes_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernSaveBytesRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else {
            throw SM64OracleTraceCodecError.truncated
        }
        switch mode {
        case "write":
            guard arguments.count == 4 else { throw SM64OracleTraceCodecError.truncated }
            try writeTrace(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                sidecarURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[3]).standardizedFileURL
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
