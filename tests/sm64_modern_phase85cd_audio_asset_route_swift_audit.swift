import Foundation

private let sourcePath = "sound/sequences/us/12_event_high_score.m64"
private let sourceSHA256 = "2e0170f20353d6ba772af9df92f2d53e8b8d807e2b5bca24ac87bc022f08fade"
private let inputSeed = "0x014f93c6ae7e2e59"
private let saveSeed = "0x2a3582ec48614066"
private let shardID = "0x03345fc560c65b75"
private let sequenceID: UInt64 = 0x12
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

@main
struct SM64ModernPhase85CDAudioAssetRouteSwiftAudit {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw SM64OracleTraceCodecError.truncated
        }
        let trace = try SM64OracleTraceFile.read(
            from: URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        )
        let expectedContent = fnvString("\(sourcePath)|sha256=\(sourceSHA256)")
        let expectedConfiguration = fnvString(
            "region=5553;fullscreen=off;skip_intro=1;native_tick=1;legacy_tick=1;"
                + "input_seed=\(inputSeed);save_seed=\(saveSeed);"
                + "shard=\(shardID);asset=\(sourcePath);asset_sha256=\(sourceSHA256)"
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
            $0.values.count >= 2 && $0.values[1] == sequenceID
        }
        guard assetRecords.count == 1, !pcmRecords.isEmpty else {
            throw SM64OracleTraceCodecError.invalidHeader
        }
        let ticks = Set(trace.records.map(\.simulationTick)).sorted()
        let asset = assetRecords[0]
        let values = asset.values.map { String(format: "0x%016llx", $0) }.joined(separator: ",")
        print(
            "phase85cd_audio_asset_swift_audit records=\(trace.records.count) "
                + "ticks=\(ticks.first ?? 0),\(ticks.last ?? 0) "
                + "audio_sequence=\(sequenceRecords.count) audio_pcm=\(pcmRecords.count) "
                + "sequence12=\(assetRecords.count) sequence12_tick=\(asset.simulationTick) "
                + "sequence12_values=\(values) source_identity_header=1 "
                + "exact_native_trace_parser=1 pair_deferred=1"
        )
    }
}
