import Foundation

enum SM64AudioNoteList: UInt8, Equatable, Sendable {
    case detached = 0
    case disabled = 1
    case decaying = 2
    case releasing = 3
    case active = 4
}

struct SM64AudioNoteAllocationPolicy: OptionSet, Equatable, Sendable {
    let rawValue: UInt8

    static let layer = Self(rawValue: 1)
    static let channel = Self(rawValue: 2)
    static let sequence = Self(rawValue: 4)
    static let globalFreeList = Self(rawValue: 8)
}

enum SM64AudioNoteScope: Equatable, Sendable {
    case channel(slot: Int)
    case sequence
    case global
}

struct SM64AudioNoteState: Equatable, Sendable {
    let id: Int
    fileprivate(set) var list: SM64AudioNoteList = .detached
    fileprivate(set) var priority: UInt8 = 3
    fileprivate(set) var parentLayer: Int?
    fileprivate(set) var wantedLayer: Int?
    fileprivate(set) var previousLayer: Int?
}

struct SM64AudioLayerPoolState: Equatable, Sendable {
    let id: Int
    fileprivate(set) var enabled = false
    fileprivate(set) var finished = false
    fileprivate(set) var channelID: Int?
    fileprivate(set) var noteID: Int?
    fileprivate(set) var status: SM64AudioLoadStatus = .notLoaded
}

struct SM64AudioChannelPoolState: Equatable, Sendable {
    let id: Int
    fileprivate(set) var enabled = false
    fileprivate(set) var finished = true
    fileprivate(set) var notePriority: UInt8 = 3
    fileprivate(set) var allocationPolicy: SM64AudioNoteAllocationPolicy = []
    fileprivate(set) var layerSlots: [Int?]
    fileprivate(set) var noteLists: SM64AudioNoteLists

    init(id: Int) {
        self.id = id
        layerSlots = Array(repeating: nil, count: 4)
        noteLists = SM64AudioNoteLists()
    }
}

struct SM64AudioNoteLists: Equatable, Sendable {
    fileprivate(set) var disabled: [Int] = []
    fileprivate(set) var decaying: [Int] = []
    fileprivate(set) var releasing: [Int] = []
    fileprivate(set) var active: [Int] = []

    fileprivate mutating func pushBack(_ list: SM64AudioNoteList, _ noteID: Int) {
        switch list {
        case .disabled: disabled.append(noteID)
        case .decaying: decaying.append(noteID)
        case .releasing: releasing.append(noteID)
        case .active: active.append(noteID)
        case .detached: break
        }
    }

    fileprivate mutating func pushFront(_ list: SM64AudioNoteList, _ noteID: Int) {
        switch list {
        case .disabled: disabled.insert(noteID, at: 0)
        case .decaying: decaying.insert(noteID, at: 0)
        case .releasing: releasing.insert(noteID, at: 0)
        case .active: active.insert(noteID, at: 0)
        case .detached: break
        }
    }

    fileprivate mutating func popBack(_ list: SM64AudioNoteList) -> Int? {
        switch list {
        case .disabled: return disabled.popLast()
        case .decaying: return decaying.popLast()
        case .releasing: return releasing.popLast()
        case .active: return active.popLast()
        case .detached: return nil
        }
    }

    fileprivate mutating func remove(_ list: SM64AudioNoteList, _ noteID: Int) {
        switch list {
        case .disabled: disabled.removeAll { $0 == noteID }
        case .decaying: decaying.removeAll { $0 == noteID }
        case .releasing: releasing.removeAll { $0 == noteID }
        case .active: active.removeAll { $0 == noteID }
        case .detached: break
        }
    }

    func values(_ list: SM64AudioNoteList) -> [Int] {
        switch list {
        case .disabled: return disabled
        case .decaying: return decaying
        case .releasing: return releasing
        case .active: return active
        case .detached: return []
        }
    }
}

enum SM64AudioPoolEventKind: UInt8, Equatable, Sendable {
    case channelAllocated = 1
    case channelReinitialized = 2
    case channelAllocationFailed = 3
    case layerAllocated = 4
    case layerReused = 5
    case layerAllocationFailed = 6
    case layerFreed = 7
    case noteFromDisabled = 8
    case noteFromDecaying = 9
    case noteFromActive = 10
    case noteLayerReuse = 11
    case noteBankUnavailable = 12
    case noteAllocationFailed = 13
    case channelDisabled = 14
}

