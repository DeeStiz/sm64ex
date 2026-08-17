import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ hash: UInt64, _ value: UInt32) -> UInt64 {
    var result = hash
    for shift in stride(from: 0, through: 24, by: 8) {
        result ^= UInt64((value >> UInt32(shift)) & 0xFF)
        result &*= fnvPrime
    }
    return result
}

private func hashTrace(_ hash: UInt64, _ trace: SM64AudioResidencyTrace) -> UInt64 {
    var value = hash
    value = hashU32(value, UInt32(trace.events.count))
    for event in trace.events {
        value = hashU32(value, UInt32(event.kind.rawValue))
        value = hashU32(value, UInt32(event.resource.rawValue))
        value = hashU32(value, UInt32(bitPattern: Int32(event.id)))
        value = hashU32(value, UInt32(bitPattern: Int32(event.index)))
        value = hashU32(value, UInt32(bitPattern: Int32(event.value)))
    }
    value = hashU32(value, UInt32(bitPattern: Int32(trace.selectedID ?? -1)))
    value = hashU32(value, trace.failed ? 1 : 0)
    return value
}

private func hashSlot(_ hash: UInt64, _ slot: SM64AudioResidencySlot) -> UInt64 {
    var value = hash
    value = hashU32(value, UInt32(slot.side))
    value = hashU32(value, UInt32(bitPattern: Int32(slot.resourceID ?? -1)))
    value = hashU32(value, UInt32(slot.size))
    value = hashU32(value, UInt32(slot.status.rawValue))
    value = hashU32(value, UInt32(slot.generation))
    return value
}

private func hashStreamSlot(_ hash: UInt64, _ slot: SM64AudioStreamSlot) -> UInt64 {
    var value = hash
    value = hashU32(value, UInt32(slot.index))
    value = hashU32(value, UInt32(bitPattern: Int32(slot.sampleID ?? -1)))
    value = hashU32(value, UInt32(slot.source))
    value = hashU32(value, UInt32(slot.bufferSize))
    value = hashU32(value, UInt32(slot.ttl))
    value = hashU32(value, UInt32(bitPattern: Int32(slot.reuseIndex)))
    return value
}

private func hashModel(_ hash: UInt64, _ model: SM64AudioResidencyModel) -> UInt64 {
    var value = hash
    for status in model.bankStatuses { value = hashU32(value, UInt32(status.rawValue)) }
    for status in model.sequenceStatuses { value = hashU32(value, UInt32(status.rawValue)) }
    value = hashU32(value, UInt32(model.bankNextSide))
    value = hashU32(value, UInt32(model.sequenceNextSide))
    for slot in model.bankSlots { value = hashSlot(value, slot) }
    for slot in model.sequenceSlots { value = hashSlot(value, slot) }
    for slot in model.shortStreamSlots { value = hashStreamSlot(value, slot) }
    for slot in model.longStreamSlots { value = hashStreamSlot(value, slot) }
    for index in model.shortReuseQueue { value = hashU32(value, UInt32(index)) }
    value = hashU32(value, 0xFFFF_FFFF)
    for index in model.longReuseQueue { value = hashU32(value, UInt32(index)) }
    value = hashU32(value, 0xFFFF_FFFF)
    return value
}

private func sound(_ sampleID: Int, _ tuningMilli: Int) -> SM64AudioSoundDescriptor {
    SM64AudioSoundDescriptor(sampleID: sampleID, tuningMilli: tuningMilli)
}

