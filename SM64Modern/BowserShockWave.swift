import Foundation

struct SM64BowserShockWaveState: Equatable, Sendable {
    var timer: UInt32 = 0
    var opacity: Int32 = 255
    var scale: Float = 0
    var markedForDeletion = false
}

struct SM64BowserShockWaveTickInput: Equatable, Sendable {
    let globalTimer: UInt64
    let marioDistance: Float
    let marioInAir: Bool

    init(globalTimer: UInt64 = 0, marioDistance: Float = 0, marioInAir: Bool = false) {
        self.globalTimer = globalTimer
        self.marioDistance = marioDistance
        self.marioInAir = marioInAir
    }
}

struct SM64BowserShockWaveEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let interactMario = Self(rawValue: 1 << 0)
    static let fade = Self(rawValue: 1 << 1)
    static let markForDeletion = Self(rawValue: 1 << 2)
}

struct SM64BowserShockWaveTickResult: Equatable, Sendable {
    let state: SM64BowserShockWaveState
    let effects: SM64BowserShockWaveEffect
}

/// Value translation of `bhv_bowser_shock_wave_loop` from the C behavior.
enum SM64BowserShockWaveKernel {
    static let activeFrameLimit: UInt32 = 70
    static let innerRangeLow: Float = 1.9
    static let innerRangeHigh: Float = 2.4
    static let outerRangeLow: Float = 4.0
    static let outerRangeHigh: Float = 4.8

    static func tick(
        _ input: SM64BowserShockWaveTickInput,
        state: inout SM64BowserShockWaveState
    ) -> SM64BowserShockWaveTickResult {
        var effects: SM64BowserShockWaveEffect = []
        state.scale = Float(state.timer * 10)
        if input.globalTimer % 3 != 0 {
            state.opacity = max(0, state.opacity - 1)
            effects.insert(.fade)
        }
        if state.timer > Self.activeFrameLimit {
            state.opacity = max(0, state.opacity - 5)
            effects.insert(.fade)
        }
        if state.opacity <= 0 {
            state.markedForDeletion = true
            effects.insert(.markForDeletion)
        }
        if state.timer < Self.activeFrameLimit, !input.marioInAir {
            let innerLow = state.scale * Self.innerRangeLow
            let innerHigh = state.scale * Self.innerRangeHigh
            let outerLow = state.scale * Self.outerRangeLow
            let outerHigh = state.scale * Self.outerRangeHigh
            if (innerLow < input.marioDistance && input.marioDistance < innerHigh)
                || (outerLow < input.marioDistance && input.marioDistance < outerHigh) {
                effects.insert(.interactMario)
            }
        }
        state.timer = state.timer == UInt32.max ? 0 : state.timer + 1
        return SM64BowserShockWaveTickResult(state: state, effects: effects)
    }
}
