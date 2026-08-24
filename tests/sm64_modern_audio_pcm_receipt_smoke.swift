import Darwin
import Foundation

private func readReceipts(_ url: URL) throws -> [SM64ModernAudioPCMReceiptV1] {
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    let size = MemoryLayout<SM64ModernAudioPCMReceiptV1>.size
    guard size == 48, data.count % size == 0 else {
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
                        start: source.baseAddress!.advanced(by: offset),
                        count: size
                    )
                )
            }
        }
        receipts.append(receipt)
        offset += size
    }
    return receipts
}

private func receiptFingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
    records.reduce(SM64OracleTraceHash.offset) { hash, record in
        var result = hash
        for byte in 0..<8 {
            result ^= (record.canonicalHash >> UInt64(byte * 8)) & 0xff
            result &*= SM64OracleTraceHash.prime
        }
        return result
    }
}

private func writePair(
    cTraceURL: URL,
    receiptsURL: URL,
    swiftTraceURL: URL
) throws {
    let cTrace: (configuration: SM64OracleTraceConfiguration, records: [SM64OracleTraceRecord])
    do {
        cTrace = try SM64OracleTraceFile.read(from: cTraceURL)
    } catch {
        print("debug_trace_error=\(error)")
        throw error
    }
    let cPCMRecords = cTrace.records.filter {
        $0.domain == SM64_MODERN_ORACLE_DOMAIN_AUDIO
            && $0.recordKind == SM64_MODERN_ORACLE_RECORD_AUDIO_PCM
            && $0.recordID == UInt64(SM64_MODERN_ORACLE_AUDIO_EVENT_PCM)
    }
    let nativeReceipts = try readReceipts(receiptsURL)
    var mirror = SM64AudioPCMReceiptMirror()
    for receipt in nativeReceipts {
        try mirror.observe(native: receipt)
    }
    precondition(!mirror.receipts.isEmpty)
    precondition(mirror.traceRecords == cPCMRecords)
    try SM64OracleTraceFile.write(
        configuration: cTrace.configuration,
        records: mirror.traceRecords,
        to: swiftTraceURL
    )
    print(
        "swift_audio_pcm_route_recorded records=\(mirror.traceRecords.count) "
            + "ticks=\(mirror.receipts.map(\.simulationTick).map(String.init).joined(separator: ",")) "
            + "frames=\(mirror.receipts.map(\.frameCount).map(String.init).joined(separator: ",")) "
            + "fingerprint=0x\(String(receiptFingerprint(mirror.traceRecords), radix: 16))"
    )
}

private func auditTamper(
    cTraceURL: URL,
    receiptsURL: URL,
    tamperedTraceURL: URL,
    tamperedReceiptsURL: URL
) throws {
    var traceData = try Data(contentsOf: cTraceURL)
    guard traceData.count >= 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    // The first schema-4 record's value bytes begin at the fixed 72-byte
    // header plus 48 bytes into its 128-byte record. This damages the stored
    // canonical hash relationship without changing the file length.
    traceData[72 + 48] ^= 0x01
    try traceData.write(to: tamperedTraceURL, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: tamperedTraceURL)
        throw SM64OracleTraceCodecError.nonCanonicalHash
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("audio_pcm_canonical_hash_tamper_rejected=1")
    }

    var receiptData = try Data(contentsOf: receiptsURL)
    guard !receiptData.isEmpty else { throw SM64OracleTraceCodecError.truncated }
    receiptData[receiptData.count - 1] ^= 0x01
    try receiptData.write(to: tamperedReceiptsURL, options: .atomic)
    let cTrace = try SM64OracleTraceFile.read(from: cTraceURL)
    let expected = cTrace.records.filter {
        $0.domain == SM64_MODERN_ORACLE_DOMAIN_AUDIO
            && $0.recordKind == SM64_MODERN_ORACLE_RECORD_AUDIO_PCM
            && $0.recordID == UInt64(SM64_MODERN_ORACLE_AUDIO_EVENT_PCM)
    }
    var mirror = SM64AudioPCMReceiptMirror()
    for receipt in try readReceipts(tamperedReceiptsURL) {
        try mirror.observe(native: receipt)
    }
    precondition(mirror.traceRecords != expected)
    print("audio_pcm_receipt_pair_tamper_rejected=1")
}

@main
enum SM64ModernAudioPCMReceiptSmoke {
    static func main() {
        do {
            try run()
        } catch {
            print("audio_pcm_smoke_failed=\(error)")
            Darwin.exit(1)
        }
    }

    private static func run() throws {
        let arguments = CommandLine.arguments
        guard arguments.count >= 2 else { throw SM64OracleTraceCodecError.invalidHeader }
        switch arguments[1] {
        case "write":
            guard arguments.count == 5 else { throw SM64OracleTraceCodecError.invalidHeader }
            try writePair(
                cTraceURL: URL(fileURLWithPath: arguments[2]),
                receiptsURL: URL(fileURLWithPath: arguments[3]),
                swiftTraceURL: URL(fileURLWithPath: arguments[4])
            )
        case "tamper":
            guard arguments.count == 6 else { throw SM64OracleTraceCodecError.invalidHeader }
            try auditTamper(
                cTraceURL: URL(fileURLWithPath: arguments[2]),
                receiptsURL: URL(fileURLWithPath: arguments[3]),
                tamperedTraceURL: URL(fileURLWithPath: arguments[4]),
                tamperedReceiptsURL: URL(fileURLWithPath: arguments[5])
            )
        default:
            throw SM64OracleTraceCodecError.invalidHeader
        }
    }
}
