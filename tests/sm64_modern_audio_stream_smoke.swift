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

private func hashEvents(_ hash: UInt64, _ events: [SM64AudioADPCMStreamEvent]) -> UInt64 {
    var result = hashU64(hash, UInt64(events.count))
    for event in events {
        result = hashU64(result, UInt64(event.kind.rawValue))
        result = hashU64(result, UInt64(bitPattern: Int64(event.value0)))
        result = hashU64(result, UInt64(bitPattern: Int64(event.value1)))
    }
    return result
}

private func hashResidencyEvents(_ hash: UInt64, _ events: [SM64AudioResidencyEvent]) -> UInt64 {
    var result = hashU64(hash, UInt64(events.count))
    for event in events {
        result = hashU64(result, UInt64(event.kind.rawValue))
        result = hashU64(result, UInt64(event.resource.rawValue))
        result = hashU64(result, UInt64(bitPattern: Int64(event.id)))
        result = hashU64(result, UInt64(bitPattern: Int64(event.index)))
        result = hashU64(result, UInt64(bitPattern: Int64(event.value)))
    }
    return result
}

private func hashResult(_ hash: UInt64, _ result: SM64AudioADPCMStreamWindowResult) -> UInt64 {
    var value = hashU64(hash, UInt64(result.samples.count))
    for sample in result.samples { value = hashI32(value, sample) }
    value = hashU64(value, UInt64(bitPattern: Int64(result.nextSamplePosition)))
    value = hashU64(value, UInt64(result.decoderState.count))
    for state in result.decoderState { value = hashI32(value, state) }
    value = hashU64(value, UInt64(result.loops))
    value = hashU64(value, result.finished ? 1 : 0)
    value = hashEvents(value, result.streamEvents)
    return hashResidencyEvents(value, result.residencyEvents)
}

private func makeBook() -> SM64AudioADPCMBook {
    var rows = Array(repeating: Array(repeating: Int32(0), count: 9), count: 8)
    for index in 0..<8 {
        rows[index][0] = 2_048
        rows[index][index + 1] = 2_048
    }
    return SM64AudioADPCMBook(order: 1, predictors: [rows])
}

@main
enum SM64ModernAudioStreamSmoke {
    static func main() {
        let book = makeBook()
        let block1: [UInt8] = [0x00, 0x12, 0x34, 0x56, 0x78, 0xF0, 0x0F, 0xAA, 0x55]
        let block2: [UInt8] = [0x10, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x10]
        let sample = SM64AudioSampleDescriptor(
            id: 7,
            loaded: true,
            encoded: true,
            loopStart: 8,
            loopEnd: 24,
            bookID: 0,
            sampleSize: 32
        )
        var residency = SM64AudioResidencyModel(bankCapacity: 8, sequenceCapacity: 8)
        residency.register(sample)
        let input = SM64AudioADPCMStreamWindowInput(
            sample: sample,
            book: book,
            encodedBlocks: [block1, block2],
            loopState: [100],
            loopCount: 1,
            samplePosition: 4,
            requestedSamples: 28,
            decoderState: [100],
            restartFromLoopState: false,
            streamClass: .long,
            deviceAddress: 0x2_000
        )
        let active = SM64AudioADPCMStreamWindow.project(input, residency: &residency)
        precondition(active.samples.count == 28)
        precondition(active.loops == 1 && !active.finished)
        precondition(active.streamEvents.contains { $0.kind == .looped })
        precondition(active.residencyEvents.contains { $0.kind == .streamMiss })
        precondition(active.residencyEvents.contains { $0.kind == .streamHit })

        var unavailableResidency = SM64AudioResidencyModel(bankCapacity: 8, sequenceCapacity: 8)
        let unavailable = SM64AudioADPCMStreamWindow.project(
            SM64AudioADPCMStreamWindowInput(
                sample: SM64AudioSampleDescriptor(
                    id: 9,
                    loaded: false,
                    encoded: true,
                    loopStart: 8,
                    loopEnd: 24,
                    bookID: 0,
                    sampleSize: 32
                ),
                book: book,
                encodedBlocks: [block1, block2],
                loopState: [100],
                loopCount: 0,
                samplePosition: 0,
                requestedSamples: 8,
                decoderState: [100],
                restartFromLoopState: true,
                streamClass: .short,
                deviceAddress: 0x3_000
            ),
            residency: &unavailableResidency
        )
        precondition(unavailable.finished && unavailable.samples.allSatisfy { $0 == 0 })
        precondition(unavailable.streamEvents.last?.kind == .sampleUnavailable)

        var fingerprint = fnvOffset
        fingerprint = hashResult(fingerprint, active)
        fingerprint = hashResult(fingerprint, unavailable)
        print("audioStreamFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern audio stream smoke passed")
    }
}
