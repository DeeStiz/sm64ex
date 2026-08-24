import Foundation

private enum Phase85CNError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self {
        case .invalid(let message): return message
        }
    }
}

private let headerSize = 72
private let recordSize = 128
private let expectedBooInCastle: UInt64 = 0xa63b_55d3_bf9b_a914
private let expectedPaintingDeathWarp: UInt64 = 0xe534_2273_4eda_5e67
private let legacySubject54: [UInt64] = [0xffff_ffff_ffff_f230, 0xffff_ffff_ffff_eba0]
private let legacySubject23: [UInt64] = [
    0xffff_ffff_ffa9_d160,
    0xffff_ffff_ff8e_37c0,
    0xffff_ffff_ffa9_9140,
]

private func u32(_ data: Data, _ offset: Int) -> UInt32 {
    var value: UInt32 = 0
    for index in 0..<4 {
        value |= UInt32(data[offset + index]) << UInt32(index * 8)
    }
    return value
}

private func u64(_ data: Data, _ offset: Int) -> UInt64 {
    var value: UInt64 = 0
    for index in 0..<8 {
        value |= UInt64(data[offset + index]) << UInt64(index * 8)
    }
    return value
}

private struct TargetRecord {
    let index: Int
    let tick: UInt64
    let domain: UInt32
    let kind: UInt32
    let subject: UInt64
    let recordID: UInt64
    let values: [UInt64]
}

private func firstRecord(
    in data: Data,
    domain expectedDomain: UInt32,
    kind expectedKind: UInt32,
    subject expectedSubject: UInt64,
    recordID expectedRecordID: UInt64,
    tick expectedTick: UInt64
) throws -> TargetRecord {
    guard data.count >= headerSize, u32(data, 8) == 4 else {
        throw Phase85CNError.invalid("schema-4 trace header missing")
    }
    let recordCount = (data.count - headerSize) / recordSize
    for index in 0..<recordCount {
        let offset = headerSize + index * recordSize
        guard u64(data, offset + 8) == expectedTick,
              u32(data, offset + 16) == expectedDomain,
              u32(data, offset + 20) == expectedKind,
              u64(data, offset + 24) == expectedSubject,
              u64(data, offset + 32) == expectedRecordID else {
            continue
        }
        let valueCount = min(Int(u32(data, offset + 44)), 8)
        let values = (0..<valueCount).map { u64(data, offset + 56 + $0 * 8) }
        return TargetRecord(
            index: index,
            tick: expectedTick,
            domain: expectedDomain,
            kind: expectedKind,
            subject: expectedSubject,
            recordID: expectedRecordID,
            values: values
        )
    }
    throw Phase85CNError.invalid(
        "target record missing domain=\(expectedDomain) kind=\(expectedKind) "
            + "subject=\(expectedSubject) id=\(expectedRecordID) tick=\(expectedTick)"
    )
}

private func sourceContains(_ sourcePath: String, _ needle: String) throws {
    let source = try String(contentsOfFile: sourcePath, encoding: .utf8)
    guard source.contains(needle) else {
        throw Phase85CNError.invalid("source identity mapping missing: \(needle)")
    }
}

private func describe(_ value: UInt64) -> String {
    "0x\(String(value, radix: 16))"
}

@main
struct SM64ModernPhase85CNDespawnPaintingIdentity {
    static func main() {
        do {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard arguments.count >= 3 else {
        throw Phase85CNError.invalid(
            "usage: phase85cn-identity C ASAN RELEASE [RERUN] [SOURCE]"
        )
    }

    let sourcePath = arguments.count >= 5
        ? arguments[4]
        : "src/pc/sm64_modern_gameplay_parity.c"
    try sourceContains(sourcePath, "SOURCE_BEHAVIOR_IDENTITY(bhvBooInCastle)")
    try sourceContains(sourcePath, "SOURCE_BEHAVIOR_IDENTITY(bhvPaintingDeathWarp)")
    try sourceContains("levels/castle_inside/script.c", "bhvBooInCastle")
    try sourceContains("levels/castle_inside/script.c", "bhvPaintingDeathWarp")

    let paths = arguments.prefix(4)
    var subject54Values: [UInt64] = []
    var subject23Values: [UInt64] = []
    var traceCounts: [Int] = []

    for path in paths {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        traceCounts.append((data.count - headerSize) / recordSize)
        let despawn = try firstRecord(
            in: data, domain: 12, kind: 4, subject: 54, recordID: 5, tick: 1
        )
        let painting = try firstRecord(
            in: data, domain: 3, kind: 1, subject: 23, recordID: 400, tick: 1
        )
        guard despawn.values.count == 1, painting.values.count == 1 else {
            throw Phase85CNError.invalid("target value count mismatch in \(path)")
        }
        subject54Values.append(despawn.values[0])
        subject23Values.append(painting.values[0])
        print(
            "phase85cn_path=\(path) records=\(traceCounts.last!) "
                + "record981_subject54=\(describe(despawn.values[0])) "
                + "record1370_subject23=\(describe(painting.values[0]))"
        )
    }

    let subject54Legacy = Set(subject54Values).isSubset(of: Set(legacySubject54))
    let subject23Legacy = Set(subject23Values).isSubset(of: Set(legacySubject23))
    let subject54Semantic = Set(subject54Values) == Set([expectedBooInCastle])
    let subject23Semantic = Set(subject23Values) == Set([expectedPaintingDeathWarp])

    guard subject54Legacy || subject54Semantic else {
        throw Phase85CNError.invalid("unexpected subject-54 identity provenance")
    }
    guard subject23Legacy || subject23Semantic else {
        throw Phase85CNError.invalid("unexpected subject-23 identity provenance")
    }

    print("phase85cn_subject54_source_behavior=bhvBooInCastle")
    print("phase85cn_subject54_expected_semantic_identity=\(describe(expectedBooInCastle))")
    print("phase85cn_subject23_source_behavior=bhvPaintingDeathWarp")
    print("phase85cn_subject23_expected_semantic_identity=\(describe(expectedPaintingDeathWarp))")
    print("phase85cn_subject54_source_mapping=1")
    print("phase85cn_subject23_source_mapping=1")
    print("phase85cn_native_full_trace_pair=\(subject54Semantic && subject23Semantic ? 1 : 0)")
    print("phase85cn_canonical_promotion=0")
    print("phase85cn_manifest_mutation=0 ledger_mutation=0 shared_docs_mutation=0")
    if !(subject54Semantic && subject23Semantic) {
        print("phase85cn_fail_closed=1 reason=retained traces still carry layout-dependent identities")
    }
        } catch {
            FileHandle.standardError.write(Data("phase85cn_identity_failed=\(error)\n".utf8))
            exit(1)
        }
    }
}
