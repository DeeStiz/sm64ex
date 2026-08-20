import Foundation

/// The three treasure-chest roots share the same child puzzle. `mode` is the
/// source `oTreasureChestUnkFC`: underwater roots (0) bubble when opened,
/// while the JRB root (1) plays the chest-open sound and awards a star.
enum SM64TreasureChestVariant: UInt8, Equatable, Sendable {
    case ship = 0
    case jrb = 1
    case standard = 2
}

enum SM64TreasureChestAction: UInt8, Equatable, Sendable {
    case idle = 0
    case started = 1
    case completed = 2
}

enum SM64TreasureChestBottomAction: UInt8, Equatable, Sendable {
    case idle = 0
    case correct = 1
    case wrong = 2
}

enum SM64TreasureChestTopAction: UInt8, Equatable, Sendable {
    case closed = 0
    case opening = 1
    case open = 2
    case closing = 3
}

struct SM64TreasureChestEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let rightAnswer = Self(rawValue: 1 << 0)
    static let wrongAnswer = Self(rawValue: 1 << 1)
    static let spawnBubble = Self(rawValue: 1 << 2)
    static let playOpenSound = Self(rawValue: 1 << 3)
    static let orangeNumber = Self(rawValue: 1 << 4)
    static let puzzleJingle = Self(rawValue: 1 << 5)
    static let fadeVolume = Self(rawValue: 1 << 6)
    static let drainSound = Self(rawValue: 1 << 7)
    static let cameraShake = Self(rawValue: 1 << 8)
    static let mist = Self(rawValue: 1 << 9)
    static let star = Self(rawValue: 1 << 10)
    static let deactivate = Self(rawValue: 1 << 11)
    static let pushMario = Self(rawValue: 1 << 12)
    static let clearInteraction = Self(rawValue: 1 << 13)
}

struct SM64TreasureChestRootState: Equatable, Sendable {
    let variant: SM64TreasureChestVariant
    let mode: Int32
    var action: SM64TreasureChestAction = .idle
    var timer: Int32 = 0
    var sequence: Int32 = 1
    var wrongLock: Int32 = 0
    var environmentalRegionHeight: Int32 = 0
    var environmentAvailable = false
    var active = true

    init(
        variant: SM64TreasureChestVariant,
        environmentalRegionHeight: Int32 = 0,
        environmentAvailable: Bool = false
    ) {
        self.variant = variant
        self.mode = variant == .jrb ? 1 : 0
        self.environmentalRegionHeight = environmentalRegionHeight
        self.environmentAvailable = environmentAvailable
    }
}

struct SM64TreasureChestRootOutput: Equatable, Sendable {
    let action: SM64TreasureChestAction
    let timer: Int32
    let sequence: Int32
    let wrongLock: Int32
    let environmentalRegionHeight: Int32
    let active: Bool
    let effects: SM64TreasureChestEffect
}

struct SM64TreasureChestBottomInput: Equatable, Sendable {
    let action: SM64TreasureChestBottomAction
    let timer: Int32
    let behaviorParameter: Int32
    let parentSequence: Int32
    let parentWrongLock: Int32
    let intangibleTimer: Int32
    let distanceToMario: Float
    let moveYaw: Int32
    let marioYaw: Int32

    init(
        action: SM64TreasureChestBottomAction = .idle,
        timer: Int32 = 0,
        behaviorParameter: Int32,
        parentSequence: Int32,
        parentWrongLock: Int32,
        intangibleTimer: Int32 = -1,
        distanceToMario: Float,
        moveYaw: Int32 = 0,
        marioYaw: Int32 = 0
    ) {
        self.action = action
        self.timer = timer
        self.behaviorParameter = behaviorParameter
        self.parentSequence = parentSequence
        self.parentWrongLock = parentWrongLock
        self.intangibleTimer = intangibleTimer
        self.distanceToMario = distanceToMario
        self.moveYaw = moveYaw
        self.marioYaw = marioYaw
    }
}

struct SM64TreasureChestBottomOutput: Equatable, Sendable {
    let action: SM64TreasureChestBottomAction
    let timer: Int32
    let parentSequence: Int32
    let parentWrongLock: Int32
    let intangibleTimer: Int32
    let effects: SM64TreasureChestEffect
}

struct SM64TreasureChestTopInput: Equatable, Sendable {
    let action: SM64TreasureChestTopAction
    let timer: Int32
    let facePitch: Int32
    let parentBottomAction: SM64TreasureChestBottomAction
    let rootMode: Int32
    let behaviorParameter: Int32
}

struct SM64TreasureChestTopOutput: Equatable, Sendable {
    let action: SM64TreasureChestTopAction
    let timer: Int32
    let facePitch: Int32
    let effects: SM64TreasureChestEffect
}

