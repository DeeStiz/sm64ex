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

private func hashPacket(_ hash: UInt64, _ packet: SM64AudioSequenceEventPacket) -> UInt64 {
    var value = hash
    value = hashU32(value, packet.advancedTatum ? 1 : 0)
    value = hashU32(value, UInt32(packet.events.count))
    for event in packet.events {
        value = hashU32(value, UInt32(event.kind.rawValue))
        value = hashU32(value, UInt32(event.opcode))
        value = hashU32(value, UInt32(bitPattern: event.value0))
        value = hashU32(value, UInt32(bitPattern: event.value1))
    }
    value = hashU32(value, packet.enabled ? 1 : 0)
    value = hashU32(value, packet.finished ? 1 : 0)
    value = hashU32(value, UInt32(packet.programCounter))
    value = hashU32(value, UInt32(packet.tempo))
    value = hashU32(value, UInt32(packet.tempoAccumulator))
    value = hashU32(value, UInt32(packet.delay))
    value = hashU32(value, UInt32(packet.depth))
    value = hashU32(value, UInt32(bitPattern: packet.value))
    value = hashU32(value, UInt32(bitPattern: Int32(packet.transposition)))
    value = hashU32(value, UInt32(bitPattern: Int32(packet.variation)))
    value = hashU32(value, UInt32(packet.enabledChannelMask))
    return value
}

@main
enum SM64ModernAudioSequenceSmoke {
    static func main() {
        let script: [UInt8] = [
            0xCC, 0x05,       // value = 5
            0xC9, 0x03,       // value &= 3
            0xC8, 0x01,       // value -= 1
            0xDE, 0xFE,       // transposition += -2
            0xD7, 0x00, 0x03, // initialize channels 0 and 1
            0x90, 0x00, 0x0F, // start channel 0
            0xFD, 0x02,       // wait two tatums
            0xF8, 0x02,       // loop twice
            0xCC, 0x07,       // value = 7
            0xF7,             // loop end
            0x70,             // variation = value
            0x80,             // value = variation
            0xFE,             // one-tatum delay
            0xFF              // sequence end
        ]
        var player = SM64AudioSequencePlayerModel(sequenceData: script, tempoInternalToExternal: 5_760)
        var fingerprint = fnvOffset

        let first = player.tick()
        precondition(first.advancedTatum)
        precondition(first.delay == 2 && first.value == 0 && first.transposition == -2)
        precondition(first.enabledChannelMask == 0x0003)
        precondition(first.events.contains { $0.kind == .startChannel && $0.value0 == 0 })
        fingerprint = hashPacket(fingerprint, first)

        let waiting = player.tick()
        precondition(waiting.events.contains { $0.kind == .wait && $0.value0 == 1 })
        precondition(waiting.delay == 1 && waiting.programCounter == 16)
        fingerprint = hashPacket(fingerprint, waiting)

        let looped = player.tick()
        precondition(looped.events.contains { $0.kind == .loop && $0.value0 == 2 })
        precondition(looped.events.contains { $0.kind == .loopEnd && $0.value0 == 0 })
        precondition(looped.events.contains { $0.kind == .setVariation && $0.value0 == 7 })
        precondition(looped.delay == 1 && looped.value == 7)
        fingerprint = hashPacket(fingerprint, looped)

        let ended = player.tick()
        precondition(ended.finished && !ended.enabled)
        precondition(ended.events.contains { $0.kind == .end })
        fingerprint = hashPacket(fingerprint, ended)

        let frozen = player.tick(advanceAudioDomain: false)
        precondition(frozen == SM64AudioSequenceEventPacket(
            advancedTatum: false,
            events: [],
            enabled: false,
            finished: true,
            programCounter: ended.programCounter,
            tempo: ended.tempo,
            tempoAccumulator: ended.tempoAccumulator,
            delay: ended.delay,
            depth: ended.depth,
            value: ended.value,
            transposition: ended.transposition,
            variation: ended.variation,
            enabledChannelMask: ended.enabledChannelMask
        ))
        fingerprint = hashPacket(fingerprint, frozen)

        print("audioSequenceFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern audio sequence smoke passed")
    }
}
