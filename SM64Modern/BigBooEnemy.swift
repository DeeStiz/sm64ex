import Foundation

enum SM64BigBooVariant: UInt8, Equatable, Sendable {
    case ghostHunt = 0
    case merryGoRound = 1
    case balcony = 2
}

enum SM64BigBooAction: UInt8, Equatable, Sendable {
    case initialize = 0
    case chase = 1
    case bounced = 2
    case death = 3
    case postDeath = 4
}

enum SM64BigBooAttackStatus: UInt8, Equatable, Sendable {
    case none = 0
    case bounced = 1
    case attacked = 2
}

struct SM64BigBooHitbox: Equatable, Sendable {
    let interactType: UInt32
    let damageOrCoinValue: Int16
    let health: Int16
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let givingStar = Self(
        interactType: 0,
        damageOrCoinValue: 3,
        health: 3,
        radius: 140,
        height: 80,
        hurtboxRadius: 40,
        hurtboxHeight: 60
    )
}

struct SM64BigBooState: Equatable, Sendable {
    let variant: SM64BigBooVariant
    let hitbox: SM64BigBooHitbox

    var action: SM64BigBooAction = .initialize
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var initialMoveYaw: Int16
    var moveYaw: Int16
    var faceYaw: Int16
    var faceRoll: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var gravity: Float = 0
    var opacity: Int16 = 255
    var targetOpacity: Int16 = 255
    var baseScale: Float = 3
    var renderScaleX: Float = 3
    var renderScaleY: Float = 3
    var renderScaleZ: Float = 3
    var oscillationTimer: UInt32 = 0
    var moveYawDuringHit: Int16 = 0
    var moveYawBeforeHit: Int16 = 0
    var negatedAggressiveness: Float = 0
    var deathStatus: UInt8 = 0
    var health: Int16 = 3
    var minionBoosKilled: Int16
    var tangible = false
    var hidden = true
    var interactionType: UInt32 = 0
    var markedForDeletion = false
    var timer: UInt32 = 0

    init(
        variant: SM64BigBooVariant = .ghostHunt,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        minionBoosKilled: Int16? = nil
    ) {
        self.variant = variant
        self.hitbox = .givingStar
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.initialMoveYaw = moveYaw
        self.moveYaw = moveYaw
        self.faceYaw = moveYaw
        self.minionBoosKilled = minionBoosKilled ?? (variant == .ghostHunt ? 0 : 10)
    }
}

struct SM64BigBooTickInput: Equatable, Sendable {
    var activeInRoom: Bool
    var distanceToMario: Float
    var lateralDistanceFromHome: Float
    var angleToMario: Int16
    var angleToHome: Int16
    var marioFaceYaw: Int16
    var marioMoveYaw: Int16
    var marioY: Float
    var marioInAir: Bool
    var attackStatus: SM64BigBooAttackStatus
    var hitWall: Bool
    var shouldStop: Bool
    var randomValue: UInt32

    init(
        activeInRoom: Bool = true,
        distanceToMario: Float = 10_000,
        lateralDistanceFromHome: Float = 0,
        angleToMario: Int16 = 0,
        angleToHome: Int16 = 0,
        marioFaceYaw: Int16 = 0,
        marioMoveYaw: Int16 = 0,
        marioY: Float = 0,
        marioInAir: Bool = false,
        attackStatus: SM64BigBooAttackStatus = .none,
        hitWall: Bool = false,
        shouldStop: Bool = false,
        randomValue: UInt32 = 0
    ) {
        self.activeInRoom = activeInRoom
        self.distanceToMario = distanceToMario
        self.lateralDistanceFromHome = lateralDistanceFromHome
        self.angleToMario = angleToMario
        self.angleToHome = angleToHome
        self.marioFaceYaw = marioFaceYaw
        self.marioMoveYaw = marioMoveYaw
        self.marioY = marioY
        self.marioInAir = marioInAir
        self.attackStatus = attackStatus
        self.hitWall = hitWall
        self.shouldStop = shouldStop
        self.randomValue = randomValue
    }
}

