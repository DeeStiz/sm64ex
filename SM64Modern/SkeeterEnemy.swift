import Foundation

enum SM64SkeeterAction: UInt8, Equatable, Sendable {
    case idle = 0
    case lunge = 1
    case walk = 2
}

struct SM64SkeeterHitbox: Equatable, Sendable {
    let interactType: UInt32
    let downOffset: Float
    let damageOrCoinValue: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let standard = Self(
        interactType: 0x0000_0001,
        downOffset: 20,
        damageOrCoinValue: 2,
        numLootCoins: 3,
        radius: 180,
        height: 100,
        hurtboxRadius: 150,
        hurtboxHeight: 90
    )
}

struct SM64SkeeterState: Equatable, Sendable {
    let hitbox: SM64SkeeterHitbox

    var action: SM64SkeeterAction = .idle
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var moveYaw: Int16 = 0
    var faceYaw: Int16 = 0
    var targetAngle: Int16 = 0
    var smoothTurnYaw: Int16 = 0
    var turningAwayFromWall: UInt16 = 0
    var targetForwardVelocity: Float = 0
    var forwardVelocity: Float = 0
    var waitTime: UInt32 = 0
    var moveFlags: UInt32 = 0
    var timer: UInt32 = 0
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
        self.faceYaw = moveYaw
        self.targetAngle = moveYaw
    }
}

struct SM64SkeeterTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var angleToMario: Int16
    var moveFlags: UInt32
    var animationNearEnd: Bool
    var animationAtEnd: Bool
    var smoothTurnComplete: Bool
    var resolvedTurnRemaining: UInt16
    var bounceOffWall: Bool
    var reflectedYaw: Int16
    var randomTargetAngle: Int16
    var randomWaitTime: UInt32
    var randomChoice: Bool
    var attacked: Bool

    init(
        distanceToMario: Float = 19_000,
        angleToMario: Int16 = 0,
        moveFlags: UInt32 = 0,
        animationNearEnd: Bool = false,
        animationAtEnd: Bool = false,
        smoothTurnComplete: Bool = false,
        resolvedTurnRemaining: UInt16 = 0,
        bounceOffWall: Bool = false,
        reflectedYaw: Int16 = 0,
        randomTargetAngle: Int16 = 0,
        randomWaitTime: UInt32 = 0,
        randomChoice: Bool = false,
        attacked: Bool = false
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.moveFlags = moveFlags
        self.animationNearEnd = animationNearEnd
        self.animationAtEnd = animationAtEnd
        self.smoothTurnComplete = smoothTurnComplete
        self.resolvedTurnRemaining = resolvedTurnRemaining
        self.bounceOffWall = bounceOffWall
        self.reflectedYaw = reflectedYaw
        self.randomTargetAngle = randomTargetAngle
        self.randomWaitTime = randomWaitTime
        self.randomChoice = randomChoice
        self.attacked = attacked
    }
}

struct SM64SkeeterEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let spawnWaves = Self(rawValue: 1 << 1)
    static let walk = Self(rawValue: 1 << 2)
    static let lunge = Self(rawValue: 1 << 3)
    static let waterSound = Self(rawValue: 1 << 4)
    static let wallBounce = Self(rawValue: 1 << 5)
    static let idle = Self(rawValue: 1 << 6)
    static let attackResponse = Self(rawValue: 1 << 7)
    static let coin = Self(rawValue: 1 << 8)
    static let markForDeletion = Self(rawValue: 1 << 9)
}

struct SM64SkeeterTickResult: Equatable, Sendable {
    let state: SM64SkeeterState
    let effects: SM64SkeeterEffect
}

struct SM64SkeeterWaveState: Equatable, Sendable {
    var scale: Float = 0.8
    var animationState: UInt32 = 0
    var relativePosition: SM64ObjectVector3 = .zero
    var markedForDeletion = false

    mutating func tick(globalFrame: UInt64) {
        if scale > 0.3 {
            scale -= 0.3
        } else {
            scale = 0
            markedForDeletion = true
        }
        animationState = UInt32((globalFrame / 6) & 0xFFFF_FFFF)
    }
}

