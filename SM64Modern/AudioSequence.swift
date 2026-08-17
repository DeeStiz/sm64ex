import Foundation

enum SM64AudioSequenceEventKind: UInt8, Equatable, Sendable {
    case tatum = 1
    case wait = 2
    case end = 3
    case `return` = 4
    case call = 5
    case loop = 6
    case loopEnd = 7
    case jump = 8
    case branch = 9
    case reserveNotes = 10
    case unreserveNotes = 11
    case transpose = 12
    case tempoSet = 13
    case tempoAdd = 14
    case setVolume = 15
    case changeVolume = 16
    case initChannels = 17
    case disableChannels = 18
    case setMuteScale = 19
    case mute = 20
    case setMuteBehavior = 21
    case setVelocityTable = 22
    case setDurationTable = 23
    case setAllocationPolicy = 24
    case setValue = 25
    case bitAnd = 26
    case subtract = 27
    case testChannel = 28
    case setVariation = 29
    case getVariation = 30
    case startChannel = 31
    case ignored = 32
    case malformed = 33
    case mutedStop = 34
}

struct SM64AudioSequenceEvent: Equatable, Sendable {
    let kind: SM64AudioSequenceEventKind
    let opcode: UInt8
    let value0: Int32
    let value1: Int32

    init(
        _ kind: SM64AudioSequenceEventKind,
        opcode: UInt8,
        value0: Int32 = 0,
        value1: Int32 = 0
    ) {
        self.kind = kind
        self.opcode = opcode
        self.value0 = value0
        self.value1 = value1
    }
}

struct SM64AudioSequenceEventPacket: Equatable, Sendable {
    let advancedTatum: Bool
    let events: [SM64AudioSequenceEvent]
    let enabled: Bool
    let finished: Bool
    let programCounter: Int
    let tempo: UInt16
    let tempoAccumulator: UInt16
    let delay: UInt16
    let depth: UInt8
    let value: Int32
    let transposition: Int16
    let variation: Int16
    let enabledChannelMask: UInt16
}

/// Owner-thread/value-only sequence-player script state before channel and
/// synthesis ownership is attached.
struct SM64AudioSequencePlayerModel: Equatable, Sendable {
    static let tempoScale: UInt16 = 48
    static let defaultTempo: UInt16 = 120 * Self.tempoScale
    static let channelCount = 16
    static let scriptStackDepth = 4

    let sequenceData: [UInt8]
    let tempoInternalToExternal: UInt16
    private(set) var enabled = true
    private(set) var finished = false
    private(set) var programCounter = 0
    private(set) var tempo: UInt16
    private(set) var tempoAccumulator: UInt16 = 0
    private(set) var delay: UInt16 = 0
    private(set) var depth: UInt8 = 0
    private(set) var value: Int32 = 0
    private(set) var transposition: Int16 = 0
    private(set) var variation: Int16 = -1
    private(set) var muted = false
    private(set) var muteBehavior: UInt8 = 0xE0
    private(set) var muteVolumeScale: Int16 = 63
    private(set) var fadeVolume: Int16 = 127
    private(set) var channelEnabledMask: UInt16 = 0
    private(set) var channelFinishedMask: UInt16 = 0
    private var stack = Array(repeating: 0, count: Self.scriptStackDepth)
    private var loopIterations = Array(repeating: UInt8(0), count: Self.scriptStackDepth)

    init(sequenceData: [UInt8], tempoInternalToExternal: UInt16 = 14_360) {
        self.sequenceData = sequenceData
        self.tempoInternalToExternal = max(tempoInternalToExternal, 1)
        tempo = Self.defaultTempo
    }

    mutating func tick(advanceAudioDomain: Bool = true) -> SM64AudioSequenceEventPacket {
        var events: [SM64AudioSequenceEvent] = []
        guard advanceAudioDomain, enabled else {
            return packet(advancedTatum: false, events: events)
        }

        tempoAccumulator = tempoAccumulator &+ tempo
        guard tempoAccumulator >= tempoInternalToExternal else {
            return packet(advancedTatum: false, events: events)
        }
        tempoAccumulator = tempoAccumulator &- tempoInternalToExternal
        events.append(SM64AudioSequenceEvent(.tatum, opcode: 0))

        if delay > 1 {
            delay &-= 1
            events.append(SM64AudioSequenceEvent(.wait, opcode: 0, value0: Int32(delay)))
            return packet(advancedTatum: true, events: events)
        }
        if muted && (muteBehavior & 0x80) != 0 {
            events.append(SM64AudioSequenceEvent(.mutedStop, opcode: 0))
            return packet(advancedTatum: true, events: events)
        }

        while enabled {
            guard let opcode = readByte() else {
                events.append(SM64AudioSequenceEvent(.malformed, opcode: 0, value0: Int32(programCounter)))
                enabled = false
                finished = true
                break
            }

            if opcode == 0xFF {
                events.append(SM64AudioSequenceEvent(.end, opcode: opcode))
                if depth == 0 {
                    enabled = false
                    finished = true
                    break
                }
                depth -= 1
                programCounter = stack[Int(depth)]
                events.append(SM64AudioSequenceEvent(.return, opcode: opcode, value0: Int32(programCounter)))
                continue
            }
            if opcode == 0xFD {
                guard let value = readCompressed() else {
                    return malformedPacket(events: &events, opcode: opcode)
                }
                delay = value
                events.append(SM64AudioSequenceEvent(.wait, opcode: opcode, value0: Int32(value)))
                break
            }
            if opcode == 0xFE {
                delay = 1
                events.append(SM64AudioSequenceEvent(.wait, opcode: opcode, value0: 1))
                break
            }

            if opcode >= 0xC0 {
                guard executeControl(opcode, events: &events) else {
                    return malformedPacket(events: &events, opcode: opcode)
                }
            } else {
                executeLowCommand(opcode, events: &events)
            }
        }
        return packet(advancedTatum: true, events: events)
    }

