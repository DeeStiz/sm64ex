import Foundation

private let sourcePath = "sound/sequences/us/12_event_high_score.m64"
private let sourceSHA256 = "2e0170f20353d6ba772af9df92f2d53e8b8d807e2b5bca24ac87bc022f08fade"
private let inputSeed = "0x014f93c6ae7e2e59"
private let saveSeed = "0x2a3582ec48614066"
private let shardID = "0x03345fc560c65b75"
private let sequenceID: UInt64 = 0x12
private let audioDomain: UInt32 = 9
private let audioEventKind: UInt32 = 3
private let audioPCMKind: UInt32 = 5
private let sequenceRecordID: UInt64 = 2
private let pcmRecordID: UInt64 = 5
private let expectedPCMRecords = 720

private func fnvString(_ value: String) -> UInt64 {
    var hash = SM64OracleTraceHash.offset
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= SM64OracleTraceHash.prime
    }
    return hash
}

private func readReceipts(_ url: URL) throws -> [SM64ModernAudioPCMReceiptV1] {
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    let size = MemoryLayout<SM64ModernAudioPCMReceiptV1>.size
    guard size == 48, !data.isEmpty, data.count.isMultiple(of: size) else {
        throw SM64OracleTraceCodecError.trailingBytes
    }
    var receipts: [SM64ModernAudioPCMReceiptV1] = []
    receipts.reserveCapacity(data.count / size)
    var offset = 0
    while offset < data.count {
        var receipt = SM64ModernAudioPCMReceiptV1()
        withUnsafeMutableBytes(of: &receipt) { destination in
            data.withUnsafeBytes { source in
                destination.copyBytes(
                    from: UnsafeRawBufferPointer(
                        start: source.baseAddress!.advanced(by: offset), count: size
                    )
                )
            }
        }
        receipts.append(receipt)
        offset += size
    }
    return receipts
}

private func expectedConfigurationFingerprint() -> UInt64 {
    fnvString(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
            + "input_seed=\(inputSeed);save_seed=\(saveSeed);shard=\(shardID);"
            + "asset=\(sourcePath);asset_sha256=\(sourceSHA256)"
    )
}

private func validateHeader(_ configuration: SM64OracleTraceConfiguration) throws {
    guard configuration.regionCode == 0x5553,
          configuration.mode == .record,
          configuration.buildFingerprint == fnvString("sm64-modern-audio-asset-route-v1"),
          configuration.contentFingerprint == fnvString(
            "\(sourcePath)|sha256=\(sourceSHA256)"
          ),
          configuration.configurationFingerprint == expectedConfigurationFingerprint()
    else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
}

private func validate(
    fullURL: URL,
    pcmURL: URL,
    receiptsURL: URL,
    swiftURL: URL
) throws {
    let full = try SM64OracleTraceFile.read(from: fullURL)
    let pcm = try SM64OracleTraceFile.read(from: pcmURL)
    try validateHeader(full.configuration)
    guard full.configuration == pcm.configuration else {
        throw SM64OracleTraceCodecError.invalidHeader
    }

    let sequenceRecords = full.records.filter {
        $0.domain == audioDomain && $0.recordKind == audioEventKind
            && $0.recordID == sequenceRecordID
    }
    let sourceRecords = sequenceRecords.filter {
        $0.values.count >= 2 && $0.values[1] == sequenceID
    }
    guard sourceRecords.count == 1,
          sourceRecords[0].simulationTick == 63,
          sourceRecords[0].values == [1, sequenceID, 0, 0, 0]
    else {
        throw SM64OracleTraceCodecError.invalidHeader
    }

    let fullPCMRecords = full.records.filter {
        $0.domain == audioDomain && $0.recordKind == audioPCMKind
            && $0.recordID == pcmRecordID
    }
    guard fullPCMRecords.count == expectedPCMRecords,
          pcm.records == fullPCMRecords
    else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    for record in pcm.records {
        guard record.values.count == 5,
              record.values[0] == 544,
              record.values[1] == 32_000,
              record.values[2] == 2,
              record.values[3] == 1 else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
    }

    let nativeReceipts = try readReceipts(receiptsURL)
    guard nativeReceipts.count == expectedPCMRecords else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    var mirror = SM64AudioPCMReceiptMirror()
    for receipt in nativeReceipts {
        try mirror.observe(native: receipt)
    }
    guard mirror.traceRecords == pcm.records else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    guard !FileManager.default.fileExists(atPath: swiftURL.path) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    try SM64OracleTraceFile.write(
        configuration: pcm.configuration, records: mirror.traceRecords, to: swiftURL
    )
    let swift = try SM64OracleTraceFile.read(from: swiftURL)
    guard swift.configuration == pcm.configuration,
          swift.records == pcm.records else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let ticks = pcm.records.map(\.simulationTick)
    let first = ticks.first ?? 0
    let last = ticks.last ?? 0
    print(
        "phase85ce_audio_pcm_pair source=\(sourcePath) "
            + "source_sha256=\(sourceSHA256) sequence12=1 sequence12_tick=63 "
            + "full_records=\(full.records.count) pcm_records=\(pcm.records.count) "
            + "receipts=\(nativeReceipts.count) pcm_ticks=\(first),\(last) "
            + "frames=391680 source_identity_records=\(pcm.records.count) "
            + "exact_c_swift_pcm_pair=1"
    )
}

