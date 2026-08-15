import Foundation

enum SM64FlyGuyAction: UInt8, Equatable, Sendable {
    case idle = 0
    case approachMario = 1
    case lunge = 2
    case shootFire = 3
}

struct SM64FlyGuyHitbox: Equatable, Sendable {
    let interactType: UInt32
    let damageOrCoinValue: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let standard = Self(
        // INTERACT_BOUNCE_TOP.
        interactType: 1 << 4,
        damageOrCoinValue: 2,
        numLootCoins: 2,
        radius: 70,
        height: 60,
        hurtboxRadius: 40,
        hurtboxHeight: 50
    )
}

struct SM64FlyGuyState: Equatable, Sendable {
    let hitbox: SM64FlyGuyHitbox

    var action: SM64FlyGuyAction = .idle
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var moveYaw: Int16 = 0
    var faceYaw: Int16 = 0
    var facePitch: Int16 = 0
    var faceRoll: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var scale: Float = 1
    var scaleVelocity: Float = 0
    var lungeTargetPitch: Int16 = 0
    var lungeYDeceleration: Float = 0
    var targetRoll: Int16 = 0
    var idleTimer: UInt32 = 0
    var oscillationTimer: UInt32 = 0
    var tangible = true
    var markedForDeletion = false
    var timer: UInt32 = 0

    init(homeX: Float = 0, homeY: Float = 0, homeZ: Float = 0, moveYaw: Int16 = 0) {
        self.hitbox = .standard
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.moveYaw = moveYaw
        self.faceYaw = moveYaw
    }
}

struct SM64FlyGuyTickInput: Equatable, Sendable {
    var activeInRoom: Bool
    var distanceToMario: Float
    var distanceFromHome: Float
    var angleToMario: Int16
    var marioY: Float
    var behaviorShootsFire: Bool
    var randomValue: UInt32
    var moveFlags: UInt32

    init(
        activeInRoom: Bool = true,
        distanceToMario: Float = 10_000,
        distanceFromHome: Float = 0,
        angleToMario: Int16 = 0,
        marioY: Float = 0,
        behaviorShootsFire: Bool = false,
        randomValue: UInt32 = 0,
        moveFlags: UInt32 = 0
    ) {
        self.activeInRoom = activeInRoom
        self.distanceToMario = distanceToMario
        self.distanceFromHome = distanceFromHome
        self.angleToMario = angleToMario
        self.marioY = marioY
        self.behaviorShootsFire = behaviorShootsFire
        self.randomValue = randomValue
        self.moveFlags = moveFlags
    }
}

struct SM64FlyGuyFlameState: Equatable, Sendable {
    var positionX: Float = 0
    var positionY: Float = 0
    var positionZ: Float = 0
    var scale: Float = 2.5
    var moveYaw: Int16 = 0
    var timer: UInt32 = 0
    var markedForDeletion = false
}

struct SM64FlyGuyFlameTickResult: Equatable, Sendable {
    let state: SM64FlyGuyFlameState
    let effects: SM64FlyGuyEffect
}

struct SM64FlyGuyEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let idle = Self(rawValue: 1 << 1)
    static let approach = Self(rawValue: 1 << 2)
    static let lunge = Self(rawValue: 1 << 3)
    static let shoot = Self(rawValue: 1 << 4)
    static let spitFire = Self(rawValue: 1 << 5)
    static let flameBlownSound = Self(rawValue: 1 << 6)
    static let wallReflect = Self(rawValue: 1 << 7)
    static let waterLift = Self(rawValue: 1 << 8)
    static let oscillate = Self(rawValue: 1 << 9)
    static let intangible = Self(rawValue: 1 << 10)
    static let flameDeath = Self(rawValue: 1 << 11)
    static let markForDeletion = Self(rawValue: 1 << 12)
}

struct SM64FlyGuyTickResult: Equatable, Sendable {
    let state: SM64FlyGuyState
    let effects: SM64FlyGuyEffect
}

enum SM64FlyGuyKernel {
    static let hitWallFlag: UInt32 = 1 << 0
    static let inWaterFlag: UInt32 = 1 << 5

