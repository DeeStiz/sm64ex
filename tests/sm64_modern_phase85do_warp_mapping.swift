import Foundation

private enum Phase85DOError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self {
        case .invalid(let message): return message
        }
    }
}

private let expectedFullRecordCount = 476_365
private let expectedSequenceID: UInt64 = 0x12
private let expectedPCMRecords = 720
private let expectedWarp: UInt64 = 0x2b00_6194_5882_01ff

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw Phase85DOError.invalid(message) }
}

private func fnv(_ value: String) -> UInt64 {
    value.utf8.reduce(SM64OracleTraceHash.offset) { partial, byte in
        (partial ^ UInt64(byte)) &* SM64OracleTraceHash.prime
    }
}

private func read(_ path: String) throws ->
    (Data, SM64OracleTraceConfiguration, [SM64OracleTraceRecord]) {
    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
    let file = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
    return (data, file.configuration, file.records)
}

private func record(
    _ records: [SM64OracleTraceRecord],
    domain: UInt32,
    kind: UInt32,
    subject: UInt64,
    id: UInt64,
    tick: UInt64
) -> SM64OracleTraceRecord? {
    records.first {
        $0.domain == domain && $0.recordKind == kind && $0.subjectID == subject
            && $0.recordID == id && $0.simulationTick == tick
    }
}

private func firstDifference(_ lhs: Data, _ rhs: Data) -> Int? {
    let limit = min(lhs.count, rhs.count)
    for offset in 0..<limit where lhs[offset] != rhs[offset] { return offset }
    return lhs.count == rhs.count ? nil : limit
}

private func sourceCheck() throws {
    let source = try String(contentsOfFile: "levels/castle_inside/script.c", encoding: .utf8)
    try require(
        source.contains(
            "OBJECT(/*model*/ MODEL_NONE, /*pos*/  1963,  819,  1280, "
                + "/*angle*/ 0,    0, 0, /*behParam*/ 0x050C0000, "
                + "/*beh*/ bhvWarp),"
        ),
        "subject-42 authored warp source entry missing"
    )

    let owner = try String(contentsOfFile: "src/pc/sm64_modern_gameplay_parity.c", encoding: .utf8)
    try require(
        owner.contains("SOURCE_BEHAVIOR_IDENTITY(bhvWarp)"),
        "warp semantic owner mapping missing"
    )
    try require(
        fnv("bhvWarp") == expectedWarp,
        "warp semantic FNV identity changed"
    )
}

private func validateRoute(_ records: [SM64OracleTraceRecord]) throws {
    try require(records.count == expectedFullRecordCount, "unexpected full trace count \(records.count)")

    let sequence = records.filter {
        $0.domain == 9 && $0.recordKind == 3 && $0.recordID == 2
    }
    let sequence12 = sequence.filter {
        $0.values.count >= 2 && $0.values[1] == expectedSequenceID
    }
    try require(
        sequence12.count == 1 && sequence12[0].simulationTick == 63
            && sequence12[0].values == [1, expectedSequenceID, 0, 0, 0],
        "sequence-12 route missing or moved"
    )

    let pcm = records.filter {
        $0.domain == 9 && $0.recordKind == 5 && $0.recordID == 5
    }
    try require(pcm.count == expectedPCMRecords, "PCM record count mismatch \(pcm.count)")
    try require(
        pcm.allSatisfy {
            $0.values.count == 5 && $0.values[0] == 544 && $0.values[1] == 32_000
                && $0.values[2] == 2 && $0.values[3] == 1
        },
        "PCM projection mismatch"
    )

    let subject42 = record(records, domain: 3, kind: 1, subject: 42, id: 400, tick: 1)
    try require(
        subject42?.values == [expectedWarp],
        "subject-42 warp semantic identity mismatch"
    )
    let subject42Position = record(records, domain: 3, kind: 1, subject: 42, id: 405, tick: 1)
    try require(
        subject42Position?.values == [0x44f5_6000, 0x444c_c000, 0x44a0_0000],
        "subject-42 authored position provenance missing"
    )
}

