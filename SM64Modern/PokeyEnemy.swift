import Foundation

enum SM64PokeyKind: UInt8, Equatable, Sendable {
    case parent = 0
    case bodyPart = 1
}

enum SM64PokeyAction: UInt8, Equatable, Sendable {
    case uninitialized = 0
    case wander = 1
    case unloadParts = 2
}

struct SM64PokeyHitbox: Equatable, Sendable {
    let interactType: UInt32
    let downOffset: Float
    let damageOrCoinValue: Int16
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let bodyPart = Self(
        interactType: 0x0000_0001,
        downOffset: 10,
        damageOrCoinValue: 2,
        radius: 40,
        height: 20,
        hurtboxRadius: 20,
        hurtboxHeight: 20
    )
}

struct SM64PokeyState: Equatable, Sendable {
    let kind: SM64PokeyKind
    let bodyIndex: Int8
    let hitbox: SM64PokeyHitbox

    var action: SM64PokeyAction = .uninitialized
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var moveYaw: Int16 = 0
    var targetYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var turningAwayFromWall: UInt16 = 0
    var changeTargetTimer: UInt32 = 0
    var aliveBodyPartFlags: UInt8 = 0
    var numAliveBodyParts: UInt8 = 0
    var bottomBodyPartSize: Float = 1
    var headWasKilled = false
    var deathDelayAfterHeadKilled: Int16 = 0
    var scale: Float = 1
    var timer: UInt32 = 0
    var animationState: UInt32 = 0
    var markedForDeletion = false

    init(
        kind: SM64PokeyKind,
        bodyIndex: Int8 = -1,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        positionX: Float? = nil,
        positionY: Float? = nil,
        positionZ: Float? = nil,
        moveYaw: Int16 = 0,
        scale: Float = 1
    ) {
        self.kind = kind
        self.bodyIndex = bodyIndex
        self.hitbox = .bodyPart
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = positionX ?? homeX
        self.positionY = positionY ?? homeY
        self.positionZ = positionZ ?? homeZ
        self.moveYaw = moveYaw
        self.targetYaw = moveYaw
        self.scale = scale
    }
}

struct SM64PokeyParentTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var angleToMario: Int16
    var moveFlags: UInt32
    var animationNearEnd: Bool
    var bounceOffWall: Bool
    var reflectedYaw: Int16
    var resolvedTurnRemaining: UInt16
    var randomTargetYaw: Int16
    var randomWaitTime: UInt32
    var randomChoice: Bool

    init(
        distanceToMario: Float = 19_000,
        angleToMario: Int16 = 0,
        moveFlags: UInt32 = 0,
        animationNearEnd: Bool = false,
        bounceOffWall: Bool = false,
        reflectedYaw: Int16 = 0,
        resolvedTurnRemaining: UInt16 = 0,
        randomTargetYaw: Int16 = 0,
        randomWaitTime: UInt32 = 0,
        randomChoice: Bool = false
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.moveFlags = moveFlags
        self.animationNearEnd = animationNearEnd
        self.bounceOffWall = bounceOffWall
        self.reflectedYaw = reflectedYaw
        self.resolvedTurnRemaining = resolvedTurnRemaining
        self.randomTargetYaw = randomTargetYaw
        self.randomWaitTime = randomWaitTime
        self.randomChoice = randomChoice
    }
}

struct SM64PokeyBodyTickInput: Equatable, Sendable {
    var parentX: Float
    var parentY: Float
    var parentZ: Float
    var parentAction: SM64PokeyAction
    var parentAliveBodyPartFlags: UInt8
    var parentNumAliveBodyParts: UInt8
    var parentBottomBodyPartSize: Float
    var parentHeadWasKilled: Bool
    var globalFrame: UInt64
    var attacked: Bool

    init(
        parentX: Float = 0,
        parentY: Float = 0,
        parentZ: Float = 0,
        parentAction: SM64PokeyAction = .wander,
        parentAliveBodyPartFlags: UInt8 = 0x1F,
        parentNumAliveBodyParts: UInt8 = 5,
        parentBottomBodyPartSize: Float = 1,
        parentHeadWasKilled: Bool = false,
        globalFrame: UInt64 = 0,
        attacked: Bool = false
    ) {
        self.parentX = parentX
        self.parentY = parentY
        self.parentZ = parentZ
        self.parentAction = parentAction
        self.parentAliveBodyPartFlags = parentAliveBodyPartFlags
        self.parentNumAliveBodyParts = parentNumAliveBodyParts
        self.parentBottomBodyPartSize = parentBottomBodyPartSize
        self.parentHeadWasKilled = parentHeadWasKilled
        self.globalFrame = globalFrame
        self.attacked = attacked
    }
}

struct SM64PokeyEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let spawnParts = Self(rawValue: 1 << 1)
    static let wander = Self(rawValue: 1 << 2)
    static let unloadParts = Self(rawValue: 1 << 3)
    static let replenishPart = Self(rawValue: 1 << 4)
    static let wallBounce = Self(rawValue: 1 << 5)
    static let attackResponse = Self(rawValue: 1 << 6)
    static let squished = Self(rawValue: 1 << 7)
    static let headKilled = Self(rawValue: 1 << 8)
    static let markForDeletion = Self(rawValue: 1 << 9)
}

struct SM64PokeyParentTickResult: Equatable, Sendable {
    let state: SM64PokeyState
    let effects: SM64PokeyEffect
}

struct SM64PokeyBodyTickResult: Equatable, Sendable {
    let state: SM64PokeyState
    let effects: SM64PokeyEffect
    let killedPart: Bool
    let killedHead: Bool
}