struct SM64AudioPoolEvent: Equatable, Sendable {
    let kind: SM64AudioPoolEventKind
    let scope: Int
    let index: Int
    let noteID: Int
    let value: Int
}

struct SM64AudioPoolTrace: Equatable, Sendable {
    let events: [SM64AudioPoolEvent]
    let selectedNoteID: Int?
    let failed: Bool
}

/// Value-only channel/layer/note list ownership for the pre-synthesis audio
/// boundary. List order is front-to-back, matching the C circular-list view.
struct SM64AudioPoolModel: Equatable, Sendable {
    let layerCapacity: Int
    let channelCapacity: Int
    let noteCapacity: Int
    private(set) var channels: [SM64AudioChannelPoolState]
    private(set) var layers: [SM64AudioLayerPoolState]
    private(set) var notes: [SM64AudioNoteState]
    private(set) var sequenceNoteLists: SM64AudioNoteLists
    private(set) var globalNoteLists: SM64AudioNoteLists
    private(set) var channelSlots: [Int?]
    private(set) var freeLayerIDs: [Int]

    init(layerCapacity: Int = 52, channelCapacity: Int = 32, noteCapacity: Int = 16) {
        self.layerCapacity = max(layerCapacity, 0)
        self.channelCapacity = max(channelCapacity, 0)
        self.noteCapacity = max(noteCapacity, 0)
        channels = (0..<self.channelCapacity).map(SM64AudioChannelPoolState.init)
        layers = (0..<self.layerCapacity).map {
            SM64AudioLayerPoolState(id: $0, channelID: nil)
        }
        notes = (0..<self.noteCapacity).map {
            SM64AudioNoteState(id: $0, parentLayer: nil, wantedLayer: nil, previousLayer: nil)
        }
        sequenceNoteLists = SM64AudioNoteLists()
        globalNoteLists = SM64AudioNoteLists()
        channelSlots = Array(repeating: nil, count: 16)
        freeLayerIDs = Array(0..<self.layerCapacity)
        for id in 0..<self.noteCapacity {
            notes[id].list = .disabled
            globalNoteLists.pushBack(.disabled, id)
        }
    }

    mutating func initializeChannels(
        mask: UInt16,
        notePriority: UInt8 = 3,
        allocationPolicy: SM64AudioNoteAllocationPolicy = []
    ) -> SM64AudioPoolTrace {
        var events: [SM64AudioPoolEvent] = []
        for slot in 0..<channelSlots.count where mask & (UInt16(1) << UInt16(slot)) != 0 {
            if let oldChannel = channelSlots[slot] {
                events.append(contentsOf: disableChannel(id: oldChannel))
                events.append(SM64AudioPoolEvent(kind: .channelReinitialized, scope: slot, index: oldChannel, noteID: -1, value: 0))
            }
            guard let channelID = channels.firstIndex(where: { !$0.enabled }) else {
                events.append(SM64AudioPoolEvent(kind: .channelAllocationFailed, scope: slot, index: -1, noteID: -1, value: 0))
                channelSlots[slot] = nil
                continue
            }
            var channel = channels[channelID]
            channel.enabled = true
            channel.finished = false
            channel.notePriority = notePriority
            channel.allocationPolicy = allocationPolicy
            channel.layerSlots = Array(repeating: nil, count: 4)
            channel.noteLists = SM64AudioNoteLists()
            channels[channelID] = channel
            channelSlots[slot] = channelID
            events.append(SM64AudioPoolEvent(kind: .channelAllocated, scope: slot, index: channelID, noteID: -1, value: Int(notePriority)))
        }
        return SM64AudioPoolTrace(events: events, selectedNoteID: nil, failed: events.contains { $0.kind == .channelAllocationFailed })
    }

    mutating func setAllocationPolicy(channelSlot: Int, _ policy: SM64AudioNoteAllocationPolicy) {
        guard channelSlots.indices.contains(channelSlot), let channelID = channelSlots[channelSlot] else { return }
        channels[channelID].allocationPolicy = policy
    }

