import Foundation

@main
struct SM64ModernMarioFaceAnimationPayloadSmoke {
    static func main() {
        let probes: [(UInt32, UInt32, UInt32)] = [
            (0x07, 0, 1), (0x07, 0, 5), (0x20, 0, 4), (0x42, 0, 2),
            (0xCF, 0, 5), (0xE2, 0, 4), (0xE5, 0, 1), (0xE8, 1, 4),
            (0xE8, 0, 1), (0x07, 0, 6),
        ]
        let decodedProbes: [(UInt32, UInt32, UInt32)] = [
            (0x07, 0, (1 << 16) | 0x8000),
            (0x20, 0, (2 << 16) | 0x4000),
            (0x42, 0, (3 << 16) | 0x8000),
            (0xCF, 0, (4 << 16) | 0x2000),
            (0xE2, 0, (1 << 16) | 0x8000),
            (0xE8, 1, (2 << 16) | 0x4000),
            (0x07, 0, (5 << 16) | 0x8000),
        ]
        let payloadFingerprint = SM64MarioFaceAnimationPayloadFingerprint.windows(
            SM64MarioFaceAnimationPayload.windows
        )
        var fingerprint = payloadFingerprint
        for (componentID, bank, frame) in probes {
            fingerprint = SM64MarioFaceAnimationPayloadFingerprint.frame(
                fingerprint,
                SM64MarioFaceAnimationPayload.window(componentID: componentID, bank: bank)?.frame(frame)
            )
        }
        var decodedFingerprint = payloadFingerprint
        for (componentID, bank, frameQ16) in decodedProbes {
            decodedFingerprint = SM64MarioFaceAnimationPayloadFingerprint.decoded(
                decodedFingerprint,
                SM64MarioFaceAnimationPayload.decode(componentID: componentID, bank: bank, frameQ16: frameQ16)
            )
        }

        precondition(SM64MarioFaceAnimationPayload.windows.count == 7)
        precondition(SM64MarioFaceAnimationPayload.window(componentID: 0x07, bank: 0)?.frame(1) == [0, 154, 1506])
        precondition(SM64MarioFaceAnimationPayload.window(componentID: 0x07, bank: 0)?.frame(5) == [0, 154, 1510])
        precondition(SM64MarioFaceAnimationPayload.window(componentID: 0xE2, bank: 0)?.frame(4) == [1085, 0, 0, 0, -16, -19000])
        precondition(SM64MarioFaceAnimationPayload.window(componentID: 0xE8, bank: 1)?.frame(4) == [0, 0, 0, 4287, 2078, 2385])
        precondition(SM64MarioFaceAnimationPayload.window(componentID: 0x07, bank: 0)?.frame(6) == nil)
        precondition(SM64MarioFaceAnimationPayload.window(componentID: 0xE8, bank: 0) == nil)
        let mustacheDecoded = SM64MarioFaceAnimationPayload.decode(componentID: 0x07, bank: 0, frameQ16: (1 << 16) | 0x8000)
        precondition(mustacheDecoded?.values.count == 3)
        if let values = mustacheDecoded?.values {
            precondition(abs(values[0]) < 0.0001)
            precondition(abs(values[1] - 15.4) < 0.01)
            precondition(abs(values[2] - 150.6) < 0.01)
        }
        precondition(mustacheDecoded?.currentSourceFrame == 1 && mustacheDecoded?.nextSourceFrame == 2)
        precondition(SM64MarioFaceAnimationPayload.decode(componentID: 0x07, bank: 0, frameQ16: (5 << 16) | 0x8000) == nil)

        print(String(format: "marioFacePayloadFingerprint=0x%016llx", payloadFingerprint))
        print(String(format: "marioFacePayloadProbeFingerprint=0x%016llx", fingerprint))
        print(String(format: "marioFacePayloadDecodedFingerprint=0x%016llx", decodedFingerprint))
        print("marioFacePayloadWindows=\(SM64MarioFaceAnimationPayload.windows.count)")
        print("marioFacePayloadProbes=\(probes.count)")
        print("marioFacePayloadDecodedProbes=\(decodedProbes.count)")
        print("SM64 Modern Mario face animation payload smoke passed")
    }
}