/// Value-only counterparts for `src/game/behaviors/treasure_chest.inc.c`.
/// Allocation, parent links, and presentation delivery stay in the object
/// bridge; these reducers only consume the fields the C routines read.
enum SM64TreasureChestBehavior {
    static func updateRoot(
        _ state: inout SM64TreasureChestRootState
    ) -> SM64TreasureChestRootOutput {
        var action = state.action
        var effects: SM64TreasureChestEffect = []
        var active = state.active
        var environmentalRegionHeight = state.environmentalRegionHeight

        switch action {
        case .idle:
            if state.sequence == 5 {
                effects.insert(.puzzleJingle)
                if state.variant == .ship {
                    effects.insert(.fadeVolume)
                }
                action = .started
            }

        case .started:
            if state.variant == .ship {
                if state.environmentAvailable {
                    environmentalRegionHeight -= 5
                    effects.insert([.drainSound, .cameraShake])
                    if environmentalRegionHeight < -335 {
                        environmentalRegionHeight = -335
                        active = false
                        effects.insert(.deactivate)
                    }
                }
            } else if state.timer == 60 {
                effects.insert([.mist, .star])
                action = .completed
            }

        case .completed:
            break
        }

        let outputTimer: Int32
        if action == state.action {
            outputTimer = state.timer &+ 1
        } else {
            outputTimer = 0
        }

        state.action = action
        state.timer = outputTimer
        state.environmentalRegionHeight = environmentalRegionHeight
        state.active = active
        return SM64TreasureChestRootOutput(
            action: action,
            timer: outputTimer,
            sequence: state.sequence,
            wrongLock: state.wrongLock,
            environmentalRegionHeight: environmentalRegionHeight,
            active: active,
            effects: effects
        )
    }

    static func updateBottom(
        _ input: SM64TreasureChestBottomInput
    ) -> SM64TreasureChestBottomOutput {
        var action = input.action
        var timer = input.timer
        var parentSequence = input.parentSequence
        var parentWrongLock = input.parentWrongLock
        var intangibleTimer = input.intangibleTimer
        var effects: SM64TreasureChestEffect = [.pushMario, .clearInteraction]

        let distanceWithin150 = input.distanceToMario < 150
        let distanceWithin500 = input.distanceToMario < 500
        let facingMario = isFacing(
            base: input.moveYaw,
            goal: input.marioYaw &+ 0x8000,
            range: 0x3000
        )

        switch action {
        case .idle:
            if facingMario && distanceWithin150 && parentWrongLock == 0 {
                if parentSequence == input.behaviorParameter {
                    effects.insert(.rightAnswer)
                    parentSequence &+= 1
                    action = .correct
                } else {
                    effects.insert(.wrongAnswer)
                    parentSequence = 1
                    parentWrongLock = 1
                    action = .wrong
                    intangibleTimer = 0
                }
            }

        case .correct:
            if parentWrongLock == 1 {
                action = .idle
            }

        case .wrong:
            intangibleTimer = -1
            if !distanceWithin500 {
                parentWrongLock = 0
                action = .idle
            }
        }

        if action != input.action {
            timer = 0
        } else {
            timer &+= 1
        }

        return SM64TreasureChestBottomOutput(
            action: action,
            timer: timer,
            parentSequence: parentSequence,
            parentWrongLock: parentWrongLock,
            intangibleTimer: intangibleTimer,
            effects: effects
        )
    }

    static func updateTop(
        _ input: SM64TreasureChestTopInput
    ) -> SM64TreasureChestTopOutput {
        var action = input.action
        var timer = input.timer
        var facePitch = input.facePitch
        var effects: SM64TreasureChestEffect = []

        switch action {
        case .closed:
            if input.parentBottomAction == .correct {
                action = .opening
            }

        case .opening:
            if input.timer == 0 {
                if input.rootMode == 0 {
                    effects.insert(.spawnBubble)
                } else {
                    effects.insert(.playOpenSound)
                }
            }
            facePitch &-= 0x200
            if facePitch < -0x4000 {
                facePitch = -0x4000
                action = .open
                if input.behaviorParameter != 4 {
                    effects.insert(.orangeNumber)
                }
            }

        case .open:
            if input.parentBottomAction == .idle {
                action = .closing
            }

        case .closing:
            facePitch &+= 0x800
            if facePitch > 0 {
                facePitch = 0
                action = .closed
            }
        }

        if action != input.action {
            timer = 0
        } else {
            timer &+= 1
        }

        return SM64TreasureChestTopOutput(
            action: action,
            timer: timer,
            facePitch: facePitch,
            effects: effects
        )
    }

    private static func isFacing(base: Int32, goal: Int32, range: Int32) -> Bool {
        // `obj_check_if_facing_toward_angle` accepts a strict signed angular
        // interval and requires a positive cosine. The 0x3000 chest range is
        // wholly inside the positive-cosine half-plane, so the wrapped delta
        // is an exact integer equivalent for this call site.
        let delta = Int32(Int16(truncatingIfNeeded: goal &- base))
        return delta > -range && delta < range && delta > -0x4000 && delta < 0x4000
    }
}