    private mutating func executeControl(_ opcode: UInt8, events: inout [SM64AudioSequenceEvent]) -> Bool {
        switch opcode {
        case 0xFC:
            guard let offset = readSigned16(), depth < Self.scriptStackDepth,
                  setProgramCounter(to: Int(offset)) else { return false }
            stack[Int(depth)] = programCounter
            depth += 1
            programCounter = Int(offset)
            events.append(SM64AudioSequenceEvent(.call, opcode: opcode, value0: Int32(offset), value1: Int32(programCounter)))
        case 0xF8:
            guard let raw = readByte(), depth < Self.scriptStackDepth else { return false }
            loopIterations[Int(depth)] = raw
            stack[Int(depth)] = programCounter
            depth += 1
            events.append(SM64AudioSequenceEvent(.loop, opcode: opcode, value0: raw == 0 ? 256 : Int32(raw), value1: Int32(programCounter)))
        case 0xF7:
            guard depth > 0 else { return false }
            let index = Int(depth - 1)
            loopIterations[index] &-= 1
            if loopIterations[index] != 0 {
                programCounter = stack[index]
            } else {
                depth -= 1
            }
            events.append(SM64AudioSequenceEvent(.loopEnd, opcode: opcode, value0: Int32(loopIterations[index]), value1: Int32(programCounter)))
        case 0xFB, 0xFA, 0xF9, 0xF5:
            guard let offset = readSigned16() else { return false }
            let taken: Bool
            switch opcode {
            case 0xFB: taken = true
            case 0xFA: taken = value == 0
            case 0xF9: taken = value < 0
            default: taken = value >= 0
            }
            if taken {
                guard setProgramCounter(to: Int(offset)) else { return false }
                programCounter = Int(offset)
            }
            events.append(SM64AudioSequenceEvent(.branch, opcode: opcode, value0: Int32(offset), value1: taken ? 1 : 0))
        case 0xF2:
            guard let count = readByte() else { return false }
            events.append(SM64AudioSequenceEvent(.reserveNotes, opcode: opcode, value0: Int32(count)))
        case 0xF1:
            events.append(SM64AudioSequenceEvent(.unreserveNotes, opcode: opcode))
        case 0xDF, 0xDE:
            guard let raw = readByte() else { return false }
            if opcode == 0xDF { transposition = 0 }
            transposition = Int16(clamping: Int(transposition) + Int(Int8(bitPattern: raw)))
            events.append(SM64AudioSequenceEvent(.transpose, opcode: opcode, value0: Int32(transposition)))
        case 0xDD, 0xDC:
            guard let raw = readByte() else { return false }
            if opcode == 0xDD {
                tempo = UInt16(raw) &* Self.tempoScale
            } else {
                let adjusted = Int(tempo) + Int(Int8(bitPattern: raw)) * Int(Self.tempoScale)
                tempo = UInt16(clamping: adjusted)
            }
            tempo = min(max(tempo, 1), tempoInternalToExternal)
            events.append(SM64AudioSequenceEvent(opcode == 0xDD ? .tempoSet : .tempoAdd, opcode: opcode, value0: Int32(tempo)))
        case 0xDB:
            guard let raw = readByte() else { return false }
            fadeVolume = Int16(clamping: Int(raw))
            events.append(SM64AudioSequenceEvent(.setVolume, opcode: opcode, value0: Int32(fadeVolume)))
        case 0xDA:
            guard let raw = readByte() else { return false }
            fadeVolume = Int16(clamping: Int(fadeVolume) + Int(Int8(bitPattern: raw)))
            events.append(SM64AudioSequenceEvent(.changeVolume, opcode: opcode, value0: Int32(fadeVolume)))
        case 0xD7, 0xD6:
            guard let mask = readSigned16() else { return false }
            let bits = UInt16(bitPattern: mask)
            if opcode == 0xD7 {
                channelEnabledMask |= bits
                channelFinishedMask &= ~bits
            } else {
                channelEnabledMask &= ~bits
                channelFinishedMask |= bits
            }
            events.append(SM64AudioSequenceEvent(opcode == 0xD7 ? .initChannels : .disableChannels, opcode: opcode, value0: Int32(mask)))
        case 0xD5:
            guard let raw = readByte() else { return false }
            muteVolumeScale = Int16(clamping: Int(Int8(bitPattern: raw)))
            events.append(SM64AudioSequenceEvent(.setMuteScale, opcode: opcode, value0: Int32(muteVolumeScale)))
        case 0xD4:
            muted = true
            events.append(SM64AudioSequenceEvent(.mute, opcode: opcode))
        case 0xD3:
            guard let raw = readByte() else { return false }
            muteBehavior = raw
            events.append(SM64AudioSequenceEvent(.setMuteBehavior, opcode: opcode, value0: Int32(raw)))
        case 0xD2, 0xD1:
            guard let offset = readSigned16() else { return false }
            events.append(SM64AudioSequenceEvent(opcode == 0xD2 ? .setVelocityTable : .setDurationTable, opcode: opcode, value0: Int32(offset)))
        case 0xD0:
            guard let raw = readByte() else { return false }
            events.append(SM64AudioSequenceEvent(.setAllocationPolicy, opcode: opcode, value0: Int32(raw)))
        case 0xCC:
            guard let raw = readByte() else { return false }
            value = Int32(Int8(bitPattern: raw))
            events.append(SM64AudioSequenceEvent(.setValue, opcode: opcode, value0: value))
        case 0xC9:
            guard let raw = readByte() else { return false }
            value &= Int32(raw)
            events.append(SM64AudioSequenceEvent(.bitAnd, opcode: opcode, value0: value))
        case 0xC8:
            guard let raw = readByte() else { return false }
            value -= Int32(raw)
            events.append(SM64AudioSequenceEvent(.subtract, opcode: opcode, value0: value))
        default:
            events.append(SM64AudioSequenceEvent(.ignored, opcode: opcode))
        }
        return true
    }

