import Foundation

enum SM64MrIAction: UInt8, Equatable, Sendable {
    case idle = 0
    case tracking = 1
    case turning = 2
    case dying = 3
}

struct SM64MrIHitbox: Equatable, Sendable {
    let interactType: UInt32
    let damageOrCoinValue: Int16
    let health: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float

    static let standard = Self(
        // INTERACT_DAMAGE.
        interactType: 1 << 3,
        damageOrCoinValue: 2,
        health: 2,
        numLootCoins: 5,
        radius: 80,
        height: 150
    )
}

struct SM64MrIState: Equatable, Sendable {
    let isKing: Bool
    let hitbox: SM64MrIHitbox

    var action: SM64MrIAction = .idle
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var moveYaw: Int16 = 0
    var movePitch: Int16 = 0
    var angleVelocityYaw: Int16 = 256
    var turnAccum: Int32 = 0
    var turnDirection: Int8 = 0
    var turnTimer: Int32 = 0
    var particleTimer: Int32 = 30
    var particleDelay: Int32 = 0
    var scale: Float = 1
    var size: Float = 1
    var timer: UInt32 = 0
    var tangible = true
    var markedForDeletion = false

    init(
        isKing: Bool = false,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0
    ) {
        self.isKing = isKing
        self.hitbox = .standard
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.moveYaw = moveYaw
        self.size = isKing ? 2 : 1
        self.scale = isKing ? 2 : 1
    }
}

struct SM64MrITickInput: Equatable, Sendable {
    var activeInRoom: Bool
    var distanceToMario: Float
    var angleToMario: Int16
    var marioFaceYaw: Int16
    var randomValue: UInt32
    var attacked: Bool
    var moveFlags: UInt32

    init(
        activeInRoom: Bool = true,
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        marioFaceYaw: Int16 = 0,
        randomValue: UInt32 = 0,
        attacked: Bool = false,
        moveFlags: UInt32 = 0
    ) {
        self.activeInRoom = activeInRoom
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.marioFaceYaw = marioFaceYaw
        self.randomValue = randomValue
        self.attacked = attacked
        self.moveFlags = moveFlags
    }
}

enum SM64MrIParticleAction: UInt8, Equatable, Sendable {
    case flight = 0
    case burst = 1
}

struct SM64MrIParticleState: Equatable, Sendable {
    var action: SM64MrIParticleAction = .flight
    var positionX: Float = 0
    var positionY: Float = 0
    var positionZ: Float = 0
    var moveYaw: Int16 = 0
    var forwardVelocity: Float = 20
    var velocityY: Float = 20
    var timer: UInt32 = 0
    var markedForDeletion = false

    init(positionX: Float = 0, positionY: Float = 0, positionZ: Float = 0, moveYaw: Int16 = 0) {
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.moveYaw = moveYaw
    }
}

struct SM64MrIParticleTickInput: Equatable, Sendable {
    var activeInRoom: Bool
    var moveFlags: UInt32
    var interacted: Bool

    init(activeInRoom: Bool = true, moveFlags: UInt32 = 0, interacted: Bool = false) {
        self.activeInRoom = activeInRoom
        self.moveFlags = moveFlags
        self.interacted = interacted
    }
}

struct SM64MrIBodyState: Equatable, Sendable {
    var positionX: Float = 0
    var positionY: Float = 0
    var positionZ: Float = 0
    var scale: Float = 1
    var relativeZ: Float = 100
    var animationState: Int32 = -1
    var timer: UInt32 = 0
    var markedForDeletion = false
}

struct SM64MrIEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let resetHome = Self(rawValue: 1 << 0)
    static let tangible = Self(rawValue: 1 << 1)
    static let intangible = Self(rawValue: 1 << 2)
    static let tracking = Self(rawValue: 1 << 3)
    static let turning = Self(rawValue: 1 << 4)
    static let particleFlash = Self(rawValue: 1 << 5)
    static let spawnParticle = Self(rawValue: 1 << 6)
    static let spinSound = Self(rawValue: 1 << 7)
    static let deathSound = Self(rawValue: 1 << 8)
    static let shake = Self(rawValue: 1 << 9)
    static let mist = Self(rawValue: 1 << 10)
    static let blueCoin = Self(rawValue: 1 << 11)
    static let star = Self(rawValue: 1 << 12)
    static let bodyDelete = Self(rawValue: 1 << 13)
    static let particleBurst = Self(rawValue: 1 << 14)
    static let particleDeath = Self(rawValue: 1 << 15)
    static let markForDeletion = Self(rawValue: 1 << 16)
}

