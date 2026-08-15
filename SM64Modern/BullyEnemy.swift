import Foundation

enum SM64BullySize: UInt8, Equatable, Sendable {
    case small = 0
    case big = 1
}

enum SM64BullySubtype: UInt8, Equatable, Sendable {
    case generic = 0
    case minion = 1
    case chill = 16
}

enum SM64BullyAction: UInt8, Equatable, Sendable {
    case patrol = 0
    case chase = 1
    case knockback = 2
    case backUp = 3
    case inactive = 4
    case activateAndFall = 5
    case lavaDeath = 100
    case deathPlaneDeath = 101
}

struct SM64BullyHitbox: Equatable, Sendable {
    let damageOrCoinValue: Int16
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let small = Self(damageOrCoinValue: 1, radius: 73, height: 123, hurtboxRadius: 63, hurtboxHeight: 113)
    static let big = Self(damageOrCoinValue: 1, radius: 115, height: 235, hurtboxRadius: 105, hurtboxHeight: 225)
}

struct SM64BullyState: Equatable, Sendable {
    let size: SM64BullySize
    let subtype: SM64BullySubtype
    let hitbox: SM64BullyHitbox

    var action: SM64BullyAction = .patrol
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var previousX: Float
    var previousY: Float
    var previousZ: Float
    var moveYaw: Int16 = 0
    var faceYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var knockbackCounter: Int16 = 0
    var marioCollisionAngle: Int16 = 0
    var collisionFlag: UInt32 = 0
    var tangible = true
    var invisible = false
    var markedForDeletion = false
    var timer: UInt32 = 0

    init(
        size: SM64BullySize,
        subtype: SM64BullySubtype = .generic,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0,
        action: SM64BullyAction = .patrol
    ) {
        self.size = size
        self.subtype = subtype
        self.hitbox = size == .small ? .small : .big
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.previousX = homeX
        self.previousY = homeY
        self.previousZ = homeZ
        self.moveYaw = moveYaw
        self.faceYaw = moveYaw
        self.action = action
        if action == .inactive {
            self.tangible = false
            self.invisible = true
        }
    }
}

struct SM64BullyTickInput: Equatable, Sendable {
    var angleToMario: Int16
    var distanceFromHome: Float
    var homeRadiusExceeded: Bool
    var interacted: Bool
    var marioCollisionAngle: Int16
    var floorCollisionFlags: UInt32
    var marioY: Float

    init(
        angleToMario: Int16 = 0,
        distanceFromHome: Float = 0,
        homeRadiusExceeded: Bool = false,
        interacted: Bool = false,
        marioCollisionAngle: Int16 = 0,
        floorCollisionFlags: UInt32 = 1,
        marioY: Float = 0
    ) {
        self.angleToMario = angleToMario
        self.distanceFromHome = distanceFromHome
        self.homeRadiusExceeded = homeRadiusExceeded
        self.interacted = interacted
        self.marioCollisionAngle = marioCollisionAngle
        self.floorCollisionFlags = floorCollisionFlags
        self.marioY = marioY
    }
}

struct SM64BullyEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let attackResponse = Self(rawValue: 1 << 1)
    static let chase = Self(rawValue: 1 << 2)
    static let patrol = Self(rawValue: 1 << 3)
    static let backUp = Self(rawValue: 1 << 4)
    static let knockback = Self(rawValue: 1 << 5)
    static let coin = Self(rawValue: 1 << 6)
    static let star = Self(rawValue: 1 << 7)
    static let mist = Self(rawValue: 1 << 8)
    static let markForDeletion = Self(rawValue: 1 << 9)
    static let tangible = Self(rawValue: 1 << 10)
    static let intangible = Self(rawValue: 1 << 11)
}

struct SM64BullyTickResult: Equatable, Sendable {
    let state: SM64BullyState
    let effects: SM64BullyEffect
}

enum SM64BullyKernel {
    static func tick(
        _ input: SM64BullyTickInput,
        state: inout SM64BullyState
    ) -> SM64BullyTickResult {
        var effects: SM64BullyEffect = [.animate]
        state.previousX = state.positionX
        state.previousY = state.positionY
        state.previousZ = state.positionZ

        if input.interacted,
           state.action != .deathPlaneDeath,
           state.action != .lavaDeath {
            state.action = .knockback
            state.marioCollisionAngle = input.marioCollisionAngle
            state.knockbackCounter = 0
            state.collisionFlag &= ~0x8
            effects.insert([.attackResponse, .knockback])
        }

        switch state.action {
        case .patrol:
            state.forwardVelocity = 5
            if input.distanceFromHome <= (state.size == .small ? 800 : 1_000) {
                state.action = .chase
                effects.insert(.chase)
            }
            step(&state)
            effects.insert(.patrol)
        case .chase:
            if state.timer < 10 {
                state.forwardVelocity = 3
                state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToMario, increment: 4_096)
            } else {
                state.forwardVelocity = state.size == .small ? 20 : 30
                let resetTimer = state.size == .small ? 31 : 36
                if state.timer >= UInt32(resetTimer) { state.timer = 0 }
            }
            if input.homeRadiusExceeded {
                state.action = .patrol
                state.forwardVelocity = 5
                effects.insert(.patrol)
            } else {
                effects.insert(.chase)
            }
            step(&state)
        case .knockback:
            if state.forwardVelocity < 10 && state.velocityY == 0 {
                state.forwardVelocity = 1
                state.knockbackCounter &+= 1
                state.collisionFlag |= 0x8
                state.moveYaw = state.faceYaw
                state.faceYaw = approachAngle(current: state.faceYaw, target: input.angleToMario, increment: 1_280)
            } else {
                state.forwardVelocity = 0
            }
            if state.knockbackCounter == 18 {
                state.action = .chase
                state.knockbackCounter = 0
                effects.insert(.chase)
            }
            step(&state)
            effects.insert(.knockback)
        case .backUp:
            if state.timer == 0 {
                state.collisionFlag &= ~0x8
                state.moveYaw &+= Int16(bitPattern: 0x8000)
            }
            state.forwardVelocity = 5
            if state.timer == 15 {
                state.moveYaw = state.faceYaw
                state.collisionFlag |= 0x8
                state.action = .patrol
                effects.insert(.patrol)
            } else {
                effects.insert(.backUp)
            }
            step(&state)
        case .inactive:
            state.forwardVelocity = 0
        case .activateAndFall:
            step(&state)
            if input.floorCollisionFlags & 0x9 == 0x9 {
                state.action = .patrol
                effects.insert(.patrol)
            }
            state.invisible = false
            state.tangible = true
            effects.insert(.tangible)
        case .lavaDeath:
            if input.floorCollisionFlags & 1 != 0 {
                effects.insert(.mist)
                if state.size == .small {
                    effects.insert(.coin)
                } else {
                    effects.insert(.star)
                }
                state.markedForDeletion = true
                effects.insert(.markForDeletion)
            }
        case .deathPlaneDeath:
            state.markedForDeletion = true
            effects.insert(.markForDeletion)
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64BullyTickResult(state: state, effects: effects)
    }

    private static func step(_ state: inout SM64BullyState) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionY += state.velocityY
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }
}
