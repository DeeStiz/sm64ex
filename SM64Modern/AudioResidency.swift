import Foundation

enum SM64AudioResidencyKind: UInt8, Equatable, Sendable {
    case sequence = 0
    case bank = 1
}

enum SM64AudioStreamClass: UInt8, Equatable, Sendable {
    case short = 0
    case long = 1

    var lifetime: Int { self == .short ? 2 : 60 }
}

struct SM64AudioSoundDescriptor: Equatable, Sendable {
    let sampleID: Int?
    let tuningMilli: Int
}

struct SM64AudioInstrumentDescriptor: Equatable, Sendable {
    let id: Int
    let loaded: Bool
    let normalRangeLo: Int
    let normalRangeHi: Int
    let releaseRate: Int
    let lowNotesSound: SM64AudioSoundDescriptor?
    let normalNotesSound: SM64AudioSoundDescriptor?
    let highNotesSound: SM64AudioSoundDescriptor?
}

struct SM64AudioDrumDescriptor: Equatable, Sendable {
    let id: Int
    let loaded: Bool
    let releaseRate: Int
    let pan: Int
    let sound: SM64AudioSoundDescriptor?
}

struct SM64AudioBankDescriptor: Equatable, Sendable {
    let id: Int
    let instruments: [SM64AudioInstrumentDescriptor?]
    let drums: [SM64AudioDrumDescriptor?]
}

struct SM64AudioSampleDescriptor: Equatable, Sendable {
    let id: Int
    let loaded: Bool
    let encoded: Bool
    let loopStart: Int
    let loopEnd: Int
    let bookID: Int?
    let sampleSize: Int
}

struct SM64AudioResidencySlot: Equatable, Sendable {
    let side: Int
    fileprivate(set) var resourceID: Int?
    fileprivate(set) var size: Int = 0
    fileprivate(set) var status: SM64AudioLoadStatus = .notLoaded
    fileprivate(set) var generation: Int = 0
}

struct SM64AudioStreamSlot: Equatable, Sendable {
    let index: Int
    fileprivate(set) var sampleID: Int?
    fileprivate(set) var source: Int = 0
    fileprivate(set) var bufferSize: Int
    fileprivate(set) var ttl: Int = 0
    fileprivate(set) var reuseIndex: Int = -1

    init(index: Int, bufferSize: Int) {
        self.index = index
        self.bufferSize = max(bufferSize, 0)
    }
}

enum SM64AudioResidencyEventKind: UInt8, Equatable, Sendable {
    case poolSideSelected = 1
    case resourceEvicted = 2
    case allocationFailed = 3
    case loadStarted = 4
    case loadCompleted = 5
    case resourceDiscardable = 6
    case residencyTouched = 7
    case instrumentUnavailable = 8
    case instrumentOutOfRange = 9
    case instrumentMissing = 10
    case instrumentResolved = 11
    case drumOutOfRange = 12
    case drumMissing = 13
    case drumResolved = 14
    case soundRangeSelected = 15
    case sampleUnavailable = 16
    case sampleResolved = 17
    case streamHit = 18
    case streamMiss = 19
    case streamAllocated = 20
    case streamExpired = 21
    case streamAllocationFailed = 22
}

struct SM64AudioResidencyEvent: Equatable, Sendable {
    let kind: SM64AudioResidencyEventKind
    let resource: SM64AudioResidencyKind
    let id: Int
    let index: Int
    let value: Int
}

struct SM64AudioResidencyTrace: Equatable, Sendable {
    let events: [SM64AudioResidencyEvent]
    let selectedID: Int?
    let failed: Bool
}

