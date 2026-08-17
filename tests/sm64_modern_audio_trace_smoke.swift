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

private func hashSession(_ session: SM64AudioPreSynthesisTraceSession) -> UInt64 {
    var value = hashU64(fnvOffset, UInt64(session.records.count))
    for record in session.records {
        value = hashU64(value, record.canonicalHash)
    }
    return hashU64(value, session.admissionFailed ? 1 : 0)
}

@main
enum SM64ModernAudioTraceSmoke {
    static func main() throws {
        let ownerToken: UInt64 = 0xA11CE
        var session = SM64AudioPreSynthesisTraceSession(ownerToken: ownerToken)
        let sequenceEvents = [
            SM64AudioSequenceEvent(.tatum, opcode: 0),
            SM64AudioSequenceEvent(.tempoSet, opcode: 0xDD, value0: 5_760)
        ]
        let packet = SM64AudioSequenceEventPacket(
            advancedTatum: true,
            events: sequenceEvents,
            enabled: true,
            finished: false,
            programCounter: 2,
            tempo: 5_760,
            tempoAccumulator: 0,
            delay: 0,
            depth: 0,
            value: 0,
            transposition: 0,
            variation: -1,
            enabledChannelMask: 1
        )
        precondition(session.append(ownerToken: ownerToken, simulationTick: 1, player: 0, packet: packet))
        let poolEvent = SM64AudioPoolEvent(
            kind: .noteFromActive,
            scope: 0,
            index: 3,
            noteID: 2,
            value: 2
        )
        precondition(session.append(ownerToken: ownerToken, simulationTick: 2, channel: 0, event: poolEvent))
        let residencyEvent = SM64AudioResidencyEvent(
            kind: .poolSideSelected,
            resource: .bank,
            id: 10,
            index: 0,
            value: 160
        )
        precondition(session.append(ownerToken: ownerToken, simulationTick: 2, subjectID: 10, event: residencyEvent))
        let streamEvent = SM64AudioResidencyEvent(
            kind: .streamAllocated,
            resource: .bank,
            id: 10,
            index: 0,
            value: 0x1230
        )
        precondition(session.append(ownerToken: ownerToken, simulationTick: 3, subjectID: 10, event: streamEvent, source: .stream))
        precondition(session.records.count == 5)
        precondition(session.records.map(\.domain) == Array(repeating: 9, count: 5))
        precondition(session.records.map(\.sequence) == [0, 1, 2, 3, 4])
        precondition(session.records[0].recordID == 0xA701_0001)
        precondition(session.records[2].recordID == 0xA702_000A)
        precondition(session.records[4].recordID == 0xA704_0014)

        let foreignAppend = session.append(
            ownerToken: 0xBAD,
            simulationTick: 4,
            player: 0,
            event: SM64AudioSequenceEvent(.wait, opcode: 0, value0: 1)
        )
        precondition(!foreignAppend)
        precondition(session.admissionFailed)
        precondition(session.records.count == 5)

        let roundTrip = try session.records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == session.records)
        print("audioTraceFingerprint=0x\(String(hashSession(session), radix: 16))")
        print("SM64 Modern audio trace smoke passed")
    }
}
