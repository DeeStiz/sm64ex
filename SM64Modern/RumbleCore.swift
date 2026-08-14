import Foundation

struct SM64RumbleQueuedData: Equatable, Sendable {
    let mode: UInt8
    let duration: Int16
    let strength: Int16
    let decay: Int16

    static let empty = SM64RumbleQueuedData(mode: 0, duration: 0, strength: 0, decay: 0)
}

struct SM64RumbleSettings: Equatable, Sendable {
    var mode: UInt8 = 0
    var strength: Int16 = 0
    var duration: Int16 = 0
    var phase: Int16 = 0
    var warmup: Int16 = 0
    var resetTimer: Int16 = 0
    var resetPeriod: Int16 = 0
    var decay: Int16 = 0
}

enum SM64RumbleCommand: UInt8, Equatable, Sendable {
    case none = 0
    case start = 1
    case stop = 2
}

struct SM64RumbleTickResult: Equatable, Sendable {
    let command: SM64RumbleCommand
    let current: SM64RumbleSettings
    let queue: [SM64RumbleQueuedData]
    let advanced: Bool
}

/// Value counterpart of `thread6.c`'s three-slot rumble queue and waveform
/// timers. It emits platform commands but never touches GameController or
/// CoreHaptics; delivery remains an audited platform boundary.
struct SM64RumbleScheduler: Equatable, Sendable {
    private(set) var queue: [SM64RumbleQueuedData] = Array(repeating: .empty, count: 3)
    private(set) var settings = SM64RumbleSettings()
    var disabled = false
    private(set) var cancelTimer: Int16 = 0

    mutating func enqueue(strength: Int16, duration: Int16) {
        guard !disabled else { return }
        queue[2] = SM64RumbleQueuedData(
            mode: duration > 70 ? 1 : 2,
            duration: duration,
            strength: strength,
            decay: 0
        )
    }

    mutating func resetTimers() {
        guard !disabled else { return }
        if settings.resetTimer == 0 { settings.resetTimer = 7 }
        if settings.resetTimer < 4 { settings.resetTimer = 4 }
        settings.resetPeriod = 7
    }

    mutating func resetTimers2(_ value: Int32) {
        guard !disabled else { return }
        if settings.resetTimer == 0 { settings.resetTimer = 7 }
        if settings.resetTimer < 4 { settings.resetTimer = 4 }
        switch value {
        case 4: settings.resetPeriod = 1
        case 3: settings.resetPeriod = 2
        case 2: settings.resetPeriod = 3
        case 1: settings.resetPeriod = 4
        case 0: settings.resetPeriod = 5
        default: break
        }
    }

    mutating func cancel() {
        queue = Array(repeating: .empty, count: 3)
        settings.duration = 0
        settings.resetTimer = 0
        cancelTimer = 0
    }

    mutating func setCancelTimer(_ value: Int16) {
        cancelTimer = max(0, value)
    }

    mutating func tick(globalTimer: UInt64, advanceLegacyDomain: Bool) -> SM64RumbleTickResult {
        guard advanceLegacyDomain else {
            return SM64RumbleTickResult(
                command: .none,
                current: settings,
                queue: queue,
                advanced: false
            )
        }
        updateQueue()

        if cancelTimer > 0 {
            cancelTimer -= 1
            return SM64RumbleTickResult(command: .stop, current: settings, queue: queue, advanced: true)
        }

        let command: SM64RumbleCommand
        if settings.warmup > 0 {
            settings.warmup -= 1
            command = .start
        } else if settings.duration > 0 {
            settings.duration -= 1
            settings.strength -= settings.decay
            if settings.strength < 0 { settings.strength = 0 }

            if settings.mode == 1 {
                command = .start
            } else if settings.phase >= 0x100 {
                settings.phase -= 0x100
                command = .start
            } else {
                settings.phase += ((settings.strength * settings.strength * settings.strength) / 0x200) + 4
                command = .stop
            }
        } else {
            settings.duration = 0
            if settings.resetTimer >= 5 {
                command = .start
            } else if settings.resetTimer >= 2 && settings.resetPeriod > 0
                        && globalTimer % UInt64(settings.resetPeriod) == 0 {
                command = .start
            } else {
                command = .stop
            }
        }

        if settings.resetTimer > 0 { settings.resetTimer -= 1 }
        return SM64RumbleTickResult(command: command, current: settings, queue: queue, advanced: true)
    }

    private mutating func updateQueue() {
        if queue[0].mode != 0 {
            settings.phase = 0
            settings.warmup = 4
            settings.mode = queue[0].mode
            settings.duration = queue[0].duration
            settings.strength = queue[0].strength
            settings.decay = queue[0].decay
        }
        queue[0] = queue[1]
        queue[1] = queue[2]
        queue[2] = .empty
    }
}
