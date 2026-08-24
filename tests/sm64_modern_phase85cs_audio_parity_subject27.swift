import Foundation

private enum Phase85CSError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self { case .invalid(let message): return message }
    }
}

private let fullRecordCount = 476_365
private let expectedSequenceID: UInt64 = 0x12
private let expectedPCMRecords = 720
private let signOnWall: UInt64 = 0x58c5_c9f3_5461_4b2d
private let oneCoin: UInt64 = 0xc4e3_fcc9_26a6_842
private let floorTrapChild: UInt64 = 0xccb7_e7b3_ab11_7769
private let floorTrapParent: UInt64 = 0x0c68_8e3d_5e7a_403e
private let booInCastle: UInt64 = 0xa63b_55d3_bf9b_a914
private let paintingDeathWarp: UInt64 = 0xe534_2273_4eda_5e67
private let paintingStarCollectWarp: UInt64 = 0xc00b_59b8_8335_4537

private func read(_ path: String) throws -> (Data, SM64OracleTraceConfiguration, [SM64OracleTraceRecord]) {
    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
    let file = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
    return (data, file.configuration, file.records)
}

private func firstDifference(_ lhs: Data, _ rhs: Data) -> Int? {
    let limit = min(lhs.count, rhs.count)
    for offset in 0..<limit where lhs[offset] != rhs[offset] { return offset }
    return lhs.count == rhs.count ? nil : limit
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw Phase85CSError.invalid(message) }
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

private func validateRoute(_ records: [SM64OracleTraceRecord]) throws {
    try require(records.count == fullRecordCount, "unexpected full trace count \(records.count)")
    let sequence = records.filter { $0.domain == 9 && $0.recordKind == 3 && $0.recordID == 2 }
    let sequence12 = sequence.filter { $0.values.count >= 2 && $0.values[1] == expectedSequenceID }
    try require(sequence12.count == 1 && sequence12[0].simulationTick == 63,
                "sequence-12 route missing or moved")
    try require(sequence12[0].values == [1, expectedSequenceID, 0, 0, 0],
                "sequence-12 payload mismatch")

    let pcm = records.filter { $0.domain == 9 && $0.recordKind == 5 && $0.recordID == 5 }
    try require(pcm.count == expectedPCMRecords, "PCM record count mismatch \(pcm.count)")
    try require(pcm.allSatisfy {
        $0.values.count == 5 && $0.values[0] == 544 && $0.values[1] == 32_000
            && $0.values[2] == 2 && $0.values[3] == 1
    }, "PCM projection mismatch")

    let sign = record(records, domain: 12, kind: 4, subject: 11, id: 4, tick: 1)
    try require(sign?.values == [0, signOnWall, 0], "bhvSignOnWall mapping mismatch")
    for subject in 17...20 {
        let coin = record(records, domain: 12, kind: 4, subject: UInt64(subject), id: 4, tick: 1)
        try require(coin?.values == [0x74, oneCoin, 0], "bhvOneCoin subject-\(subject) mismatch")
    }
    for subject in [62, 63] {
        let child = record(records, domain: 12, kind: 4, subject: UInt64(subject), id: 4, tick: 1)
        try require(child?.values == [0x35, floorTrapChild, 0x3c],
                    "floor-trap child subject-\(subject) mismatch")
    }
    let parent = record(records, domain: 3, kind: 1, subject: 60, id: 400, tick: 1)
    try require(parent?.values == [floorTrapParent], "floor-trap parent mapping mismatch")
    let boo = record(records, domain: 12, kind: 4, subject: 54, id: 5, tick: 1)
    try require(boo?.values == [booInCastle], "bhvBooInCastle mapping mismatch")
    let painting = record(records, domain: 3, kind: 1, subject: 23, id: 400, tick: 1)
    try require(painting?.values == [paintingDeathWarp], "bhvPaintingDeathWarp mapping mismatch")
    for subject in 27...30 {
        let starWarp = record(records, domain: 3, kind: 1, subject: UInt64(subject), id: 400, tick: 1)
        try require(starWarp?.values == [paintingStarCollectWarp],
                    "bhvPaintingStarCollectWarp subject-\(subject) mapping mismatch")
    }
}

private func writeProjection(_ input: String, _ output: String) throws {
    let (_, configuration, records) = try read(input)
    try validateRoute(records)
    try SM64OracleTraceFile.write(
        configuration: configuration,
        records: records,
        to: URL(fileURLWithPath: output).standardizedFileURL
    )
    print("phase85cs_swift_projection_written=1 records=\(records.count)")
}

private func audit(_ paths: ArraySlice<String>) throws {
    guard paths.count == 5 else { throw Phase85CSError.invalid("audit requires five traces") }
    let values = try paths.map(read)
    try validateRoute(values[0].2)
    for index in 1..<values.count {
        try require(values[0].1 == values[index].1, "trace configuration mismatch at \(index)")
        if let offset = firstDifference(values[0].0, values[index].0) {
            throw Phase85CSError.invalid("full-trace divergence trace=\(index) offset=\(offset)")
        }
    }
    print("phase85cs_full_parity records=\(values[0].2.count) sequence12_tick=63 pcm_records=\(expectedPCMRecords) c_swift_asan_release_rerun_byte_match=1")
}

private func reject(_ path: String, _ errors: SM64OracleTraceCodecError...) throws {
    do {
        _ = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
        throw Phase85CSError.invalid("negative fence accepted \(path)")
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
    print("phase85cs_tamper_fence=1")
}

private func partial(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    try require(data.count > 72, "trace too short to truncate")
    data.removeLast()
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    try reject(output, .trailingBytes, .truncated)
    print("phase85cs_partial_fence=1")
}

@main
struct SM64ModernPhase85CSAudioParitySubject27 {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard let mode = arguments.first else { throw Phase85CSError.invalid("missing mode") }
            switch mode {
            case "write":
                guard arguments.count == 3 else { throw Phase85CSError.invalid("write requires C SWIFT") }
                try writeProjection(arguments[1], arguments[2])
            case "audit":
                try audit(arguments.dropFirst())
            case "tamper":
                guard arguments.count == 3 else { throw Phase85CSError.invalid("tamper requires input output") }
                try tamper(arguments[1], arguments[2])
            case "partial":
                guard arguments.count == 3 else { throw Phase85CSError.invalid("partial requires input output") }
                try partial(arguments[1], arguments[2])
            case "fixture":
                guard arguments.count == 3 else { throw Phase85CSError.invalid("fixture requires input marker") }
                defer { try? FileManager.default.removeItem(atPath: arguments[2]) }
                try Data("fixture_only=1\n".utf8).write(to: URL(fileURLWithPath: arguments[2]), options: .atomic)
                print("phase85cs_fixture_only_fence=1")
                throw Phase85CSError.invalid("fixture-only evidence rejected")
            case "single":
                guard arguments.count == 3 else { throw Phase85CSError.invalid("single requires two paths") }
                guard URL(fileURLWithPath: arguments[1]).standardizedFileURL == URL(fileURLWithPath: arguments[2]).standardizedFileURL else {
                    throw Phase85CSError.invalid("single-artifact fence did not reject distinct paths")
                }
                print("phase85cs_single_artifact_fence=1")
                throw Phase85CSError.invalid("single-artifact evidence rejected")
            default:
                throw Phase85CSError.invalid("unknown mode \(mode)")
            }
        } catch {
            FileHandle.standardError.write(Data("phase85cs_audio_parity_failed=\(error)\n".utf8))
            exit(1)
        }
    }
}
