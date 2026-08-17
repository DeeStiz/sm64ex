import Foundation

@main
struct SM64ModernMarioFaceExpressionSmoke {
    static func main() {
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
            .init(face: baseFace, animationBank: 0, animationFrameQ16: (1 << 16) | 0x8000, peachKissTimeline: true, actionTimer: 96),
            .init(face: baseFace, animationBank: 1, animationFrameQ16: (2 << 16) | 0x4000, peachKissTimeline: false, actionTimer: 20),
            .init(face: baseFace, animationBank: 0, animationFrameQ16: (5 << 16) | 0x8000, peachKissTimeline: false, actionTimer: 52),
        ]

        let packets = inputs.map(SM64MarioFaceExpression.resolve)
        let payloadSelectionSeed = SM64MarioFaceExpressionFingerprint.payloadSelectionSeed
        var fingerprint = payloadSelectionSeed
        for packet in packets {
            fingerprint = SM64MarioFaceExpressionFingerprint.packet(fingerprint, packet)
        }

        precondition(packets[0].payloadWindowMask == 0x3F)
        precondition(packets[0].decodedPayloadWindowCount == 6)
        precondition(packets[0].unavailableCatalogChannelCount == 19)
        precondition(packets[1].eyeOverrideSource == 1 && packets[1].eyeOverrideState == SM64MarioFaceEyeState.open.rawValue)
        precondition(packets[1].face.eyeCase == SM64MarioFaceEyeState.open.rawValue - 1)
        precondition(packets[2].payloadWindowMask == 0x40)
        precondition(packets[2].eyeOverrideSource == 2 && packets[2].eyeOverrideState == SM64MarioFaceEyeState.halfClosed.rawValue)
        precondition(packets[2].face.eyeCase == SM64MarioFaceEyeState.halfClosed.rawValue - 1)
        precondition(packets[3].payloadWindowMask == 0 && packets[3].decodedPayloadWindowCount == 0)
        precondition(packets[3].eyeOverrideSource == 0 && packets[3].eyeOverrideState == 0xFFFF_FFFF)

        print(String(format: "marioFaceExpressionPayloadSelectionSeed=0x%016llx", payloadSelectionSeed))
        print(String(format: "marioFaceExpressionFingerprint=0x%016llx", fingerprint))
        print("marioFaceExpressionScenarios=\(inputs.count)")
        print("marioFaceExpressionPayloadWindows=\(SM64MarioFaceExpression.payloadWindowCount)")
        print("marioFaceExpressionCatalogChannels=\(SM64MarioFaceExpression.catalogChannelCount)")
        print("SM64 Modern Mario face expression smoke passed")
    }
}
