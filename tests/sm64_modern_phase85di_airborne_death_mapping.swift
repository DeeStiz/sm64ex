import Foundation

private enum Phase85DIError: Error, CustomStringConvertible {
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
private let expectedAirborneDeathWarp: UInt64 = 0x53e0_13ea_7d7c_c8b5

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw Phase85DIError.invalid(message) }
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
            "OBJECT(/*model*/ MODEL_NONE, /*pos*/ -1024,  900,   717, "
                + "/*angle*/ 0,  180, 0, /*behParam*/ 0x00210000, "
                + "/*beh*/ bhvAirborneDeathWarp),"
        ),
        "authored airborne-death source entry missing"
    )
    try require(
        source.contains(
            "OBJECT(/*model*/ MODEL_NONE, /*pos*/ -1024,  900,   717, "
                + "/*angle*/ 0,  180, 0, /*behParam*/ 0x00200000, "
                + "/*beh*/ bhvAirborneWarp),"
        ),
        "adjacent airborne source entry missing"
    )
    try require(
        source.contains(
            "OBJECT(/*model*/ MODEL_NONE, /*pos*/ -1024,  900,   717, "
                + "/*angle*/ 0,  180, 0, /*behParam*/ 0x00220000, "
                + "/*beh*/ bhvHardAirKnockBackWarp),"
        ),
        "adjacent hard-air source entry missing"
    )

    let owner = try String(contentsOfFile: "src/pc/sm64_modern_gameplay_parity.c", encoding: .utf8)
    try require(
        owner.contains("SOURCE_BEHAVIOR_IDENTITY(bhvAirborneDeathWarp)"),
        "airborne-death semantic owner mapping missing"
    )
    try require(
        fnv("bhvAirborneDeathWarp") == expectedAirborneDeathWarp,
        "airborne-death semantic FNV identity changed"
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

    let airborneDeath = record(records, domain: 3, kind: 1, subject: 38, id: 400, tick: 1)
    try require(
        airborneDeath?.values == [expectedAirborneDeathWarp],
        "subject-38 airborne-death semantic identity mismatch"
    )
    let airborneDeathYaw = record(records, domain: 3, kind: 1, subject: 38, id: 407, tick: 1)
    try require(
        airborneDeathYaw?.values == [0, 0xffff_8000, 0],
        "subject-38 airborne-death yaw provenance missing"
    )
}

private func requireInvalid(_ path: String, _ expected: SM64OracleTraceCodecError...) throws {
    do {
        _ = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
        throw Phase85DIError.invalid("negative fence accepted \(path)")
    } catch let error as SM64OracleTraceCodecError {
        try require(expected.contains(error), "unexpected negative-fence error \(error)")
    }
}

private func tamper(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    try require(data.count > 72 + SM64OracleTraceRecord.encodedSize, "trace too short to tamper")
    data[72 + 56] ^= 1
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    try requireInvalid(output, .nonCanonicalHash)
    print("phase85di_tamper_fence=1")
}

private func partial(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    try require(data.count > 72, "trace too short to truncate")
    data.removeLast()
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    try requireInvalid(output, .trailingBytes, .truncated)
    print("phase85di_partial_fence=1")
}

private func fixture(_ trace: String, _ marker: String) throws {
    try Data("fixture_only=1\n".utf8).write(
        to: URL(fileURLWithPath: marker), options: .atomic
    )
    defer { try? FileManager.default.removeItem(atPath: marker) }
    try require(FileManager.default.fileExists(atPath: trace), "fixture trace missing")
    print("phase85di_fixture_only_fence=1")
    throw Phase85DIError.invalid("fixture-only evidence rejected")
}

@main
struct SM64ModernPhase85DIAirborneDeathMapping {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard let mode = arguments.first else {
                throw Phase85DIError.invalid(
                    "usage: write C SWIFT | audit C SWIFT ASAN RELEASE RERUN | "
                        + "tamper C OUT | partial C OUT | fixture C MARKER | single A B"
                )
            }
            switch mode {
            case "write":
                try require(arguments.count == 3, "write requires C SWIFT")
                let c = try read(arguments[1])
                try sourceCheck()
                try validateRoute(c.2)
                try SM64OracleTraceFile.write(
                    configuration: c.1,
                    records: c.2,
                    to: URL(fileURLWithPath: arguments[2]).standardizedFileURL
                )
                print("phase85di_swift_projection_written=1 records=\(c.2.count)")
            case "audit":
                try require(arguments.count == 6, "audit requires C SWIFT ASAN RELEASE RERUN")
                try sourceCheck()
                let values = try arguments.dropFirst().map(read)
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
                        throw Phase85DIError.invalid(
                            "full-trace divergence trace=\(index) offset=\(offset) "
                                + "record=\(recordIndex) record_offset=\(recordOffset)\(detail)"
                        )
                    }
                }
                print(
                    "phase85di_full_parity records=\(values[0].2.count) sequence12_tick=63 "
                        + "pcm_records=\(expectedPCMRecords) airborne_death_identity=0x"
                        + String(expectedAirborneDeathWarp, radix: 16)
                        + " c_swift_asan_release_rerun_byte_match=1"
                )
            case "tamper":
                try require(arguments.count == 3, "tamper requires C OUT")
                try tamper(arguments[1], arguments[2])
            case "partial":
                try require(arguments.count == 3, "partial requires C OUT")
                try partial(arguments[1], arguments[2])
            case "fixture":
                try require(arguments.count == 3, "fixture requires C MARKER")
                try fixture(arguments[1], arguments[2])
            case "single":
                try require(arguments.count == 3, "single requires two paths")
                print("phase85di_single_artifact_fence=1")
                throw Phase85DIError.invalid("single-artifact evidence rejected")
            default:
                throw Phase85DIError.invalid("unknown mode \(mode)")
            }
        } catch {
            FileHandle.standardError.write(
                Data("phase85di_airborne_death_mapping_failed=\(error)\n".utf8)
            )
            exit(1)
        }
    }
}
