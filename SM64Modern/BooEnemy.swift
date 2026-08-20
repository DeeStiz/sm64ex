import Foundation

enum SM64BooAction: UInt8, Equatable, Sendable {
    case initialize = 0
    case chase = 1
    case bounced = 2
    case death = 3
    case disabled = 4
}

enum SM64BooAttackStatus: UInt8, Equatable, Sendable {
    case none = 0
    case bounced = 1
    case attacked = 2
}

struct SM64BooHitbox: Equatable, Sendable {
    let interactType: UInt32
    let damageOrCoinValue: Int16
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let standard = Self(
        // The behavior script supplies the radii; interaction type is selected
        // by the chase/vanish state in the native actor.
        interactType: 0,
        damageOrCoinValue: 2,
        radius: 140,
        height: 80,
        hurtboxRadius: 40,
        hurtboxHeight: 60
    )

    static let withCage = Self(
        interactType: 1 << 15,
        damageOrCoinValue: 3,
        radius: 180,
        height: 140,
        hurtboxRadius: 80,
        hurtboxHeight: 120
    )
}

struct SM64BooState: Equatable, Sendable {
    let hitbox: SM64BooHitbox

    var action: SM64BooAction = .initialize
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var initialMoveYaw: Int16
    var moveYaw: Int16
    var faceYaw: Int16
    var facePitch: Int16 = 0
    var faceRoll: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var gravity: Float = 0
    var opacity: Int16 = 255
    var targetOpacity: Int16 = 255
    var baseScale: Float = 1
    var renderScaleX: Float = 1
    var renderScaleY: Float = 1
    var renderScaleZ: Float = 1
    var oscillationTimer: UInt32 = 0
    var moveYawDuringHit: Int16 = 0
    var moveYawBeforeHit: Int16 = 0
    var negatedAggressiveness: Float = 0
    var turningSpeed: Int16 = 0
    var deathStatus: UInt8 = 0
    var tangible = false
    var interactionType: UInt32 = 0
    var markedForDeletion = false
    var timer: UInt32 = 0

    init(homeX: Float = 0, homeY: Float = 0, homeZ: Float = 0, moveYaw: Int16 = 0, hitbox: SM64BooHitbox = .standard, baseScale: Float = 1) {
        self.hitbox = hitbox
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.initialMoveYaw = moveYaw
        self.moveYaw = moveYaw
        self.faceYaw = moveYaw
        self.baseScale = baseScale
    }
}

struct SM64BooTickInput: Equatable, Sendable {
    var activeInRoom: Bool
    var distanceToMario: Float
    var lateralDistanceFromHome: Float
    var angleToMario: Int16
    var angleToHome: Int16
    var marioFaceYaw: Int16
    var marioMoveYaw: Int16
    var marioY: Float
    var marioInAir: Bool
    var marioForwardVelocity: Float
    var attackStatus: SM64BooAttackStatus
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
        marioForwardVelocity: Float = 0,
        attackStatus: SM64BooAttackStatus = .none,
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
        self.marioForwardVelocity = marioForwardVelocity
        self.attackStatus = attackStatus
        self.hitWall = hitWall
        self.shouldStop = shouldStop
        self.randomValue = randomValue
    }
}

struct SM64BooEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
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
    static let markForDeletion = Self(rawValue: 1 << 12)
}

struct SM64BooTickResult: Equatable, Sendable {
    let state: SM64BooState
    let effects: SM64BooEffect
}

enum SM64BooKernel {
    // D_8032F0CC from behavior_actions.c, used by the native Boo roll.
    private static let rollCurve: [Int16] = [
        6047, 5664, 5292, 4934, 4587, 4254, 3933, 3624, 3329, 3046, 2775,
        2517, 2271, 2039, 1818, 1611, 1416, 1233, 1063, 906, 761, 629,
        509, 402, 308, 226, 157, 100, 56, 25, 4, 0
    ]

