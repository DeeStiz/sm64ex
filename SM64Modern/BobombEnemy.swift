import Foundation

/// The generic Bob-omb behavior is intentionally kept separate from the
/// Bob-omb Buddy NPC.  The C behavior uses the same object fields for a
/// patrol/chase actor, a held object, and a launched explosive; these enums
/// preserve those values without exposing a C object pointer.
enum SM64BobombSubtype: UInt8, Equatable, Sendable {
    case generic = 0
    case stationary = 1
}

enum SM64BobombHeldState: UInt8, Equatable, Sendable {
    case free = 0
    case held = 1
    case thrown = 2
    case dropped = 3
}

enum SM64BobombAction: UInt16, Equatable, Sendable {
    case patrol = 0
    case launched = 1
    case chase = 2
    case explode = 3
    case lavaDeath = 100
    case deathPlaneDeath = 101
}

struct SM64BobombHitbox: Equatable, Sendable {
    let interactType: UInt32
    let interactionSubtype: UInt32
    let damageOrCoinValue: Int16
    let health: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let standard = Self(
        // INTERACT_GRABBABLE and INT_SUBTYPE_KICKABLE.
        interactType: 1 << 1,
        interactionSubtype: 1 << 8,
        damageOrCoinValue: 0,
        health: 0,
        numLootCoins: 0,
        radius: 65,
        height: 113,
        hurtboxRadius: 0,
        hurtboxHeight: 0
    )
}

struct SM64BobombState: Equatable, Sendable {
    let subtype: SM64BobombSubtype
    let hitbox: SM64BobombHitbox

    var heldState: SM64BobombHeldState
    var action: SM64BobombAction
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var floorHeight: Float
    var moveYaw: Int16
    var faceYaw: Int16
    var forwardVelocity: Float
    var velocityY: Float
    var gravity: Float = 2.5
    var friction: Float = 0.8
    var buoyancy: Float = 1.3
    var fuseLit = false
    var fuseTimer: UInt32 = 0
    var blinkTimer: UInt32 = 0
    var animationFrame: Int16 = 0
    var scale: Float = 1
    var hidden = false
    var tangible = true
    var markedForDeletion = false
    var respawnRequested = false
    var coinRequested = false
    var timer: UInt32 = 0

    init(
        subtype: SM64BobombSubtype = .generic,
        heldState: SM64BobombHeldState = .free,
        action: SM64BobombAction = .patrol,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0
    ) {
        self.subtype = subtype
        self.hitbox = .standard
        self.heldState = heldState
        self.action = action
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.floorHeight = floorHeight
        self.moveYaw = moveYaw
        self.faceYaw = moveYaw
        self.forwardVelocity = 0
        self.velocityY = 0
    }
}

struct SM64BobombTickInput: Equatable, Sendable {
    var activeWithinRadius: Bool
    var distanceFromHome: Float
    var homeRadiusExceeded: Bool
    var facingTowardMario: Bool
    var angleToMario: Int16
    var marioYaw: Int16
    var marioX: Float
    var marioY: Float
    var marioZ: Float
    var interacted: Bool
    var marioUnk1: Bool
    var touchedBobomb: Bool
    var attackCollided: Bool
    var moveFlags: UInt32
    var floorDeath: Bool
    var randomBlink: Bool

    init(
        activeWithinRadius: Bool = true,
        distanceFromHome: Float = 0,
        homeRadiusExceeded: Bool = false,
        facingTowardMario: Bool = true,
        angleToMario: Int16 = 0,
        marioYaw: Int16 = 0,
        marioX: Float = 0,
        marioY: Float = 0,
        marioZ: Float = 0,
        interacted: Bool = false,
        marioUnk1: Bool = false,
        touchedBobomb: Bool = false,
        attackCollided: Bool = false,
        moveFlags: UInt32 = 1,
        floorDeath: Bool = false,
        randomBlink: Bool = false
    ) {
        self.activeWithinRadius = activeWithinRadius
        self.distanceFromHome = distanceFromHome
        self.homeRadiusExceeded = homeRadiusExceeded
        self.facingTowardMario = facingTowardMario
        self.angleToMario = angleToMario
        self.marioYaw = marioYaw
        self.marioX = marioX
        self.marioY = marioY
        self.marioZ = marioZ
        self.interacted = interacted
        self.marioUnk1 = marioUnk1
        self.touchedBobomb = touchedBobomb
        self.attackCollided = attackCollided
        self.moveFlags = moveFlags
        self.floorDeath = floorDeath
        self.randomBlink = randomBlink
    }
}