    private mutating func executeLowCommand(_ opcode: UInt8, events: inout [SM64AudioSequenceEvent]) {
        let lowBits = opcode & 0x0F
        switch opcode & 0xF0 {
        case 0x00:
            if channelEnabledMask & (UInt16(1) << UInt16(lowBits)) != 0 {
                value = (channelFinishedMask & (UInt16(1) << UInt16(lowBits))) != 0 ? 1 : 0
            }
            events.append(SM64AudioSequenceEvent(.testChannel, opcode: opcode, value0: value))
        case 0x50:
            value -= Int32(variation)
            events.append(SM64AudioSequenceEvent(.subtract, opcode: opcode, value0: value))
        case 0x70:
            variation = Int16(clamping: Int(value))
            events.append(SM64AudioSequenceEvent(.setVariation, opcode: opcode, value0: value))
        case 0x80:
            value = Int32(variation)
            events.append(SM64AudioSequenceEvent(.getVariation, opcode: opcode, value0: value))
        case 0x90:
            guard let offset = readSigned16(), setProgramCounter(to: programCounter) else {
                events.append(SM64AudioSequenceEvent(.malformed, opcode: opcode, value0: Int32(programCounter)))
                return
            }
            channelEnabledMask |= UInt16(1) << UInt16(lowBits)
            channelFinishedMask &= ~(UInt16(1) << UInt16(lowBits))
            events.append(SM64AudioSequenceEvent(.startChannel, opcode: opcode, value0: Int32(lowBits), value1: Int32(offset)))
        default:
            events.append(SM64AudioSequenceEvent(.ignored, opcode: opcode))
        }
    }

    private mutating func readByte() -> UInt8? {
        guard sequenceData.indices.contains(programCounter) else { return nil }
        defer { programCounter += 1 }
        return sequenceData[programCounter]
    }

    private mutating func readCompressed() -> UInt16? {
        guard let first = readByte() else { return nil }
        if first & 0x80 == 0 { return UInt16(first) }
        guard let second = readByte() else { return nil }
        return UInt16(first & 0x7F) << 8 | UInt16(second)
    }

    private mutating func readSigned16() -> Int16? {
        guard let high = readByte(), let low = readByte() else { return nil }
        return Int16(bitPattern: UInt16(high) << 8 | UInt16(low))
    }

    private func setProgramCounter(to offset: Int) -> Bool {
        sequenceData.indices.contains(offset)
    }

    private mutating func malformedPacket(
        events: inout [SM64AudioSequenceEvent],
        opcode: UInt8
    ) -> SM64AudioSequenceEventPacket {
        events.append(SM64AudioSequenceEvent(.malformed, opcode: opcode, value0: Int32(programCounter)))
        enabled = false
        finished = true
        return packet(advancedTatum: true, events: events)
    }

    private func packet(advancedTatum: Bool, events: [SM64AudioSequenceEvent]) -> SM64AudioSequenceEventPacket {
        SM64AudioSequenceEventPacket(
            advancedTatum: advancedTatum,
            events: events,
            enabled: enabled,
            finished: finished,
            programCounter: programCounter,
            tempo: tempo,
            tempoAccumulator: tempoAccumulator,
            delay: delay,
            depth: depth,
            value: value,
            transposition: transposition,
            variation: variation,
            enabledChannelMask: channelEnabledMask
        )
    }
}