/// Copied bank/instrument/sample identity and bounded sample-DMA residency.
/// It deliberately contains no ROM pointers, C globals, PCM, or AVAudio state.
struct SM64AudioResidencyModel: Equatable, Sendable {
    let bankCapacity: Int
    let sequenceCapacity: Int
    private(set) var bankStatuses: [SM64AudioLoadStatus]
    private(set) var sequenceStatuses: [SM64AudioLoadStatus]
    private(set) var bankSlots: [SM64AudioResidencySlot]
    private(set) var sequenceSlots: [SM64AudioResidencySlot]
    private(set) var bankNextSide = 0
    private(set) var sequenceNextSide = 0
    private(set) var banks: [Int: SM64AudioBankDescriptor] = [:]
    private(set) var samples: [Int: SM64AudioSampleDescriptor] = [:]
    private(set) var shortStreamSlots: [SM64AudioStreamSlot]
    private(set) var longStreamSlots: [SM64AudioStreamSlot]
    private(set) var shortReuseQueue: [Int]
    private(set) var longReuseQueue: [Int]

    init(
        bankCapacity: Int = 64,
        sequenceCapacity: Int = 256,
        shortStreamCapacity: Int = 4,
        longStreamCapacity: Int = 4,
        shortBufferSize: Int = 1296,
        longBufferSize: Int = 1440
    ) {
        self.bankCapacity = max(bankCapacity, 0)
        self.sequenceCapacity = max(sequenceCapacity, 0)
        bankStatuses = Array(repeating: .notLoaded, count: self.bankCapacity)
        sequenceStatuses = Array(repeating: .notLoaded, count: self.sequenceCapacity)
        bankSlots = (0..<2).map { SM64AudioResidencySlot(side: $0, resourceID: nil) }
        sequenceSlots = (0..<2).map { SM64AudioResidencySlot(side: $0, resourceID: nil) }
        shortStreamSlots = (0..<max(shortStreamCapacity, 0)).map {
            SM64AudioStreamSlot(index: $0, bufferSize: shortBufferSize)
        }
        longStreamSlots = (0..<max(longStreamCapacity, 0)).map {
            SM64AudioStreamSlot(index: $0, bufferSize: longBufferSize)
        }
        shortReuseQueue = Array(0..<shortStreamSlots.count)
        longReuseQueue = Array(0..<longStreamSlots.count)
    }

    mutating func register(_ bank: SM64AudioBankDescriptor) {
        guard bank.id >= 0, bank.id < bankCapacity else { return }
        banks[bank.id] = bank
    }

    mutating func register(_ sample: SM64AudioSampleDescriptor) {
        guard sample.id >= 0 else { return }
        samples[sample.id] = sample
    }

    func status(_ kind: SM64AudioResidencyKind, id: Int) -> SM64AudioLoadStatus? {
        switch kind {
        case .bank: return bankStatuses.indices.contains(id) ? bankStatuses[id] : nil
        case .sequence: return sequenceStatuses.indices.contains(id) ? sequenceStatuses[id] : nil
        }
    }

    mutating func loadBank(id: Int, size: Int, asynchronous: Bool) -> SM64AudioResidencyTrace {
        load(kind: .bank, id: id, size: size, asynchronous: asynchronous)
    }

    mutating func loadSequence(id: Int, size: Int, asynchronous: Bool) -> SM64AudioResidencyTrace {
        let trace = load(kind: .sequence, id: id, size: size, asynchronous: asynchronous)
        if !asynchronous || size <= SM64AudioLoadModel.shortSequenceThreshold {
            return trace
        }
        return trace
    }

    mutating func complete(_ kind: SM64AudioResidencyKind, id: Int) -> SM64AudioResidencyTrace {
        guard let slot = slotIndex(kind, id: id) else {
            return failure(.allocationFailed, resource: kind, id: id, index: -1)
        }
        setStatus(kind, id: id, status: .complete)
        return trace(
            SM64AudioResidencyEvent(kind: .loadCompleted, resource: kind, id: id, index: slot, value: 0),
            selectedID: id
        )
    }

    mutating func markDiscardable(_ kind: SM64AudioResidencyKind, id: Int) -> SM64AudioResidencyTrace {
        guard slotIndex(kind, id: id) != nil else {
            return failure(.allocationFailed, resource: kind, id: id, index: -1)
        }
        setStatus(kind, id: id, status: .discardable)
        return trace(
            SM64AudioResidencyEvent(kind: .resourceDiscardable, resource: kind, id: id, index: -1, value: 0),
            selectedID: id
        )
    }