    static func tick(_ input: SM64BooTickInput, state: inout SM64BooState) -> SM64BooTickResult {
        var effects: SM64BooEffect = [.animate]

        switch state.action {
        case .initialize:
            state.positionX = state.homeX
            state.positionY = state.homeY
            state.positionZ = state.homeZ
            state.moveYaw = state.initialMoveYaw
            state.forwardVelocity = 0
            state.velocityY = 0
            state.gravity = 0
            state.baseScale = state.baseScale == 0 ? 1 : state.baseScale
            state.targetOpacity = 255
            state.tangible = false
            state.interactionType = 0
            if input.activeInRoom && input.distanceToMario < 1_500 {
                state.action = .chase
                effects.insert(.chase)
            }

        case .chase:
            if state.timer == 0 {
                state.negatedAggressiveness = -Float(input.randomValue % 100) / 20
                state.turningSpeed = Int16(truncatingIfNeeded: input.randomValue & 0x7F)
            }

            if shouldAppearOrVanish(input: input, state: &state, effects: &effects) {
                state.interactionType = 0x8000
                state.tangible = true
                let targetYaw = input.lateralDistanceFromHome > 1_500 ? input.angleToHome : input.angleToMario
                state.moveYaw = approachAngle(current: state.moveYaw, target: targetYaw, increment: state.turningSpeed &+ 0x180)
                state.faceYaw = state.moveYaw
                state.velocityY = 0
                if !input.marioInAir {
                    let deltaY = state.positionY - input.marioY
                    if deltaY > -100 && deltaY < 500 {
                        state.velocityY = approach(state.velocityY, target: input.marioY + 50 - state.positionY, step: 10)
                    }
                }
                state.forwardVelocity = max(0, 10 - state.negatedAggressiveness)
                if state.forwardVelocity != 0 { oscillate(&state, effects: &effects, ignoreOpacity: false) }
                effects.insert(.chase)
            } else {
                state.interactionType = 0
                state.tangible = false
                state.forwardVelocity = 0
                state.velocityY = 0
                state.gravity = 0
                effects.insert(.vanish)
                effects.insert(.intangible)
            }

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
            if state.timer < 32 {
                let roll = rollCurve[Int(state.timer)]
                state.forwardVelocity = Float(roll) / 5_000 * 20
                state.velocityY = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: Int32(state.timer) * 0x800 + 0x800))
                state.moveYaw = state.moveYawDuringHit
                state.faceYaw &+= Int16(roll)
                state.faceRoll &+= Int16(roll)
                effects.insert(.bounced)
            } else {
                state.tangible = true
                state.interactionType = state.hitbox.interactType
                state.moveYaw = state.moveYawBeforeHit
                state.faceYaw = state.moveYaw
                state.action = .chase
                effects.insert(.tangible)
                effects.insert(.chase)
            }
            advance(&state)

        case .death:
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
                state.markedForDeletion = true
                effects.insert([.mist, .markForDeletion])
            } else {
                effects.insert(.deathStart)
            }
            advance(&state)

        case .disabled:
            stop(&state)
        }

        approachOpacityAndScale(&state)
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64BooTickResult(state: state, effects: effects)
    }

    private static func shouldAppearOrVanish(
        input: SM64BooTickInput,
        state: inout SM64BooState,
        effects: inout SM64BooEffect
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
        if state.opacity == 255 {
            state.targetOpacity = 40
            effects.insert(.vanish)
        }
        return false
    }

    private static func setMoveYawForHit(input: SM64BooTickInput, state: inout SM64BooState) {
        state.moveYawBeforeHit = state.moveYaw
        if SM64CanonicalTrig.coss(state.moveYaw &- input.angleToMario) < 0 {
            state.moveYawDuringHit = state.moveYaw
        } else {
            state.moveYawDuringHit = state.moveYaw &+ Int16(truncatingIfNeeded: 0x8000)
        }
    }

    private static func approachOpacityAndScale(_ state: inout SM64BooState) {
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
    }

    private static func oscillate(
        _ state: inout SM64BooState,
        effects: inout SM64BooEffect,
        ignoreOpacity: Bool
    ) {
        state.facePitch = Int16(truncatingIfNeeded: Int32(SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: state.oscillationTimer))) * 0x400)
        if state.opacity == 255 || ignoreOpacity {
            let sine = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: state.oscillationTimer))
            state.renderScaleX = sine * 0.08 + state.baseScale
            state.renderScaleY = -sine * 0.08 + state.baseScale
            state.renderScaleZ = state.renderScaleX
            state.gravity = sine * state.baseScale
            state.oscillationTimer &+= 0x400
        }
        effects.insert(.oscillate)
    }

    private static func stop(_ state: inout SM64BooState) {
        state.forwardVelocity = 0
        state.velocityY = 0
        state.gravity = 0
    }

    private static func advance(_ state: inout SM64BooState) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionY += state.velocityY
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
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
