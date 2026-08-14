import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU8(_ initial: UInt64, _ value: UInt8) -> UInt64 {
    var hash = initial
    hash ^= UInt64(value); hash &*= fnvPrime
    return hash
}

private func hashU16(_ initial: UInt64, _ value: UInt16) -> UInt64 {
    var hash = initial
    for byte in 0..<2 { hash ^= UInt64((value >> UInt16(byte * 8)) & 0xff); hash &*= fnvPrime }
    return hash
}

private func hashTick(_ initial: UInt64, _ tick: SM64RumbleTickResult) -> UInt64 {
    var hash = hashU8(initial, tick.command.rawValue)
    hash = hashU8(hash, tick.advanced ? 1 : 0)
    hash = hashU8(hash, tick.current.mode)
    hash = hashU16(hash, UInt16(bitPattern: tick.current.strength))
    hash = hashU16(hash, UInt16(bitPattern: tick.current.duration))
    hash = hashU16(hash, UInt16(bitPattern: tick.current.phase))
    hash = hashU16(hash, UInt16(bitPattern: tick.current.warmup))
    hash = hashU16(hash, UInt16(bitPattern: tick.current.resetTimer))
    hash = hashU16(hash, UInt16(bitPattern: tick.current.resetPeriod))
    for item in tick.queue {
        hash = hashU8(hash, item.mode)
        hash = hashU16(hash, UInt16(bitPattern: item.duration))
        hash = hashU16(hash, UInt16(bitPattern: item.strength))
        hash = hashU16(hash, UInt16(bitPattern: item.decay))
    }
    return hash
}

@main
enum SM64ModernRumbleCoreSmoke {
    static func main() {
        var scheduler = SM64RumbleScheduler()
        scheduler.enqueue(strength: 5, duration: 80)
        let held = scheduler.tick(globalTimer: 0, advanceLegacyDomain: false)
        precondition(!held.advanced && held.command == .none, "held native rumble tick")

        var fingerprint = fnvOffset
        fingerprint = hashTick(fingerprint, held)
        for timer in 0..<7 {
            let tick = scheduler.tick(globalTimer: UInt64(timer), advanceLegacyDomain: true)
            if timer < 2 { precondition(tick.command == .stop, "queue latency") }
            if timer >= 2 { precondition(tick.command == .start, "continuous rumble start") }
            fingerprint = hashTick(fingerprint, tick)
        }

        scheduler.enqueue(strength: 5, duration: 70)
        let modeTwo0 = scheduler.tick(globalTimer: 7, advanceLegacyDomain: true)
        let modeTwo1 = scheduler.tick(globalTimer: 8, advanceLegacyDomain: true)
        let modeTwo2 = scheduler.tick(globalTimer: 9, advanceLegacyDomain: true)
        let modeTwo3 = scheduler.tick(globalTimer: 10, advanceLegacyDomain: true)
        let modeTwo4 = scheduler.tick(globalTimer: 11, advanceLegacyDomain: true)
        let modeTwo5 = scheduler.tick(globalTimer: 12, advanceLegacyDomain: true)
        let modeTwo6 = scheduler.tick(globalTimer: 13, advanceLegacyDomain: true)
        precondition(modeTwo0.command == .start && modeTwo1.command == .start, "mode-two warmup")
        precondition(modeTwo2.command == .start && modeTwo3.command == .start
                     && modeTwo4.command == .start && modeTwo5.command == .start, "mode-two warmup")
        precondition(modeTwo6.command == .stop, "mode-two phase stop")
        fingerprint = hashTick(fingerprint, modeTwo0)
        fingerprint = hashTick(fingerprint, modeTwo1)
        fingerprint = hashTick(fingerprint, modeTwo2)
        fingerprint = hashTick(fingerprint, modeTwo3)
        fingerprint = hashTick(fingerprint, modeTwo4)
        fingerprint = hashTick(fingerprint, modeTwo5)
        fingerprint = hashTick(fingerprint, modeTwo6)

        scheduler.resetTimers2(0)
        let reset = scheduler.tick(globalTimer: 14, advanceLegacyDomain: true)
        precondition(reset.current.resetTimer == 6 && reset.current.resetPeriod == 5, "reset timers")
        fingerprint = hashTick(fingerprint, reset)

        scheduler.setCancelTimer(2)
        let cancel0 = scheduler.tick(globalTimer: 15, advanceLegacyDomain: true)
        let cancel1 = scheduler.tick(globalTimer: 16, advanceLegacyDomain: true)
        precondition(cancel0.command == .stop && cancel1.command == .stop, "cancel stop")
        fingerprint = hashTick(fingerprint, cancel0)
        fingerprint = hashTick(fingerprint, cancel1)

        scheduler.cancel()
        precondition(scheduler.queue.allSatisfy { $0 == .empty } && scheduler.settings.duration == 0, "cancel clears state")
        print(String(format: "rumbleCoreFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern rumble core smoke passed")
    }
}