    mutating func touch(_ kind: SM64AudioResidencyKind, id: Int) -> SM64AudioResidencyTrace {
        guard let slot = slotIndex(kind, id: id) else {
            return failure(.allocationFailed, resource: kind, id: id, index: -1)
        }
        setNextSide(kind, slot == 0 ? 1 : 0)
        return trace(
            SM64AudioResidencyEvent(kind: .residencyTouched, resource: kind, id: id, index: slot, value: nextSide(kind)),
            selectedID: id
        )
    }

    mutating func lookupInstrument(
        bankID: Int,
        instrumentID: Int,
        fallbackToLower: Bool = false,
        clampOutOfRange: Bool = false
    ) -> SM64AudioResidencyTrace {
        guard status(.bank, id: bankID)?.isAvailable == true else {
            return failure(.instrumentUnavailable, resource: .bank, id: bankID, index: instrumentID)
        }
        guard let bank = banks[bankID] else {
            return failure(.instrumentMissing, resource: .bank, id: bankID, index: instrumentID)
        }
        guard !bank.instruments.isEmpty else {
            return failure(.instrumentMissing, resource: .bank, id: bankID, index: instrumentID)
        }
        if instrumentID < 0 {
            return failure(.instrumentOutOfRange, resource: .bank, id: bankID, index: instrumentID)
        }
        var candidate = instrumentID
        if candidate >= bank.instruments.count {
            guard clampOutOfRange else {
                return failure(.instrumentOutOfRange, resource: .bank, id: bankID, index: instrumentID)
            }
            candidate = bank.instruments.count - 1
        }
        while candidate >= 0 {
            if let instrument = bank.instruments[candidate], instrument.loaded {
                let event = SM64AudioResidencyEvent(
                    kind: .instrumentResolved,
                    resource: .bank,
                    id: bankID,
                    index: candidate,
                    value: instrument.releaseRate
                )
                return trace(event, selectedID: candidate)
            }
            if !fallbackToLower { break }
            candidate -= 1
        }
        return failure(.instrumentMissing, resource: .bank, id: bankID, index: instrumentID)
    }

    mutating func lookupDrum(bankID: Int, drumID: Int) -> SM64AudioResidencyTrace {
        guard status(.bank, id: bankID)?.isAvailable == true,
              let bank = banks[bankID] else {
            return failure(.instrumentUnavailable, resource: .bank, id: bankID, index: drumID)
        }
        guard drumID >= 0, drumID < bank.drums.count else {
            return failure(.drumOutOfRange, resource: .bank, id: bankID, index: drumID)
        }
        guard let drum = bank.drums[drumID], drum.loaded else {
            return failure(.drumMissing, resource: .bank, id: bankID, index: drumID)
        }
        return trace(
            SM64AudioResidencyEvent(kind: .drumResolved, resource: .bank, id: bankID, index: drumID, value: drum.pan),
            selectedID: drumID
        )
    }