struct SM64BigBooEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let initialize = Self(rawValue: 1 << 0)
    static let chase = Self(rawValue: 1 << 1)
    static let appear = Self(rawValue: 1 << 2)
    static let vanish = Self(rawValue: 1 << 3)
    static let oscillate = Self(rawValue: 1 << 4)
    static let bounced = Self(rawValue: 1 << 5)
    static let attacked = Self(rawValue: 1 << 6)
    static let deathStart = Self(rawValue: 1 << 7)
    static let mist = Self(rawValue: 1 << 8)
    static let intangible = Self(rawValue: 1 << 9)
    static let tangible = Self(rawValue: 1 << 10)
    static let sound = Self(rawValue: 1 << 11)
    static let shake = Self(rawValue: 1 << 12)
    static let star = Self(rawValue: 1 << 13)
    static let spawnBridge = Self(rawValue: 1 << 14)
    static let markForDeletion = Self(rawValue: 1 << 15)
}

struct SM64BigBooTickResult: Equatable, Sendable {
    let state: SM64BigBooState
    let effects: SM64BigBooEffect
    let starPosition: SM64ObjectVector3?
    let bridgePosition: SM64ObjectVector3?
}

enum SM64BigBooKernel {
    private static let rollCurve: [Int16] = [
        6047, 5664, 5292, 4934, 4587, 4254, 3933, 3624, 3329, 3046,
        2775, 2517, 2271, 2039, 1818, 1611, 1416, 1233, 1063, 906,
        761, 629, 509, 402, 308, 226, 157, 100, 56, 25, 4, 0
    ]

    static let ghostHuntStarPosition = SM64ObjectVector3(x: 980, y: 1_100, z: 250)
    static let merryGoRoundStarPosition = SM64ObjectVector3(x: -1_600, y: -2_100, z: 205)
    static let balconyStarPosition = SM64ObjectVector3(x: 700, y: 3_200, z: 1_900)
    static let ghostHuntBridgePosition = SM64ObjectVector3(x: 973, y: 717, z: 626)
    static let minimumMinionBoos: Int16 = 5

    static func tick(
        _ input: SM64BigBooTickInput,
        state: inout SM64BigBooState
    ) -> SM64BigBooTickResult {
        var effects: SM64BigBooEffect = []
        var starPosition: SM64ObjectVector3?
        var bridgePosition: SM64ObjectVector3?

        switch state.action {
        case .initialize:
            effects.insert(.initialize)
            state.positionX = state.homeX
            state.positionY = state.homeY
            state.positionZ = state.homeZ
            state.moveYaw = state.initialMoveYaw
            state.forwardVelocity = 0
            state.velocityY = 0
            state.gravity = 0
            state.hidden = true
            state.tangible = false
            state.interactionType = 0
            state.targetOpacity = 255
            state.baseScale = 3
            if input.activeInRoom && state.minionBoosKilled >= minimumMinionBoos {
                state.action = .chase
                state.hidden = false
                state.tangible = true
                state.interactionType = 0x8000
                state.health = 3
                effects.insert(.tangible)
                effects.insert(.chase)
            }

        case .chase:
            chase(input: input, state: &state, effects: &effects)
            switch input.attackStatus {
            case .none:
                break
            case .bounced:
                state.action = .bounced
                state.timer = 0
                effects.insert(.bounced)
            case .attacked:
                state.action = .death
                state.timer = 0
                state.interactionType = 0
                state.tangible = false
                effects.insert([.attacked, .deathStart, .intangible, .sound])
            }
            if input.shouldStop { state.action = .initialize }
            advance(&state)

        case .bounced:
            stop(&state)
            if state.timer == 0 { setMoveYawForHit(input: input, state: &state) }
            if state.timer < UInt32(rollCurve.count) {
                let roll = rollCurve[Int(state.timer)]
                state.forwardVelocity = Float(roll) / 5_000 * 20
                state.velocityY = SM64CanonicalTrig.coss(
                    Int16(truncatingIfNeeded: Int32(state.timer) * 0x800 + 0x800)
                )
                state.moveYaw = state.moveYawDuringHit
                state.faceYaw &+= roll
                state.faceRoll &+= roll
                effects.insert([.bounced, .oscillate])
            } else {
                state.tangible = true
                state.interactionType = state.hitbox.interactType
                state.moveYaw = state.moveYawBeforeHit
                state.faceYaw = state.moveYaw
                state.action = .chase
                effects.insert([.tangible, .chase])
            }
            advance(&state)

        case .death:
            if state.timer == 0 {
                state.health = max(0, state.health - 1)
            }
            if state.health == 0 {
                if updateDuringDeath(input: input, state: &state, effects: &effects) {
                    state.action = .postDeath
                    state.faceYaw = 0
                    state.faceRoll = 0
                    starPosition = rewardPosition(for: state.variant)
                    effects.insert(.star)
                }
            } else {
                if state.timer == 0 {
                    effects.insert(.mist)
                    state.baseScale -= 0.5
                }
                if updateDuringNonlethalHit(input: input, state: &state, effects: &effects) {
                    state.action = .chase
                }
            }
            if state.action == .death { advance(&state) }

        case .postDeath:
            stop(&state)
            if state.variant == .ghostHunt {
                state.positionX = 973
                state.positionY = 0
                state.positionZ = 626
                if state.timer > 60 && input.distanceToMario < 600 {
                    state.positionY = 0
                    state.positionZ = 717
                    bridgePosition = ghostHuntBridgePosition
                    effects.insert([.spawnBridge, .markForDeletion])
                    state.markedForDeletion = true
                }
            } else {
                effects.insert(.markForDeletion)
                state.markedForDeletion = true
            }
        }

        approachOpacityAndScale(&state, effects: &effects)
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64BigBooTickResult(
            state: state,
            effects: effects,
            starPosition: starPosition,
            bridgePosition: bridgePosition
        )
    }

