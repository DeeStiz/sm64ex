import Foundation

/// The load states used by `src/audio/heap.h`.
enum SM64AudioLoadStatus: UInt8, Equatable, Sendable {
    case notLoaded = 0
    case inProgress = 1
    case complete = 2
    case discardable = 3

    var isAvailable: Bool { rawValue >= Self.complete.rawValue }
}

enum SM64AudioLoadLock: UInt32, Equatable, Sendable {
    case uninitialized = 0
    case notLoading = 0x7655_7364
    case loading = 0x1971_0515
}

struct SM64AudioPreloadMask: OptionSet, Equatable, Sendable {
    let rawValue: UInt8

    static let sequence = Self(rawValue: 1)
    static let banks = Self(rawValue: 2)
}

struct SM64AudioSequenceDescriptor: Equatable, Sendable {
    let id: UInt8
    let byteLength: Int
    let requiredBanks: [UInt8]

    init(id: UInt8, byteLength: Int, requiredBanks: [UInt8]) {
        self.id = id
        self.byteLength = max(byteLength, 0)
        self.requiredBanks = requiredBanks
    }
}

struct SM64AudioSequencePlayerState: Equatable, Sendable {
    fileprivate(set) var enabled = false
    fileprivate(set) var finished = true
    fileprivate(set) var sequenceID: UInt8 = 0
    fileprivate(set) var defaultBank: UInt8 = 0
    fileprivate(set) var sequenceDMAInProgress = false
    fileprivate(set) var bankDMAInProgress = false
}

enum SM64AudioDMACompletion: Equatable, Sendable {
    case none
    case bank
    case sequence
}

/// A pre-synthesis load/ownership model for the US/JP three-player audio path.
///
/// It intentionally models status transitions and DMA ordering only. It does not
/// own ROM bytes, instrument pointers, audio lists, or synthesized samples.
struct SM64AudioLoadModel: Equatable, Sendable {
    static let playerCount = 3
    static let bankSlotCount = 64
    static let sequenceSlotCount = 256
    static let shortSequenceThreshold = 0x40

    private(set) var bankStatuses: [SM64AudioLoadStatus]
    private(set) var sequenceStatuses: [SM64AudioLoadStatus]
    private(set) var players: [SM64AudioSequencePlayerState]
    private(set) var loadLock: SM64AudioLoadLock = .notLoading
    private var descriptors: [SM64AudioSequenceDescriptor]

    init(descriptors: [SM64AudioSequenceDescriptor] = []) {
        bankStatuses = Array(repeating: .notLoaded, count: Self.bankSlotCount)
        sequenceStatuses = Array(repeating: .notLoaded, count: Self.sequenceSlotCount)
        players = Array(repeating: SM64AudioSequencePlayerState(), count: Self.playerCount)
        self.descriptors = []
        for descriptor in descriptors {
            register(descriptor)
        }
    }

    mutating func register(_ descriptor: SM64AudioSequenceDescriptor) {
        guard Int(descriptor.id) < Self.sequenceSlotCount,
              descriptor.requiredBanks.allSatisfy({ Int($0) < Self.bankSlotCount }) else {
            return
        }
        if let index = descriptors.firstIndex(where: { $0.id == descriptor.id }) {
            descriptors[index] = descriptor
        } else {
            descriptors.append(descriptor)
        }
    }

    func descriptor(for id: UInt8) -> SM64AudioSequenceDescriptor? {
        descriptors.first(where: { $0.id == id })
    }

    func isBankAvailable(_ id: UInt8) -> Bool {
        guard Int(id) < bankStatuses.count else { return false }
        return bankStatuses[Int(id)].isAvailable
    }

    func isSequenceAvailable(_ id: UInt8) -> Bool {
        sequenceStatuses[Int(id)].isAvailable
    }

    /// Mirrors `preload_sequence`: the lock is held only around the synchronous
    /// preload operation, and all selected resources finish immediately.
    mutating func preload(sequenceID: UInt8, mask: SM64AudioPreloadMask) {
        guard let descriptor = descriptor(for: sequenceID) else { return }
        loadLock = .loading
        if mask.contains(.banks) {
            completeBanks(descriptor.requiredBanks)
        }
        if mask.contains(.sequence) {
            sequenceStatuses[Int(sequenceID)] = .complete
        }
        loadLock = .notLoading
    }