    mutating func setLayer(channelSlot: Int, layerIndex: Int) -> SM64AudioPoolTrace {
        guard channelSlots.indices.contains(channelSlot), (0..<4).contains(layerIndex),
              let channelID = channelSlots[channelSlot], channels[channelID].enabled else {
            return failure(.layerAllocationFailed, scope: channelSlot, index: layerIndex)
        }
        if let existing = channels[channelID].layerSlots[layerIndex] {
            let events = [SM64AudioPoolEvent(kind: .layerReused, scope: channelID, index: existing, noteID: layers[existing].noteID ?? -1, value: layerIndex)]
            decayLayer(existing)
            initializeLayer(existing, channelID: channelID, layerIndex: layerIndex)
            return SM64AudioPoolTrace(events: events, selectedNoteID: nil, failed: false)
        }
        guard let layerID = freeLayerIDs.popLast() else {
            return failure(.layerAllocationFailed, scope: channelID, index: layerIndex)
        }
        channels[channelID].layerSlots[layerIndex] = layerID
        initializeLayer(layerID, channelID: channelID, layerIndex: layerIndex)
        return SM64AudioPoolTrace(
            events: [SM64AudioPoolEvent(kind: .layerAllocated, scope: channelID, index: layerID, noteID: -1, value: layerIndex)],
            selectedNoteID: nil,
            failed: false
        )
    }

    mutating func allocateNote(
        channelSlot: Int,
        layerIndex: Int,
        bankAvailable: Bool = true
    ) -> SM64AudioPoolTrace {
        guard channelSlots.indices.contains(channelSlot), (0..<4).contains(layerIndex),
              let channelID = channelSlots[channelSlot], channels[channelID].enabled,
              let layerID = channels[channelID].layerSlots[layerIndex], layers[layerID].enabled else {
            return failure(.noteAllocationFailed, scope: channelSlot, index: layerIndex)
        }
        let policy = channels[channelID].allocationPolicy
        if policy.contains(.layer), let noteID = layers[layerID].noteID,
           notes[noteID].previousLayer == layerID, notes[noteID].wantedLayer == nil {
            moveNoteToReleasing(noteID, from: noteScope(for: noteID), wantedLayer: layerID)
            return trace(.noteLayerReuse, scope: layerID, index: layerIndex, noteID: noteID, value: 0)
        }

        var scopes: [SM64AudioNoteScope] = []
        if policy.contains(.channel) { scopes.append(.channel(slot: channelID)) }
        if policy.contains(.sequence) {
            scopes.append(.channel(slot: channelID))
            scopes.append(.sequence)
        }
        if policy.contains(.globalFreeList) { scopes.append(.global) }
        if scopes.isEmpty {
            scopes = [.channel(slot: channelID), .sequence, .global]
        }
        var events: [SM64AudioPoolEvent] = []
        for scope in scopes {
            if let noteID = takeDisabled(scope, layerID: layerID, bankAvailable: bankAvailable, events: &events) {
                return SM64AudioPoolTrace(events: events, selectedNoteID: noteID, failed: false)
            }
            if let noteID = takeDecaying(scope, layerID: layerID, events: &events) {
                return SM64AudioPoolTrace(events: events, selectedNoteID: noteID, failed: false)
            }
            if let noteID = takeActive(scope, channelID: channelID, layerID: layerID, events: &events) {
                return SM64AudioPoolTrace(events: events, selectedNoteID: noteID, failed: false)
            }
        }
        layers[layerID].status = .notLoaded
        events.append(SM64AudioPoolEvent(kind: .noteAllocationFailed, scope: layerID, index: layerIndex, noteID: -1, value: Int(policy.rawValue)))
        return SM64AudioPoolTrace(events: events, selectedNoteID: nil, failed: true)
    }

    mutating func seedNote(
        _ noteID: Int,
        scope: SM64AudioNoteScope,
        list: SM64AudioNoteList,
        priority: UInt8 = 3
    ) {
        guard notes.indices.contains(noteID), list != .detached else { return }
        detachNote(noteID)
        notes[noteID].priority = priority
        notes[noteID].list = list
        append(noteID, to: scope, list: list)
    }

    mutating func markLayerNoteReusable(channelSlot: Int, layerIndex: Int) {
        guard channelSlots.indices.contains(channelSlot), (0..<4).contains(layerIndex),
              let channelID = channelSlots[channelSlot],
              let layerID = channels[channelID].layerSlots[layerIndex],
              let noteID = layers[layerID].noteID else { return }
        notes[noteID].previousLayer = layerID
        notes[noteID].wantedLayer = nil
    }

    mutating func disableChannel(slot: Int) -> SM64AudioPoolTrace {
        guard channelSlots.indices.contains(slot), let channelID = channelSlots[slot] else {
            return SM64AudioPoolTrace(events: [], selectedNoteID: nil, failed: false)
        }
        let events = disableChannel(id: channelID)
        channelSlots[slot] = nil
        return SM64AudioPoolTrace(events: events, selectedNoteID: nil, failed: false)
    }

