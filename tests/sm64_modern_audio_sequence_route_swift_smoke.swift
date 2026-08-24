import Foundation

private let audioDomain: UInt32 = 9
private let audioRecordKind: UInt32 = 3
private let eventFirst: UInt64 = 1
private let eventLast: UInt64 = 4

private func expectedValueCount(for eventID: UInt64, values: [UInt64]) -> Bool {
    switch eventID {
    case 1:
        return values.count == 3
    case 2:
        return values.count == 5
    case 3:
        return values.count == 3 || values.count >= 5
    case 4:
        return values.count == 4
    default:
        return false
    }
}

private func validOrdering(_ records: [SM64OracleTraceRecord]) -> Bool {
    guard !records.isEmpty else { return false }
    var lastTick: UInt64?
    var lastSequence: UInt32 = 0
    for record in records {
        guard record.domain == audioDomain,
              record.recordKind == audioRecordKind,
              (eventFirst...eventLast).contains(record.recordID),
              expectedValueCount(for: record.recordID, values: record.values),
              (2...3).contains(record.simulationTick)
        else { return false }
        if let lastTick {
            if record.simulationTick == lastTick {
                guard record.sequence == lastSequence &+ 1 else { return false }
            } else {
                guard record.simulationTick == lastTick + 1,
                      record.sequence == 0 else { return false }
            }
        } else {
            guard record.simulationTick == 2, record.sequence == 0 else {
                return false
            }
        }
        lastTick = record.simulationTick
        lastSequence = record.sequence
    }
    return true
}

private struct ReplayResult {
    let records: [SM64OracleTraceRecord]
    let fingerprint: UInt64
    let model: SM64AudioSequenceRuntimeModel
}

private func replay(_ records: [SM64OracleTraceRecord]) throws -> ReplayResult {
    guard validOrdering(records) else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    var model = SM64AudioSequenceRuntimeModel()
    var fingerprint = SM64AudioSequenceRuntimeFingerprint.offset
    var rebuilt: [SM64OracleTraceRecord] = []
    rebuilt.reserveCapacity(records.count)
    for record in records {
        guard let receipt = model.observe(
            eventID: UInt32(record.recordID),
            simulationTick: record.simulationTick,
            values: record.values
        ) else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        fingerprint = SM64AudioSequenceRuntimeFingerprint.receipt(
            fingerprint, receipt
        )
        rebuilt.append(try SM64OracleTraceRecord(
            simulationTick: receipt.simulationTick,
            domain: record.domain,
            recordKind: record.recordKind,
            subjectID: record.subjectID,
            recordID: record.recordID,
            sequence: record.sequence,
            flags: record.flags,
            values: receipt.values
        ))
    }
    return ReplayResult(records: rebuilt, fingerprint: fingerprint, model: model)
}

private func parseFingerprint(_ raw: String) -> UInt64? {
    let normalized = raw.hasPrefix("0x") ? String(raw.dropFirst(2)) : raw
    return UInt64(normalized, radix: 16)
}

private func writeTrace(cURL: URL, swiftURL: URL) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let result = try replay(cTrace.records)
    guard result.records.count == cTrace.records.count else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    try SM64OracleTraceFile.write(
        configuration: cTrace.configuration,
        records: result.records,
        to: swiftURL
    )
    let eventIDs = Set(result.records.map(\.recordID))
        .sorted()
        .map(String.init)
        .joined(separator: ",")
    let ticks = Set(result.records.map(\.simulationTick))
        .sorted()
        .map(String.init)
        .joined(separator: ",")
    print(
        "swift_audio_sequence_route_recorded records=\(result.records.count) "
            + "ticks=\(ticks) event_ids=\(eventIDs) "
            + "coverage=0x\(String(cTrace.configuration.coverageFingerprint, radix: 16)) "
            + "fingerprint=0x\(String(result.fingerprint, radix: 16)) "
            + "model_ticks=\(result.model.tickCount) queue=\(result.model.queue.count)"
    )
}

private func audit(
    cURL: URL,
    swiftURL: URL,
    expectedFingerprint: UInt64
) throws {
    let cTrace = try SM64OracleTraceFile.read(from: cURL)
    let swiftTrace = try SM64OracleTraceFile.read(from: swiftURL)
    let result = try replay(cTrace.records)
    var blockers: [String] = []
    if cTrace.configuration != swiftTrace.configuration { blockers.append("header") }
    if !validOrdering(swiftTrace.records) { blockers.append("ordering") }
    if cTrace.records.count != swiftTrace.records.count { blockers.append("record_count") }
    if cTrace.records != swiftTrace.records { blockers.append("record_bytes") }
    if result.fingerprint != expectedFingerprint { blockers.append("fingerprint") }
    let firstDivergence = zip(cTrace.records, swiftTrace.records)
        .enumerated()
        .first(where: { $0.element.0 != $0.element.1 })
        .map { String($0.offset) } ?? "none"
    print(
        "audio_sequence_pairing_audit admitted=\(blockers.isEmpty ? 1 : 0) "
            + "c_records=\(cTrace.records.count) swift_records=\(swiftTrace.records.count) "
            + "blockers=\(blockers.joined(separator: ",")) "
            + "first_divergence=\(firstDivergence) "
            + "fingerprint=0x\(String(result.fingerprint, radix: 16))"
    )
    guard blockers.isEmpty else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
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
        print("audio_sequence_pairing_tamper_rejected=0")
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("audio_sequence_pairing_tamper_rejected=1")
    }
}

@main
struct SM64ModernAudioSequenceRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else {
            throw SM64OracleTraceCodecError.truncated
        }
        switch mode {
        case "write":
            guard arguments.count == 3 else {
                throw SM64OracleTraceCodecError.truncated
            }
            try writeTrace(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        case "audit":
            guard arguments.count == 4,
                  let expected = parseFingerprint(arguments[3]) else {
                throw SM64OracleTraceCodecError.truncated
            }
            try audit(
                cURL: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                swiftURL: URL(fileURLWithPath: arguments[2]).standardizedFileURL,
                expectedFingerprint: expected
            )
        case "tamper":
            guard arguments.count == 3 else {
                throw SM64OracleTraceCodecError.truncated
            }
            try tamper(
                input: URL(fileURLWithPath: arguments[1]).standardizedFileURL,
                output: URL(fileURLWithPath: arguments[2]).standardizedFileURL
            )
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
