import Foundation

enum SM64PiranhaPlantAction: UInt8, Equatable, Sendable {
    case idle = 0
    case sleeping = 1
    case biting = 2
    case wokenUp = 3
    case stoppedBiting = 4
    case attacked = 5
    case shrinkAndDie = 6
    case waitToRespawn = 7
    case respawn = 8
}

struct SM64PiranhaPlantHitbox: Equatable, Sendable {
    let interactType: UInt32
    let damageOrCoinValue: Int16
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let sleeping = Self(
        // INTERACT_BOUNCE_TOP; sleeping plants are harmless in the US build.
        interactType: 1 << 15,
        damageOrCoinValue: 0,
        radius: 250,
        height: 200,
        hurtboxRadius: 150,
        hurtboxHeight: 100
    )

    static let biting = Self(
        // INTERACT_DAMAGE.
        interactType: 1 << 3,
        damageOrCoinValue: 3,
        radius: 150,
        height: 100,
        hurtboxRadius: 150,
        hurtboxHeight: 100
    )
}

struct SM64PiranhaPlantState: Equatable, Sendable {
    var action: SM64PiranhaPlantAction
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var moveYaw: Int16
    var scale: Float = 1
    var opacity: Int32 = 255
    var timer: UInt32 = 0
    var tangible = false
    var hidden = false
    var blueCoinRequested = false
    var markedForDeletion = false

    init(
        action: SM64PiranhaPlantAction = .idle,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0
    ) {
        self.action = action
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.moveYaw = moveYaw
    }

    var hitbox: SM64PiranhaPlantHitbox {
        action == .biting ? .biting : .sleeping
    }
}

struct SM64PiranhaPlantTickInput: Equatable, Sendable {
    var activeWithinRadius: Bool
    var distanceToMario: Float
    var angleToMario: Int16
    var marioMovingFast: Bool
    var marioMetalCap: Bool
    var interacted: Bool
    var wasAttacked: Bool
    var nearAnimationEnd: Bool
    var biteAnimationFrame: Int16
    var hiddenByLevelHeight: Bool

    init(
        activeWithinRadius: Bool = true,
        distanceToMario: Float = 2_000,
        angleToMario: Int16 = 0,
        marioMovingFast: Bool = false,
        marioMetalCap: Bool = false,
        interacted: Bool = false,
        wasAttacked: Bool = false,
        nearAnimationEnd: Bool = false,
        biteAnimationFrame: Int16 = 0,
        hiddenByLevelHeight: Bool = false
    ) {
        self.activeWithinRadius = activeWithinRadius
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.marioMovingFast = marioMovingFast
        self.marioMetalCap = marioMetalCap
        self.interacted = interacted
        self.wasAttacked = wasAttacked
        self.nearAnimationEnd = nearAnimationEnd
        self.biteAnimationFrame = biteAnimationFrame
        self.hiddenByLevelHeight = hiddenByLevelHeight
    }
}

struct SM64PiranhaPlantEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let idle = Self(rawValue: 1 << 0)
    static let sleeping = Self(rawValue: 1 << 1)
    static let wokenUp = Self(rawValue: 1 << 2)
    static let biting = Self(rawValue: 1 << 3)
    static let biteSound = Self(rawValue: 1 << 4)
    static let stoppedBiting = Self(rawValue: 1 << 5)
    static let attacked = Self(rawValue: 1 << 6)
    static let particles = Self(rawValue: 1 << 7)
    static let shrink = Self(rawValue: 1 << 8)
    static let blueCoin = Self(rawValue: 1 << 9)
    static let waitToRespawn = Self(rawValue: 1 << 10)
    static let respawn = Self(rawValue: 1 << 11)
    static let tangible = Self(rawValue: 1 << 12)
    static let intangible = Self(rawValue: 1 << 13)
    static let hidden = Self(rawValue: 1 << 14)
    static let shown = Self(rawValue: 1 << 15)
    static let markForDeletion = Self(rawValue: 1 << 16)
}