struct SM64BobombEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let walkSound = Self(rawValue: 1 << 1)
    static let fuseLit = Self(rawValue: 1 << 2)
    static let fuseSmoke = Self(rawValue: 1 << 3)
    static let launch = Self(rawValue: 1 << 4)
    static let chase = Self(rawValue: 1 << 5)
    static let held = Self(rawValue: 1 << 6)
    static let dropped = Self(rawValue: 1 << 7)
    static let explosion = Self(rawValue: 1 << 8)
    static let coin = Self(rawValue: 1 << 9)
    static let respawn = Self(rawValue: 1 << 10)
    static let mist = Self(rawValue: 1 << 11)
    static let markForDeletion = Self(rawValue: 1 << 12)
    static let tangible = Self(rawValue: 1 << 13)
    static let intangible = Self(rawValue: 1 << 14)
    static let blink = Self(rawValue: 1 << 15)
    static let hidden = Self(rawValue: 1 << 16)
    static let shown = Self(rawValue: 1 << 17)
}

struct SM64BobombTickResult: Equatable, Sendable {
    let state: SM64BobombState
    let effects: SM64BobombEffect
}

enum SM64BobombKernel {
    // OBJ_COL_FLAG_GROUNDED and the held-object interaction bits.
    static let collisionGrounded: UInt32 = 1 << 0
    static let collisionHitWall: UInt32 = 1 << 1
    static let marioUnk1Status: UInt32 = 1 << 1
    static let touchedBobombStatus: UInt32 = 1 << 23

    static func tick(
        _ input: SM64BobombTickInput,
        state: inout SM64BobombState
    ) -> SM64BobombTickResult {
        var effects: SM64BobombEffect = []

        guard input.activeWithinRadius else {
            return SM64BobombTickResult(state: state, effects: effects)
        }

        switch state.heldState {
        case .free:
            tickFree(input, state: &state, effects: &effects)
        case .held:
            tickHeld(input, state: &state, effects: &effects)
        case .thrown:
            release(.thrown, input: input, state: &state, effects: &effects)
        case .dropped:
            release(.dropped, input: input, state: &state, effects: &effects)
        }

        randomBlink(input: input, state: &state, effects: &effects)
        if state.fuseLit {
            effects.insert(.fuseLit)
            let periodMinusOne: UInt32 = state.fuseTimer >= 121 ? 1 : 7
            if state.fuseTimer & periodMinusOne == 0 {
                effects.insert(.fuseSmoke)
            }
            state.fuseTimer = state.fuseTimer == UInt32.max ? .max : state.fuseTimer + 1
            if state.fuseTimer >= 151 {
                state.action = .explode
            }
        }

        if state.timer < 0x3FFF_FFFF { state.timer += 1 }
        return SM64BobombTickResult(state: state, effects: effects)
    }

