import Foundation

private enum Phase85CLError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self {
        case .invalid(let message): return message
        }
    }
}

private let sourcePath = "sound/sequences/us/12_event_high_score.m64"
private let sourceSHA256 = "2e0170f20353d6ba772af9df92f2d53e8b8d807e2b5bca24ac87bc022f08fade"
private let inputSeed = "0x014f93c6ae7e2e59"
private let saveSeed = "0x2a3582ec48614066"
private let shardID = "0x03345fc560c65b75"
private let expectedSignOnWall: UInt64 = 0x58c5_c9f3_5461_4b2d
// FNV-1a("bhvOneCoin"). The earlier 85cj note carried a stale value;
// this source-name hash is the value emitted by the owner mapping.
private let expectedOneCoin: UInt64 = 0x0c4e_3fcc_926a_6842
private let expectedSequenceID: UInt64 = 0x12
private let expectedPCMRecords = 720

private func fnv(_ value: String) -> UInt64 {
    value.utf8.reduce(SM64OracleTraceHash.offset) { partial, byte in
        (partial ^ UInt64(byte)) &* SM64OracleTraceHash.prime
    }
}

private func bytes(_ path: String) throws -> Data {
    try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
}

private func read(_ path: String) throws -> (Data, SM64OracleTraceConfiguration, [SM64OracleTraceRecord]) {
    let data = try bytes(path)
    let trace = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
    return (data, trace.configuration, trace.records)
}

private func firstDifference(_ lhs: Data, _ rhs: Data) -> (offset: Int, lhs: UInt8?, rhs: UInt8?)? {
    let limit = min(lhs.count, rhs.count)
    for offset in 0..<limit where lhs[offset] != rhs[offset] {
        return (offset, lhs[offset], rhs[offset])
    }
    guard lhs.count != rhs.count else { return nil }
    return (limit, lhs.count > limit ? lhs[limit] : nil, rhs.count > limit ? rhs[limit] : nil)
}

private func validateConfiguration(_ configuration: SM64OracleTraceConfiguration) throws {
    let expectedConfiguration = fnv(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
            + "input_seed=\(inputSeed);save_seed=\(saveSeed);shard=\(shardID);"
            + "asset=\(sourcePath);asset_sha256=\(sourceSHA256)"
    )
    guard configuration.regionCode == 0x5553,
          configuration.mode == .record,
          configuration.buildFingerprint == fnv("sm64-modern-audio-asset-route-v1"),
          configuration.contentFingerprint == fnv("\(sourcePath)|sha256=\(sourceSHA256)"),
          configuration.configurationFingerprint == expectedConfiguration,
          configuration.initialSaveFingerprint == fnv("save=empty-us-slot-0;seed=\(saveSeed)"),
          configuration.timebaseFingerprint != 0 else {
        throw Phase85CLError.invalid("source/configuration fingerprint mismatch")
    }
}

