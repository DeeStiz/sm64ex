import Foundation

private enum ProbeError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self {
        case .invalid(let message): return message
        }
    }
}

private func u32(_ data: Data, _ offset: Int) -> UInt32 {
    var result: UInt32 = 0
    for index in 0..<4 {
        result |= UInt32(data[offset + index]) << UInt32(index * 8)
    }
    return result
}

private func u64(_ data: Data, _ offset: Int) -> UInt64 {
    var result: UInt64 = 0
    for index in 0..<8 {
        result |= UInt64(data[offset + index]) << UInt64(index * 8)
    }
    return result
}

private struct NonPCMRecord {
    let path: String
    let tick: UInt64
    let domain: UInt32
    let kind: UInt32
    let subject: UInt64
    let recordID: UInt64
    let sequence: UInt32
    let valueCount: UInt32
    let model: UInt64
    let behaviorIdentity: UInt64
    let parent: UInt64
}

private let traceHeaderSize = 72
private let recordSize = 128
private let firstDivergentRecord = 355
private let recordOffset = traceHeaderSize + firstDivergentRecord * recordSize
private let divergentByteOffset = recordOffset + 64

private func parse(_ path: String) throws -> NonPCMRecord {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    guard data.count >= recordOffset + recordSize else {
        throw ProbeError.invalid("trace too small: \(path)")
    }
    guard u32(data, 0) == 1, u32(data, 4) == UInt32(traceHeaderSize),
          u32(data, 8) == 4 else {
        throw ProbeError.invalid("schema-4 header mismatch: \(path)")
    }
    guard u64(data, recordOffset + 8) == 1,
          u32(data, recordOffset + 16) == 12,
          u32(data, recordOffset + 20) == 4,
          u64(data, recordOffset + 24) == 11,
          u64(data, recordOffset + 32) == 4,
          u32(data, recordOffset + 40) == 10,
          u32(data, recordOffset + 44) == 3 else {
        throw ProbeError.invalid("record-355 metadata mismatch: \(path)")
    }
    let record = NonPCMRecord(
        path: path,
        tick: u64(data, recordOffset + 8),
        domain: u32(data, recordOffset + 16),
        kind: u32(data, recordOffset + 20),
        subject: u64(data, recordOffset + 24),
        recordID: u64(data, recordOffset + 32),
        sequence: u32(data, recordOffset + 40),
        valueCount: u32(data, recordOffset + 44),
        model: u64(data, recordOffset + 56),
        behaviorIdentity: u64(data, recordOffset + 64),
        parent: u64(data, recordOffset + 72))
    print("phase85cg_nonpcm_record path=\(path) byte_offset=\(divergentByteOffset) tick=\(record.tick) domain=\(record.domain) kind=\(record.kind) subject=\(record.subject) record_id=\(record.recordID) sequence=\(record.sequence) value_count=\(record.valueCount) model=0x\(String(record.model, radix: 16)) behavior_identity=0x\(String(record.behaviorIdentity, radix: 16)) parent=0x\(String(record.parent, radix: 16))")
    return record
}

do {
    let paths = Array(CommandLine.arguments.dropFirst())
    guard paths.count >= 3 else {
        throw ProbeError.invalid("usage: phase85cg-probe DEBUG ASAN RELEASE")
    }
    let records = try paths.map(parse)
    let first = records[0]
    guard records.dropFirst().allSatisfy({
        $0.tick == first.tick && $0.domain == first.domain && $0.kind == first.kind
            && $0.subject == first.subject && $0.recordID == first.recordID
            && $0.sequence == first.sequence && $0.valueCount == first.valueCount
            && $0.model == first.model && $0.parent == first.parent
    }) else {
        throw ProbeError.invalid("non-PCM metadata is not stable across variants")
    }
    guard Set(records.map(\.behaviorIdentity)).count > 1 else {
        throw ProbeError.invalid("behavior identity unexpectedly stable; rerun provenance gate")
    }
    print("phase85cg_nonpcm_provenance=fallback_behavior_pointer_delta")
    print("phase85cg_nonpcm_source_bound=0")
    print("phase85cg_canonical_promotion=0")
} catch {
    FileHandle.standardError.write(Data("phase85cg_nonpcm_probe_failed=\(error)\n".utf8))
    exit(1)
}
