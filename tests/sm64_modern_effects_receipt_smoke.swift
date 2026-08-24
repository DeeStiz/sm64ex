import Darwin
import Foundation

private func readReceipts(_ url: URL) throws -> [SM64ModernEffectReceiptV1] {
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    let size = MemoryLayout<SM64ModernEffectReceiptV1>.size
    guard size == 120, data.count % size == 0 else {
        throw SM64OracleTraceCodecError.trailingBytes
    }
    var receipts: [SM64ModernEffectReceiptV1] = []
    receipts.reserveCapacity(data.count / size)
    var offset = 0
    while offset < data.count {
        var receipt = SM64ModernEffectReceiptV1()
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

private func effects(from records: [SM64OracleTraceRecord]) -> [SM64OracleTraceRecord] {
    records.filter {
        $0.domain == SM64_MODERN_ORACLE_DOMAIN_EFFECT
            && $0.recordKind == SM64_MODERN_ORACLE_RECORD_EFFECT
    }
}

private func writePair(
    cTraceURL: URL,
    receiptsURL: URL,
    swiftTraceURL: URL
) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cTraceURL)
    let cEffects = effects(from: cTrace.records)
    var mirror = SM64EffectsMirror()
    for receipt in try readReceipts(receiptsURL) {
        try mirror.observe(native: receipt)
    }
    guard mirror.traceRecords == cEffects,
          mirror.receipts.count == 58,
          mirror.receipts.first?.simulationTick == 2,
          mirror.receipts.last?.simulationTick == 3 else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    try SM64OracleTraceFile.write(
        configuration: cTrace.configuration,
        records: mirror.traceRecords,
        to: swiftTraceURL
    )
    let idCounts = Dictionary(grouping: mirror.receipts, by: \.effectID)
        .mapValues(\.count)
    let idSummary = idCounts.keys.sorted().map {
        "\($0):\(idCounts[$0]!)"
    }.joined(separator: ",")
    print(
        "swift_effects_route_recorded records=\(mirror.traceRecords.count) "
            + "ticks=\(mirror.receipts.first!.simulationTick),\(mirror.receipts.last!.simulationTick) "
            + "ids=\(idSummary) "
            + "owner_thread_receipts=1"
    )
}

private func tamper(
    cTraceURL: URL,
    receiptsURL: URL,
    tamperedTraceURL: URL,
    tamperedReceiptsURL: URL
) throws {
    var traceData = try Data(contentsOf: cTraceURL)
    guard traceData.count >= 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    traceData[72 + 56] ^= 1
    try traceData.write(to: tamperedTraceURL, options: .atomic)
    do {
        _ = try SM64OracleTraceFile.read(from: tamperedTraceURL)
        throw SM64OracleTraceCodecError.nonCanonicalHash
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("effects_canonical_hash_tamper_rejected=1")
    }

    var receiptData = try Data(contentsOf: receiptsURL)
    guard receiptData.count >= MemoryLayout<SM64ModernEffectReceiptV1>.size else {
        throw SM64OracleTraceCodecError.truncated
    }
    receiptData[receiptData.count - 1] ^= 1
    try receiptData.write(to: tamperedReceiptsURL, options: .atomic)
    do {
        for receipt in try readReceipts(tamperedReceiptsURL) {
            _ = try SM64EffectReceipt(native: receipt)
        }
        throw SM64OracleTraceCodecError.nonCanonicalHash
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("effects_receipt_hash_tamper_rejected=1")
    }
}

@main
enum SM64ModernEffectsReceiptSmoke {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard let mode = arguments.first else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
            switch mode {
            case "pair":
                guard arguments.count == 4 else {
                    throw SM64OracleTraceCodecError.invalidHeader
                }
                try writePair(
                    cTraceURL: URL(fileURLWithPath: arguments[1]),
                    receiptsURL: URL(fileURLWithPath: arguments[2]),
                    swiftTraceURL: URL(fileURLWithPath: arguments[3])
                )
            case "tamper":
                guard arguments.count == 5 else {
                    throw SM64OracleTraceCodecError.invalidHeader
                }
                try tamper(
                    cTraceURL: URL(fileURLWithPath: arguments[1]),
                    receiptsURL: URL(fileURLWithPath: arguments[2]),
                    tamperedTraceURL: URL(fileURLWithPath: arguments[3]),
                    tamperedReceiptsURL: URL(fileURLWithPath: arguments[4])
                )
            default:
                throw SM64OracleTraceCodecError.invalidHeader
            }
        } catch {
            print("effects_receipt_smoke_failed=\(error)")
            Darwin.exit(1)
        }
    }
}
