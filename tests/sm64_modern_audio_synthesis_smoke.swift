import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ hash: UInt64, _ value: UInt64) -> UInt64 {
    var result = hash
    for shift in stride(from: 0, through: 56, by: 8) {
        result ^= (value >> UInt64(shift)) & 0xFF
        result &*= fnvPrime
    }
    return result
}

private func hashI32(_ hash: UInt64, _ value: Int32) -> UInt64 {
    hashU64(hash, UInt64(bitPattern: Int64(value)))
}

private func hashSamples(_ hash: UInt64, _ values: [Int32]) -> UInt64 {
    var result = hashU64(hash, UInt64(values.count))
    for value in values {
        result = hashI32(result, value)
    }
    return result
}

private func hashADSRFrames(_ hash: UInt64, _ frames: [SM64AudioADSRFrame]) -> UInt64 {
    var result = hashU64(hash, UInt64(frames.count))
    for frame in frames {
        result = hashU64(result, UInt64(frame.state.rawValue))
        result = hashU64(result, UInt64(frame.action.rawValue))
        result = hashI32(result, frame.current)
        result = hashI32(result, frame.target)
        result = hashI32(result, frame.delay)
        result = hashU64(result, UInt64(frame.envelopeIndex))
    }
    return result
}

@main
enum SM64ModernAudioSynthesisSmoke {
    static func main() {
        var rows = Array(repeating: Array(repeating: Int32(0), count: 9), count: 8)
        for index in 0..<8 {
            rows[index][0] = 2_048
            rows[index][index + 1] = 2_048
        }
        let book = SM64AudioADPCMBook(order: 1, predictors: [rows])
        let decoder = SM64AudioADPCMDecoder(book: book)
        var decoderState: [Int32] = [100]
        let block1: [UInt8] = [0x00, 0x12, 0x34, 0x56, 0x78, 0xF0, 0x0F, 0xAA, 0x55]
        let block2: [UInt8] = [0x10, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x10]
        guard let decoded1 = decoder.decode(block: block1, state: &decoderState),
              let decoded2 = decoder.decode(block: block2, state: &decoderState) else {
            fatalError("VADPCM decode rejected the deterministic fixture")
        }
        precondition(decoded1.count == 16 && decoded2.count == 16)
        precondition(decoderState.count == 1)

        let envelope = [
            SM64AudioEnvelopePoint(delay: 4, target: 1_600),
            SM64AudioEnvelopePoint(delay: 3, target: 2_400),
            SM64AudioEnvelopePoint(delay: 0, target: 0)
        ]
        var adsr = SM64AudioADSR(envelope: envelope)
        adsr.start(initial: 100)
        var frames: [SM64AudioADSRFrame] = []
        for _ in 0..<3 {
            frames.append(adsr.tick())
        }
        adsr.setDecay(sustain: 400, fadeOutVelocity: 250)
        frames.append(adsr.tick())
        adsr.requestRelease()
        for _ in 0..<8 {
            frames.append(adsr.tick())
        }
        adsr.requestRelease()
        let disabledFrame = adsr.tick()
        frames.append(disabledFrame)
        precondition(disabledFrame.state == .disabled && disabledFrame.action.contains(.release))
        precondition(!frames.isEmpty)

        let envelopeQ15: [UInt16] = [32_767, 30_000, 28_000, 26_000, 24_000, 22_000, 20_000, 18_000]
        let pcm = SM64AudioPCMWindow.render(
            decoded: decoded1,
            pitchQ16: 0x8000,
            envelopeQ15: envelopeQ15
        )
        precondition(pcm.samples.count == envelopeQ15.count)

        var fingerprint = fnvOffset
        fingerprint = hashSamples(fingerprint, decoded1)
        fingerprint = hashSamples(fingerprint, decoded2)
        fingerprint = hashSamples(fingerprint, decoderState)
        fingerprint = hashADSRFrames(fingerprint, frames)
        fingerprint = hashU64(fingerprint, UInt64(pcm.samples.count))
        for sample in pcm.samples {
            fingerprint = hashU64(fingerprint, UInt64(bitPattern: Int64(sample)))
        }
        fingerprint = hashU64(fingerprint, UInt64(pcm.resamplePhase))
        print("audioSynthesisFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern audio synthesis smoke passed")
    }
}
