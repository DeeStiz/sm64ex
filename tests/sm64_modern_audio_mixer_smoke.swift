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

private func hashI64(_ hash: UInt64, _ value: Int64) -> UInt64 {
    hashU64(hash, UInt64(bitPattern: value))
}

private func hashI16Array(_ hash: UInt64, _ values: [Int16]) -> UInt64 {
    var result = hashU64(hash, UInt64(values.count))
    for value in values { result = hashI64(result, Int64(value)) }
    return result
}

private func hashFrame(_ hash: UInt64, _ frame: SM64AudioPCMFrame) -> UInt64 {
    var value = hashU64(hash, UInt64(frame.sampleRateHz))
    value = hashU64(value, UInt64(frame.frameCount))
    value = hashI16Array(value, frame.interleavedStereo)
    value = hashI16Array(value, frame.dryLeft)
    value = hashI16Array(value, frame.dryRight)
    value = hashI16Array(value, frame.wetLeft)
    value = hashI16Array(value, frame.wetRight)
    value = hashU64(value, UInt64(frame.voiceOrder.count))
    for id in frame.voiceOrder { value = hashU64(value, UInt64(bitPattern: Int64(id))) }
    value = hashU64(value, UInt64(frame.clippedSamples))
    value = hashI64Array(value, frame.nextReverb.left)
    value = hashI64Array(value, frame.nextReverb.right)
    value = hashU64(value, UInt64(frame.nextReverb.writeIndex))
    value = hashU64(value, UInt64(frame.nextReverb.feedbackQ15))
    return hashU64(value, UInt64(frame.nextReverb.gainQ15))
}

private func hashI64Array(_ hash: UInt64, _ values: [Int32]) -> UInt64 {
    var result = hashU64(hash, UInt64(values.count))
    for value in values { result = hashI64(result, Int64(value)) }
    return result
}

@main
enum SM64ModernAudioMixerSmoke {
    static func main() {
        let voices = [
            SM64AudioMixVoice(
                noteID: 2,
                priority: 3,
                source: .music,
                left: [12_000, -12_000, 20_000, -20_000, 30_000, -30_000, 32_000, -32_000],
                right: [8_000, -8_000, 16_000, -16_000, 24_000, -24_000, 30_000, -30_000],
                reverb: [1_000, 2_000, 3_000, 4_000, 5_000, 6_000, 7_000, 8_000]
            ),
            SM64AudioMixVoice(
                noteID: 1,
                priority: 3,
                source: .effect,
                left: [25_000, 25_000, -25_000, -25_000, 30_000, -30_000, 1_000, -1_000],
                right: [10_000, 10_000, -10_000, -10_000, 28_000, -28_000, 2_000, -2_000],
                reverb: [2_000, 2_000, 2_000, 2_000, 2_000, 2_000, 2_000, 2_000]
            ),
            SM64AudioMixVoice(
                noteID: 3,
                priority: 1,
                source: .effect,
                left: [500, 500, 500, 500, 500, 500, 500, 500],
                right: [-500, -500, -500, -500, -500, -500, -500, -500],
                reverb: [100, 100, 100, 100, 100, 100, 100, 100]
            )
        ]
        let reverb = SM64AudioReverbState(
            left: [1_000, -2_000, 3_000, -4_000],
            right: [-500, 600, -700, 800],
            writeIndex: 1,
            feedbackQ15: 12_000,
            gainQ15: 16_000
        )
        let withReverb = SM64AudioMixer.mix(voices: voices, frameCount: 8, reverb: reverb, enableReverb: true)
        precondition(withReverb.voiceOrder == [2, 1, 3])
        precondition(withReverb.sampleRateHz == 32_000 && withReverb.interleavedStereo.count == 16)
        let dry = SM64AudioMixer.mix(voices: voices, frameCount: 8, reverb: nil, enableReverb: false)
        precondition(dry.nextReverb.left.isEmpty && dry.interleavedStereo.count == 16)

        var fingerprint = fnvOffset
        fingerprint = hashFrame(fingerprint, withReverb)
        fingerprint = hashFrame(fingerprint, dry)
        print("audioMixerFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern audio mixer smoke passed")
    }
}
