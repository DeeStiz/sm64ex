import Foundation

@main
struct SM64ModernMarioFaceExpressionCompositionSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw NSError(domain: "MarioFaceExpressionCompositionSmoke", code: 1)
        }
        let pack = try SM64ContentPack.load(from: URL(fileURLWithPath: CommandLine.arguments[1]))
        let index = try SM64ContentPackIndex(pack: pack)
        let bytes = try index.bytes(
            kind: .sourceManifest,
            relativePath: "source_manifest/mario_face_payloads.mfpb"
        )
        let bundle = try SM64MarioFacePayloadBundle.decode(bytes)
        let baseFace = SM64MarioFaceInput(
            bodyIndex: 0,
            areaUpdateCounter: 0,
            eyeState: SM64MarioFaceEyeState.blink.rawValue,
            action: 0,
            handState: SM64MarioFaceHandState.fists.rawValue,
            handSwitchCaseCount: 0,
            capState: 0,
            modelState: 0
        )
        let inputs: [SM64MarioFaceExpressionInput] = [
            .init(face: baseFace, animationBank: 0, animationFrameQ16: (1 << 16) | 0x8000, peachKissTimeline: false, actionTimer: 100),
            .init(face: baseFace, animationBank: 0, animationFrameQ16: (820 << 16) | 0x8000, peachKissTimeline: true, actionTimer: 96),
            .init(face: baseFace, animationBank: 1, animationFrameQ16: (165 << 16) | 0x4000, peachKissTimeline: false, actionTimer: 20),
            .init(face: baseFace, animationBank: 1, animationFrameQ16: (166 << 16) | 0x8000, peachKissTimeline: false, actionTimer: 52),
            .init(face: baseFace, animationBank: 2, animationFrameQ16: (1 << 16) | 0x8000, peachKissTimeline: false, actionTimer: 52),
        ]

        let packets = inputs.map {
            SM64MarioFaceExpressionComposition.compose(input: $0, bundle: bundle)
        }
        var fingerprint = SM64MarioFaceExpressionCompositionFingerprint.seed
        for packet in packets {
            fingerprint = SM64MarioFaceExpressionCompositionFingerprint.packet(fingerprint, packet)
        }

        precondition(packets[0].channelMask == (UInt64(1) << 25) - 1)
        precondition(packets[0].residentChannelCount == 25)
        precondition(packets[0].channels[0].values.count == 3)
        precondition(packets[0].channels[22].values.count == 6)
        precondition(packets[1].channels[0].nextSourceFrame == 1)
        precondition(packets[1].eyeOverrideSource == 1)
        precondition(packets[2].residentChannelCount == 20)
        precondition(packets[2].unavailableChannelCount == 5)
        precondition(packets[2].channels[5].available == false)
        precondition(packets[2].channels[22].values.count == 6)
        precondition(packets[3].residentChannelCount == 20)
        precondition(packets[4].residentChannelCount == 0)
        precondition(packets[4].unavailableChannelCount == 25)

        print(String(format: "marioFaceExpressionCompositionSeed=0x%016llx", SM64MarioFaceExpressionCompositionFingerprint.seed))
        print(String(format: "marioFaceExpressionCompositionFingerprint=0x%016llx", fingerprint))
        print("marioFaceExpressionCompositionScenarios=\(packets.count)")
        print("marioFaceExpressionCompositionChannels=\(packets[0].channels.count)")
        print("SM64 Modern Mario face expression composition smoke passed")
    }
}