    /// Mirrors `load_sequence_internal` for the status/ownership boundary.
    /// Async loads expose one missing bank and long sequence data as DMA work;
    /// multiple missing banks follow the source's immediate-bank path.
    mutating func loadSequence(player index: Int, sequenceID: UInt8, asynchronous: Bool) {
        guard players.indices.contains(index),
              let descriptor = descriptor(for: sequenceID) else { return }

        if !asynchronous { loadLock = .loading }
        disablePlayer(index)

        let missingBanks = descriptor.requiredBanks.filter {
            !bankStatuses[Int($0)].isAvailable
        }
        var bankDMAInProgress = false
        var defaultBank = descriptor.requiredBanks.last ?? 0
        if asynchronous && missingBanks.count == 1 {
            defaultBank = missingBanks[0]
            bankStatuses[Int(defaultBank)] = .inProgress
            bankDMAInProgress = true
        } else {
            completeBanks(descriptor.requiredBanks)
        }

        let sequenceAlreadyLoaded = sequenceStatuses[Int(sequenceID)].isAvailable
        var sequenceDMAInProgress = false
        if !sequenceAlreadyLoaded {
            if asynchronous && descriptor.byteLength > Self.shortSequenceThreshold {
                sequenceStatuses[Int(sequenceID)] = .inProgress
                sequenceDMAInProgress = true
            } else {
                sequenceStatuses[Int(sequenceID)] = .complete
            }
        }

        players[index] = SM64AudioSequencePlayerState(
            enabled: true,
            finished: false,
            sequenceID: sequenceID,
            defaultBank: defaultBank,
            sequenceDMAInProgress: sequenceDMAInProgress,
            bankDMAInProgress: bankDMAInProgress
        )
        if !asynchronous { loadLock = .notLoading }
    }

    /// Advances one source message boundary. The C player services bank DMA
    /// first and returns, so a bank completion cannot also complete sequence DMA
    /// in the same call.
    mutating func processDMA(player index: Int, completion: SM64AudioDMACompletion) {
        guard players.indices.contains(index), players[index].enabled else { return }
        var player = players[index]
        switch completion {
        case .none:
            return
        case .bank:
            guard player.bankDMAInProgress else { return }
            bankStatuses[Int(player.defaultBank)] = .complete
            player.bankDMAInProgress = false
            players[index] = player
            return
        case .sequence:
            guard !player.bankDMAInProgress, player.sequenceDMAInProgress else { return }
            sequenceStatuses[Int(player.sequenceID)] = .complete
            player.sequenceDMAInProgress = false
        }

        players[index] = player
        reconcile(player: index)
    }

    /// Mirrors `sequence_player_disable`: loaded resources become discardable,
    /// while the immutable model retains their IDs for the next request.
    mutating func disablePlayer(_ index: Int) {
        guard players.indices.contains(index) else { return }
        var player = players[index]
        if sequenceStatuses[Int(player.sequenceID)].isAvailable {
            sequenceStatuses[Int(player.sequenceID)] = .discardable
        }
        if bankStatuses[Int(player.defaultBank)].isAvailable {
            bankStatuses[Int(player.defaultBank)] = .discardable
        }
        player.enabled = false
        player.finished = true
        player.sequenceDMAInProgress = false
        player.bankDMAInProgress = false
        players[index] = player
    }

    private mutating func completeBanks(_ ids: [UInt8]) {
        for id in ids where Int(id) < bankStatuses.count {
            bankStatuses[Int(id)] = .complete
        }
    }

    private mutating func reconcile(player index: Int) {
        let player = players[index]
        guard sequenceStatuses[Int(player.sequenceID)].isAvailable,
              bankStatuses[Int(player.defaultBank)].isAvailable else {
            disablePlayer(index)
            return
        }
        sequenceStatuses[Int(player.sequenceID)] = .complete
        bankStatuses[Int(player.defaultBank)] = .complete
    }
}

enum SM64AudioSequenceCommand: Equatable, Sendable {
    case note(semitone: UInt8, playPercentage: UInt16, velocity: UInt8?, duration: UInt8?, encoding: UInt8)
    case delay(UInt16)
    case end
    case call(offset: Int16)
    case loop(iterations: UInt16)
    case jump(offset: Int16)
    case setShortNoteVelocity(UInt8)
    case setPan(UInt8)
    case transpose(UInt8)
    case setShortNoteDuration(UInt8)
    case continuousNotes(Bool)
    case setDefaultPlayPercentage(UInt16)
    case setInstrument(UInt8)
    case portamento(mode: UInt8, target: UInt8, time: UInt16)
    case disablePortamento
    case tableShortNoteVelocity(index: UInt8)
    case tableShortNoteDuration(index: UInt8)
    case unknown(opcode: UInt8)
}

