import Foundation

enum SM64SwoopAction: UInt8, Equatable, Sendable {
    case idle = 0
    case move = 1
}

struct SM64SwoopHitbox: Equatable, Sendable {
    let damageOrCoinValue: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let standard = Self(
        damageOrCoinValue: 1,
        numLootCoins: 1,
        radius: 100,
        height: 80,
        hurtboxRadius: 70,
        hurtboxHeight: 70
    )
}

struct SM64SwoopState: Equatable, Sendable {
    let hitbox: SM64SwoopHitbox

    var action: SM64SwoopAction = .idle
    var scale: Float = 0
    var moveYaw: Int16 = 0
    var faceRoll: Int16 = 0
    var facePitch: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var positionY: Float = 0
    var homeY: Float = 0
    var targetYaw: Int16 = 0
    var targetPitch: Int16 = 0
    var bonkCountdown: Int16 = 0
    var timer: UInt32 = 0
    var markedForDeletion = false

    init(positionY: Float = 0, homeY: Float? = nil, moveYaw: Int16 = 0) {
        self.hitbox = .standard
        self.positionY = positionY
        self.homeY = homeY ?? positionY
        self.moveYaw = moveYaw
        self.targetYaw = moveYaw
    }
}

struct SM64SwoopTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var marioY: Float
    var angleToMario: Int16
    var targetPitch: Int16
    var targetRoll: Int16
    var reflectedYaw: Int16
    var moveFlags: UInt32
    var marioFarAway: Bool
    var animationNearEnd: Bool
    var attacked: Bool

    init(
        distanceToMario: Float = 10_000,
        marioY: Float = 0,
        angleToMario: Int16 = 0,
        targetPitch: Int16 = 0,
        targetRoll: Int16 = 0,
        reflectedYaw: Int16 = 0,
        moveFlags: UInt32 = 0,
        marioFarAway: Bool = false,
        animationNearEnd: Bool = false,
        attacked: Bool = false
    ) {
        self.distanceToMario = distanceToMario
        self.marioY = marioY
        self.angleToMario = angleToMario
        self.targetPitch = targetPitch
        self.targetRoll = targetRoll
        self.reflectedYaw = reflectedYaw
        self.moveFlags = moveFlags
        self.marioFarAway = marioFarAway
        self.animationNearEnd = animationNearEnd
        self.attacked = attacked
    }
}

struct SM64SwoopEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let enterMove = Self(rawValue: 1 << 1)
    static let swoopSound = Self(rawValue: 1 << 2)
    static let beginDive = Self(rawValue: 1 << 3)
    static let speedUp = Self(rawValue: 1 << 4)
    static let wallBounce = Self(rawValue: 1 << 5)
    static let resetHome = Self(rawValue: 1 << 6)
    static let animationSound = Self(rawValue: 1 << 7)
    static let attackResponse = Self(rawValue: 1 << 8)
    static let markForDeletion = Self(rawValue: 1 << 9)
}

struct SM64SwoopTickResult: Equatable, Sendable {
    let state: SM64SwoopState
    let effects: SM64SwoopEffect
}

enum SM64SwoopKernel {
    static let hitWallFlag: UInt32 = 1 << 9

    static func tick(
        _ input: SM64SwoopTickInput,
        state: inout SM64SwoopState
    ) -> SM64SwoopTickResult {
        var effects: SM64SwoopEffect = [.animate]

        switch state.action {
        case .idle:
            state.scale = min(1, state.scale + 0.05)
            if state.scale == 1,
               input.distanceToMario < 1_500,
               rotateYaw(current: &state.moveYaw, target: input.angleToMario, increment: 800) {
                state.action = .move
                state.velocityY = -12
                effects.insert([.enterMove, .swoopSound])
            }
            state.faceRoll = Int16(bitPattern: 0x8000)
        case .move:
            if state.forwardVelocity == 0 {
                if approach(&state.faceRoll, target: 0, increment: 2_500) {
                    state.forwardVelocity = 10
                    state.velocityY = -10
                    effects.insert(.beginDive)
                }
            } else if input.marioFarAway {
                state.action = .idle
                state.positionY = state.homeY
                state.scale = 0
                state.forwardVelocity = 0
                state.velocityY = 0
                state.faceRoll = 0
                effects.insert(.resetHome)
            } else {
                if state.bonkCountdown != 0 {
                    state.bonkCountdown &-= 1
                } else if state.velocityY != 0 {
                    state.targetYaw = input.angleToMario
                    if state.positionY < input.marioY + 200 {
                        if approach(&state.velocityY, target: 0, increment: 0.5) {
                            state.forwardVelocity *= 2
                            effects.insert(.speedUp)
                        }
                    } else {
                        _ = approach(&state.velocityY, target: -10, increment: 0.5)
                    }
                } else if input.moveFlags & Self.hitWallFlag != 0 {
                    state.targetYaw = input.reflectedYaw
                    state.bonkCountdown = 30
                    effects.insert(.wallBounce)
                }

                state.targetPitch = input.targetPitch
                _ = approach(&state.facePitch, target: state.targetPitch, increment: 140)
                _ = rotateYaw(current: &state.moveYaw, target: state.targetYaw, increment: 1_200)
                _ = approach(&state.faceRoll, target: input.targetRoll, increment: 500)
                if input.animationNearEnd {
                    effects.insert(.animationSound)
                }
            }
        }

        if input.attacked {
            state.markedForDeletion = true
            effects.insert([.attackResponse, .markForDeletion])
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64SwoopTickResult(state: state, effects: effects)
    }

    @discardableResult
    private static func approach(
        _ value: inout Float,
        target: Float,
        increment: Float
    ) -> Bool {
        let distance = target - value
        if distance > increment {
            value += increment
            return false
        }
        if distance < -increment {
            value -= increment
            return false
        }
        value = target
        return true
    }

    @discardableResult
    private static func approach(
        _ value: inout Int16,
        target: Int16,
        increment: Int16
    ) -> Bool {
        let distance = Int32(target) - Int32(value)
        if distance > Int32(increment) {
            value = value &+ increment
            return false
        }
        if distance < -Int32(increment) {
            value = value &- increment
            return false
        }
        value = target
        return true
    }

    @discardableResult
    private static func rotateYaw(
        current: inout Int16,
        target: Int16,
        increment: Int16
    ) -> Bool {
        approach(&current, target: target, increment: increment)
    }
}
