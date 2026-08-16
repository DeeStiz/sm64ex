import Foundation

enum SM64WhompSize: UInt8, Equatable, Sendable {
    case normal = 0
    case king = 1
}

enum SM64WhompAction: UInt8, Equatable, Sendable {
    case initialize = 0
    case chase = 1
    case turn = 2
    case pound = 3
    case fall = 4
    case landed = 5
    case onGround = 6
    case returnHome = 7
    case death = 8
    case bossWait = 9
}

struct SM64WhompHitbox: Equatable, Sendable {
    let interactType: UInt32
    let damageOrCoinValue: Int16
    let radius: Float
    let height: Float

    static let normal = Self(
        // INTERACT_BREAKABLE.
        interactType: 1 << 9,
        damageOrCoinValue: 2,
        radius: 80,
        height: 200
    )

    static let king = Self(
        interactType: 1 << 9,
        damageOrCoinValue: 2,
        radius: 160,
        height: 400
    )
}

struct SM64WhompState: Equatable, Sendable {
    let size: SM64WhompSize
    let hitbox: SM64WhompHitbox

    var action: SM64WhompAction = .initialize
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var moveYaw: Int16 = 0
    var facePitch: Int16 = 0
    var angleVelocityPitch: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var health: Int16
    var subAction: Int32 = 0
    var shakeValue: Int32 = 0
    var timer: UInt32 = 0
    var tangible = true
    var hidden = false
    var markedForDeletion = false

    init(
        size: SM64WhompSize = .normal,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        moveYaw: Int16 = 0
    ) {
        self.size = size
        self.hitbox = size == .king ? .king : .normal
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.moveYaw = moveYaw
        self.health = size == .king ? 3 : 1
    }
}

struct SM64WhompTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var angleToMario: Int16
    var lateralDistanceHome: Float
    var marioFarBelow: Bool
    var marioGroundPound: Bool
    var marioOnPlatform: Bool
    var landed: Bool
    var onGround: Bool
    var animationNearEnd: Bool
    var marioSquished: Bool
    var dialogComplete: Bool
    /// When true, the owner bridge applies the source-order movement pass
    /// after the action function. The default keeps the bounded value kernel
    /// behavior and its existing differential fingerprint unchanged.
    var movementHandledExternally: Bool

    init(
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        lateralDistanceHome: Float = 0,
        marioFarBelow: Bool = false,
        marioGroundPound: Bool = false,
        marioOnPlatform: Bool = false,
        landed: Bool = false,
        onGround: Bool = false,
        animationNearEnd: Bool = false,
        marioSquished: Bool = false,
        dialogComplete: Bool = false,
        movementHandledExternally: Bool = false
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.lateralDistanceHome = lateralDistanceHome
        self.marioFarBelow = marioFarBelow
        self.marioGroundPound = marioGroundPound
        self.marioOnPlatform = marioOnPlatform
        self.landed = landed
        self.onGround = onGround
        self.animationNearEnd = animationNearEnd
        self.marioSquished = marioSquished
        self.dialogComplete = dialogComplete
        self.movementHandledExternally = movementHandledExternally
    }
}

struct SM64WhompEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let resetHome = Self(rawValue: 1 << 0)
    static let animate = Self(rawValue: 1 << 1)
    static let cameraFocus = Self(rawValue: 1 << 2)
    static let scaleKing = Self(rawValue: 1 << 3)
    static let bossMusic = Self(rawValue: 1 << 4)
    static let chase = Self(rawValue: 1 << 5)
    static let turn = Self(rawValue: 1 << 6)
    static let pound = Self(rawValue: 1 << 7)
    static let fall = Self(rawValue: 1 << 8)
    static let landSound = Self(rawValue: 1 << 9)
    static let shake = Self(rawValue: 1 << 10)
    static let coin = Self(rawValue: 1 << 11)
    static let coins = Self(rawValue: 1 << 12)
    static let star = Self(rawValue: 1 << 13)
    static let mist = Self(rawValue: 1 << 14)
    static let triangleBreak = Self(rawValue: 1 << 15)
    static let deathSound = Self(rawValue: 1 << 16)
    static let hide = Self(rawValue: 1 << 17)
    static let intangible = Self(rawValue: 1 << 18)
    static let markForDeletion = Self(rawValue: 1 << 19)
    static let soundSpawner = Self(rawValue: 1 << 20)
    static let stopBossMusic = Self(rawValue: 1 << 21)
    static let returnHome = Self(rawValue: 1 << 22)
}

struct SM64WhompTickResult: Equatable, Sendable {
    let state: SM64WhompState
    let effects: SM64WhompEffect
}

