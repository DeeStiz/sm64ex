import Foundation

enum SM64ScuttlebugSubAction: UInt8, Equatable, Sendable {
    case initialize = 0
    case chase = 1
    case turn = 2
    case knockback = 3
    case knockbackFall = 4
    case recover = 5
}

struct SM64ScuttlebugHitbox: Equatable, Sendable {
    let interactType: UInt32
    let damageOrCoinValue: Int16
    let health: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let standard = Self(
        // INTERACT_BOUNCE_TOP.
        interactType: 1 << 15,
        damageOrCoinValue: 1,
        health: 1,
        numLootCoins: 3,
        radius: 130,
        height: 70,
        hurtboxRadius: 90,
        hurtboxHeight: 60
    )
}

struct SM64ScuttlebugState: Equatable, Sendable {
    let hitbox: SM64ScuttlebugHitbox

    var subAction: SM64ScuttlebugSubAction = .initialize
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var moveYaw: Int16 = 0
    var targetYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var attackWindow: UInt32 = 0
    var alertTimer: UInt32 = 0
    var moveFlags: UInt32 = 0
    var animationState: UInt32 = 0
    var timer: UInt32 = 0
    var tangible = true
    var markedForDeletion = false

    init(homeX: Float = 0, homeY: Float = 0, homeZ: Float = 0, moveYaw: Int16 = 0) {
        self.hitbox = .standard
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.moveYaw = moveYaw
        self.targetYaw = moveYaw
    }
}

struct SM64ScuttlebugTickInput: Equatable, Sendable {
    var moveFlags: UInt32
    var lateralDistanceToHome: Float
    var distanceToMario: Float
    var angleToMario: Int16
    var wallAngle: Int16
    var animationNearEnd: Bool
    var animationAtEnd: Bool
    var attacked: Bool

    init(
        moveFlags: UInt32 = 0,
        lateralDistanceToHome: Float = 0,
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        wallAngle: Int16 = 0,
        animationNearEnd: Bool = false,
        animationAtEnd: Bool = false,
        attacked: Bool = false
    ) {
        self.moveFlags = moveFlags
        self.lateralDistanceToHome = lateralDistanceToHome
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.wallAngle = wallAngle
        self.animationNearEnd = animationNearEnd
        self.animationAtEnd = animationAtEnd
        self.attacked = attacked
    }
}

struct SM64ScuttlebugSpawnerState: Equatable, Sendable {
    var action: UInt8 = 0
    var timer: UInt32 = 0
    var childActive = false
    var childUnknown: UInt32 = 0
    var markedForDeletion = false
}

struct SM64ScuttlebugSpawnerTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var childCleared: Bool

    init(distanceToMario: Float = 10_000, childCleared: Bool = false) {
        self.distanceToMario = distanceToMario
        self.childCleared = childCleared
    }
}

struct SM64ScuttlebugEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let landed = Self(rawValue: 1 << 1)
    static let chase = Self(rawValue: 1 << 2)
    static let alert = Self(rawValue: 1 << 3)
    static let turn = Self(rawValue: 1 << 4)
    static let knockback = Self(rawValue: 1 << 5)
    static let recover = Self(rawValue: 1 << 6)
    static let wallOrEdge = Self(rawValue: 1 << 7)
    static let attackResponse = Self(rawValue: 1 << 8)
    static let coin = Self(rawValue: 1 << 9)
    static let spawnScuttlebug = Self(rawValue: 1 << 10)
    static let childCleared = Self(rawValue: 1 << 11)
    static let markForDeletion = Self(rawValue: 1 << 12)
}

struct SM64ScuttlebugTickResult: Equatable, Sendable {
    let state: SM64ScuttlebugState
    let effects: SM64ScuttlebugEffect
}

struct SM64ScuttlebugSpawnerTickResult: Equatable, Sendable {
    let state: SM64ScuttlebugSpawnerState
    let effects: SM64ScuttlebugEffect
}

enum SM64ScuttlebugKernel {
    static let onGroundMask: UInt32 = (1 << 0) | (1 << 1)
    static let hitWallFlag: UInt32 = 1 << 9
    static let hitEdgeFlag: UInt32 = 1 << 10
    static let activeDifferentRoomFlag: UInt32 = 1 << 3