    private mutating func disableChannel(id: Int) -> [SM64AudioPoolEvent] {
        guard channels.indices.contains(id), channels[id].enabled else { return [] }
        var events: [SM64AudioPoolEvent] = []
        for layerIndex in channels[id].layerSlots.indices {
            if let layerID = channels[id].layerSlots[layerIndex] {
                freeLayer(layerID, channelID: id, layerIndex: layerIndex, events: &events)
            }
        }
        for list in [SM64AudioNoteList.disabled, .decaying, .releasing, .active] {
            let ids = channels[id].noteLists.values(list)
            for noteID in ids {
                channels[id].noteLists.remove(list, noteID)
                notes[noteID].list = list
                globalNoteLists.pushBack(list, noteID)
            }
        }
        channels[id].enabled = false
        channels[id].finished = true
        channels[id].layerSlots = Array(repeating: nil, count: 4)
        channels[id].noteLists = SM64AudioNoteLists()
        events.append(SM64AudioPoolEvent(kind: .channelDisabled, scope: id, index: id, noteID: -1, value: 0))
        return events
    }

    private mutating func freeLayer(_ layerID: Int, channelID: Int, layerIndex: Int, events: inout [SM64AudioPoolEvent]) {
        guard layers.indices.contains(layerID) else { return }
        decayLayer(layerID)
        layers[layerID].enabled = false
        layers[layerID].finished = true
        layers[layerID].channelID = nil
        layers[layerID].noteID = nil
        layers[layerID].status = .notLoaded
        freeLayerIDs.append(layerID)
        events.append(SM64AudioPoolEvent(kind: .layerFreed, scope: channelID, index: layerID, noteID: -1, value: layerIndex))
    }

    private mutating func decayLayer(_ layerID: Int) {
        guard let noteID = layers[layerID].noteID, notes.indices.contains(noteID) else { return }
        let scope = noteScope(for: noteID)
        moveNoteToDecaying(noteID, from: scope)
        notes[noteID].previousLayer = layerID
        layers[layerID].noteID = nil
    }

    private mutating func initializeLayer(_ layerID: Int, channelID: Int, layerIndex: Int) {
        layers[layerID].enabled = true
        layers[layerID].finished = false
        layers[layerID].channelID = channelID
        layers[layerID].noteID = nil
        layers[layerID].status = .notLoaded
        _ = layerIndex
    }

    private mutating func takeDisabled(
        _ scope: SM64AudioNoteScope,
        layerID: Int,
        bankAvailable: Bool,
        events: inout [SM64AudioPoolEvent]
    ) -> Int? {
        guard let noteID = popBack(scope, list: .disabled) else { return nil }
        guard bankAvailable else {
            notes[noteID].list = .disabled
            globalNoteLists.pushFront(.disabled, noteID)
            events.append(SM64AudioPoolEvent(kind: .noteBankUnavailable, scope: layerID, index: 0, noteID: noteID, value: 0))
            return nil
        }
        initializeNote(noteID, layerID: layerID, scope: scope)
        events.append(SM64AudioPoolEvent(kind: .noteFromDisabled, scope: scopeID(scope), index: layerID, noteID: noteID, value: 0))
        return noteID
    }

    private mutating func takeDecaying(_ scope: SM64AudioNoteScope, layerID: Int, events: inout [SM64AudioPoolEvent]) -> Int? {
        guard let noteID = popBack(scope, list: .decaying) else { return nil }
        notes[noteID].wantedLayer = layerID
        notes[noteID].priority = 1
        notes[noteID].list = .releasing
        append(noteID, to: scope, list: .releasing)
        events.append(SM64AudioPoolEvent(kind: .noteFromDecaying, scope: scopeID(scope), index: layerID, noteID: noteID, value: 1))
        layers[layerID].noteID = noteID
        layers[layerID].status = .discardable
        return noteID
    }

    private mutating func takeActive(
        _ scope: SM64AudioNoteScope,
        channelID: Int,
        layerID: Int,
        events: inout [SM64AudioPoolEvent]
    ) -> Int? {
        let ids = values(scope, list: .active)
        guard var best = ids.first else { return nil }
        for candidate in ids.dropFirst() where notes[best].priority >= notes[candidate].priority {
            best = candidate
        }
        guard channels[channelID].notePriority >= notes[best].priority else { return nil }
        remove(best, from: scope, list: .active)
        notes[best].wantedLayer = layerID
        notes[best].list = .releasing
        append(best, to: scope, list: .releasing)
        layers[layerID].noteID = best
        layers[layerID].status = .discardable
        events.append(SM64AudioPoolEvent(kind: .noteFromActive, scope: scopeID(scope), index: layerID, noteID: best, value: Int(notes[best].priority)))
        return best
    }