    private static func chase(
        input: SM64BigBooTickInput,
        state: inout SM64BigBooState,
        effects: inout SM64BigBooEffect
    ) {
        if state.timer == 0 {
            state.negatedAggressiveness = -Float(input.randomValue % 100) / 20
        }
        guard shouldAppearOrVanish(input: input, state: &state, effects: &effects) else {
            state.interactionType = 0
            state.tangible = false
            stop(&state)
            effects.insert([.vanish, .intangible])
            return
        }

        state.interactionType = 0x8000
        state.tangible = true
        let increment: Int16
        let sideways: Float
        switch state.health {
        case 3:
            increment = 0x180
            sideways = 0.5
        case 2:
            increment = 0x240
            sideways = 0.6
        default:
            increment = 0x300
            sideways = 0.8
        }
        let targetYaw = input.lateralDistanceFromHome > 1_500 ? input.angleToHome : input.angleToMario
        state.moveYaw = approachAngle(current: state.moveYaw, target: targetYaw, increment: increment)
        state.faceYaw = state.moveYaw
        state.velocityY = 0
        if !input.marioInAir {
            let deltaY = state.positionY - input.marioY
            if deltaY > -100 && deltaY < 500 {
                state.velocityY = approach(
                    state.velocityY,
                    target: input.marioY + 50 - state.positionY,
                    step: 10
                )
            }
        }
        state.forwardVelocity = max(0, 10 - state.negatedAggressiveness)
        if state.forwardVelocity != 0 {
            oscillate(&state, effects: &effects)
        }
        _ = sideways // retained as an explicit source health branch
        effects.insert(.chase)
    }

    private static func shouldAppearOrVanish(
        input: SM64BigBooTickInput,
        state: inout SM64BigBooState,
        effects: inout SM64BigBooEffect
    ) -> Bool {
        let relativeAngleToMario = absAngleDiff(input.angleToMario, state.moveYaw)
        let relativeMarioFaceAngle = absAngleDiff(state.moveYaw, input.marioFaceYaw)
        if relativeAngleToMario > 0x1568 || relativeMarioFaceAngle < 0x6B58 {
            if state.opacity == 40 {
                state.targetOpacity = 255
                effects.insert([.appear, .sound])
            }
            if state.opacity > 180 { effects.insert(.appear) }
            return true
        }
        if state.opacity == 255 { state.targetOpacity = 40; effects.insert(.vanish) }
        return false
    }