    static func tick(
        _ input: SM64FlyGuyTickInput,
        state: inout SM64FlyGuyState
    ) -> SM64FlyGuyTickResult {
        var effects: SM64FlyGuyEffect = [.animate]
        guard input.activeInRoom else { return SM64FlyGuyTickResult(state: state, effects: effects) }

        state.oscillationTimer &+= 1
        let oscillation = SM64CanonicalTrig.coss(
            Int16(truncatingIfNeeded: Int32(0x400) * Int32(state.oscillationTimer))
        ) * 1.5
        state.positionY += oscillation
        effects.insert(.oscillate)

        if input.moveFlags & hitWallFlag != 0 {
            state.moveYaw &+= Int16(truncatingIfNeeded: 0x8000)
            effects.insert(.wallReflect)
        } else if input.moveFlags & inWaterFlag != 0 {
            state.velocityY = 6
            effects.insert(.waterLift)
        }

        switch state.action {
        case .idle:
            state.forwardVelocity = 0
            state.scale = approach(state.scale, target: 1.5, step: 0.02)
            if state.scale >= 1.5 {
                if input.distanceToMario >= 25_000 || input.distanceToMario < 2_000 {
                    state.faceYaw = approachAngle(current: state.faceYaw, target: input.angleToMario, increment: 0x300)
                    state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToMario, increment: 0x300)
                    if absAngleDiff(input.angleToMario, state.faceYaw) < 0x300 {
                        state.action = .approachMario
                        effects.insert(.approach)
                    }
                } else if state.idleTimer >= 3 || state.idleTimer == (input.randomValue & 1) + 2 {
                    state.idleTimer = 0
                    state.action = .approachMario
                    effects.insert(.approach)
                } else {
                    state.idleTimer &+= 1
                }
            }
            effects.insert(.idle)

        case .approachMario:
            if input.distanceToMario >= 25_000 || input.distanceToMario < 2_000 {
                state.forwardVelocity = approach(state.forwardVelocity, target: 10, step: 0.5)
                state.faceYaw = approachAngle(current: state.faceYaw, target: input.angleToMario, increment: 0x400)
                state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToMario, increment: 0x200)
                if absAngleDiff(input.angleToMario, state.faceYaw) < 0x2000,
                   state.positionY - input.marioY > 400 || input.distanceToMario < 400 {
                    if input.behaviorShootsFire && input.randomValue & 1 != 0 {
                        state.action = .shootFire
                        state.scaleVelocity = 0.06
                        effects.insert(.shoot)
                    } else {
                        state.action = .lunge
                        state.lungeTargetPitch = -0x1000
                        state.forwardVelocity = 25 * SM64CanonicalTrig.coss(state.lungeTargetPitch)
                        state.velocityY = 25 * -SM64CanonicalTrig.sins(state.lungeTargetPitch)
                        state.lungeYDeceleration = -state.velocityY / 30
                        effects.insert(.lunge)
                    }
                }
            } else {
                state.forwardVelocity = approach(state.forwardVelocity, target: 0, step: 0.2)
                if state.forwardVelocity == 0 {
                    state.action = .idle
                    effects.insert(.idle)
                }
            }
            advance(&state)
            effects.insert(.approach)

        case .lunge:
            if state.velocityY < 0 {
                state.velocityY += state.lungeYDeceleration
                state.facePitch = approachAngle(current: state.facePitch, target: state.lungeTargetPitch, increment: 0x400)
                state.targetRoll = Int16(truncatingIfNeeded: Int32((input.randomValue % 3)) * 0x1000 - 0x1000)
                state.timer = 0
            } else {
                state.facePitch = approachAngle(current: state.facePitch, target: 0, increment: 0x100)
                state.faceRoll = approachAngle(current: state.faceRoll, target: state.targetRoll, increment: 0x12C)
                state.moveYaw &-= state.faceRoll / 4
                state.faceYaw = approachAngle(current: state.faceYaw, target: state.moveYaw, increment: 0x800)
                if state.positionY < input.marioY + 200 {
                    state.velocityY = approach(state.velocityY, target: 20, step: 0.5)
                } else if state.velocityY == 0, state.faceRoll == 0 {
                    state.action = .approachMario
                    state.targetRoll = 0
                    effects.insert(.approach)
                } else {
                    state.velocityY = approach(state.velocityY, target: 0, step: 0.5)
                }
            }
            advance(&state)
            effects.insert(.lunge)

        case .shootFire:
            state.forwardVelocity = 0
            state.faceYaw = approachAngle(current: state.faceYaw, target: input.angleToMario, increment: 0x800)
            if state.faceYaw == input.angleToMario {
                state.moveYaw = state.faceYaw
                state.scale += state.scaleVelocity
                state.scaleVelocity -= 0.01
                if state.scaleVelocity < -0.03 { state.scaleVelocity = -0.03 }
                if state.scale < 1.2, state.scaleVelocity < 0 {
                    effects.insert([.spitFire, .flameBlownSound])
                    state.scaleVelocity = 0
                }
                if state.scale <= 1.1 {
                    state.scale = 1.1
                    state.action = .idle
                    effects.insert(.idle)
                }
            } else {
                state.timer = 0
            }
            effects.insert(.shoot)
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64FlyGuyTickResult(state: state, effects: effects)
    }

    static func tickFlame(
        parent: SM64FlyGuyState,
        state: inout SM64FlyGuyFlameState
    ) -> SM64FlyGuyFlameTickResult {
        var effects: SM64FlyGuyEffect = []
        state.positionX = parent.positionX + SM64CanonicalTrig.sins(parent.moveYaw) * 20
        state.positionY = parent.positionY + 38
        state.positionZ = parent.positionZ + SM64CanonicalTrig.coss(parent.moveYaw) * 20
        state.moveYaw = parent.moveYaw
        state.scale = max(0, state.scale - 0.6)
        if state.scale == 0 {
            state.markedForDeletion = true
            effects.insert([.flameDeath, .markForDeletion])
        }
        state.timer &+= 1
        return SM64FlyGuyFlameTickResult(state: state, effects: effects)
    }

    private static func advance(_ state: inout SM64FlyGuyState) {
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
