import Foundation

enum SM64MoneybagAction: UInt8, Equatable, Sendable {
    case appear = 0
    case unusedAppear = 1
    case moveAround = 2
    case returnHome = 3
    case disappear = 4
    case death = 5
}

enum SM64MoneybagJumpState: UInt8, Equatable, Sendable {
    case landing = 0
    case prepare = 1
    case jump = 2
    case jumpAndBounce = 3
    case walkAround = 4
    case walkHome = 5
}

enum SM64MoneybagHiddenAction: UInt8, Equatable, Sendable {
    case idle = 0
    case transform = 1
}

struct SM64MoneybagHitbox: Equatable, Sendable {
    let interactType: UInt32
    let damageOrCoinValue: Int16
    let health: Int16
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let visible = Self(
        interactType: 1 << 15, // INTERACT_BOUNCE_TOP
        damageOrCoinValue: 2,
        health: 1,
        radius: 120,
        height: 60,
        hurtboxRadius: 100,
        hurtboxHeight: 50
    )
    static let hidden = Self(
        interactType: 1 << 3, // INTERACT_DAMAGE
        damageOrCoinValue: 2,
        health: 1,
        radius: 120,
        height: 60,
        hurtboxRadius: 100,
        hurtboxHeight: 50
    )
}

struct SM64MoneybagState: Equatable, Sendable {
    var action: SM64MoneybagAction
    var jumpState: SM64MoneybagJumpState = .landing
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var floorHeight: Float
    var moveYaw: Int16
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var opacity: Int32 = 0
    var timer: UInt32 = 0
    var tangible = false
    var markedForDeletion = false
    var coinCount: UInt8 = 0

    init(
        action: SM64MoneybagAction = .appear,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        homeX: Float? = nil,
        homeY: Float? = nil,
        homeZ: Float? = nil,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0
    ) {
        self.action = action
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.homeX = homeX ?? positionX
        self.homeY = homeY ?? positionY
        self.homeZ = homeZ ?? positionZ
        self.floorHeight = floorHeight
        self.moveYaw = moveYaw
    }

    var hitbox: SM64MoneybagHitbox { .visible }
}

struct SM64MoneybagHiddenState: Equatable, Sendable {
    var action: SM64MoneybagHiddenAction = .idle
    var positionX: Float = 0
    var positionY: Float = 0
    var positionZ: Float = 0
    var timer: UInt32 = 0

    var hitbox: SM64MoneybagHitbox { .hidden }
}

struct SM64MoneybagTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var homeDistanceToMario: Float
    var closeToHome: Bool
    var angleToMario: Int16
    var angleToHome: Int16
    var interacted: Bool
    var attackedMario: Bool
    var wasAttacked: Bool
    var collisionFlags: UInt32
    var animationFrame: Int16
    var nearAnimationEnd: Bool
    var randomWalkChoice: Bool

    init(
        distanceToMario: Float = 2_000,
        homeDistanceToMario: Float = 0,
        closeToHome: Bool = false,
        angleToMario: Int16 = 0,
        angleToHome: Int16 = 0,
        interacted: Bool = false,
        attackedMario: Bool = false,
        wasAttacked: Bool = false,
        collisionFlags: UInt32 = 1,
        animationFrame: Int16 = 0,
        nearAnimationEnd: Bool = false,
        randomWalkChoice: Bool = false
    ) {
        self.distanceToMario = distanceToMario
        self.homeDistanceToMario = homeDistanceToMario
        self.closeToHome = closeToHome
        self.angleToMario = angleToMario
        self.angleToHome = angleToHome
        self.interacted = interacted
        self.attackedMario = attackedMario
        self.wasAttacked = wasAttacked
        self.collisionFlags = collisionFlags
        self.animationFrame = animationFrame
        self.nearAnimationEnd = nearAnimationEnd
        self.randomWalkChoice = randomWalkChoice
    }
}

struct SM64MoneybagHiddenTickInput: Equatable, Sendable {
    var withinRadius: Bool
    var moneybagPositionX: Float
    var moneybagPositionY: Float
    var moneybagPositionZ: Float

    init(withinRadius: Bool = false, moneybagPositionX: Float = 0, moneybagPositionY: Float = 0, moneybagPositionZ: Float = 0) {
        self.withinRadius = withinRadius
        self.moneybagPositionX = moneybagPositionX
        self.moneybagPositionY = moneybagPositionY
        self.moneybagPositionZ = moneybagPositionZ
    }
}

struct SM64MoneybagEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let appear = Self(rawValue: 1 << 0)
    static let moveAround = Self(rawValue: 1 << 1)
    static let returnHome = Self(rawValue: 1 << 2)
    static let disappear = Self(rawValue: 1 << 3)
    static let death = Self(rawValue: 1 << 4)
    static let prepareJump = Self(rawValue: 1 << 5)
    static let jump = Self(rawValue: 1 << 6)
    static let walk = Self(rawValue: 1 << 7)
    static let land = Self(rawValue: 1 << 8)
    static let bounce = Self(rawValue: 1 << 9)
    static let coin = Self(rawValue: 1 << 10)
    static let coins = Self(rawValue: 1 << 11)
    static let hiddenSpawn = Self(rawValue: 1 << 12)
    static let mist = Self(rawValue: 1 << 13)
    static let markForDeletion = Self(rawValue: 1 << 14)
    static let tangible = Self(rawValue: 1 << 15)
    static let intangible = Self(rawValue: 1 << 16)
    static let hiddenTransform = Self(rawValue: 1 << 17)
}