struct SM64PiranhaPlantTickResult: Equatable, Sendable {
    let state: SM64PiranhaPlantState
    let effects: SM64PiranhaPlantEffect
}

enum SM64PiranhaPlantKernel {
    static func tick(
        _ input: SM64PiranhaPlantTickInput,
        state: inout SM64PiranhaPlantState
    ) -> SM64PiranhaPlantTickResult {
        var effects: SM64PiranhaPlantEffect = []

        state.hidden = input.hiddenByLevelHeight
        if state.hidden { effects.insert(.hidden) } else { effects.insert(.shown) }
        if !input.activeWithinRadius {
            state.action = .idle
        }

        switch state.action {
        case .idle:
            state.tangible = false
            state.scale = 1
            state.opacity = 255
            effects.formUnion([.idle, .intangible])
            if input.distanceToMario < 1_200 {
                state.action = .sleeping
            }
        case .sleeping:
            state.tangible = true
            effects.formUnion([.sleeping, .tangible])
            if input.distanceToMario < 400, input.marioMovingFast {
                state.action = .wokenUp
                effects.insert(.wokenUp)
            }
        case .biting:
            state.tangible = true
            state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToMario, increment: 0x400)
            effects.formUnion([.biting, .tangible])
            if [12, 28, 50, 64].contains(input.biteAnimationFrame) {
                effects.insert(.biteSound)
            }
            if input.distanceToMario > 500, input.nearAnimationEnd {
                state.action = .stoppedBiting
                effects.insert(.stoppedBiting)
            }
        case .wokenUp:
            state.tangible = true
            effects.formUnion([.wokenUp, .tangible])
            if !input.interacted, state.timer > 10 {
                state.action = .biting
                effects.insert(.biting)
            }
        case .stoppedBiting:
            state.tangible = false
            effects.formUnion([.stoppedBiting, .intangible])
            if input.distanceToMario < 400, input.marioMovingFast {
                state.action = .biting
                effects.insert(.biting)
            } else if input.nearAnimationEnd {
                state.action = .sleeping
                effects.insert(.sleeping)
            }
        case .attacked:
            state.tangible = false
            effects.formUnion([.attacked, .intangible])
            if input.nearAnimationEnd {
                state.action = .shrinkAndDie
                effects.insert(.shrink)
            }
        case .shrinkAndDie:
            state.tangible = false
            state.scale = max(0, state.scale - 0.04)
            effects.formUnion([.shrink, .intangible])
            if state.scale == 0 {
                state.blueCoinRequested = true
                state.action = .waitToRespawn
                effects.formUnion([.blueCoin, .waitToRespawn])
            }
        case .waitToRespawn:
            state.tangible = false
            effects.formUnion([.waitToRespawn, .intangible])
            if input.distanceToMario > 1_200 {
                state.action = .respawn
            }
        case .respawn:
            state.tangible = false
            if state.timer == 0 { state.scale = 0.3 }
            state.scale = min(1, state.scale + 0.02)
            effects.formUnion([.respawn, .intangible])
            if state.scale >= 1 {
                state.action = .idle
                effects.insert(.idle)
            }
        }

        if input.interacted {
            if input.wasAttacked || (state.action == .biting && input.marioMetalCap) {
                state.action = .attacked
                state.tangible = false
                effects.formUnion([.attacked, .particles, .intangible])
            } else {
                state.action = .wokenUp
                effects.insert(.wokenUp)
            }
        }

        if state.timer < 0x3FFF_FFFF { state.timer += 1 }
        return SM64PiranhaPlantTickResult(state: state, effects: effects)
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int32) -> Int16 {
        let delta = Int32(target) - Int32(current)
        if delta > increment { return current &+ Int16(clamping: increment) }
        if delta < -increment { return current &- Int16(clamping: increment) }
        return target
    }
}