enum SM64SkeeterKernel {
    static let onGroundMask: UInt32 = 0x0000_0003
    static let atWaterSurfaceFlag: UInt32 = 0x0000_0010
    static let hitWallFlag: UInt32 = 0x0000_0200

    static func tick(
        _ input: SM64SkeeterTickInput,
        state: inout SM64SkeeterState
    ) -> SM64SkeeterTickResult {
        var effects: SM64SkeeterEffect = [.animate]
        state.moveFlags = input.moveFlags

        switch state.action {
        case .idle:
            if input.moveFlags & onGroundMask != 0 {
                state.forwardVelocity = 0
                if state.timer > state.waitTime, input.animationNearEnd {
                    state.action = .walk
                    effects.insert(.walk)
                }
            } else if input.moveFlags & atWaterSurfaceFlag != 0 {
                effects.insert(.spawnWaves)
                if state.timer > 60, input.smoothTurnComplete {
                    if state.waitTime != 0 {
                        state.waitTime &-= 1
                    } else if input.animationNearEnd {
                        state.action = .lunge
                        state.forwardVelocity = 80
                        state.smoothTurnYaw = 0
                        effects.insert([.lunge, .waterSound])
                    }
                }
            } else {
                state.forwardVelocity = 0
            }

        case .lunge:
            guard input.moveFlags & atWaterSurfaceFlag != 0 else {
                state.action = .idle
                state.forwardVelocity = 0
                effects.insert(.idle)
                break
            }

            effects.insert(.spawnWaves)
            if input.moveFlags & hitWallFlag != 0 {
                state.moveYaw = input.reflectedYaw
                state.forwardVelocity *= 0.3
                state.moveFlags &= ~hitWallFlag
                effects.insert(.wallBounce)
            }

            if approach(&state.forwardVelocity, target: 0, increment: 0.8), input.animationAtEnd {
                state.moveYaw = state.faceYaw
                state.targetAngle = input.distanceToMario >= 25_000 ? input.angleToMario : input.randomTargetAngle
                state.action = .idle
                state.waitTime = input.randomWaitTime
                state.smoothTurnYaw = 0
                effects.insert(.idle)
            }

        case .walk:
            guard input.moveFlags & onGroundMask != 0 else {
                state.action = .idle
                state.forwardVelocity = 0
                effects.insert(.idle)
                break
            }

            state.targetForwardVelocity = input.distanceToMario < 500 ? 20 : 10
            if state.turningAwayFromWall != 0 {
                state.turningAwayFromWall = input.resolvedTurnRemaining
            } else {
                if input.distanceToMario >= 25_000 {
                    state.targetAngle = input.angleToMario
                    state.waitTime = input.randomWaitTime
                }

                if input.bounceOffWall {
                    state.targetAngle = input.reflectedYaw
                    state.turningAwayFromWall = input.resolvedTurnRemaining
                    effects.insert(.wallBounce)
                } else if input.distanceToMario < 500 {
                    state.targetAngle = input.angleToMario
                    state.targetForwardVelocity = 20
                } else {
                    state.targetForwardVelocity = 10
                    if state.waitTime != 0 {
                        state.waitTime &-= 1
                    } else if input.animationNearEnd {
                        if input.randomChoice {
                            state.targetAngle = input.randomTargetAngle
                            state.waitTime = input.randomWaitTime
                        } else {
                            state.action = .idle
                            state.waitTime = input.randomWaitTime
                            effects.insert(.idle)
                        }
                    }
                }
            }

            _ = approach(&state.forwardVelocity, target: state.targetForwardVelocity, increment: 0.4)
            state.moveYaw = approachAngle(current: state.moveYaw, target: state.targetAngle, increment: 0x400)
            effects.insert(.walk)
        }

        if input.attacked {
            state.markedForDeletion = true
            effects.insert([.attackResponse, .coin, .markForDeletion])
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
        return SM64SkeeterTickResult(state: state, effects: effects)
    }

    @discardableResult
    private static func approach(_ value: inout Float, target: Float, increment: Float) -> Bool {
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

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }
}
