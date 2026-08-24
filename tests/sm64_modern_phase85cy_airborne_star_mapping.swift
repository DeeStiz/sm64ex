import Foundation

private enum Phase85CYError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self {
        case .invalid(let message): return message
        }
    }
}

private let fullRecordCount = 476_365
private let expectedSequenceID: UInt64 = 0x12
private let expectedPCMRecords = 720
private let expectedDeathWarp: UInt64 = 0xa22b_7ff1_6730_e047
private let expectedAirborneStarCollectWarp: UInt64 = 0xa855_1039_4290_b349

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw Phase85CYError.invalid(message) }
}

private func fnv(_ value: String) -> UInt64 {
    value.utf8.reduce(SM64OracleTraceHash.offset) { partial, byte in
        (partial ^ UInt64(byte)) &* SM64OracleTraceHash.prime
    }
}

private func read(_ path: String) throws -> (Data, SM64OracleTraceConfiguration, [SM64OracleTraceRecord]) {
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
            "OBJECT(/*model*/ MODEL_NONE, /*pos*/  2816, 1200,  -256, "
                + "/*angle*/ 0,   90, 0, /*behParam*/ 0x00270000, "
                + "/*beh*/ bhvAirborneStarCollectWarp),"
        ),
        "authored 90-degree airborne-star source entry missing"
    )
    try require(
        source.contains(
            "OBJECT(/*model*/ MODEL_NONE, /*pos*/  2816, 1200,  -256, "
                + "/*angle*/ 0,  270, 0, /*behParam*/ 0x00280000, "
                + "/*beh*/ bhvDeathWarp),"
        ),
        "adjacent 270-degree death-warp source entry missing"
    )

    let owner = try String(contentsOfFile: "src/pc/sm64_modern_gameplay_parity.c", encoding: .utf8)
    try require(
        owner.contains("SOURCE_BEHAVIOR_IDENTITY(bhvAirborneStarCollectWarp)"),
        "airborne-star semantic owner mapping missing"
    )
    try require(
        fnv("bhvAirborneStarCollectWarp") == expectedAirborneStarCollectWarp,
        "airborne-star semantic FNV identity changed"
    )
}

private func validateRoute(_ records: [SM64OracleTraceRecord]) throws {
    try require(records.count == fullRecordCount, "unexpected full trace count \(records.count)")
    let sequence = records.filter { $0.domain == 9 && $0.recordKind == 3 && $0.recordID == 2 }
    let sequence12 = sequence.filter { $0.values.count >= 2 && $0.values[1] == expectedSequenceID }
    try require(
        sequence12.count == 1 && sequence12[0].simulationTick == 63
            && sequence12[0].values == [1, expectedSequenceID, 0, 0, 0],
        "sequence-12 route missing or moved"
    )

    let pcm = records.filter { $0.domain == 9 && $0.recordKind == 5 && $0.recordID == 5 }
    try require(pcm.count == expectedPCMRecords, "PCM record count mismatch \(pcm.count)")
    try require(
        pcm.allSatisfy {
            $0.values.count == 5 && $0.values[0] == 544 && $0.values[1] == 32_000
                && $0.values[2] == 2 && $0.values[3] == 1
        },
        "PCM projection mismatch"
    )

    let deathWarp = record(records, domain: 3, kind: 1, subject: 31, id: 400, tick: 1)
    try require(deathWarp?.values == [expectedDeathWarp], "subject-31 death-warp mapping regressed")
    let airborne = record(records, domain: 3, kind: 1, subject: 32, id: 400, tick: 1)
    try require(
        airborne?.values == [expectedAirborneStarCollectWarp],
        "subject-32 airborne-star mapping mismatch"
    )
    let airborneYaw = record(records, domain: 3, kind: 1, subject: 32, id: 407, tick: 1)
    try require(
        airborneYaw?.values == [0, 0x0000_4000, 0],
        "subject-32 90-degree yaw provenance missing"
    )
    let deathYaw = record(records, domain: 3, kind: 1, subject: 31, id: 407, tick: 1)
    try require(
        deathYaw?.values == [0, 0xffff_c000, 0],
        "subject-31 270-degree yaw provenance missing"
    )
}