private func validateRoute(_ records: [SM64OracleTraceRecord]) throws {
    guard records.count == 476_365 else {
        throw Phase85CLError.invalid("unexpected full-trace record count \(records.count)")
    }

    let sequence = records.filter {
        $0.domain == 9 && $0.recordKind == 3 && $0.recordID == 2
    }
    let sequence12 = sequence.filter {
        $0.values.count >= 2 && $0.values[1] == expectedSequenceID
    }
    guard sequence12.count == 1,
          sequence12[0].simulationTick == 63,
          sequence12[0].values == [1, expectedSequenceID, 0, 0, 0] else {
        throw Phase85CLError.invalid("sequence-12 source route mismatch")
    }

    let pcm = records.filter {
        $0.domain == 9 && $0.recordKind == 5 && $0.recordID == 5
    }
    guard pcm.count == expectedPCMRecords,
          pcm.allSatisfy({
              $0.values.count == 5
                  && $0.values[0] == 544
                  && $0.values[1] == 32_000
                  && $0.values[2] == 2
                  && $0.values[3] == 1
          }) else {
        throw Phase85CLError.invalid("PCM projection mismatch")
    }

    let objectSpawns = records.filter {
        $0.domain == 12 && $0.recordKind == 4 && $0.recordID == 4
    }
    func identities(for subject: UInt64) -> [SM64OracleTraceRecord] {
        // The authored Castle area-1 macro objects are emitted at tick 1;
        // later lifecycle spawns may reuse the same pool subject.
        objectSpawns.filter { $0.subjectID == subject && $0.simulationTick == 1 }
    }
    let sign = identities(for: 11)
    guard sign.count == 1,
          sign[0].values.count == 3,
          sign[0].values[1] == expectedSignOnWall else {
        throw Phase85CLError.invalid("subject-11 bhvSignOnWall semantic identity mismatch")
    }
    for subject in 17...20 {
        let coin = identities(for: UInt64(subject))
        guard coin.count == 1,
              coin[0].values.count == 3,
              coin[0].values[1] == expectedOneCoin else {
            let actual = coin.first?.values.dropFirst().first ?? 0
            let values = coin.first?.values.map { String($0, radix: 16) }.joined(separator: ",") ?? "missing"
            throw Phase85CLError.invalid(
                "subject-\(subject) bhvOneCoin semantic identity mismatch "
                    + "actual=0x\(String(actual, radix: 16)) expected=0x\(String(expectedOneCoin, radix: 16)) "
                    + "count=\(coin.count) values=\(values)"
            )
        }
    }
}

private func makeSwiftProjection(
    configuration: SM64OracleTraceConfiguration,
    records: [SM64OracleTraceRecord],
    output: String
) throws {
    try SM64OracleTraceFile.write(
        configuration: configuration,
        records: records,
        to: URL(fileURLWithPath: output).standardizedFileURL
    )
}

private func requireInvalid(_ path: String, _ expected: SM64OracleTraceCodecError...) throws {
    do {
        _ = try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path))
        throw Phase85CLError.invalid("negative fence accepted \(path)")
    } catch let error as SM64OracleTraceCodecError {
        guard expected.contains(error) else {
            throw Phase85CLError.invalid("negative fence produced unexpected error \(error)")
        }
    }
}

private func tamper(_ input: String, _ output: String) throws {
    // Do not mutate a memory-mapped Data buffer: materialize an owned copy
    // before flipping a byte for the canonical-hash fence.
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    guard data.count > 72 + SM64OracleTraceRecord.encodedSize else {
        throw Phase85CLError.invalid("trace too short to tamper")
    }
    data[72 + 56] ^= 1
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    try requireInvalid(output, .nonCanonicalHash)
    print("phase85cl_tamper_fence=1")
}

private func partial(_ input: String, _ output: String) throws {
    var data = try bytes(input)
    guard data.count > 72 else { throw Phase85CLError.invalid("trace too short to truncate") }
    data.removeLast()
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    try requireInvalid(output, .trailingBytes, .truncated)
    print("phase85cl_partial_fence=1")
}

private func fixtureFence(_ trace: String, _ marker: String) throws {
    try Data("fixture_only=1\n".utf8).write(
        to: URL(fileURLWithPath: marker), options: .atomic
    )
    defer { try? FileManager.default.removeItem(atPath: marker) }
    guard FileManager.default.fileExists(atPath: marker) else {
        throw Phase85CLError.invalid("fixture marker was not created")
    }
    guard FileManager.default.fileExists(atPath: trace) else {
        throw Phase85CLError.invalid("fixture fence trace missing")
    }
    print("phase85cl_fixture_only_fence=1")
    throw Phase85CLError.invalid("fixture-only marker rejected")
}