    mutating func selectSound(
        bankID: Int,
        instrumentID: Int,
        semitone: Int,
        fallbackToLower: Bool = false
    ) -> SM64AudioResidencyTrace {
        let instrumentTrace = lookupInstrument(
            bankID: bankID,
            instrumentID: instrumentID,
            fallbackToLower: fallbackToLower,
            clampOutOfRange: fallbackToLower
        )
        guard let selectedInstrument = instrumentTrace.selectedID,
              let bank = banks[bankID],
              let instrument = bank.instruments[selectedInstrument] else {
            return instrumentTrace
        }
        let range: Int
        let sound: SM64AudioSoundDescriptor?
        if semitone < instrument.normalRangeLo {
            range = 0
            sound = instrument.lowNotesSound
        } else if semitone <= instrument.normalRangeHi {
            range = 1
            sound = instrument.normalNotesSound
        } else {
            range = 2
            sound = instrument.highNotesSound
        }
        var events = instrumentTrace.events
        events.append(SM64AudioResidencyEvent(
            kind: .soundRangeSelected,
            resource: .bank,
            id: bankID,
            index: range,
            value: semitone
        ))
        guard let sampleID = sound?.sampleID, samples[sampleID]?.loaded == true else {
            events.append(SM64AudioResidencyEvent(
                kind: .sampleUnavailable,
                resource: .bank,
                id: bankID,
                index: range,
                value: semitone
            ))
            return SM64AudioResidencyTrace(events: events, selectedID: nil, failed: true)
        }
        events.append(SM64AudioResidencyEvent(
            kind: .sampleResolved,
            resource: .bank,
            id: sampleID,
            index: range,
            value: sound?.tuningMilli ?? 0
        ))
        return SM64AudioResidencyTrace(events: events, selectedID: sampleID, failed: false)
    }

    mutating func requestSample(
        sampleID: Int,
        deviceAddress: Int,
        size: Int,
        streamClass: SM64AudioStreamClass,
        hint: Int? = nil
    ) -> SM64AudioResidencyTrace {
        guard samples[sampleID]?.loaded == true else {
            return failure(.sampleUnavailable, resource: .bank, id: sampleID, index: -1)
        }
        let aligned = deviceAddress & ~0xF
        let classSlots = streamClass == .short ? shortStreamSlots : longStreamSlots
        if let hit = findStreamHit(classSlots, address: deviceAddress, size: size, hint: hint, useHint: streamClass == .short) {
            var events = [SM64AudioResidencyEvent(
                kind: .streamHit,
                resource: .bank,
                id: sampleID,
                index: hit,
                value: Int(streamClass.rawValue)
            )]
            setStreamTTL(streamClass, index: hit)
            removeFromReuse(streamClass, index: hit)
            events.append(SM64AudioResidencyEvent(
                kind: .sampleResolved,
                resource: .bank,
                id: sampleID,
                index: hit,
                value: streamClass.lifetime
            ))
            return SM64AudioResidencyTrace(events: events, selectedID: hit, failed: false)
        }

        var events = [SM64AudioResidencyEvent(
            kind: .streamMiss,
            resource: .bank,
            id: sampleID,
            index: -1,
            value: Int(streamClass.rawValue)
        )]
        guard let slot = takeReusable(streamClass) else {
            events.append(SM64AudioResidencyEvent(
                kind: .streamAllocationFailed,
                resource: .bank,
                id: sampleID,
                index: -1,
                value: Int(streamClass.rawValue)
            ))
            return SM64AudioResidencyTrace(events: events, selectedID: nil, failed: true)
        }
        updateStreamSlot(streamClass, index: slot, sampleID: sampleID, source: aligned)
        events.append(SM64AudioResidencyEvent(
            kind: .streamAllocated,
            resource: .bank,
            id: sampleID,
            index: slot,
            value: aligned
        ))
        return SM64AudioResidencyTrace(events: events, selectedID: slot, failed: false)
    }

    mutating func advanceStreamTTL() -> SM64AudioResidencyTrace {
        var events: [SM64AudioResidencyEvent] = []
        expireStreams(.short, events: &events)
        expireStreams(.long, events: &events)
        return SM64AudioResidencyTrace(events: events, selectedID: nil, failed: false)
    }