    private static func tickFree(
        _ input: SM64BobombTickInput,
        state: inout SM64BobombState,
        effects: inout SM64BobombEffect
    ) {
        switch state.action {
        case .patrol:
            if state.subtype == .generic {
                state.forwardVelocity = 5
                moveStandard(state: &state, floorFlags: input.moveFlags)
                if input.distanceFromHome <= 400, input.facingTowardMario {
                    state.fuseLit = true
                    state.action = .chase
                    effects.insert(.chase)
                }
            }
        case .launched:
            moveStandard(state: &state, floorFlags: input.moveFlags)
            if input.moveFlags & collisionGrounded != 0 {
                state.action = .explode
            }
        case .chase:
            state.animationFrame &+= 1
            state.forwardVelocity = 20
            state.moveYaw = approachAngle(
                current: state.moveYaw,
                target: input.angleToMario,
                increment: 0x800
            )
            moveStandard(state: &state, floorFlags: input.moveFlags)
            effects.insert(.chase)
            if state.animationFrame == 5 || state.animationFrame == 16 {
                effects.insert(.walkSound)
            }
        case .explode:
            if state.timer < 5 {
                state.scale = 1 + Float(state.timer) / 5
            } else {
                state.scale = 2
                state.coinRequested = true
                state.respawnRequested = true
                state.markedForDeletion = true
                effects.formUnion([.explosion, .coin, .respawn, .markForDeletion])
            }
        case .lavaDeath:
            if input.floorDeath {
                state.respawnRequested = true
                state.markedForDeletion = true
                effects.formUnion([.mist, .respawn, .markForDeletion])
            }
        case .deathPlaneDeath:
            state.respawnRequested = true
            state.markedForDeletion = true
            effects.formUnion([.respawn, .markForDeletion])
        }

        // C checks interactions after the action callback, so these writes
        // intentionally win over a movement decision from the same frame.
        if input.interacted {
            if input.marioUnk1 {
                state.moveYaw = input.marioYaw
                state.forwardVelocity = 25
                state.velocityY = 30
                state.action = .launched
                effects.insert(.launch)
            }
            if input.touchedBobomb {
                state.action = .explode
            }
        }
        if input.attackCollided {
            state.action = .explode
        }
    }

    private static func tickHeld(
        _ input: SM64BobombTickInput,
        state: inout SM64BobombState,
        effects: inout SM64BobombEffect
    ) {
        state.hidden = true
        state.tangible = true
        state.moveYaw = input.marioYaw
        state.positionX = input.marioX + 100 * SM64CanonicalTrig.sins(input.marioYaw)
        state.positionY = input.marioY + 60
        state.positionZ = input.marioZ + 100 * SM64CanonicalTrig.coss(input.marioYaw)
        state.fuseLit = true
        effects.formUnion([.held, .hidden])
        if state.fuseTimer >= 151 {
            state.action = .explode
            effects.insert(.dropped)
        }
    }

    private static func release(
        _ heldState: SM64BobombHeldState,
        input: SM64BobombTickInput,
        state: inout SM64BobombState,
        effects: inout SM64BobombEffect
    ) {
        state.heldState = .free
        state.hidden = false
        effects.formUnion([.shown, .tangible])
        if heldState == .thrown {
            state.action = .launched
            state.forwardVelocity = 25
            state.velocityY = 20
            state.moveYaw = input.marioYaw
            effects.insert(.launch)
        } else {
            state.action = .patrol
            state.forwardVelocity = 0
            state.velocityY = 0
            effects.insert(.dropped)
        }
    }

    private static func randomBlink(
        input: SM64BobombTickInput,
        state: inout SM64BobombState,
        effects: inout SM64BobombEffect
    ) {
        if state.blinkTimer == 0 {
            if input.randomBlink {
                state.blinkTimer = 1
                effects.insert(.blink)
            }
        } else {
            state.blinkTimer += 1
            if state.blinkTimer >= 16 {
                state.blinkTimer = 0
            }
            effects.insert(.blink)
        }
    }

    private static func moveStandard(state: inout SM64BobombState, floorFlags: UInt32) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
        state.velocityY -= state.gravity
        state.velocityY = max(state.velocityY, -75)
        state.positionY += state.velocityY
        if floorFlags & collisionGrounded != 0, state.positionY <= state.floorHeight {
            state.positionY = state.floorHeight
            if state.velocityY < -17.5 {
                state.velocityY = -(state.velocityY / 2)
            } else {
                state.velocityY = 0
            }
        }
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int32) -> Int16 {
        let delta = Int32(target) - Int32(current)
        if delta > increment { return current &+ Int16(clamping: increment) }
        if delta < -increment { return current &- Int16(clamping: increment) }
        return target
    }
}