enum SM64PokeyKernel {
    static let onGroundMask: UInt32 = 0x0000_0003
    static let hitWallFlag: UInt32 = 0x0000_0200

    static func tickParent(
        _ input: SM64PokeyParentTickInput,
        state: inout SM64PokeyState
    ) -> SM64PokeyParentTickResult {
        var effects: SM64PokeyEffect = [.animate]

        switch state.action {
        case .uninitialized:
            if input.distanceToMario < 2_000 {
                state.aliveBodyPartFlags = 0x1F
                state.numAliveBodyParts = 5
                state.bottomBodyPartSize = 1
                state.headWasKilled = false
                state.action = .wander
                effects.insert([.spawnParts, .wander])
            }

        case .wander:
            if state.numAliveBodyParts == 0 {
                state.markedForDeletion = true
                effects.insert(.markForDeletion)
            } else if input.distanceToMario > 2_500 {
                state.action = .unloadParts
                state.forwardVelocity = 0
                effects.insert(.unloadParts)
            } else {
                state.forwardVelocity = state.headWasKilled ? 0 : 5
                if state.numAliveBodyParts < 5, state.timer > 100, !state.headWasKilled {
                    state.numAliveBodyParts &+= 1
                    state.aliveBodyPartFlags |= 1 << (state.numAliveBodyParts - 1)
                    state.bottomBodyPartSize = 0
                    state.timer = 0
                    effects.insert(.replenishPart)
                }

                if state.turningAwayFromWall != 0 {
                    state.turningAwayFromWall = input.resolvedTurnRemaining
                } else {
                    if input.distanceToMario >= 25_000 {
                        state.targetYaw = input.angleToMario
                        state.changeTargetTimer = input.randomWaitTime
                    }
                    if input.bounceOffWall {
                        state.targetYaw = input.reflectedYaw
                        state.turningAwayFromWall = input.resolvedTurnRemaining
                        effects.insert(.wallBounce)
                    } else if state.changeTargetTimer != 0 {
                        state.changeTargetTimer &-= 1
                    } else if input.distanceToMario > 2_000 {
                        state.targetYaw = input.randomTargetYaw
                        state.changeTargetTimer = input.randomWaitTime
                    } else {
                        let distanceOffset = max(0, min(0x4000, Int32(0x4000) - Int32((input.distanceToMario - 200) * 10)))
                        let signedOffset = Int16((Int32(input.angleToMario) - Int32(state.moveYaw)) > 0 ? -distanceOffset : distanceOffset)
                        state.targetYaw = input.angleToMario &+ signedOffset
                        if input.animationNearEnd, input.randomChoice {
                            state.targetYaw = input.randomTargetYaw
                            state.changeTargetTimer = input.randomWaitTime
                        }
                    }
                }
                state.moveYaw = approachAngle(current: state.moveYaw, target: state.targetYaw, increment: 0x200)
                effects.insert(.wander)
            }

        case .unloadParts:
            state.action = .uninitialized
            state.positionX = state.homeX
            state.positionY = state.homeY
            state.positionZ = state.homeZ
            state.forwardVelocity = 0
            effects.insert(.unloadParts)
        }

        if state.action == .wander {
            state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
            state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
        }
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64PokeyParentTickResult(state: state, effects: effects)
    }

    static func tickBody(
        _ input: SM64PokeyBodyTickInput,
        state: inout SM64PokeyState
    ) -> SM64PokeyBodyTickResult {
        var effects: SM64PokeyEffect = [.animate]
        var killedPart = false
        var killedHead = false

        guard input.parentAction != .unloadParts else {
            state.markedForDeletion = true
            return SM64PokeyBodyTickResult(
                state: state,
                effects: [.markForDeletion, .unloadParts],
                killedPart: false,
                killedHead: false
            )
        }

        if state.bodyIndex + 1 == Int8(input.parentNumAliveBodyParts), input.parentBottomBodyPartSize < 1 {
            state.scale = min(1, state.scale + 0.1)
        }

        let offsetAngle = Int16(truncatingIfNeeded: Int32(state.bodyIndex) * 0x4000 &+ Int32(truncatingIfNeeded: input.globalFrame * 0x800))
        state.positionX = input.parentX + SM64CanonicalTrig.coss(offsetAngle) * 6
        state.positionZ = input.parentZ + SM64CanonicalTrig.sins(offsetAngle) * 6
        let baseHeight = input.parentY
            + Float(120 * (Int(input.parentNumAliveBodyParts) - Int(state.bodyIndex)) - 240)
            + 120 * input.parentBottomBodyPartSize
        if state.positionY < baseHeight {
            state.positionY = baseHeight
        }

        if input.attacked {
            killedPart = true
            killedHead = state.bodyIndex == 0
            state.markedForDeletion = true
            effects.insert([.attackResponse, .squished, .markForDeletion])
            if killedHead { effects.insert(.headKilled) }
        } else if input.parentHeadWasKilled {
            state.timer = 0
            state.deathDelayAfterHeadKilled &-= 1
            if state.deathDelayAfterHeadKilled <= 0 {
                state.markedForDeletion = true
                killedPart = true
                effects.insert(.markForDeletion)
            }
        } else {
            state.deathDelayAfterHeadKilled = Int16(state.bodyIndex) * 4 + 20
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64PokeyBodyTickResult(
            state: state,
            effects: effects,
            killedPart: killedPart,
            killedHead: killedHead
        )
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }
}