    private mutating func initializeNote(_ noteID: Int, layerID: Int, scope: SM64AudioNoteScope) {
        notes[noteID].parentLayer = layerID
        notes[noteID].wantedLayer = nil
        notes[noteID].previousLayer = nil
        notes[noteID].list = .active
        append(noteID, to: scope, list: .active, front: true)
        layers[layerID].noteID = noteID
        layers[layerID].status = .discardable
    }

    private mutating func moveNoteToReleasing(_ noteID: Int, from scope: SM64AudioNoteScope, wantedLayer: Int) {
        let oldList = notes[noteID].list
        remove(noteID, from: scope, list: oldList)
        notes[noteID].wantedLayer = wantedLayer
        notes[noteID].list = .releasing
        append(noteID, to: scope, list: .releasing)
    }

    private mutating func moveNoteToDecaying(_ noteID: Int, from scope: SM64AudioNoteScope) {
        let oldList = notes[noteID].list
        remove(noteID, from: scope, list: oldList)
        notes[noteID].list = .decaying
        append(noteID, to: scope, list: .decaying, front: true)
    }

    private mutating func detachNote(_ noteID: Int) {
        let scope = noteScope(for: noteID)
        let list = notes[noteID].list
        remove(noteID, from: scope, list: list)
        notes[noteID].list = .detached
    }

    private func noteScope(for noteID: Int) -> SM64AudioNoteScope {
        for channel in channels where channel.noteLists.values(notes[noteID].list).contains(noteID) {
            return .channel(slot: channel.id)
        }
        if sequenceNoteLists.values(notes[noteID].list).contains(noteID) {
            return .sequence
        }
        return globalNoteLists.values(notes[noteID].list).contains(noteID) ? .global : .sequence
    }

    private func scopeID(_ scope: SM64AudioNoteScope) -> Int {
        switch scope {
        case let .channel(slot): return slot
        case .sequence: return -2
        case .global: return -1
        }
    }

    private func values(_ scope: SM64AudioNoteScope, list: SM64AudioNoteList) -> [Int] {
        switch scope {
        case let .channel(id): return channels[id].noteLists.values(list)
        case .sequence: return sequenceNoteLists.values(list)
        case .global: return globalNoteLists.values(list)
        }
    }

    private mutating func popBack(_ scope: SM64AudioNoteScope, list: SM64AudioNoteList) -> Int? {
        switch scope {
        case let .channel(id): return channels[id].noteLists.popBack(list)
        case .sequence: return sequenceNoteLists.popBack(list)
        case .global: return globalNoteLists.popBack(list)
        }
    }

    private mutating func remove(_ noteID: Int, from scope: SM64AudioNoteScope, list: SM64AudioNoteList) {
        switch scope {
        case let .channel(id): channels[id].noteLists.remove(list, noteID)
        case .sequence: sequenceNoteLists.remove(list, noteID)
        case .global: globalNoteLists.remove(list, noteID)
        }
    }

    private mutating func append(_ noteID: Int, to scope: SM64AudioNoteScope, list: SM64AudioNoteList, front: Bool = false) {
        switch scope {
        case let .channel(id):
            if front { channels[id].noteLists.pushFront(list, noteID) }
            else { channels[id].noteLists.pushBack(list, noteID) }
        case .sequence:
            if front { sequenceNoteLists.pushFront(list, noteID) }
            else { sequenceNoteLists.pushBack(list, noteID) }
        case .global:
            if front { globalNoteLists.pushFront(list, noteID) }
            else { globalNoteLists.pushBack(list, noteID) }
        }
    }

    private func trace(_ kind: SM64AudioPoolEventKind, scope: Int, index: Int, noteID: Int, value: Int) -> SM64AudioPoolTrace {
        SM64AudioPoolTrace(events: [SM64AudioPoolEvent(kind: kind, scope: scope, index: index, noteID: noteID, value: value)], selectedNoteID: noteID, failed: false)
    }

    private func failure(_ kind: SM64AudioPoolEventKind, scope: Int, index: Int) -> SM64AudioPoolTrace {
        SM64AudioPoolTrace(events: [SM64AudioPoolEvent(kind: kind, scope: scope, index: index, noteID: -1, value: 0)], selectedNoteID: nil, failed: true)
    }
}