struct SM64MrITickResult: Equatable, Sendable {
    let state: SM64MrIState
    let effects: SM64MrIEffect
}

struct SM64MrIParticleTickResult: Equatable, Sendable {
    let state: SM64MrIParticleState
    let effects: SM64MrIEffect
}

struct SM64MrIBodyTickResult: Equatable, Sendable {
    let state: SM64MrIBodyState
    let effects: SM64MrIEffect
}

enum SM64MrIKernel {
    static let hitWallFlag: UInt32 = 1 << 9
    static let differentRoomFlag: UInt32 = 1 << 3

    static func tick(
        _ input: SM64MrITickInput,
        state: inout SM64MrIState
    ) -> SM64MrITickResult {
        var effects: SM64MrIEffect = []

        if input.attacked, state.action != .dying {
            state.action = .dying
            state.timer = 0
            effects.insert(.deathSound)
        }

        if !input.activeInRoom, state.action != .dying {
            state.action = .idle
        }

        switch state.action {
        case .idle:
            state.movePitch = 0
            state.moveYaw = 0
            state.scale = state.size
            if state.timer == 0 {
                state.positionX = state.homeX
                state.positionY = state.homeY
                state.positionZ = state.homeZ
                effects.insert(.resetHome)
            }
            state.tangible = false
            effects.insert(.intangible)
            if input.distanceToMario < 1_500 {
                state.action = .tracking
                effects.insert(.tracking)
            }
        case .tracking:
            if state.timer == 0 {
                state.tangible = true
                state.movePitch = 0
                state.particleTimer = 30
                state.particleDelay = Int32(input.randomValue % 20)
                state.angleVelocityYaw = (input.randomValue & 1) == 0 ? 256 : -256
                effects.insert(.tangible)
            }
            let angleToMario = absAngleDiff(state.moveYaw, input.angleToMario)
            let marioFaceDelta = absAngleDiff(state.moveYaw, input.marioFaceYaw)
            if angleToMario < 1_024, marioFaceDelta > 0x4000 {
                if input.distanceToMario < 700 {
                    state.action = .turning
                    state.timer = 0
                    effects.insert(.turning)
                } else {
                    state.particleTimer &+= 1
                }
            } else {
                state.moveYaw &+= state.angleVelocityYaw
                state.particleTimer = 30
            }
            if state.particleTimer == state.particleDelay + 60 {
                effects.insert(.particleFlash)
            }
            if state.particleTimer > state.particleDelay + 80 {
                state.particleTimer = 0
                state.particleDelay = Int32((input.randomValue >> 8) % 80)
                effects.insert(.spawnParticle)
            }
            effects.insert(.tracking)
        case .turning:
            if state.timer == 0 {
                state.turnTimer = state.isKing ? 200 : 120
                state.turnAccum = 0
                state.turnDirection = 0
                state.particleTimer = 0
                state.particleDelay = Int32(input.randomValue % 50 + 50)
            }
            let previousYaw = state.moveYaw
            state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToMario, increment: 0x800)
            state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToMario, increment: 0x400)
            let delta = Int32(previousYaw) - Int32(state.moveYaw)
            if delta != 0 {
                let direction: Int8 = delta > 0 ? 1 : -1
                if state.turnDirection == direction {
                    state.turnAccum &+= abs(delta)
                } else {
                    state.turnAccum = 0
                    state.turnDirection = direction
                }
            }
            if state.turnAccum > 1 << 16 {
                state.action = .dying
                state.timer = 0
                effects.insert(.deathSound)
            }
            state.turnTimer &-= 1
            if state.turnTimer <= 0 {
                state.turnTimer = state.isKing ? 200 : 120
                state.turnAccum = 0
            }
            if state.turnAccum < 5_000 {
                if state.particleTimer == state.particleDelay { effects.insert(.particleFlash) }
                if state.particleTimer == state.particleDelay + 20 {
                    state.particleTimer = 0
                    state.particleDelay = Int32((input.randomValue >> 8) % 50 + 50)
                    effects.insert(.spawnParticle)
                }
                state.particleTimer &+= 1
            } else {
                state.particleTimer = 0
                state.particleDelay = Int32((input.randomValue >> 8) % 50 + 50)
            }
            if input.distanceToMario > 800 { state.action = .tracking }
            effects.formUnion([.turning, .tangible])
        case .dying:
            state.tangible = false
            effects.insert(.intangible)
            let phase = Float(state.timer + 1) / 96
            let direction: Int16 = state.turnDirection < 0 ? 0x1000 : Int16(bitPattern: 0xF000)
            if state.timer < 64 {
                state.moveYaw &+= Int16(Float(direction) * SM64CanonicalTrig.coss(Int16(0x4000 * phase)))
                state.movePitch = Int16((1 - SM64CanonicalTrig.coss(Int16(0x4000 * phase))) * -0x4000)
                effects.insert(.shake)
            } else if state.timer < 96 {
                let sizePhase = Float(state.timer - 63) / 32
                state.moveYaw &+= Int16(Float(direction) * SM64CanonicalTrig.coss(Int16(0x4000 * phase)))
                state.movePitch = Int16((1 - SM64CanonicalTrig.coss(Int16(0x4000 * phase))) * -0x4000)
                state.scale = SM64CanonicalTrig.coss(Int16(0x4000 * sizePhase)) * 0.4 + 0.6
                state.scale *= state.size
                effects.insert(.shake)
            } else if state.timer == 104 {
                state.size *= 0.6
                state.scale = state.size
                effects.insert(.mist)
                if state.isKing {
                    state.positionY += 100
                    effects.insert(.star)
                    state.markedForDeletion = true
                    effects.insert([.markForDeletion, .bodyDelete])
                } else {
                    effects.insert(.blueCoin)
                }
            } else if state.timer > 104 {
                state.size = max(0, state.size - 0.2)
                state.scale = state.size
            }
            if state.timer >= 168 {
                state.markedForDeletion = true
                effects.insert(.markForDeletion)
            }
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64MrITickResult(state: state, effects: effects)
    }

    static func tickBody(
        _ input: SM64MrIBodyTickInput,
        state: inout SM64MrIBodyState
    ) -> SM64MrIBodyTickResult {
        var effects: SM64MrIEffect = []
        state.positionX = input.parentPositionX
        state.positionY = input.parentPositionY
        state.positionZ = input.parentPositionZ
        state.scale = input.parentScale
        state.relativeZ = input.parentScale * 100
        if input.parentParticleFlash {
            state.animationState = 0
            effects.insert(.particleFlash)
        } else if state.animationState >= 0 {
            state.animationState += 1
            if state.animationState == 15 { state.animationState = -1 }
        }
        if input.parentDeleted {
            state.markedForDeletion = true
            effects.insert(.bodyDelete)
        }
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64MrIBodyTickResult(state: state, effects: effects)
    }

    static func tickParticle(
        _ input: SM64MrIParticleTickInput,
        state: inout SM64MrIParticleState
    ) -> SM64MrIParticleTickResult {
        var effects: SM64MrIEffect = []
        if state.action == .flight {
            state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
            state.positionY += state.velocityY
            state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
            state.velocityY -= 4
            if input.interacted {
                state.action = .burst
            } else if state.timer >= 101 || input.moveFlags & Self.hitWallFlag != 0
                        || !input.activeInRoom {
                state.markedForDeletion = true
                effects.formUnion([.particleDeath, .markForDeletion])
            }
        } else {
            state.markedForDeletion = true
            effects.formUnion([.particleBurst, .particleDeath, .markForDeletion])
        }
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64MrIParticleTickResult(state: state, effects: effects)
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

struct SM64MrIBodyTickInput: Equatable, Sendable {
    var parentPositionX: Float
    var parentPositionY: Float
    var parentPositionZ: Float
    var parentScale: Float
    var parentParticleFlash: Bool
    var parentDeleted: Bool

    init(
        parentPositionX: Float = 0,
        parentPositionY: Float = 0,
        parentPositionZ: Float = 0,
        parentScale: Float = 1,
        parentParticleFlash: Bool = false,
        parentDeleted: Bool = false
    ) {
        self.parentPositionX = parentPositionX
        self.parentPositionY = parentPositionY
        self.parentPositionZ = parentPositionZ
        self.parentScale = parentScale
        self.parentParticleFlash = parentParticleFlash
        self.parentDeleted = parentDeleted
    }
}
