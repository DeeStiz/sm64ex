import Foundation

enum SM64SnufitAction: UInt8, Equatable, Sendable {
    case idle = 0
    case shoot = 1
}

struct SM64SnufitHitbox: Equatable, Sendable {
    let interactType: UInt32
    let downOffset: Float
    let damageOrCoinValue: Int16
    let health: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let snufit = Self(
        // INTERACT_HIT_FROM_BELOW.
        interactType: 1 << 15,
        downOffset: 0,
        damageOrCoinValue: 2,
        health: 0,
        numLootCoins: 2,
        radius: 100,
        height: 60,
        hurtboxRadius: 70,
        hurtboxHeight: 50
    )

    static let bullet = Self(
        // INTERACT_SNUFIT_BULLET.
        interactType: 1 << 28,
        downOffset: 50,
        damageOrCoinValue: 1,
        health: 0,
        numLootCoins: 0,
        radius: 100,
        height: 50,
        hurtboxRadius: 100,
        hurtboxHeight: 50
    )
}

struct SM64SnufitState: Equatable, Sendable {
    var action: SM64SnufitAction = .idle
    var positionX: Float = 0
    var positionY: Float = 0
    var positionZ: Float = 0
    var homeX: Float = 0
    var homeY: Float = 0
    var homeZ: Float = 0
    var moveYaw: Int16 = 0
    var movePitch: Int16 = 0
    var facePitch: Int16 = 0
    var circularPeriod: Int16 = 0
    var bodyScalePeriod: Int16 = 0
    var bodyBaseScale: Int16 = 0
    var bodyScale: Int16 = 0
    var scale: Float = 1
    var recoil: Int16 = 0
    var bullets: UInt8 = 0
    var timer: UInt32 = 0
    var tangible = true
    var markedForDeletion = false

    init(
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        homeX: Float? = nil,
        homeY: Float? = nil,
        homeZ: Float? = nil,
        moveYaw: Int16 = 0
    ) {
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.homeX = homeX ?? positionX
        self.homeY = homeY ?? positionY
        self.homeZ = homeZ ?? positionZ
        self.moveYaw = moveYaw
    }

    var hitbox: SM64SnufitHitbox { .snufit }
}

struct SM64SnufitTickInput: Equatable, Sendable {
    var activeInRoom: Bool
    var distanceToMario: Float
    var angleToMario: Int16
    var marioFaceYaw: Int16
    var marioPitch: Int16
    var globalTimer: UInt32

    init(
        activeInRoom: Bool = true,
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        marioFaceYaw: Int16 = 0,
        marioPitch: Int16 = 0,
        globalTimer: UInt32 = 0
    ) {
        self.activeInRoom = activeInRoom
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.marioFaceYaw = marioFaceYaw
        self.marioPitch = marioPitch
        self.globalTimer = globalTimer
    }
}

enum SM64SnufitBulletAction: UInt8, Equatable, Sendable {
    case flying = 0
    case bouncedFromMetal = 1
}

struct SM64SnufitBulletState: Equatable, Sendable {
    var action: SM64SnufitBulletAction = .flying
    var positionX: Float = 0
    var positionY: Float = 0
    var positionZ: Float = 0
    var moveYaw: Int16 = 0
    var movePitch: Int16 = 0
    var forwardVelocity: Float = 40
    var velocityY: Float = 0
    var gravity: Float = 0
    var timer: UInt32 = 0
    var intangible = false
    var markedForDeletion = false

    init(
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        moveYaw: Int16 = 0,
        movePitch: Int16 = 0
    ) {
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.moveYaw = moveYaw
        self.movePitch = movePitch
    }

    var hitbox: SM64SnufitHitbox { .bullet }
}

struct SM64SnufitBulletTickInput: Equatable, Sendable {
    var differentRoom: Bool
    var distanceToMario: Float
    var moveFlags: UInt32
    var hitMetalMario: Bool
    var hitWallOrGround: Bool

    init(
        differentRoom: Bool = false,
        distanceToMario: Float = 0,
        moveFlags: UInt32 = 0,
        hitMetalMario: Bool = false,
        hitWallOrGround: Bool = false
    ) {
        self.differentRoom = differentRoom
        self.distanceToMario = distanceToMario
        self.moveFlags = moveFlags
        self.hitMetalMario = hitMetalMario
        self.hitWallOrGround = hitWallOrGround
    }
}

struct SM64SnufitEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let orbit = Self(rawValue: 1 << 0)
    static let faceMario = Self(rawValue: 1 << 1)
    static let idle = Self(rawValue: 1 << 2)
    static let shoot = Self(rawValue: 1 << 3)
    static let recoil = Self(rawValue: 1 << 4)
    static let shootSound = Self(rawValue: 1 << 5)
    static let spawnBullet = Self(rawValue: 1 << 6)
    static let tangible = Self(rawValue: 1 << 7)
    static let hitWall = Self(rawValue: 1 << 8)
    static let bulletBounce = Self(rawValue: 1 << 9)
    static let bulletDeath = Self(rawValue: 1 << 10)
    static let bulletIntangible = Self(rawValue: 1 << 11)
    static let markForDeletion = Self(rawValue: 1 << 12)
}

struct SM64SnufitTickResult: Equatable, Sendable {
    let state: SM64SnufitState
    let effects: SM64SnufitEffect
}

struct SM64SnufitBulletTickResult: Equatable, Sendable {
    let state: SM64SnufitBulletState
    let effects: SM64SnufitEffect
}