    private mutating func load(
        kind: SM64AudioResidencyKind,
        id: Int,
        size: Int,
        asynchronous: Bool
    ) -> SM64AudioResidencyTrace {
        guard validResource(kind, id: id) else {
            return failure(.allocationFailed, resource: kind, id: id, index: -1)
        }
        let currentStatuses = statuses(kind)
        let slots = residencySlots(kind)
        let first = slots[0].resourceID.flatMap { currentStatuses[$0] } ?? .notLoaded
        let second = slots[1].resourceID.flatMap { currentStatuses[$0] } ?? .notLoaded
        let selected: Int?
        if first == .notLoaded {
            selected = 0
        } else if second == .notLoaded {
            selected = 1
        } else if first == .discardable, second == .discardable {
            selected = nextSide(kind)
        } else if first == .discardable {
            selected = 0
        } else if second == .discardable {
            selected = 1
        } else if first != .inProgress {
            selected = 0
        } else if second != .inProgress {
            selected = 1
        } else {
            selected = nil
        }
        guard let side = selected else {
            return failure(.allocationFailed, resource: kind, id: id, index: -1)
        }
        var events: [SM64AudioResidencyEvent] = []
        if let oldID = slots[side].resourceID {
            setStatus(kind, id: oldID, status: .notLoaded)
            events.append(SM64AudioResidencyEvent(
                kind: .resourceEvicted,
                resource: kind,
                id: oldID,
                index: side,
                value: slots[side].generation
            ))
        }
        var newSlot = slots[side]
        newSlot.resourceID = id
        newSlot.size = max(size, 0)
        newSlot.status = asynchronous && !(kind == .sequence && size <= SM64AudioLoadModel.shortSequenceThreshold)
            ? .inProgress
            : .complete
        newSlot.generation += 1
        replaceSlot(kind, side: side, slot: newSlot)
        setStatus(kind, id: id, status: newSlot.status)
        setNextSide(kind, side ^ 1)
        events.append(SM64AudioResidencyEvent(
            kind: .poolSideSelected,
            resource: kind,
            id: id,
            index: side,
            value: newSlot.size
        ))
        if newSlot.status == .inProgress {
            events.append(SM64AudioResidencyEvent(
                kind: .loadStarted,
                resource: kind,
                id: id,
                index: side,
                value: newSlot.size
            ))
        } else {
            events.append(SM64AudioResidencyEvent(
                kind: .loadCompleted,
                resource: kind,
                id: id,
                index: side,
                value: newSlot.size
            ))
        }
        return SM64AudioResidencyTrace(events: events, selectedID: id, failed: false)
    }

    private func validResource(_ kind: SM64AudioResidencyKind, id: Int) -> Bool {
        switch kind {
        case .bank: return bankStatuses.indices.contains(id)
        case .sequence: return sequenceStatuses.indices.contains(id)
        }
    }

    private func statuses(_ kind: SM64AudioResidencyKind) -> [SM64AudioLoadStatus] {
        kind == .bank ? bankStatuses : sequenceStatuses
    }

    private func residencySlots(_ kind: SM64AudioResidencyKind) -> [SM64AudioResidencySlot] {
        kind == .bank ? bankSlots : sequenceSlots
    }

    private func nextSide(_ kind: SM64AudioResidencyKind) -> Int {
        kind == .bank ? bankNextSide : sequenceNextSide
    }

    private mutating func setNextSide(_ kind: SM64AudioResidencyKind, _ side: Int) {
        if kind == .bank { bankNextSide = side } else { sequenceNextSide = side }
    }

    private mutating func setStatus(_ kind: SM64AudioResidencyKind, id: Int, status: SM64AudioLoadStatus) {
        switch kind {
        case .bank: if bankStatuses.indices.contains(id) { bankStatuses[id] = status }
        case .sequence: if sequenceStatuses.indices.contains(id) { sequenceStatuses[id] = status }
        }
    }

    private mutating func replaceSlot(_ kind: SM64AudioResidencyKind, side: Int, slot: SM64AudioResidencySlot) {
        if kind == .bank { bankSlots[side] = slot } else { sequenceSlots[side] = slot }
    }

    private func slotIndex(_ kind: SM64AudioResidencyKind, id: Int) -> Int? {
        residencySlots(kind).firstIndex { $0.resourceID == id }
    }

    private func findStreamHit(
        _ slots: [SM64AudioStreamSlot],
        address: Int,
        size: Int,
        hint: Int?,
        useHint: Bool
    ) -> Int? {
        if useHint, let hint, slots.indices.contains(hint), covers(slots[hint], address: address, size: size) {
            return hint
        }
        return slots.firstIndex { covers($0, address: address, size: size) }
    }