struct SM64AudioSequenceDecodedCommand: Equatable, Sendable {
    let command: SM64AudioSequenceCommand
    let nextOffset: Int
}

/// Decodes one M64 layer command. This is deliberately pre-synthesis: it does
/// not allocate notes, resolve banks, or evaluate instrument tuning.
enum SM64AudioSequenceDecoder {
    static func decode(
        _ bytes: [UInt8],
        offset: Int = 0,
        largeNotes: Bool,
        defaultPlayPercentage: UInt16 = 0,
        previousPlayPercentage: UInt16 = 0
    ) -> SM64AudioSequenceDecodedCommand? {
        guard bytes.indices.contains(offset) else { return nil }
        let opcode = bytes[offset]
        var cursor = offset + 1

        func readByte() -> UInt8? {
            guard bytes.indices.contains(cursor) else { return nil }
            defer { cursor += 1 }
            return bytes[cursor]
        }

        func readCompressed() -> UInt16? {
            guard let first = readByte() else { return nil }
            if first & 0x80 == 0 { return UInt16(first) }
            guard let second = readByte() else { return nil }
            return UInt16(first & 0x7F) << 8 | UInt16(second)
        }

        func readSigned16() -> Int16? {
            guard let high = readByte(), let low = readByte() else { return nil }
            return Int16(bitPattern: UInt16(high) << 8 | UInt16(low))
        }

        let command: SM64AudioSequenceCommand?
        if opcode <= 0xC0 {
            if opcode == 0xC0 {
                command = readCompressed().map(SM64AudioSequenceCommand.delay)
            } else {
                let encoding = opcode & 0xC0
                let semitone = opcode & 0x3F
                var playPercentage: UInt16
                switch encoding {
                case 0x00:
                    guard let value = readCompressed() else { return nil }
                    playPercentage = value
                case 0x40:
                    playPercentage = defaultPlayPercentage
                default:
                    playPercentage = previousPlayPercentage
                }
                var velocity: UInt8?
                var duration: UInt8?
                if largeNotes {
                    guard let value = readByte() else { return nil }
                    velocity = value
                    if encoding != 0x40 {
                        guard let value = readByte() else { return nil }
                        duration = value
                    } else {
                        duration = 0
                    }
                }
                command = .note(
                    semitone: semitone,
                    playPercentage: playPercentage,
                    velocity: velocity,
                    duration: duration,
                    encoding: encoding >> 6
                )
            }
        } else {
            switch opcode {
            case 0xFF:
                command = .end
            case 0xFC:
                command = readSigned16().map(SM64AudioSequenceCommand.call)
            case 0xF8:
                guard let raw = readByte() else { return nil }
                command = .loop(iterations: raw == 0 ? 256 : UInt16(raw))
            case 0xFB:
                command = readSigned16().map(SM64AudioSequenceCommand.jump)
            case 0xC1:
                command = readByte().map(SM64AudioSequenceCommand.setShortNoteVelocity)
            case 0xCA:
                command = readByte().map(SM64AudioSequenceCommand.setPan)
            case 0xC2:
                command = readByte().map(SM64AudioSequenceCommand.transpose)
            case 0xC9:
                command = readByte().map(SM64AudioSequenceCommand.setShortNoteDuration)
            case 0xC4:
                command = .continuousNotes(true)
            case 0xC5:
                command = .continuousNotes(false)
            case 0xC3:
                command = readCompressed().map(SM64AudioSequenceCommand.setDefaultPlayPercentage)
            case 0xC6:
                command = readByte().map(SM64AudioSequenceCommand.setInstrument)
            case 0xC7:
                guard let mode = readByte(), let target = readByte() else { return nil }
                guard let time = (mode & 0x80) != 0 ? readByte().map(UInt16.init) : readCompressed() else {
                    return nil
                }
                command = .portamento(mode: mode, target: target, time: time)
            case 0xC8:
                command = .disablePortamento
            default:
                if opcode & 0xF0 == 0xD0 {
                    command = .tableShortNoteVelocity(index: opcode & 0x0F)
                } else if opcode & 0xF0 == 0xE0 {
                    command = .tableShortNoteDuration(index: opcode & 0x0F)
                } else {
                    command = .unknown(opcode: opcode)
                }
            }
        }
        guard let command else { return nil }
        return SM64AudioSequenceDecodedCommand(command: command, nextOffset: cursor)
    }
}