enum SM64WhompKernel {
    static func tick(
        _ input: SM64WhompTickInput,
        state: inout SM64WhompState
    ) -> SM64WhompTickResult {
        var effects: SM64WhompEffect = [.animate]

        switch state.action {
        case .initialize:
            state.forwardVelocity = 0
            state.velocityY = 0
            state.positionX = state.homeX
            state.positionY = state.homeY
            state.positionZ = state.homeZ
            effects.insert(.resetHome)
            if state.size == .king {
                effects.insert([.cameraFocus, .scaleKing])
                if state.subAction == 0 {
                    if input.distanceToMario < 600 {
                        state.subAction = 1
                        effects.insert(.bossMusic)
                    } else {
                        state.health = 3
                    }
                } else if input.dialogComplete {
                    state.action = .turn
                }
            } else if input.distanceToMario < 500 {
                state.action = .chase
                effects.insert(.chase)
            }

        case .chase:
            state.forwardVelocity = 3
            let homeLimit: Float = state.size == .king ? 200 : 700
            if input.lateralDistanceHome > homeLimit {
                state.action = .returnHome
                state.subAction = 0
                state.timer = 0
                effects.insert(.returnHome)
            } else {
                let angle = absAngleDiff(input.angleToMario, state.moveYaw)
                if angle < 0x2000 {
                    if input.distanceToMario < 1_500 {
                        state.forwardVelocity = 9
                    }
                    if input.distanceToMario < 300 {
                        state.action = .pound
                        state.timer = 0
                        effects.insert(.pound)
                    }
                }
                effects.insert(.chase)
            }
            if !input.movementHandledExternally { advance(&state) }

        case .turn:
            state.forwardVelocity = 3
            state.moveYaw = approachAngle(
                current: state.moveYaw,
                target: input.angleToMario,
                increment: 0x200
            )
            if state.timer > 30 {
                let angle = absAngleDiff(input.angleToMario, state.moveYaw)
                if angle < 0x2000 {
                    if input.distanceToMario < 1_500 { state.forwardVelocity = 9 }
                    if input.distanceToMario < 300 {
                        state.action = .pound
                        state.timer = 0
                        effects.insert(.pound)
                    }
                }
            }
            if input.marioFarBelow {
                state.action = .initialize
                state.timer = 0
                effects.insert(.stopBossMusic)
            }
            effects.insert(.turn)
            if !input.movementHandledExternally { advance(&state) }

        case .pound:
            state.forwardVelocity = 0
            if input.animationNearEnd {
                state.action = .fall
                state.timer = 0
                effects.insert(.fall)
            }
            effects.insert(.pound)

        case .fall:
            if state.timer == 0 { state.velocityY = 40 }
            if state.timer >= 8 {
                state.angleVelocityPitch &+= 0x100
                state.facePitch &+= state.angleVelocityPitch
                if state.facePitch > 0x4000 {
                    state.angleVelocityPitch = 0
                    state.facePitch = 0x4000
                    state.action = .landed
                    state.subAction = 0
                }
            }
            effects.insert(.fall)
            if !input.movementHandledExternally {
                state.positionY += state.velocityY
                state.velocityY -= 4
            }

        case .landed:
            if state.subAction == 0 && input.landed {
                state.velocityY = 0
                state.subAction = 1
                effects.insert([.landSound, .shake])
            }
            if input.onGround { state.action = .onGround; state.timer = 0 }
            effects.insert(.landSound)

        case .onGround:
            state.forwardVelocity = 0
            state.angleVelocityPitch = 0
            if state.subAction != 10 {
                if state.size == .king {
                    if state.subAction == 0 && input.marioGroundPound {
                        state.health = max(0, state.health - 1)
                        effects.insert([.landSound, .deathSound, .shake, .mist, .triangleBreak])
                        if state.health == 0 {
                            state.action = .death
                            state.timer = 0
                        } else {
                            state.subAction = 1
                        }
                    }
                    state.shakeValue = 0
                } else if state.subAction == 0, input.marioOnPlatform {
                    if input.marioGroundPound {
                        effects.insert(.coins)
                        state.action = .death
                        state.timer = 0
                    } else {
                        effects.insert(.coin)
                        state.subAction = 1
                    }
                } else if !input.marioOnPlatform {
                    state.subAction = 0
                }

                if state.size == .king && state.action == .onGround {
                    if state.shakeValue < 10 {
                        if state.shakeValue.isMultiple(of: 2) { state.positionY -= 8 } else { state.positionY += 8 }
                    } else {
                        state.subAction = 10
                    }
                    state.shakeValue &+= 1
                }
                if state.timer > 100 || (input.marioSquished && state.timer > 30) {
                    state.subAction = 10
                }
            } else if state.facePitch > 0 {
                state.angleVelocityPitch = -0x200
                state.facePitch &+= state.angleVelocityPitch
            } else {
                state.angleVelocityPitch = 0
                state.facePitch = 0
                state.action = state.size == .king ? .turn : .chase
                state.timer = 0
            }

        case .returnHome:
            if state.subAction == 0 {
                state.forwardVelocity = 0
                if state.timer > 31 {
                    state.subAction = 1
                    state.timer = 0
                } else {
                    state.moveYaw &+= 0x400
                }
            } else {
                state.forwardVelocity = 3
                if state.timer > 42 {
                    state.action = .chase
                    state.timer = 0
                }
            }
            effects.insert(.returnHome)
            if !input.movementHandledExternally { advance(&state) }

        case .death:
            if state.size == .king {
                if input.dialogComplete {
                    state.hidden = true
                    state.tangible = false
                    state.positionY += 100
                    effects.insert([.hide, .intangible, .mist, .triangleBreak, .shake, .star, .deathSound])
                    state.action = .bossWait
                    state.timer = 0
                }
            } else {
                state.tangible = false
                effects.insert([.intangible, .mist, .triangleBreak, .shake, .soundSpawner, .markForDeletion])
                state.markedForDeletion = true
            }

        case .bossWait:
            state.tangible = false
            effects.insert(.intangible)
            if state.timer == 60 { effects.insert(.stopBossMusic) }
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64WhompTickResult(state: state, effects: effects)
    }

    private static func advance(_ state: inout SM64WhompState) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionY += state.velocityY
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
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