    private func covers(_ slot: SM64AudioStreamSlot, address: Int, size: Int) -> Bool {
        guard slot.sampleID != nil, address >= slot.source else { return false }
        return size >= 0 && address - slot.source <= slot.bufferSize - size
    }

    private mutating func setStreamTTL(_ streamClass: SM64AudioStreamClass, index: Int) {
        if streamClass == .short { shortStreamSlots[index].ttl = streamClass.lifetime }
        else { longStreamSlots[index].ttl = streamClass.lifetime }
    }

    private mutating func removeFromReuse(_ streamClass: SM64AudioStreamClass, index: Int) {
        if streamClass == .short { shortReuseQueue.removeAll { $0 == index } }
        else { longReuseQueue.removeAll { $0 == index } }
    }

    private mutating func takeReusable(_ streamClass: SM64AudioStreamClass) -> Int? {
        if streamClass == .short { return shortReuseQueue.isEmpty ? nil : shortReuseQueue.removeFirst() }
        return longReuseQueue.isEmpty ? nil : longReuseQueue.removeFirst()
    }

    private mutating func updateStreamSlot(_ streamClass: SM64AudioStreamClass, index: Int, sampleID: Int, source: Int) {
        if streamClass == .short {
            shortStreamSlots[index].sampleID = sampleID
            shortStreamSlots[index].source = source
            shortStreamSlots[index].ttl = streamClass.lifetime
            shortStreamSlots[index].reuseIndex = -1
        } else {
            longStreamSlots[index].sampleID = sampleID
            longStreamSlots[index].source = source
            longStreamSlots[index].ttl = streamClass.lifetime
            longStreamSlots[index].reuseIndex = -1
        }
    }

    private mutating func expireStreams(_ streamClass: SM64AudioStreamClass, events: inout [SM64AudioResidencyEvent]) {
        if streamClass == .short {
            for index in shortStreamSlots.indices where shortStreamSlots[index].sampleID != nil && shortStreamSlots[index].ttl > 0 {
                shortStreamSlots[index].ttl -= 1
                if shortStreamSlots[index].ttl == 0 {
                    shortStreamSlots[index].reuseIndex = shortReuseQueue.count
                    shortReuseQueue.append(index)
                    events.append(SM64AudioResidencyEvent(kind: .streamExpired, resource: .bank, id: shortStreamSlots[index].sampleID ?? -1, index: index, value: Int(streamClass.rawValue)))
                }
            }
        } else {
            for index in longStreamSlots.indices where longStreamSlots[index].sampleID != nil && longStreamSlots[index].ttl > 0 {
                longStreamSlots[index].ttl -= 1
                if longStreamSlots[index].ttl == 0 {
                    longStreamSlots[index].reuseIndex = longReuseQueue.count
                    longReuseQueue.append(index)
                    events.append(SM64AudioResidencyEvent(kind: .streamExpired, resource: .bank, id: longStreamSlots[index].sampleID ?? -1, index: index, value: Int(streamClass.rawValue)))
                }
            }
        }
    }

    private func scopeEvent(_ event: SM64AudioResidencyEvent) -> SM64AudioResidencyTrace {
        trace(event, selectedID: event.id)
    }

    private func trace(_ event: SM64AudioResidencyEvent, selectedID: Int?) -> SM64AudioResidencyTrace {
        SM64AudioResidencyTrace(events: [event], selectedID: selectedID, failed: false)
    }

    private func failure(
        _ kind: SM64AudioResidencyEventKind,
        resource: SM64AudioResidencyKind,
        id: Int,
        index: Int
    ) -> SM64AudioResidencyTrace {
        SM64AudioResidencyTrace(
            events: [SM64AudioResidencyEvent(kind: kind, resource: resource, id: id, index: index, value: 0)],
            selectedID: nil,
            failed: true
        )
    }
}