struct SM64MoneybagTickResult: Equatable, Sendable {
    let state: SM64MoneybagState
    let effects: SM64MoneybagEffect
}

struct SM64MoneybagHiddenTickResult: Equatable, Sendable {
    let state: SM64MoneybagHiddenState
    let effects: SM64MoneybagEffect
}

enum SM64MoneybagKernel {
    static let grounded: UInt32 = 1 << 0
    static let noYVelocity: UInt32 = 1 << 3
    static let landedFlags: UInt32 = grounded | noYVelocity

    static func tick(
        _ input: SM64MoneybagTickInput,
        state: inout SM64MoneybagState
    ) -> SM64MoneybagTickResult {
        var effects: SM64MoneybagEffect = []
        switch state.action {
        case .appear, .unusedAppear:
            state.opacity = min(255, state.opacity + 12)
            effects.insert(.appear)
            if state.opacity >= 255 {
                state.action = .moveAround
                effects.insert(.moveAround)
            }
        case .moveAround:
            state.tangible = state.timer >= 31
            if state.tangible { effects.insert(.tangible) } else { effects.insert(.intangible) }
            stepJump(input, state: &state, effects: &effects)
            if input.homeDistanceToMario > 800, input.collisionFlags & landedFlags == landedFlags {
                state.action = .returnHome
                effects.insert(.returnHome)
            }
        case .returnHome:
            state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToHome, increment: 0x800)
            stepJump(input, state: &state, effects: &effects)
            if input.closeToHome {
                state.action = .disappear
                state.jumpState = .landing
                effects.formUnion([.hiddenSpawn, .disappear])
            }
            if input.homeDistanceToMario < 800 {
                state.action = .moveAround
                state.jumpState = .landing
                effects.insert(.moveAround)
            }
        case .disappear:
            state.opacity -= 6
            effects.insert(.disappear)
            if state.opacity <= 0 {
                state.opacity = 0
                state.markedForDeletion = true
                effects.insert(.markForDeletion)
            }
        case .death:
            state.tangible = false
            effects.insert(.death)
            if state.timer == 1 {
                state.coinCount = 5
                state.markedForDeletion = true
                effects.formUnion([.coins, .mist, .markForDeletion])
            }
        }

        if state.action == .moveAround || state.action == .returnHome {
            if input.interacted {
                if input.attackedMario {
                    state.moveYaw = input.angleToMario &+ Int16(bitPattern: 0x8000)
                    state.velocityY = 30
                    effects.insert(.bounce)
                }
                if input.wasAttacked {
                    state.action = .death
                    effects.insert(.death)
                }
            }
        }
        if state.timer < 0x3FFF_FFFF { state.timer += 1 }
        return SM64MoneybagTickResult(state: state, effects: effects)
    }

    static func tickHidden(
        _ input: SM64MoneybagHiddenTickInput,
        state: inout SM64MoneybagHiddenState
    ) -> SM64MoneybagHiddenTickResult {
        var effects: SM64MoneybagEffect = []
        if state.action == .idle, input.withinRadius {
            state.action = .transform
            effects.insert(.hiddenTransform)
            effects.insert(.hiddenSpawn)
        }
        state.timer += 1
        return SM64MoneybagHiddenTickResult(state: state, effects: effects)
    }

    private static func stepJump(
        _ input: SM64MoneybagTickInput,
        state: inout SM64MoneybagState,
        effects: inout SM64MoneybagEffect
    ) {
        switch state.jumpState {
        case .landing:
            state.forwardVelocity = 0
        case .prepare:
            if input.animationFrame == 5 {
                state.forwardVelocity = 20
                state.velocityY = 40
            }
            effects.insert(.prepareJump)
            if input.nearAnimationEnd {
                state.jumpState = .jump
                effects.insert(.jump)
            }
        case .jump:
            effects.insert(.jump)
            if input.collisionFlags & grounded != 0 {
                state.forwardVelocity = 0
                state.velocityY = 0
                state.jumpState = .landing
                effects.insert(.land)
            }
        case .jumpAndBounce:
            effects.insert(.bounce)
            if input.nearAnimationEnd { state.jumpState = .landing; effects.insert(.land) }
        case .walkAround:
            state.forwardVelocity = 10
            effects.insert(.walk)
            if state.timer >= 61 {
                state.jumpState = .landing
                state.forwardVelocity = 0
            }
        case .walkHome:
            state.forwardVelocity = 5
            effects.insert(.walk)
        }
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
        state.velocityY -= 3
        state.velocityY = max(state.velocityY, -75)
        state.positionY += state.velocityY
        if input.collisionFlags & grounded != 0, state.positionY <= state.floorHeight {
            state.positionY = state.floorHeight
            if state.velocityY < -17.5 { state.velocityY = -state.velocityY / 2 } else { state.velocityY = 0 }
        }
        if state.jumpState == .landing, input.collisionFlags & landedFlags == landedFlags {
            if input.randomWalkChoice {
                state.jumpState = .walkAround
                state.timer = 0
            } else {
                state.jumpState = .prepare
            }
            effects.insert(.land)
        }
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int32) -> Int16 {
        let delta = Int32(target) - Int32(current)
        if delta > increment { return current &+ Int16(clamping: increment) }
        if delta < -increment { return current &- Int16(clamping: increment) }
        return target
    }
}