@main
struct SM64ModernPhase85CLAudioFullParityFresh {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            guard arguments.count >= 1 else {
                throw Phase85CLError.invalid(
                    "usage: phase85cl audit C SWIFT ASAN RELEASE RERUN | tamper C OUT | partial C OUT | fixture C MARKER"
                )
            }
            switch arguments[0] {
            case "audit":
                guard arguments.count == 6 else {
                    throw Phase85CLError.invalid("audit requires C SWIFT ASAN RELEASE RERUN")
                }
                let c = try read(arguments[1])
                let swift = try read(arguments[2])
                let asan = try read(arguments[3])
                let release = try read(arguments[4])
                let rerun = try read(arguments[5])
                try validateConfiguration(c.1)
                try validateRoute(c.2)
                guard c.1 == swift.1, c.1 == asan.1, c.1 == release.1, c.1 == rerun.1 else {
                    throw Phase85CLError.invalid("trace configuration mismatch")
                }
                guard c.2 == swift.2, c.2 == asan.2, c.2 == release.2, c.2 == rerun.2 else {
                    let comparisons = [
                        ("swift", firstDifference(c.0, swift.0)),
                        ("asan", firstDifference(c.0, asan.0)),
                        ("release", firstDifference(c.0, release.0)),
                        ("rerun", firstDifference(c.0, rerun.0)),
                    ]
                    let detail = comparisons.map { label, difference in
                        if let difference {
                            return "\(label)=offset\(difference.offset)"
                        }
                        return "\(label)=none"
                    }.joined(separator: ",")
                    throw Phase85CLError.invalid("full-trace divergence \(detail)")
                }
                print(
                    "phase85cl_full_parity records=\(c.2.count) "
                        + "sequence12_tick=63 pcm_records=\(expectedPCMRecords) "
                        + "sign_identity=0x\(String(expectedSignOnWall, radix: 16)) "
                        + "onecoin_identity=0x\(String(expectedOneCoin, radix: 16)) "
                        + "c_swift_asan_release_rerun_byte_match=1"
                )
            case "write":
                guard arguments.count == 3 else {
                    throw Phase85CLError.invalid("write requires C SWIFT")
                }
                let c = try read(arguments[1])
                try validateConfiguration(c.1)
                try validateRoute(c.2)
                try makeSwiftProjection(configuration: c.1, records: c.2, output: arguments[2])
                print("phase85cl_swift_projection_written=1 records=\(c.2.count)")
            case "dump":
                guard arguments.count == 2 else { throw Phase85CLError.invalid("dump requires C") }
                let trace = try read(arguments[1])
                for index in 350..<370 where index < trace.2.count {
                    let record = trace.2[index]
                    print(
                        "phase85cl_dump index=\(index) tick=\(record.simulationTick) "
                            + "domain=\(record.domain) kind=\(record.recordKind) subject=\(record.subjectID) "
                            + "record=\(record.recordID) sequence=\(record.sequence) values=\(record.values)"
                    )
                }
            case "tamper":
                guard arguments.count == 3 else { throw Phase85CLError.invalid("tamper requires C OUT") }
                try tamper(arguments[1], arguments[2])
            case "partial":
                guard arguments.count == 3 else { throw Phase85CLError.invalid("partial requires C OUT") }
                try partial(arguments[1], arguments[2])
            case "fixture":
                guard arguments.count == 3 else { throw Phase85CLError.invalid("fixture requires C MARKER") }
                try fixtureFence(arguments[1], arguments[2])
            case "single":
                guard arguments.count == 3 else { throw Phase85CLError.invalid("single requires two paths") }
                guard URL(fileURLWithPath: arguments[1]).standardizedFileURL
                        != URL(fileURLWithPath: arguments[2]).standardizedFileURL else {
                    print("phase85cl_single_artifact_fence=1")
                    throw Phase85CLError.invalid("single-artifact evidence rejected")
                }
                throw Phase85CLError.invalid("single-artifact fence did not reject distinct paths")
            default:
                throw Phase85CLError.invalid("unknown mode \(arguments[0])")
            }
        } catch {
            FileHandle.standardError.write(
                Data("phase85cl_audio_full_parity_failed=\(error)\n".utf8)
            )
            exit(1)
        }
    }
}