    private static func updateDuringNonlethalHit(
        input: SM64BigBooTickInput,
        state: inout SM64BigBooState,
        effects: inout SM64BigBooEffect
    ) -> Bool {
        stop(&state)
        if state.timer == 0 { setMoveYawForHit(input: input, state: &state, hurt: true) }
        if state.timer < 32 {
            let roll = rollCurve[Int(state.timer)]
            state.forwardVelocity = Float(roll) / 5_000 * 40
            state.velocityY = SM64CanonicalTrig.coss(
                Int16(truncatingIfNeeded: Int32(state.timer) * 0x800 + 0x800)
            )
            state.faceYaw &+= roll
            state.faceRoll &+= roll
            effects.insert([.deathStart, .shake])
        } else if state.timer < 48 {
            state.faceYaw &+= Int16(truncatingIfNeeded: Int32(SM64CanonicalTrig.coss(
                Int16(truncatingIfNeeded: Int32(state.timer) * 0x2000 - 0x3E000)
            ) * 0x400))
            effects.insert(.shake)
        } else {
            state.tangible = true
            state.interactionType = state.hitbox.interactType
            state.moveYaw = state.moveYawBeforeHit
            state.faceYaw = state.moveYaw
            effects.insert(.tangible)
            return true
        }
        return false
    }

    private static func updateDuringDeath(
        input: SM64BigBooTickInput,
        state: inout SM64BigBooState,
        effects: inout SM64BigBooEffect
    ) -> Bool {
        if state.timer == 0 {
            state.forwardVelocity = 40
            state.moveYaw = input.marioMoveYaw
            state.deathStatus = 1
        } else if state.timer == 5 {
            state.targetOpacity = 0
        }
        state.velocityY = 5
        state.faceRoll &+= 0x800
        state.faceYaw &+= 0x800
        if state.timer > 30 || input.hitWall {
            state.deathStatus = 2
            effects.insert(.mist)
            return true
        }
        effects.insert(.deathStart)
        return false
    }

    private static func setMoveYawForHit(
        input: SM64BigBooTickInput,
        state: inout SM64BigBooState,
        hurt: Bool = false
    ) {
        state.moveYawBeforeHit = state.moveYaw
        state.moveYawDuringHit = hurt
            ? input.marioMoveYaw
            : (SM64CanonicalTrig.coss(state.moveYaw &- input.angleToMario) < 0
                ? state.moveYaw
                : state.moveYaw &+ Int16(truncatingIfNeeded: 0x8000))
    }

    private static func approachOpacityAndScale(
        _ state: inout SM64BigBooState,
        effects: inout SM64BigBooEffect
    ) {
        if state.targetOpacity != state.opacity {
            if state.targetOpacity > state.opacity {
                state.opacity = min(state.targetOpacity, state.opacity &+ 20)
            } else {
                state.opacity = max(state.targetOpacity, state.opacity &- 20)
            }
        }
        let opacity = Float(state.opacity) / 255
        let scale = (opacity * 0.4 + 0.6) * state.baseScale
        state.renderScaleX = scale
        state.renderScaleY = scale
        state.renderScaleZ = scale
        _ = effects
    }

    private static func oscillate(
        _ state: inout SM64BigBooState,
        effects: inout SM64BigBooEffect
    ) {
        let sine = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: state.oscillationTimer))
        if state.opacity == 255 {
            state.renderScaleX = sine * 0.08 + state.baseScale
            state.renderScaleY = -sine * 0.08 + state.baseScale
            state.renderScaleZ = state.renderScaleX
            state.gravity = sine * state.baseScale
            state.oscillationTimer &+= 0x400
        }
        effects.insert(.oscillate)
    }

    private static func stop(_ state: inout SM64BigBooState) {
        state.forwardVelocity = 0
        state.velocityY = 0
        state.gravity = 0
    }

    private static func advance(_ state: inout SM64BigBooState) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionY += state.velocityY
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
    }

    private static func rewardPosition(for variant: SM64BigBooVariant) -> SM64ObjectVector3 {
        switch variant {
        case .ghostHunt: return ghostHuntStarPosition
        case .merryGoRound: return merryGoRoundStarPosition
        case .balcony: return balconyStarPosition
        }
    }

    private static func approach(_ current: Float, target: Float, step: Float) -> Float {
        if current < target { return min(target, current + step) }
        if current > target { return max(target, current - step) }
        return current
    }

    private static func absAngleDiff(_ lhs: Int16, _ rhs: Int16) -> Int32 {
        let distance = abs(Int32(lhs) - Int32(rhs))
        return min(distance, 0x1_0000 - distance)
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }
}
