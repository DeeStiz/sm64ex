import Foundation

enum SM64BouncingFireballAction: UInt8, Equatable, Sendable {
    case waiting = 0
    case spawnFlame = 1
    case cycle = 2
}

struct SM64BouncingFireballEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let activate = Self(rawValue: 1 << 0)
    static let spawnFlame = Self(rawValue: 1 << 1)
    static let tangible = Self(rawValue: 1 << 2)
    static let landed = Self(rawValue: 1 << 3)
    static let reset = Self(rawValue: 1 << 4)
    static let markForDeletion = Self(rawValue: 1 << 5)
    static let move = Self(rawValue: 1 << 6)
}

struct SM64BouncingFireballState: Equatable, Sendable {
    var action: SM64BouncingFireballAction = .waiting
    var timer: UInt32 = 0
    var randomOffset: Float = 0
    var velocityY: Float = 0
    var forwardVelocity: Float = 0
    var animState: UInt16 = 0
    var tangible = false
    var markedForDeletion = false

    init(action: SM64BouncingFireballAction = .waiting) {
        self.action = action
    }
}

struct SM64BouncingFireballTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var landed: Bool
    var surfaceContact: Bool
    var randomUnit: Float

    init(
        distanceToMario: Float = 10_000,
        landed: Bool = false,
        surfaceContact: Bool = false,
        randomUnit: Float = 0
    ) {
        self.distanceToMario = distanceToMario
        self.landed = landed
        self.surfaceContact = surfaceContact
        self.randomUnit = randomUnit
    }
}

struct SM64BouncingFireballTickResult: Equatable, Sendable {
    let state: SM64BouncingFireballState
    let effects: SM64BouncingFireballEffect
    let flameScale: Float?
}

enum SM64BouncingFireballKernel {
    static func tick(
        _ input: SM64BouncingFireballTickInput,
        state: inout SM64BouncingFireballState
    ) -> SM64BouncingFireballTickResult {
        var effects: SM64BouncingFireballEffect = [.move]
        var flameScale: Float?

        switch state.action {
        case .waiting:
            if input.distanceToMario < 2_000 {
                state.action = .spawnFlame
                effects.insert(.activate)
            }
        case .spawnFlame:
            if state.timer == 0 {
                state.animState = UInt16(clamping: Int(input.randomUnit * 10))
                state.velocityY = 30
            }
            flameScale = Float(10 - min(state.timer, 10)) * 0.5
            effects.insert(.spawnFlame)
            if state.timer == 0 {
                state.tangible = true
                effects.insert(.tangible)
            }
            if state.timer > 10 {
                state.action = .cycle
                effects.insert(.landed)
            }
        case .cycle:
            if state.timer == 0 {
                state.velocityY = 50
                state.forwardVelocity = 30
            }
            if input.surfaceContact, state.timer > 100 {
                state.markedForDeletion = true
                effects.insert(.markForDeletion)
            }
            if state.randomOffset + 100 < Float(state.timer) {
                state.action = .waiting
                effects.insert(.reset)
            }
        }

        if state.timer > 300 {
            state.markedForDeletion = true
            effects.insert(.markForDeletion)
        }
        state.timer &+= 1
        return SM64BouncingFireballTickResult(state: state, effects: effects, flameScale: flameScale)
    }
}

enum SM64BouncingFireballFlameAction: UInt8, Equatable, Sendable {
    case rising = 0
    case bouncing = 1
}

struct SM64BouncingFireballFlameState: Equatable, Sendable {
    var action: SM64BouncingFireballFlameAction = .rising
    var timer: UInt32 = 0
    var velocityY: Float = 0
    var forwardVelocity: Float = 0
    var markedForDeletion = false

    init() {}
}

struct SM64BouncingFireballFlameTickInput: Equatable, Sendable {
    var landed: Bool
    var surfaceContact: Bool

    init(landed: Bool = false, surfaceContact: Bool = false) {
        self.landed = landed
        self.surfaceContact = surfaceContact
    }
}

struct SM64BouncingFireballFlameTickResult: Equatable, Sendable {
    let state: SM64BouncingFireballFlameState
    let effects: SM64BouncingFireballEffect
}

enum SM64BouncingFireballFlameKernel {
    static func tick(
        _ input: SM64BouncingFireballFlameTickInput,
        state: inout SM64BouncingFireballFlameState
    ) -> SM64BouncingFireballFlameTickResult {
        var effects: SM64BouncingFireballEffect = [.move]
        switch state.action {
        case .rising:
            if state.timer == 0 { state.velocityY = 30 }
            if input.landed {
                state.action = .bouncing
                effects.insert(.landed)
            }
        case .bouncing:
            if state.timer == 0 {
                state.velocityY = 50
                state.forwardVelocity = 30
            }
            if input.surfaceContact, state.timer > 100 {
                state.markedForDeletion = true
                effects.insert(.markForDeletion)
            }
        }
        if state.timer > 300 {
            state.markedForDeletion = true
            effects.insert(.markForDeletion)
        }
        state.timer &+= 1
        return SM64BouncingFireballFlameTickResult(state: state, effects: effects)
    }
}
