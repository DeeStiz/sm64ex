import Foundation

enum SM64AudioMixSource: UInt8, Equatable, Sendable {
    case music = 0
    case effect = 1
}

struct SM64AudioMixVoice: Equatable, Sendable {
    let noteID: Int
    let priority: UInt8
    let source: SM64AudioMixSource
    let left: [Int16]
    let right: [Int16]
    let reverb: [Int16]
}

struct SM64AudioReverbState: Equatable, Sendable {
    let left: [Int32]
    let right: [Int32]
    let writeIndex: Int
    let feedbackQ15: UInt16
    let gainQ15: UInt16

    init(left: [Int32], right: [Int32], writeIndex: Int, feedbackQ15: UInt16, gainQ15: UInt16) {
        self.left = left
        self.right = right
        self.writeIndex = writeIndex
        self.feedbackQ15 = feedbackQ15
        self.gainQ15 = gainQ15
    }
}

struct SM64AudioPCMFrame: Equatable, Sendable {
    let sampleRateHz: Int
    let frameCount: Int
    let interleavedStereo: [Int16]
    let dryLeft: [Int16]
    let dryRight: [Int16]
    let wetLeft: [Int16]
    let wetRight: [Int16]
    let voiceOrder: [Int]
    let clippedSamples: Int
    let nextReverb: SM64AudioReverbState
}

/// Deterministic value mixer for one 32-kHz frame. Stable priority ordering
/// makes music/effect accumulation explicit while leaving AVAudio scheduling
/// outside this value boundary.
enum SM64AudioMixer {
    static let sampleRateHz = 32_000

    static func mix(
        voices: [SM64AudioMixVoice],
        frameCount: Int,
        reverb: SM64AudioReverbState?,
        enableReverb: Bool
    ) -> SM64AudioPCMFrame {
        let count = max(frameCount, 0)
        let indexed = voices.enumerated().sorted { lhs, rhs in
            let left = lhs.element
            let right = rhs.element
            if left.priority != right.priority { return left.priority > right.priority }
            if left.source != right.source { return left.source.rawValue < right.source.rawValue }
            if left.noteID != right.noteID { return left.noteID < right.noteID }
            return lhs.offset < rhs.offset
        }
        let orderedVoices = indexed.map(\.element)
        let order = orderedVoices.map(\.noteID)
        let ringLength = max(reverb?.left.count ?? 0, reverb?.right.count ?? 0)
        var ringLeft = reverb.map { Array($0.left.prefix(ringLength)) } ?? []
        var ringRight = reverb.map { Array($0.right.prefix(ringLength)) } ?? []
        if ringLeft.count < ringLength { ringLeft += Array(repeating: 0, count: ringLength - ringLeft.count) }
        if ringRight.count < ringLength { ringRight += Array(repeating: 0, count: ringLength - ringRight.count) }
        var writeIndex = ringLength == 0 ? 0 : (reverb?.writeIndex ?? 0) % ringLength
        let feedback = Int64(min(reverb?.feedbackQ15 ?? 0, UInt16(32_767)))
        let gain = Int64(min(reverb?.gainQ15 ?? 0, UInt16(32_767)))
        var dryLeft: [Int16] = []
        var dryRight: [Int16] = []
        var wetLeft: [Int16] = []
        var wetRight: [Int16] = []
        var interleaved: [Int16] = []
        dryLeft.reserveCapacity(count)
        dryRight.reserveCapacity(count)
        wetLeft.reserveCapacity(count)
        wetRight.reserveCapacity(count)
        interleaved.reserveCapacity(count * 2)
        var clipped = 0

        for sampleIndex in 0..<count {
            var dryL: Int64 = 0
            var dryR: Int64 = 0
            var sendL: Int64 = 0
            var sendR: Int64 = 0
            for voice in orderedVoices {
                if voice.left.indices.contains(sampleIndex) { dryL += Int64(voice.left[sampleIndex]) }
                if voice.right.indices.contains(sampleIndex) { dryR += Int64(voice.right[sampleIndex]) }
                if voice.reverb.indices.contains(sampleIndex) {
                    let send = Int64(voice.reverb[sampleIndex])
                    sendL += send
                    sendR += send
                }
            }
            var outputL = dryL
            var outputR = dryR
            if enableReverb, ringLength > 0 {
                let delayedL = Int64(ringLeft[writeIndex])
                let delayedR = Int64(ringRight[writeIndex])
                outputL += (delayedL * gain) / 32_767
                outputR += (delayedR * gain) / 32_767
                ringLeft[writeIndex] = Int32(clamping: sendL + (delayedL * feedback) / 32_767)
                ringRight[writeIndex] = Int32(clamping: sendR + (delayedR * feedback) / 32_767)
                writeIndex = (writeIndex + 1) % ringLength
            }
            let dryLSample = Int16(clamping: dryL)
            let dryRSample = Int16(clamping: dryR)
            let wetLSample = Int16(clamping: outputL)
            let wetRSample = Int16(clamping: outputR)
            if Int64(dryLSample) != dryL { clipped += 1 }
            if Int64(dryRSample) != dryR { clipped += 1 }
            if Int64(wetLSample) != outputL { clipped += 1 }
            if Int64(wetRSample) != outputR { clipped += 1 }
            dryLeft.append(dryLSample)
            dryRight.append(dryRSample)
            wetLeft.append(wetLSample)
            wetRight.append(wetRSample)
            interleaved.append(wetLSample)
            interleaved.append(wetRSample)
        }

        let nextReverb = SM64AudioReverbState(
            left: ringLeft,
            right: ringRight,
            writeIndex: writeIndex,
            feedbackQ15: UInt16(clamping: Int(feedback)),
            gainQ15: UInt16(clamping: Int(gain))
        )
        return SM64AudioPCMFrame(
            sampleRateHz: Self.sampleRateHz,
            frameCount: count,
            interleavedStereo: interleaved,
            dryLeft: dryLeft,
            dryRight: dryRight,
            wetLeft: wetLeft,
            wetRight: wetRight,
            voiceOrder: order,
            clippedSamples: clipped,
            nextReverb: nextReverb
        )
    }
}