enum SM64SnufitKernel {
    static let hitWallFlag: UInt32 = 1 << 9 // OBJ_MOVE_HIT_WALL
    static let onGroundMask: UInt32 = (1 << 0) | (1 << 1)

    static func tick(
        _ input: SM64SnufitTickInput,
        state: inout SM64SnufitState
    ) -> SM64SnufitTickResult {
        var effects: SM64SnufitEffect = [.orbit, .tangible]

        if input.activeInRoom {
            if input.distanceToMario < 800 {
                state.movePitch = approachAngle(
                    current: state.movePitch,
                    target: input.marioPitch,
                    increment: 0x200
                )
                state.movePitch = min(0x2000, max(-0x2000, state.movePitch))
                state.moveYaw = approachAngle(
                    current: state.moveYaw,
                    target: input.angleToMario,
                    increment: 0x7D0
                )
                effects.insert(.faceMario)
            } else {
                state.movePitch = approachAngle(current: state.movePitch, target: 0, increment: 0x200)
                state.moveYaw &+= 200
            }
            state.facePitch = state.movePitch

            switch state.action {
            case .idle:
                effects.insert(.idle)
                let timerDistance = UInt32(max(0, Int(input.distanceToMario / 10)))
                if state.timer > timerDistance, input.distanceToMario < 800 {
                    state.bodyScalePeriod = approachS16(
                        current: state.bodyScalePeriod,
                        target: 0,
                        increment: 1500
                    )
                    state.bodyBaseScale = approachS16(
                        current: state.bodyBaseScale,
                        target: 600,
                        increment: 15
                    )
                    if state.bodyScalePeriod == 0, state.bodyBaseScale == 600 {
                        state.action = .shoot
                        state.bullets = 0
                        state.timer = 0
                        effects.insert(.shoot)
                    }
                } else {
                    state.circularPeriod &+= 400
                }
            case .shoot:
                effects.insert(.shoot)
                state.bodyScalePeriod = approachS16(
                    current: state.bodyScalePeriod,
                    target: Int16(bitPattern: 0x8000),
                    increment: 3000
                )
                state.bodyBaseScale = approachS16(
                    current: state.bodyBaseScale,
                    target: 167,
                    increment: 20
                )
                if UInt16(bitPattern: state.bodyScalePeriod) == 0x8000,
                   state.bodyBaseScale == 167 {
                    state.action = .idle
                    effects.insert(.idle)
                } else if state.bullets < 3, state.timer >= 3 {
                    state.bullets &+= 1
                    state.recoil = -30
                    state.timer = 0
                    effects.formUnion([.spawnBullet, .shootSound, .recoil])
                }
            }

            let cosineScale = SM64CanonicalTrig.coss(state.bodyScalePeriod)
            let bodyScale = Int32(state.bodyBaseScale) + 666
                + Int32(Float(state.bodyBaseScale) * cosineScale)
            state.bodyScale = Int16(clamping: bodyScale)
            if state.bodyScale > 1000 {
                state.scale = Float(state.bodyScale - 1000) / 1000 + 1
                state.bodyScale = 1000
            } else {
                state.scale = 1
            }
            state.positionX = state.homeX + 100 * SM64CanonicalTrig.coss(state.circularPeriod)
            state.positionY = state.homeY + 8 * SM64CanonicalTrig.coss(
                Int16(truncatingIfNeeded: input.globalTimer &* 4000)
            )
            state.positionZ = state.homeZ + 100 * SM64CanonicalTrig.sins(state.circularPeriod)
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64SnufitTickResult(state: state, effects: effects)
    }

    static func tickBullet(
        _ input: SM64SnufitBulletTickInput,
        state: inout SM64SnufitBulletState
    ) -> SM64SnufitBulletTickResult {
        var effects: SM64SnufitEffect = []
        if state.timer != 0,
           (input.differentRoom || input.distanceToMario > 1_500) {
            state.markedForDeletion = true
            effects.insert(.markForDeletion)
        }

        if state.gravity == 0 {
            if input.hitMetalMario {
                state.moveYaw &+= Int16(bitPattern: 0x8000)
                state.forwardVelocity *= 0.05
                state.velocityY = 30
                state.gravity = -4
                state.action = .bouncedFromMetal
                state.intangible = true
                effects.formUnion([.bulletBounce, .bulletIntangible])
            } else if state.action == .bouncedFromMetal
                        || input.hitWallOrGround
                        || input.moveFlags & onGroundMask != 0
                        || input.moveFlags & hitWallFlag != 0 {
                state.markedForDeletion = true
                effects.formUnion([.bulletDeath, .markForDeletion])
            }
            let pitchCosine = SM64CanonicalTrig.coss(state.movePitch)
            state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * pitchCosine * state.forwardVelocity
            state.positionY += SM64CanonicalTrig.sins(state.movePitch) * state.forwardVelocity
            state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * pitchCosine * state.forwardVelocity
        } else {
            state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
            state.positionY += state.velocityY
            state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
            state.velocityY += state.gravity
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64SnufitBulletTickResult(state: state, effects: effects)
    }

    private static func approachS16(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let current32 = Int32(current)
        let target32 = Int32(target)
        let delta = target32 - current32
        if abs(delta) <= Int32(increment) { return target }
        return Int16(truncatingIfNeeded: current32 + (delta > 0 ? Int32(increment) : -Int32(increment)))
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let delta = Int32(target) - Int32(current)
        if delta > Int32(increment) { return current &+ increment }
        if delta < -Int32(increment) { return current &- increment }
        return target
    }
}
