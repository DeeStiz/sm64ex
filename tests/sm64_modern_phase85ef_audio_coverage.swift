import Darwin
import Foundation

private let sourcePath = "sound/sequences/us/12_event_high_score.m64"
private let sourceSHA256 = "2e0170f20353d6ba772af9df92f2d53e8b8d807e2b5bca24ac87bc022f08fade"
private let inputSeed = "0x014f93c6ae7e2e59"
private let saveSeed = "0x2a3582ec48614066"
private let shardID = "0x03345fc560c65b75"
private let expectedSequenceID: UInt64 = 0x12

private enum Phase85EFError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self { case let .invalid(message): return message }
    }
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw Phase85EFError.invalid(message) }
}

private func fnvString(_ value: String) -> UInt64 {
    var hash: UInt64 = 1_469_598_103_934_665_603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1_099_511_628_211
    }
    return hash
}

private func fnvU64(_ hash: UInt64, _ value: UInt64) -> UInt64 {
    var result = hash
    for byte in 0..<8 {
        result ^= (value >> UInt64(byte * 8)) & 0xff
        result &*= 1_099_511_628_211
    }
    return result
}

private func expectedAudioCoverageFingerprint() -> UInt64 {
    var hash: UInt64 = 1_469_598_103_934_665_603
    for recordID in [UInt64(1), UInt64(2), UInt64(3), UInt64(5)] {
        hash = fnvU64(hash, 9)
        hash = fnvU64(hash, 0)
        hash = fnvU64(hash, recordID)
    }
    return fnvU64(hash, 4)
}

private func read(_ path: String) throws -> (
    configuration: SM64OracleTraceConfiguration,
    records: [SM64OracleTraceRecord]
) {
    try SM64OracleTraceFile.read(from: URL(fileURLWithPath: path).standardizedFileURL)
}

private func audit(_ path: String) throws {
    let trace = try read(path)
    let expectedContent = fnvString("\(sourcePath)|sha256=\(sourceSHA256)")
    let expectedConfiguration = fnvString(
        "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
            + "input_seed=\(inputSeed);save_seed=\(saveSeed);shard=\(shardID);"
            + "asset=\(sourcePath);asset_sha256=\(sourceSHA256)"
    )
    try require(trace.configuration.mode == .record, "trace mode is not record")
    try require(trace.configuration.contentFingerprint == expectedContent, "content fingerprint mismatch")
    try require(trace.configuration.configurationFingerprint == expectedConfiguration, "configuration fingerprint mismatch")
    try require(trace.configuration.coverageFingerprint == expectedAudioCoverageFingerprint(), "audio coverage fingerprint mismatch")
    try require(!trace.records.isEmpty, "audio route has no records")

    let allowedKinds: Set<UInt32> = [3, 5]
    let allowedIDs: Set<UInt64> = [1, 2, 3, 4, 5]
    try require(trace.records.allSatisfy { $0.domain == 9 }, "audio-only trace contains unrelated domain")
    try require(trace.records.allSatisfy { allowedKinds.contains($0.recordKind) && allowedIDs.contains($0.recordID) }, "audio-only trace contains unrelated record")

    let sequenceRecords = trace.records.filter { $0.recordKind == 3 && $0.recordID == 2 }
    let assetRecords = sequenceRecords.filter { $0.values.count >= 2 && $0.values[1] == expectedSequenceID }
    let pcmRecords = trace.records.filter { $0.recordKind == 5 && $0.recordID == 5 }
    let observed = Set(trace.records.map { "\($0.recordKind):\($0.recordID)" })
    try require(Set(["3:1", "3:2", "3:3", "5:5"]).isSubset(of: observed), "audio inventory coverage records incomplete")
    try require(assetRecords.count == 1, "source sequence 12 record missing")
    try require(assetRecords[0].simulationTick == 63, "source sequence 12 tick changed")
    try require(assetRecords[0].values == [1, expectedSequenceID, 0, 0, 0], "source sequence 12 payload changed")
    try require(!pcmRecords.isEmpty, "audio PCM records missing")

    let ticks = Set(trace.records.map(\.simulationTick)).sorted()
    print(
        "phase85ef_audio_coverage_audit records=\(trace.records.count) "
            + "ticks=\(ticks.first ?? 0),\(ticks.last ?? 0) "
            + "sequence12_tick=\(assetRecords[0].simulationTick) "
            + "pcm_records=\(pcmRecords.count) coverage=0x"
            + String(trace.configuration.coverageFingerprint, radix: 16)
            + " audio_only=1 unrelated_domains=0"
    )
}

private func tamper(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    try require(data.count > 72 + SM64OracleTraceRecord.encodedSize, "trace too short to tamper")
    data[data.index(before: data.endIndex)] ^= 1
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    do {
        _ = try read(output)
        throw Phase85EFError.invalid("tampered trace accepted")
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("phase85ef_tamper_rejected=1")
    }
}

private func partial(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    try require(data.count > 72, "trace too short to truncate")
    data.removeLast()
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    do {
        _ = try read(output)
        throw Phase85EFError.invalid("partial trace accepted")
    } catch SM64OracleTraceCodecError.trailingBytes,
            SM64OracleTraceCodecError.truncated {
        print("phase85ef_partial_rejected=1")
    }
}

private func rejectSingleArtifact(_ first: String, _ second: String) throws {
    guard URL(fileURLWithPath: first).standardizedFileURL
            == URL(fileURLWithPath: second).standardizedFileURL else {
        return
    }
    print("phase85ef_single_artifact_rejected=1")
    Darwin.exit(1)
}

@main
struct SM64ModernPhase85EFAudioCoverage {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else { throw Phase85EFError.invalid("missing mode") }
        switch mode {
        case "audit":
            guard arguments.count == 2 else { throw Phase85EFError.invalid("audit requires trace") }
            try audit(arguments[1])
        case "tamper":
            guard arguments.count == 3 else { throw Phase85EFError.invalid("tamper requires input/output") }
            try tamper(arguments[1], arguments[2])
        case "partial":
            guard arguments.count == 3 else { throw Phase85EFError.invalid("partial requires input/output") }
            try partial(arguments[1], arguments[2])
        case "single":
            guard arguments.count == 3 else { throw Phase85EFError.invalid("single requires two traces") }
            try rejectSingleArtifact(arguments[1], arguments[2])
        default:
            throw Phase85EFError.invalid("unknown mode \(mode)")
        }
    }
}