@main
enum SM64ModernAudioResidencySmoke {
    static func main() {
        var model = SM64AudioResidencyModel(
            bankCapacity: 12,
            sequenceCapacity: 16,
            shortStreamCapacity: 2,
            longStreamCapacity: 2,
            shortBufferSize: 128,
            longBufferSize: 256
        )
        var fingerprint = fnvOffset

        let bank = SM64AudioBankDescriptor(
            id: 10,
            instruments: [
                SM64AudioInstrumentDescriptor(
                    id: 0,
                    loaded: true,
                    normalRangeLo: 40,
                    normalRangeHi: 80,
                    releaseRate: 5,
                    lowNotesSound: sound(10, 900),
                    normalNotesSound: sound(11, 1000),
                    highNotesSound: sound(12, 1100)
                ),
                nil,
                SM64AudioInstrumentDescriptor(
                    id: 2,
                    loaded: false,
                    normalRangeLo: 40,
                    normalRangeHi: 80,
                    releaseRate: 6,
                    lowNotesSound: sound(10, 900),
                    normalNotesSound: sound(11, 1000),
                    highNotesSound: sound(12, 1100)
                )
            ],
            drums: [
                SM64AudioDrumDescriptor(id: 0, loaded: true, releaseRate: 7, pan: 64, sound: sound(11, 1000)),
                nil
            ]
        )
        model.register(bank)
        model.register(SM64AudioSampleDescriptor(id: 10, loaded: true, encoded: true, loopStart: 8, loopEnd: 128, bookID: 3, sampleSize: 129))
        model.register(SM64AudioSampleDescriptor(id: 11, loaded: true, encoded: false, loopStart: 0, loopEnd: 0, bookID: nil, sampleSize: 64))
        model.register(SM64AudioSampleDescriptor(id: 12, loaded: false, encoded: true, loopStart: 0, loopEnd: 256, bookID: 4, sampleSize: 257))

        fingerprint = hashTrace(fingerprint, model.loadBank(id: 7, size: 0x40, asynchronous: false))
        let bankAsync = model.loadBank(id: 8, size: 0x80, asynchronous: true)
        precondition(bankAsync.events.contains { $0.kind == .loadStarted })
        fingerprint = hashTrace(fingerprint, bankAsync)
        fingerprint = hashTrace(fingerprint, model.complete(.bank, id: 8))
        fingerprint = hashTrace(fingerprint, model.touch(.bank, id: 8))
        fingerprint = hashTrace(fingerprint, model.markDiscardable(.bank, id: 7))
        fingerprint = hashTrace(fingerprint, model.loadBank(id: 9, size: 0x90, asynchronous: false))
        fingerprint = hashTrace(fingerprint, model.loadBank(id: 10, size: 0xA0, asynchronous: false))

        let sequenceShort = model.loadSequence(id: 3, size: 0x20, asynchronous: true)
        precondition(sequenceShort.events.contains { $0.kind == .loadCompleted })
        fingerprint = hashTrace(fingerprint, sequenceShort)
        fingerprint = hashTrace(fingerprint, model.loadSequence(id: 4, size: 0x80, asynchronous: true))
        fingerprint = hashTrace(fingerprint, model.complete(.sequence, id: 4))
        fingerprint = hashTrace(fingerprint, model.markDiscardable(.sequence, id: 3))
        fingerprint = hashTrace(fingerprint, model.loadSequence(id: 5, size: 0x40, asynchronous: true))

        let direct = model.lookupInstrument(bankID: 10, instrumentID: 0)
        precondition(direct.selectedID == 0 && !direct.failed)
        fingerprint = hashTrace(fingerprint, direct)
        let fallback = model.lookupInstrument(bankID: 10, instrumentID: 1, fallbackToLower: true)
        precondition(fallback.selectedID == 0 && !fallback.failed)
        fingerprint = hashTrace(fingerprint, fallback)
        let outOfRange = model.lookupInstrument(bankID: 10, instrumentID: 9)
        precondition(outOfRange.failed && outOfRange.events.first?.kind == .instrumentOutOfRange)
        fingerprint = hashTrace(fingerprint, outOfRange)
        let drum = model.lookupDrum(bankID: 10, drumID: 0)
        precondition(drum.selectedID == 0 && !drum.failed)
        fingerprint = hashTrace(fingerprint, drum)
        let soundNormal = model.selectSound(bankID: 10, instrumentID: 0, semitone: 60)
        precondition(soundNormal.selectedID == 11 && !soundNormal.failed)
        fingerprint = hashTrace(fingerprint, soundNormal)
        let soundUnavailable = model.selectSound(bankID: 10, instrumentID: 0, semitone: 90)
        precondition(soundUnavailable.failed && soundUnavailable.events.contains { $0.kind == .sampleUnavailable })
        fingerprint = hashTrace(fingerprint, soundUnavailable)
        let evictedLookup = model.lookupInstrument(bankID: 7, instrumentID: 0)
        precondition(evictedLookup.failed && evictedLookup.events.first?.kind == .instrumentUnavailable)
        fingerprint = hashTrace(fingerprint, evictedLookup)

        let streamMiss = model.requestSample(sampleID: 10, deviceAddress: 0x1234, size: 64, streamClass: .short)
        precondition(streamMiss.selectedID == 0 && streamMiss.events.contains { $0.kind == .streamMiss })
        fingerprint = hashTrace(fingerprint, streamMiss)
        let streamHit = model.requestSample(sampleID: 10, deviceAddress: 0x1240, size: 64, streamClass: .short, hint: 0)
        precondition(streamHit.selectedID == 0 && streamHit.events.contains { $0.kind == .streamHit })
        fingerprint = hashTrace(fingerprint, streamHit)
        fingerprint = hashTrace(fingerprint, model.advanceStreamTTL())
        let expired = model.advanceStreamTTL()
        precondition(expired.events.contains { $0.kind == .streamExpired })
        fingerprint = hashTrace(fingerprint, expired)
        fingerprint = hashTrace(fingerprint, model.requestSample(sampleID: 11, deviceAddress: 0x2345, size: 32, streamClass: .short))
        fingerprint = hashTrace(fingerprint, model.requestSample(sampleID: 10, deviceAddress: 0x4000, size: 128, streamClass: .long))
        fingerprint = hashTrace(fingerprint, model.requestSample(sampleID: 10, deviceAddress: 0x4010, size: 64, streamClass: .long, hint: 0))

        fingerprint = hashModel(fingerprint, model)
        print("audioResidencyFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern audio residency smoke passed")
    }
}
