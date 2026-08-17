import Foundation

@main
struct SM64ModernMarioFaceRenderPacketSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw NSError(domain: "MarioFaceRenderPacketSmoke", code: 1)
        }
        let bundle = try SM64MarioFacePayloadBundle.decode(
            Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        )
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
            SM64MarioFaceRenderPacketBuilder.make(input: $0, bundle: bundle)
        }

        var fingerprint = SM64MarioFaceRenderPacketFingerprint.seed
        for packet in packets {
            fingerprint = hash(fingerprint, SM64MarioFaceRenderPacketFingerprint.packet(packet))
        }

        precondition(packets.allSatisfy { $0.catalogFingerprint == 0x47eaad2dfd5d62ed })
        precondition(packets.allSatisfy { $0.masterGroupID == 0x3E8 && $0.animationParentGroupID == 0x3E9 })
        precondition(packets[0].meshes.count == 6 && packets[0].animations.count == 25)
        precondition(packets[0].meshes[0].materialIDs == Array(0..<8))
        precondition(packets[0].meshes[0].materialPolicy == .sourceMaterialGroup)
        precondition(packets[0].meshes[0].lodPolicy == .sourceFullResolution)
        precondition(packets[0].meshes[5].materialIDs == [0])
        precondition(packets[0].lights.map(\.objectID) == [0xE4, 0xE7])
        precondition(packets[0].channelMask == (UInt64(1) << 25) - 1)
        precondition(packets[0].residentChannelCount == 25)
        precondition(packets[0].animations[0].linkedObjectID == 0x06)
        precondition(packets[0].animations[22].linkedObjectID == 0xDD)
        precondition(packets[0].animations[22].values.count == 6)
        precondition(packets[1].animations[0].nextSourceFrame == 1)
        precondition(packets[1].eyeOverrideSource == 1 && packets[1].eyeOverrideState == 1)
        precondition(packets[2].residentChannelCount == 20)
        precondition(packets[2].unavailableChannelCount == 5)
        precondition(packets[2].animations[5].available == false)
        precondition(packets[3].animations[22].nextSourceFrame == 1)
        precondition(packets[4].residentChannelCount == 0)
        precondition(packets[4].unavailableChannelCount == 25)

        print(String(format: "marioFaceRenderPacketSeed=0x%016llx", SM64MarioFaceRenderPacketFingerprint.seed))
        print(String(format: "marioFaceRenderPacketFingerprint=0x%016llx", fingerprint))
        print("marioFaceRenderPacketScenarios=\(packets.count)")
        print("marioFaceRenderPacketMeshes=\(packets[0].meshes.count)")
        print("marioFaceRenderPacketAnimations=\(packets[0].animations.count)")
        print("SM64 Modern Mario face render packet smoke passed")
    }

    private static func hash(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xFF
            result &*= SM64MarioFaceRenderPacketFingerprint.prime
        }
        return result
    }
}
