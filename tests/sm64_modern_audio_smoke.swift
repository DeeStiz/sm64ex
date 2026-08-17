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

private func hashCommand(_ hash: UInt64, _ decoded: SM64AudioSequenceDecodedCommand) -> UInt64 {
    var value = hash
    var kind: UInt32 = 0
    var fields = Array(repeating: UInt32(0), count: 5)
    switch decoded.command {
    case let .note(semitone, playPercentage, velocity, duration, encoding):
        kind = 1; fields = [UInt32(semitone), UInt32(playPercentage), velocity.map(UInt32.init) ?? 0x1FF,
                          duration.map(UInt32.init) ?? 0x1FF, UInt32(encoding)]
    case let .delay(ticks): kind = 2; fields[0] = UInt32(ticks)
    case .end: kind = 3
    case let .call(offset): kind = 4; fields[0] = UInt32(bitPattern: Int32(offset))
    case let .loop(iterations): kind = 5; fields[0] = UInt32(iterations)
    case let .jump(offset): kind = 6; fields[0] = UInt32(bitPattern: Int32(offset))
    case let .setShortNoteVelocity(raw): kind = 7; fields[0] = UInt32(raw)
    case let .setPan(raw): kind = 8; fields[0] = UInt32(raw)
    case let .transpose(raw): kind = 9; fields[0] = UInt32(raw)
    case let .setShortNoteDuration(raw): kind = 10; fields[0] = UInt32(raw)
    case let .continuousNotes(enabled): kind = 11; fields[0] = enabled ? 1 : 0
    case let .setDefaultPlayPercentage(raw): kind = 12; fields[0] = UInt32(raw)
    case let .setInstrument(raw): kind = 13; fields[0] = UInt32(raw)
    case let .portamento(mode, target, time): kind = 14; fields[0] = UInt32(mode); fields[1] = UInt32(target); fields[2] = UInt32(time)
    case .disablePortamento: kind = 15
    case let .tableShortNoteVelocity(index): kind = 16; fields[0] = UInt32(index)
    case let .tableShortNoteDuration(index): kind = 17; fields[0] = UInt32(index)
    case let .unknown(opcode): kind = 18; fields[0] = UInt32(opcode)
    }
    value = hashU32(value, UInt32(decoded.nextOffset))
    value = hashU32(value, kind)
    for field in fields { value = hashU32(value, field) }
    return value
}

private func hashLoad(_ hash: UInt64, _ model: SM64AudioLoadModel) -> UInt64 {
    var value = hash
    value = hashU32(value, model.loadLock.rawValue)
    for status in [model.bankStatuses[3], model.bankStatuses[4], model.bankStatuses[5], model.bankStatuses[6],
                   model.sequenceStatuses[7], model.sequenceStatuses[8], model.sequenceStatuses[9]] {
        value = hashU32(value, UInt32(status.rawValue))
    }
    for player in model.players {
        value = hashU32(value, player.enabled ? 1 : 0)
        value = hashU32(value, player.finished ? 1 : 0)
        value = hashU32(value, UInt32(player.sequenceID))
        value = hashU32(value, UInt32(player.defaultBank))
        value = hashU32(value, player.sequenceDMAInProgress ? 1 : 0)
        value = hashU32(value, player.bankDMAInProgress ? 1 : 0)
    }
    return value
}

@main
enum SM64ModernAudioSmoke {
    static func main() {
        let commandFixtures: [([UInt8], Bool, UInt16, UInt16)] = [
            ([0x05, 0x81, 0x2C], false, 0, 0),
            ([0xC0, 0x82, 0x10], false, 0, 0),
            ([0xFC, 0xFF, 0xF0], false, 0, 0),
            ([0xF8, 0x00], false, 0, 0),
            ([0xC7, 0x81, 0x05, 0x07], false, 0, 0),
            ([0x42, 0x7F], true, 90, 0),
            ([0x82, 0x7F, 0x20], true, 90, 300),
            ([0xD3], false, 0, 0),
            ([0xE9], false, 0, 0),
            ([0xFF], false, 0, 0)
        ]
        var commandFingerprint = fnvOffset
        for (bytes, largeNotes, defaultPercentage, previousPercentage) in commandFixtures {
            guard let decoded = SM64AudioSequenceDecoder.decode(
                bytes,
                largeNotes: largeNotes,
                defaultPlayPercentage: defaultPercentage,
                previousPlayPercentage: previousPercentage
            ) else { preconditionFailure("decoder rejected fixture") }
            commandFingerprint = hashCommand(commandFingerprint, decoded)
        }

        let descriptors = [
            SM64AudioSequenceDescriptor(id: 7, byteLength: 0x80, requiredBanks: [3, 4]),
            SM64AudioSequenceDescriptor(id: 8, byteLength: 0x20, requiredBanks: [5]),
            SM64AudioSequenceDescriptor(id: 9, byteLength: 0x90, requiredBanks: [6, 7])
        ]
        var model = SM64AudioLoadModel(descriptors: descriptors)
        model.preload(sequenceID: 7, mask: .banks)
        precondition(model.loadLock == .notLoading)
        precondition(model.isBankAvailable(3) && model.isBankAvailable(4))

        model.loadSequence(player: 0, sequenceID: 7, asynchronous: true)
        precondition(model.players[0].enabled && model.players[0].sequenceDMAInProgress)
        precondition(model.sequenceStatuses[7] == .inProgress)
        model.processDMA(player: 0, completion: .sequence)
        precondition(model.sequenceStatuses[7] == .complete)
        model.disablePlayer(0)
        precondition(model.sequenceStatuses[7] == .discardable)
        precondition(model.bankStatuses[4] == .discardable)

        model.loadSequence(player: 1, sequenceID: 8, asynchronous: true)
        precondition(model.players[1].bankDMAInProgress)
        precondition(model.sequenceStatuses[8] == .complete)
        model.processDMA(player: 1, completion: .sequence)
        precondition(model.players[1].bankDMAInProgress)
        model.processDMA(player: 1, completion: .bank)
        precondition(model.bankStatuses[5] == .complete)

        model.loadSequence(player: 2, sequenceID: 9, asynchronous: true)
        precondition(!model.players[2].bankDMAInProgress && model.players[2].sequenceDMAInProgress)
        precondition(model.bankStatuses[6] == .complete && model.bankStatuses[7] == .complete)
        model.processDMA(player: 2, completion: .sequence)
        precondition(model.sequenceStatuses[9] == .complete)

        let fingerprint = hashLoad(commandFingerprint, model)
        print("audioFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern audio command/load smoke passed")
    }
}