private func tamper(
    pcmURL: URL,
    receiptsURL: URL,
    tamperedTraceURL: URL,
    tamperedReceiptsURL: URL
) throws {
    var traceData = try Data(contentsOf: pcmURL)
    guard traceData.count > 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    traceData[72 + 48] ^= 1
    try traceData.write(to: tamperedTraceURL, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: tamperedTraceURL)
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("phase85ce_pcm_trace_tamper_rejected=1")
    }

    var receiptData = try Data(contentsOf: receiptsURL)
    guard !receiptData.isEmpty else { throw SM64OracleTraceCodecError.truncated }
    receiptData[receiptData.count - 1] ^= 1
    try receiptData.write(to: tamperedReceiptsURL, options: .atomic)
    let expected = try SM64OracleTraceFile.read(from: pcmURL).records
    var mirror = SM64AudioPCMReceiptMirror()
    for receipt in try readReceipts(tamperedReceiptsURL) {
        try mirror.observe(native: receipt)
    }
    guard mirror.traceRecords != expected else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    print("phase85ce_pcm_receipt_tamper_rejected=1")
}

@main
struct SM64ModernPhase85CEAudioPCMBackend {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard let mode = arguments.first else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
            switch mode {
            case "audit":
                guard arguments.count == 5 else {
                    throw SM64OracleTraceCodecError.invalidHeader
                }
                try validate(
                    fullURL: URL(fileURLWithPath: arguments[1]),
                    pcmURL: URL(fileURLWithPath: arguments[2]),
                    receiptsURL: URL(fileURLWithPath: arguments[3]),
                    swiftURL: URL(fileURLWithPath: arguments[4])
                )
            case "tamper":
                guard arguments.count == 5 else {
                    throw SM64OracleTraceCodecError.invalidHeader
                }
                try tamper(
                    pcmURL: URL(fileURLWithPath: arguments[1]),
                    receiptsURL: URL(fileURLWithPath: arguments[2]),
                    tamperedTraceURL: URL(fileURLWithPath: arguments[3]),
                    tamperedReceiptsURL: URL(fileURLWithPath: arguments[4])
                )
            case "partial":
                guard arguments.count == 3 else {
                    throw SM64OracleTraceCodecError.invalidHeader
                }
                var data = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
                guard data.count > 72 else { throw SM64OracleTraceCodecError.truncated }
                data.removeLast()
                try data.write(
                    to: URL(fileURLWithPath: arguments[2]), options: .atomic
                )
                do {
                    _ = try SM64OracleTraceFile.read(
                        from: URL(fileURLWithPath: arguments[2])
                    )
                    throw SM64OracleTraceCodecError.invalidHeader
                } catch SM64OracleTraceCodecError.trailingBytes,
                        SM64OracleTraceCodecError.truncated {
                    print("phase85ce_pcm_partial_rejected=1")
                }
            default:
                throw SM64OracleTraceCodecError.invalidHeader
            }
        } catch {
            FileHandle.standardError.write(Data("phase85ce_audio_pcm_pair_failed=\(error)\n".utf8))
            exit(2)
        }
    }
}