private func project(_ input: String, _ output: String) throws {
    try sourceCheck()
    let (_, configuration, records) = try read(input)
    try validateRoute(records)
    try SM64OracleTraceFile.write(
        configuration: configuration,
        records: records,
        to: URL(fileURLWithPath: output).standardizedFileURL
    )
    print("phase85do_swift_projection_written=1 records=\(records.count)")
}

private func audit(_ paths: ArraySlice<String>) throws {
    try sourceCheck()
    try require(paths.count == 5, "audit requires five traces")
    let values = try paths.map(read)
    try validateRoute(values[0].2)
    for index in 1..<values.count {
        try require(values[0].1 == values[index].1, "trace configuration mismatch at \(index)")
        if let offset = firstDifference(values[0].0, values[index].0) {
            let recordIndex = offset >= 72
                ? (offset - 72) / SM64OracleTraceRecord.encodedSize : -1
            let recordOffset = offset >= 72
                ? (offset - 72) % SM64OracleTraceRecord.encodedSize : -1
            let differingRecord = recordIndex >= 0 && recordIndex < values[0].2.count
                ? values[0].2[recordIndex] : nil
            let detail = differingRecord.map {
                " tick=\($0.simulationTick) domain=\($0.domain) kind=\($0.recordKind)"
                    + " subject=\($0.subjectID) id=\($0.recordID)"
            } ?? ""
            throw Phase85DOError.invalid(
                "full-trace divergence trace=\(index) offset=\(offset) "
                    + "record=\(recordIndex) record_offset=\(recordOffset)\(detail)"
            )
        }
    }
    print(
        "phase85do_full_parity records=\(values[0].2.count) sequence12_tick=63 "
            + "pcm_records=\(expectedPCMRecords) warp_identity=0x"
            + String(expectedWarp, radix: 16)
            + " c_swift_asan_release_rerun_byte_match=1"
    )
}

private func reject(_ path: String, _ expected: SM64OracleTraceCodecError...) throws {
    do {
        _ = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
        throw Phase85DOError.invalid("negative fence accepted \(path)")
    } catch let error as SM64OracleTraceCodecError {
        try require(expected.contains(error), "unexpected negative-fence error \(error)")
    }
}

private func tamper(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    try require(data.count > 72 + SM64OracleTraceRecord.encodedSize, "trace too short to tamper")
    data[72 + 56] ^= 1
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    try reject(output, .nonCanonicalHash)
    print("phase85do_tamper_fence=1")
}

private func partial(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    try require(data.count > 72, "trace too short to truncate")
    data.removeLast()
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    try reject(output, .trailingBytes, .truncated)
    print("phase85do_partial_fence=1")
}

@main
struct SM64ModernPhase85DOWarpMapping {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard let mode = arguments.first else {
                throw Phase85DOError.invalid(
                    "usage: write C SWIFT | audit C SWIFT ASAN RELEASE RERUN | "
                        + "tamper C OUT | partial C OUT | fixture C MARKER | single A B"
                )
            }
            switch mode {
            case "write":
                try require(arguments.count == 3, "write requires C SWIFT")
                try project(arguments[1], arguments[2])
            case "audit":
                try audit(arguments.dropFirst())
            case "tamper":
                try require(arguments.count == 3, "tamper requires input output")
                try tamper(arguments[1], arguments[2])
            case "partial":
                try require(arguments.count == 3, "partial requires input output")
                try partial(arguments[1], arguments[2])
            case "fixture":
                try require(arguments.count == 3, "fixture requires input marker")
                defer { try? FileManager.default.removeItem(atPath: arguments[2]) }
                try Data("fixture_only=1\n".utf8).write(
                    to: URL(fileURLWithPath: arguments[2]), options: .atomic
                )
                print("phase85do_fixture_only_fence=1")
                throw Phase85DOError.invalid("fixture-only evidence rejected")
            case "single":
                try require(arguments.count == 3, "single requires two paths")
                print("phase85do_single_artifact_fence=1")
                throw Phase85DOError.invalid("single-artifact evidence rejected")
            default:
                throw Phase85DOError.invalid("unknown mode \(mode)")
            }
        } catch {
            FileHandle.standardError.write(
                Data("phase85do_warp_mapping_failed=\(error)\n".utf8)
            )
            exit(1)
        }
    }
}
