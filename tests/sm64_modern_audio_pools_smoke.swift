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

private func hashTrace(_ hash: UInt64, _ trace: SM64AudioPoolTrace) -> UInt64 {
    var value = hash
    value = hashU32(value, UInt32(trace.events.count))
    for event in trace.events {
        value = hashU32(value, UInt32(event.kind.rawValue))
        value = hashU32(value, UInt32(bitPattern: Int32(event.scope)))
        value = hashU32(value, UInt32(bitPattern: Int32(event.index)))
        value = hashU32(value, UInt32(bitPattern: Int32(event.noteID)))
        value = hashU32(value, UInt32(bitPattern: Int32(event.value)))
    }
    value = hashU32(value, UInt32(bitPattern: Int32(trace.selectedNoteID ?? -1)))
    value = hashU32(value, trace.failed ? 1 : 0)
    return value
}

private func hashModel(_ hash: UInt64, _ model: SM64AudioPoolModel) -> UInt64 {
    var value = hash
    for slot in model.channelSlots { value = hashU32(value, UInt32(bitPattern: Int32(slot ?? -1))) }
    for id in model.freeLayerIDs { value = hashU32(value, UInt32(id)) }
    for layer in model.layers {
        value = hashU32(value, UInt32(layer.id))
        value = hashU32(value, layer.enabled ? 1 : 0)
        value = hashU32(value, layer.finished ? 1 : 0)
        value = hashU32(value, UInt32(bitPattern: Int32(layer.channelID ?? -1)))
        value = hashU32(value, UInt32(bitPattern: Int32(layer.noteID ?? -1)))
        value = hashU32(value, UInt32(layer.status.rawValue))
    }
    for note in model.notes {
        value = hashU32(value, UInt32(note.id))
        value = hashU32(value, UInt32(note.list.rawValue))
        value = hashU32(value, UInt32(note.priority))
        value = hashU32(value, UInt32(bitPattern: Int32(note.parentLayer ?? -1)))
        value = hashU32(value, UInt32(bitPattern: Int32(note.wantedLayer ?? -1)))
        value = hashU32(value, UInt32(bitPattern: Int32(note.previousLayer ?? -1)))
    }
    for lists in [model.globalNoteLists, model.sequenceNoteLists] {
        for list in [SM64AudioNoteList.disabled, .decaying, .releasing, .active] {
            for id in lists.values(list) { value = hashU32(value, UInt32(id)) }
            value = hashU32(value, 0xFFFF_FFFF)
        }
    }
    return value
}

@main
enum SM64ModernAudioPoolsSmoke {
    static func main() {
        var model = SM64AudioPoolModel(layerCapacity: 4, channelCapacity: 2, noteCapacity: 6)
        var fingerprint = fnvOffset

        let channels = model.initializeChannels(mask: 0x0003, notePriority: 3)
        precondition(!channels.failed && model.channelSlots[0] == 0 && model.channelSlots[1] == 1)
        fingerprint = hashTrace(fingerprint, channels)

        let layer00 = model.setLayer(channelSlot: 0, layerIndex: 0)
        let layer01 = model.setLayer(channelSlot: 0, layerIndex: 1)
        let layer10 = model.setLayer(channelSlot: 1, layerIndex: 0)
        precondition(layer00.selectedNoteID == nil && layer01.selectedNoteID == nil && layer10.selectedNoteID == nil)
        precondition(model.channels[0].layerSlots == [3, 2, nil, nil])
        precondition(model.channels[1].layerSlots == [1, nil, nil, nil])
        precondition(model.freeLayerIDs == [0])
        fingerprint = hashTrace(fingerprint, layer00)
        fingerprint = hashTrace(fingerprint, layer01)
        fingerprint = hashTrace(fingerprint, layer10)

        model.seedNote(0, scope: .channel(slot: 0), list: .disabled, priority: 3)
        model.seedNote(1, scope: .channel(slot: 0), list: .decaying, priority: 2)
        model.seedNote(2, scope: .channel(slot: 0), list: .active, priority: 2)
        model.seedNote(3, scope: .sequence, list: .disabled, priority: 3)
        model.seedNote(4, scope: .global, list: .disabled, priority: 3)

        model.setAllocationPolicy(channelSlot: 0, .channel)
        let disabled = model.allocateNote(channelSlot: 0, layerIndex: 0)
        precondition(disabled.selectedNoteID == 0 && !disabled.failed)
        fingerprint = hashTrace(fingerprint, disabled)

        let decaying = model.allocateNote(channelSlot: 0, layerIndex: 1)
        precondition(decaying.selectedNoteID == 1 && !decaying.failed)
        fingerprint = hashTrace(fingerprint, decaying)

        let active = model.allocateNote(channelSlot: 0, layerIndex: 0)
        precondition(active.selectedNoteID == 2 && !active.failed)
        fingerprint = hashTrace(fingerprint, active)

        model.setAllocationPolicy(channelSlot: 1, .sequence)
        let sequenceLayer = model.allocateNote(channelSlot: 1, layerIndex: 0)
        precondition(sequenceLayer.selectedNoteID == 3 && !sequenceLayer.failed)
        fingerprint = hashTrace(fingerprint, sequenceLayer)

        model.setAllocationPolicy(channelSlot: 0, .globalFreeList)
        let global = model.allocateNote(channelSlot: 0, layerIndex: 1)
        precondition(global.selectedNoteID == 4 && !global.failed)
        fingerprint = hashTrace(fingerprint, global)

        model.setAllocationPolicy(channelSlot: 0, .layer)
        model.markLayerNoteReusable(channelSlot: 0, layerIndex: 0)
        let reused = model.allocateNote(channelSlot: 0, layerIndex: 0)
        precondition(reused.selectedNoteID == 2 && reused.events.contains { $0.kind == .noteLayerReuse })
        fingerprint = hashTrace(fingerprint, reused)

        model.setAllocationPolicy(channelSlot: 1, .globalFreeList)
        let unavailable = model.allocateNote(channelSlot: 1, layerIndex: 0, bankAvailable: false)
        precondition(unavailable.selectedNoteID == 4 && !unavailable.failed
            && unavailable.events.contains { $0.kind == .noteBankUnavailable })
        fingerprint = hashTrace(fingerprint, unavailable)

        let disabledChannel = model.disableChannel(slot: 1)
        precondition(disabledChannel.events.contains { $0.kind == .layerFreed })
        precondition(model.channelSlots[1] == nil)
        fingerprint = hashTrace(fingerprint, disabledChannel)
        fingerprint = hashModel(fingerprint, model)

        print("audioPoolsFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern audio pools smoke passed")
    }
}
