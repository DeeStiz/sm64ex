import Foundation

@main
enum SM64ModernAudioMigrationSmoke {
    static func main() {
        var model = SM64AudioSequenceRuntimeModel()
        var fingerprint = SM64AudioSequenceRuntimeFingerprint.offset
        let events: [(UInt64, UInt32, [UInt64])] = [
            (1, UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_TICK), [60, 0x1234, 0x0402]),
            (1, UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_QUEUE), [0, 0x0402, 0, 0, 0x0402]),
            (1, UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_SEQUENCE), [0, 2, 0, 1, 1]),
            (2, UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_QUEUE), [0, 0x0205, 0, 1, 0x0402]),
            (2, UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_QUEUE), [5, 2, 0x0402]),
            (3, UInt32(SM64_MODERN_AUDIO_SEQUENCE_EVENT_SECONDARY), [7, 0x80, 0x60, 12])
        ]

        for (tick, eventID, values) in events {
            guard let receipt = model.observe(
                eventID: eventID, simulationTick: tick, values: values
            ) else {
                fatalError("audio migration event rejected")
            }
            fingerprint = SM64AudioSequenceRuntimeFingerprint.receipt(
                fingerprint, receipt
            )
        }

        precondition(model.tickCount == 1)
        precondition(model.queue == [
            SM64AudioSequenceQueueEntry(priority: 4, sequenceID: 2),
        ])
        precondition(model.playerSequenceIDs[0] == 2)
        print("audioSequenceMigrationFingerprint=0x\(String(fingerprint, radix: 16))")
        print("audioSequenceMigrationEvents=\(events.count)")
        print("audioSequenceMigrationQueue=\(model.queue.count)")
        print("SM64 Modern audio sequence migration smoke passed")
    }
}
