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

private func hashInt16Array(_ hash: UInt64, _ values: [Int16]) -> UInt64 {
    var result = hashU64(hash, UInt64(values.count))
    for value in values {
        result = hashI64(result, Int64(value))
    }
    return result
}

private func hashVoiceResult(_ hash: UInt64, _ result: SM64AudioVoiceWindowResult) -> UInt64 {
    var value = hashU64(hash, UInt64(result.noteID))
    value = hashU64(value, UInt64(result.streamClass.rawValue))
    value = hashInt16Array(value, result.left)
    value = hashInt16Array(value, result.right)
    value = hashInt16Array(value, result.reverb)
    value = hashU64(value, result.nextSamplePositionQ16)
    value = hashU64(value, UInt64(result.loops))
    value = hashU64(value, result.finished ? 1 : 0)
    value = hashU64(value, UInt64(result.events.count))
    for event in result.events {
        value = hashU64(value, UInt64(event.kind.rawValue))
        value = hashU64(value, UInt64(bitPattern: Int64(event.value0)))
        value = hashU64(value, UInt64(bitPattern: Int64(event.value1)))
    }
    return value
}

private func makeDecodedSamples() -> [Int32] {
    var rows = Array(repeating: Array(repeating: Int32(0), count: 9), count: 8)
    for index in 0..<8 {
        rows[index][0] = 2_048
        rows[index][index + 1] = 2_048
    }
    let decoder = SM64AudioADPCMDecoder(
        book: SM64AudioADPCMBook(order: 1, predictors: [rows])
    )
    var state: [Int32] = [100]
    let block1: [UInt8] = [0x00, 0x12, 0x34, 0x56, 0x78, 0xF0, 0x0F, 0xAA, 0x55]
    let block2: [UInt8] = [0x10, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x10]
    return decoder.decode(block: block1, state: &state)! + decoder.decode(block: block2, state: &state)!
}

@main
enum SM64ModernAudioVoiceSmoke {
    static func main() {
        var pool = SM64AudioPoolModel(layerCapacity: 1, channelCapacity: 1, noteCapacity: 2)
        _ = pool.initializeChannels(mask: 1, allocationPolicy: .globalFreeList)
        _ = pool.setLayer(channelSlot: 0, layerIndex: 0)
        let allocation = pool.allocateNote(channelSlot: 0, layerIndex: 0)
        precondition(!allocation.failed)
        let note = pool.notes[allocation.selectedNoteID!]
        precondition(note.list == .active && note.priority == 3)

        let decoded = makeDecodedSamples()
        let sample = SM64AudioSampleDescriptor(
            id: 7,
            loaded: true,
            encoded: true,
            loopStart: 8,
            loopEnd: 24,
            bookID: 0,
            sampleSize: decoded.count
        )
        let input = SM64AudioVoiceWindowInput(
            note: note,
            sample: sample,
            streamClass: .long,
            decoded: decoded,
            pitchQ16: 0x18000,
            envelopeQ15: [32_767, 30_000, 28_000, 26_000, 24_000, 22_000],
            panQ15: 10_000,
            reverbQ15: 9_000,
            samplePositionQ16: UInt64(12) << 16,
            loopCount: 1,
            outputCount: 18,
            releaseRequested: true
        )
        let activeResult = SM64AudioVoiceWindow.project(input)
        precondition(activeResult.loops == 1)
        precondition(!activeResult.finished)
        precondition(activeResult.events.contains { $0.kind == .released })

        var disabledPool = SM64AudioPoolModel(layerCapacity: 0, channelCapacity: 0, noteCapacity: 1)
        disabledPool.seedNote(0, scope: .global, list: .disabled, priority: 0)
        let disabledInput = SM64AudioVoiceWindowInput(
            note: disabledPool.notes[0],
            sample: sample,
            streamClass: .short,
            decoded: decoded,
            pitchQ16: 0x10000,
            envelopeQ15: [],
            panQ15: 16_383,
            reverbQ15: 0,
            samplePositionQ16: 0,
            loopCount: 0,
            outputCount: 18,
            releaseRequested: false
        )
        let disabledResult = SM64AudioVoiceWindow.project(disabledInput)
        precondition(disabledResult.finished && disabledResult.events.last?.kind == .disabled)

        let unavailableSample = SM64AudioSampleDescriptor(
            id: 9,
            loaded: false,
            encoded: true,
            loopStart: 8,
            loopEnd: 24,
            bookID: 0,
            sampleSize: decoded.count
        )
        let unavailableResult = SM64AudioVoiceWindow.project(
            SM64AudioVoiceWindowInput(
                note: note,
                sample: unavailableSample,
                streamClass: .short,
                decoded: decoded,
                pitchQ16: 0x10000,
                envelopeQ15: [],
                panQ15: 16_383,
                reverbQ15: 0,
                samplePositionQ16: 0,
                loopCount: 0,
                outputCount: 18,
                releaseRequested: false
            )
        )
        precondition(unavailableResult.finished && unavailableResult.events.last?.kind == .sampleUnavailable)

        var fingerprint = fnvOffset
        fingerprint = hashVoiceResult(fingerprint, activeResult)
        fingerprint = hashVoiceResult(fingerprint, disabledResult)
        fingerprint = hashVoiceResult(fingerprint, unavailableResult)
        print("audioVoiceFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern audio voice smoke passed")
    }
}
