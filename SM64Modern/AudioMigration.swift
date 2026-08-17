import Darwin
import Foundation
import os

private let audioMigrationLogger = Logger(
    subsystem: "io.github.deestiz.sm64modern",
    category: "AudioMigration"
)

struct SM64AudioSequenceQueueEntry: Equatable, Sendable {
    let priority: UInt8
    let sequenceID: UInt8
}

struct SM64AudioSequenceRuntimeReceipt: Equatable, Sendable {
    let simulationTick: UInt64
    let eventID: UInt32
    let values: [UInt64]
    let queue: [SM64AudioSequenceQueueEntry]
    let playerSequenceIDs: [UInt8]
    let currentBackgroundMusic: UInt16
}

/// Value-only shadow of the C sequence/queue boundary. It intentionally does
/// not synthesize PCM or touch AVAudio; it consumes the exact fixed-width
/// events emitted by the C owner and makes queue ordering replayable in Swift.
struct SM64AudioSequenceRuntimeModel: Equatable, Sendable {
    static let queueCapacity = 6

    private(set) var tickCount: UInt64 = 0
    private(set) var queue: [SM64AudioSequenceQueueEntry] = []
    private(set) var playerSequenceIDs = Array(repeating: UInt8.max, count: 4)
    private(set) var currentBackgroundMusic = UInt16.max

    mutating func observe(
        eventID: UInt32,
        simulationTick: UInt64,
        values: [UInt64]
    ) -> SM64AudioSequenceRuntimeReceipt? {
        guard eventID >= UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_FIRST),
              eventID <= UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_LAST),
              values.count <= Int(SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY) else {
            return nil
        }

        switch eventID {
        case UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_TICK):
            guard values.count >= 3 else { return nil }
            tickCount &+= 1
            currentBackgroundMusic = UInt16(truncatingIfNeeded: values[2])
        case UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_SEQUENCE):
            guard values.count >= 5 else { return nil }
            let player = Int(values[0])
            guard player >= 0 && player < playerSequenceIDs.count else { return nil }
            playerSequenceIDs[player] = UInt8(truncatingIfNeeded: values[1])
        case UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_QUEUE):
            guard values.count == 3 || values.count >= 5 else { return nil }
            if values.count >= 5 {
                let player = UInt8(truncatingIfNeeded: values[0])
                guard player < playerSequenceIDs.count else { return nil }
                if player == 0 {
                    enqueue(sequenceArguments: UInt16(truncatingIfNeeded: values[1]))
                }
            } else if values.count == 3 {
                let queueSize = Int(values[1])
                if queueSize <= Self.queueCapacity,
                   values[2] == UInt64(currentBackgroundMusic) {
                    stop(sequenceID: UInt8(truncatingIfNeeded: values[0]))
                }
            }
        case UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_SECONDARY):
            guard values.count >= 4 else { return nil }
        default:
            return nil
        }

        return SM64AudioSequenceRuntimeReceipt(
            simulationTick: simulationTick,
            eventID: eventID,
            values: values,
            queue: queue,
            playerSequenceIDs: playerSequenceIDs,
            currentBackgroundMusic: currentBackgroundMusic
        )
    }

    private mutating func enqueue(sequenceArguments: UInt16) {
        guard queue.count < Self.queueCapacity else { return }
        let sequenceID = UInt8(truncatingIfNeeded: sequenceArguments)
        let priority = UInt8(truncatingIfNeeded: sequenceArguments >> 8)
        guard !queue.contains(where: { $0.sequenceID == sequenceID }) else { return }

        var foundIndex = 0
        for index in queue.indices where priority <= queue[index].priority {
            foundIndex = index
            break
        }

        if foundIndex == 0 {
            queue.append(SM64AudioSequenceQueueEntry(priority: 0, sequenceID: 0))
        }
        if !queue.isEmpty {
            for index in stride(from: queue.count - 1, through: foundIndex + 1, by: -1) {
                queue[index] = queue[index - 1]
            }
            queue[foundIndex] = SM64AudioSequenceQueueEntry(
                priority: priority,
                sequenceID: sequenceID
            )
        }
    }

    private mutating func stop(sequenceID: UInt8) {
        guard let index = queue.firstIndex(where: { $0.sequenceID == sequenceID }) else {
            return
        }
        queue.remove(at: index)
    }
}

enum SM64AudioSequenceRuntimeFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    static func hash(_ hash: UInt64, _ value: UInt64) -> UInt64 {
        var result = hash
        for shift in stride(from: 0, through: 56, by: 8) {
            result ^= (value >> UInt64(shift)) & 0xFF
            result &*= prime
        }
        return result
    }

    static func receipt(
        _ initialHash: UInt64,
        _ receipt: SM64AudioSequenceRuntimeReceipt
    ) -> UInt64 {
        var result = initialHash
        result = Self.hash(result, receipt.simulationTick)
        result = Self.hash(result, UInt64(receipt.eventID))
        result = Self.hash(result, UInt64(receipt.values.count))
        for value in receipt.values {
            result = Self.hash(result, value)
        }
        result = Self.hash(result, UInt64(receipt.queue.count))
        for entry in receipt.queue {
            result = Self.hash(result, UInt64(entry.priority))
            result = Self.hash(result, UInt64(entry.sequenceID))
        }
        result = Self.hash(result, UInt64(receipt.playerSequenceIDs.count))
        for value in receipt.playerSequenceIDs {
            result = Self.hash(result, UInt64(value))
        }
        return Self.hash(result, UInt64(receipt.currentBackgroundMusic))
    }
}

private func currentThreadIdentity() -> UInt64 {
    var identifier: UInt64 = 0
    let result = pthread_threadid_np(nil, &identifier)
    precondition(result == 0, "pthread_threadid_np must produce an owner token")
    return identifier
}

private func audioMigrationService(
    from context: UnsafeMutableRawPointer?
) -> SwiftAudioMigrationService? {
    guard let context else { return nil }
    return Unmanaged<SwiftAudioMigrationService>.fromOpaque(context)
        .takeUnretainedValue()
}

private let swiftAudioObserveSequenceEvent: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernAudioSequenceEventV1>?
) -> SM64ModernStatus = { context, event in
    guard let service = audioMigrationService(from: context), let event else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return service.observe(event: event.pointee)
}

/// Owner-thread adapter for the M31y sequence boundary. This is deliberately
/// an observer: C remains the sequence-player/PCM/hardware authority while
/// Swift receives and replays the exact event stream for later cutover.
final class SwiftAudioMigrationService {
    private let ownerThreadToken: UInt64
    private let constructionThreadToken: UInt64
    private var model = SM64AudioSequenceRuntimeModel()
    private(set) var eventCount: UInt64 = 0
    private(set) var boundaryFingerprint = SM64AudioSequenceRuntimeFingerprint.offset
    private var loggedFirstEvent = false
    private var lastError: SM64ModernStatus = SM64_MODERN_STATUS_OK

    init(ownerThreadToken: UInt64) {
        self.ownerThreadToken = ownerThreadToken
        self.constructionThreadToken = currentThreadIdentity()
    }

    func makeAPI() -> SM64ModernAudioMigrationApiV1 {
        assertOwnerThread()
        var api = SM64ModernAudioMigrationApiV1()
        api.header.abi_version = SM64_MODERN_ABI_VERSION_1
        api.header.struct_size = UInt32(
            MemoryLayout<SM64ModernAudioMigrationApiV1>.size
        )
        api.context = Unmanaged.passUnretained(self).toOpaque()
        api.observe_sequence_event = swiftAudioObserveSequenceEvent
        return api
    }

    func observe(event: SM64ModernAudioSequenceEventV1) -> SM64ModernStatus {
        assertOwnerThread()
        guard event.header.abi_version == SM64_MODERN_ABI_VERSION_1,
              event.header.struct_size >= UInt32(
                MemoryLayout<SM64ModernAudioSequenceEventV1>.size
              ),
              event.reserved == 0,
              event.value_count <= UInt32(SM64_MODERN_ORACLE_TRACE_VALUE_CAPACITY) else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT)
        }

        let values = [
            event.values.0, event.values.1, event.values.2, event.values.3,
            event.values.4, event.values.5, event.values.6, event.values.7
        ].prefix(Int(event.value_count))
        guard let receipt = model.observe(
            eventID: event.event_id,
            simulationTick: event.simulation_tick,
            values: Array(values)
        ) else {
            return fail(SM64_MODERN_STATUS_INVALID_ARGUMENT)
        }

        eventCount &+= 1
        boundaryFingerprint = SM64AudioSequenceRuntimeFingerprint.receipt(
            boundaryFingerprint, receipt
        )
        if !loggedFirstEvent {
            loggedFirstEvent = true
            audioMigrationLogger.notice(
                "swift_audio_sequence_observer event=\(event.event_id, privacy: .public) tick=\(event.simulation_tick, privacy: .public) queue=\(receipt.queue.count, privacy: .public)"
            )
        }
        return SM64_MODERN_STATUS_OK
    }

    func summary() -> (events: UInt64, ticks: UInt64, queueCount: Int, fingerprint: UInt64) {
        assertOwnerThread()
        return (
            eventCount,
            model.tickCount,
            model.queue.count,
            boundaryFingerprint
        )
    }

    private func assertOwnerThread() {
        precondition(currentThreadIdentity() == constructionThreadToken)
        precondition(currentThreadIdentity() == ownerThreadToken)
    }

    private func fail(_ status: SM64ModernStatus) -> SM64ModernStatus {
        lastError = status
        return status
    }
}