    static func tick(
        _ input: SM64ScuttlebugTickInput,
        state: inout SM64ScuttlebugState
    ) -> SM64ScuttlebugTickResult {
        var effects: SM64ScuttlebugEffect = [.animate]
        state.moveFlags = input.moveFlags

        if state.subAction != .initialize, input.attacked {
            state.subAction = .knockback
            state.markedForDeletion = true
            state.tangible = false
            effects.formUnion([.attackResponse, .coin, .markForDeletion])
        }

        switch state.subAction {
        case .initialize:
            if input.moveFlags & (Self.onGroundMask | (1 << 2)) != 0 {
                state.homeX = state.positionX
                state.homeY = state.positionY
                state.homeZ = state.positionZ
                state.subAction = .chase
                effects.formUnion([.landed, .chase])
            }
        case .chase:
            state.forwardVelocity = 5
            if input.lateralDistanceToHome > 1_000 {
                state.targetYaw = angleToHome(state: state)
            } else if state.alertTimer == 0 {
                state.targetYaw = input.angleToMario
                if absAngleDiff(state.targetYaw, state.moveYaw) < 0x800 {
                    state.alertTimer = 1
                    state.velocityY = 20
                    effects.insert(.alert)
                }
            } else {
                state.forwardVelocity = 15
                state.alertTimer &+= 1
                if state.alertTimer > 50 { state.alertTimer = 0 }
            }
            if input.moveFlags & Self.hitWallFlag != 0 {
                state.targetYaw = input.wallAngle
                state.subAction = .turn
                effects.insert(.wallOrEdge)
            } else if input.moveFlags & Self.hitEdgeFlag != 0 {
                state.targetYaw = state.moveYaw &+ Int16(bitPattern: 0x8000)
                state.subAction = .turn
                effects.insert(.wallOrEdge)
            }
            state.moveYaw = approachAngle(current: state.moveYaw, target: state.targetYaw, increment: 0x200)
            effects.insert(.chase)
        case .turn:
            state.forwardVelocity = 5
            if state.moveYaw == state.targetYaw { state.subAction = .chase }
            if state.positionY - state.homeY < -200 {
                state.markedForDeletion = true
                effects.insert(.markForDeletion)
            }
            state.moveYaw = approachAngle(current: state.moveYaw, target: state.targetYaw, increment: 0x400)
            effects.insert(.turn)
        case .knockback:
            state.tangible = false
            state.forwardVelocity = -10
            state.velocityY = 30
            state.subAction = .knockbackFall
            effects.insert(.knockback)
        case .knockbackFall:
            state.tangible = false
            state.forwardVelocity = -10
            if input.moveFlags & Self.onGroundMask != 0 {
                state.subAction = .recover
                state.velocityY = 0
                state.attackWindow = 0
                effects.insert(.recover)
            }
            effects.insert(.knockback)
        case .recover:
            state.tangible = true
            state.forwardVelocity = 2
            state.attackWindow &+= 1
            if state.attackWindow > 30 {
                state.subAction = .initialize
                effects.insert(.recover)
            }
        }

        if !state.markedForDeletion {
            state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
            state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
            state.positionY += state.velocityY
            if state.subAction == .knockbackFall { state.velocityY = max(-50, state.velocityY - 4) }
        }
        if input.animationNearEnd { state.animationState &+= 1 }
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64ScuttlebugTickResult(state: state, effects: effects)
    }

    static func tickSpawner(
        _ input: SM64ScuttlebugSpawnerTickInput,
        state: inout SM64ScuttlebugSpawnerState
    ) -> SM64ScuttlebugSpawnerTickResult {
        var effects: SM64ScuttlebugEffect = []
        if state.action == 0,
           state.timer > 30,
           input.distanceToMario > 500,
           input.distanceToMario < 1_500 {
            state.action = 1
            state.childActive = true
            state.childUnknown = 1
            effects.insert(.spawnScuttlebug)
        } else if state.action != 0, input.childCleared {
            state.action = 0
            state.childActive = false
            state.childUnknown = 0
            effects.insert(.childCleared)
        }
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64ScuttlebugSpawnerTickResult(state: state, effects: effects)
    }

    private static func angleToHome(state: SM64ScuttlebugState) -> Int16 {
        SM64CanonicalTrig.atan2s(y: state.homeZ - state.positionZ, x: state.homeX - state.positionX)
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
