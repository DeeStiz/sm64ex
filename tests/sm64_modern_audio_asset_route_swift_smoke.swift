import Darwin
import Foundation

private let sourcePath = "sound/sequences/us/12_event_high_score.m64"
private let sourceSHA256 = "2e0170f20353d6ba772af9df92f2d53e8b8d807e2b5bca24ac87bc022f08fade"
private let inputSeed = "0x014f93c6ae7e2e59"
private let saveSeed = "0x2a3582ec48614066"
private let shardID = "0x03345fc560c65b75"
private let assetSequenceID: UInt64 = 0x12
private let audioDomain: UInt32 = 9
private let audioEventKind: UInt32 = 3
private let audioPCMKind: UInt32 = 5
private let audioSequenceRecordID: UInt64 = 2
private let audioPCMRecordID: UInt64 = 5

private func fnvString(_ value: String) -> UInt64 {
    var hash: UInt64 = 1_469_598_103_934_665_603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1_099_511_628_211
    }
    return hash
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
    guard trace.configuration.mode == .record,
          trace.configuration.contentFingerprint == expectedContent,
          trace.configuration.configurationFingerprint == expectedConfiguration,
          !trace.records.isEmpty else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    let sequenceRecords = trace.records.filter {
        $0.domain == audioDomain
            && $0.recordKind == audioEventKind
            && $0.recordID == audioSequenceRecordID
    }
    let pcmRecords = trace.records.filter {
        $0.domain == audioDomain
            && $0.recordKind == audioPCMKind
            && $0.recordID == audioPCMRecordID
    }
    let assetRecords = sequenceRecords.filter {
        $0.values.count >= 2 && $0.values[1] == assetSequenceID
    }
    let ticks = Set(trace.records.map(\.simulationTick)).sorted()
    guard !pcmRecords.isEmpty, assetRecords.isEmpty else {
        throw SM64OracleTraceCodecError.invalidHeader
    }
    print(
        "audio_asset_route_swift_audit records=\(trace.records.count) "
            + "ticks=\(ticks.first ?? 0),\(ticks.last ?? 0) "
            + "audio_sequence=\(sequenceRecords.count) "
            + "audio_pcm=\(pcmRecords.count) sequence12=\(assetRecords.count) "
            + "source_identity_header=1 pair_deferred=1"
    )
}

private func tamper(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    guard data.count > 72 + SM64OracleTraceRecord.encodedSize else {
        throw SM64OracleTraceCodecError.truncated
    }
    data[data.index(before: data.endIndex)] ^= 1
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    do {
        _ = try read(output)
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.nonCanonicalHash {
        print("audio_asset_route_swift_tamper_rejected=1")
    }
}

private func partial(_ input: String, _ output: String) throws {
    var data = try Data(contentsOf: URL(fileURLWithPath: input))
    guard data.count > 72 else { throw SM64OracleTraceCodecError.truncated }
    data.removeLast()
    try data.write(to: URL(fileURLWithPath: output), options: .atomic)
    do {
        _ = try read(output)
        throw SM64OracleTraceCodecError.invalidHeader
    } catch SM64OracleTraceCodecError.trailingBytes,
            SM64OracleTraceCodecError.truncated {
        print("audio_asset_route_swift_partial_rejected=1")
    }
}

private func rejectSingleArtifact(_ first: String, _ second: String) throws {
    guard URL(fileURLWithPath: first).standardizedFileURL
            != URL(fileURLWithPath: second).standardizedFileURL else {
        print("audio_asset_route_single_artifact_rejected=1")
        Darwin.exit(1)
    }
}

@main
struct SM64ModernAudioAssetRouteSwiftSmoke {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let mode = arguments.first else {
            throw SM64OracleTraceCodecError.truncated
        }
        switch mode {
        case "audit":
            guard arguments.count == 2 else {
                throw SM64OracleTraceCodecError.truncated
            }
            try audit(arguments[1])
        case "tamper":
            guard arguments.count == 3 else {
                throw SM64OracleTraceCodecError.truncated
            }
            try tamper(arguments[1], arguments[2])
        case "partial":
            guard arguments.count == 3 else {
                throw SM64OracleTraceCodecError.truncated
            }
            try partial(arguments[1], arguments[2])
        case "single":
            guard arguments.count == 3 else {
                throw SM64OracleTraceCodecError.truncated
            }
            try rejectSingleArtifact(arguments[1], arguments[2])
        default:
            throw SM64OracleTraceCodecError.truncated
        }
    }
}