private func writeProjection(_ input: String, _ output: String) throws {
    try sourceCheck()
    let (_, configuration, records) = try read(input)
    try validateRoute(records)
    try SM64OracleTraceFile.write(
        configuration: configuration,
        records: records,
        to: URL(fileURLWithPath: output).standardizedFileURL
    )
    print("phase85cy_swift_projection_written=1 records=\(records.count)")
}

private func audit(_ paths: ArraySlice<String>) throws {
    try sourceCheck()
    guard paths.count == 5 else { throw Phase85CYError.invalid("audit requires five traces") }
    let values = try paths.map(read)
    try validateRoute(values[0].2)
    for index in 1..<values.count {
        try require(values[0].1 == values[index].1, "trace configuration mismatch at \(index)")
        if let offset = firstDifference(values[0].0, values[index].0) {
            let recordIndex = offset >= 72 ? (offset - 72) / SM64OracleTraceRecord.encodedSize : -1
            let recordOffset = offset >= 72 ? (offset - 72) % SM64OracleTraceRecord.encodedSize : -1
            throw Phase85CYError.invalid(
                "full-trace divergence trace=\(index) offset=\(offset) "
                    + "record=\(recordIndex) record_offset=\(recordOffset)"
            )
        }
    }
    print(
        "phase85cy_full_parity records=\(values[0].2.count) sequence12_tick=63 "
            + "pcm_records=\(expectedPCMRecords) c_swift_asan_release_rerun_byte_match=1"
    )
}

private func reject(_ path: String, _ errors: SM64OracleTraceCodecError...) throws {
    do {
        _ = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
        throw Phase85CYError.invalid("negative fence accepted \(path)")
    } catch let error as SM64OracleTraceCodecError {
        try require(errors.contains(error), "unexpected negative-fence error \(error)")
    }
}

private func tamper(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    try require(data.count > 72 + SM64OracleTraceRecord.encodedSize, "trace too short to tamper")
    data[72 + 56] ^= 1
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    try reject(output, .nonCanonicalHash)
    print("phase85cy_tamper_fence=1")
}

private func partial(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    try require(data.count > 72, "trace too short to truncate")
    data.removeLast()
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    try reject(output, .trailingBytes, .truncated)
    print("phase85cy_partial_fence=1")
}

@main
struct SM64ModernPhase85CYAirborneStarMapping {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard let mode = arguments.first else { throw Phase85CYError.invalid("missing mode") }
            switch mode {
            case "write":
                guard arguments.count == 3 else { throw Phase85CYError.invalid("write requires C SWIFT") }
                try writeProjection(arguments[1], arguments[2])
            case "audit":
                try audit(arguments.dropFirst())
            case "tamper":
                guard arguments.count == 3 else { throw Phase85CYError.invalid("tamper requires input output") }
                try tamper(arguments[1], arguments[2])
            case "partial":
                guard arguments.count == 3 else { throw Phase85CYError.invalid("partial requires input output") }
                try partial(arguments[1], arguments[2])
            case "fixture":
                guard arguments.count == 3 else { throw Phase85CYError.invalid("fixture requires input marker") }
                defer { try? FileManager.default.removeItem(atPath: arguments[2]) }
                try Data("fixture_only=1\n".utf8).write(to: URL(fileURLWithPath: arguments[2]), options: .atomic)
                print("phase85cy_fixture_only_fence=1")
                throw Phase85CYError.invalid("fixture-only evidence rejected")
            case "single":
                guard arguments.count == 3 else { throw Phase85CYError.invalid("single requires two paths") }
                guard URL(fileURLWithPath: arguments[1]).standardizedFileURL == URL(fileURLWithPath: arguments[2]).standardizedFileURL else {
                    throw Phase85CYError.invalid("single-artifact fence did not reject distinct paths")
                }
                print("phase85cy_single_artifact_fence=1")
                throw Phase85CYError.invalid("single-artifact evidence rejected")
            default:
                throw Phase85CYError.invalid("unknown mode \(mode)")
            }
        } catch {
            FileHandle.standardError.write(Data("phase85cy_airborne_star_mapping_failed=\(error)\n".utf8))
            exit(1)
        }
    }
}
