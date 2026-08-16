import Foundation

enum SM64EyerokHandAction: UInt8, Equatable, Sendable {
    case sleep = 0
    case idle = 1
    case open = 2
    case showEye = 3
    case close = 4
    case retreat = 5
    case targetMario = 6
    case smash = 7
    case fistPush = 8
    case fistSweep = 9
    case beginDoublePound = 10
    case doublePound = 11
    case attacked = 12
    case recover = 13
    case becomeActive = 14
    case die = 15
}

struct SM64EyerokHandState: Equatable, Sendable {
    let side: Int8
    var action: SM64EyerokHandAction = .sleep
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var faceYaw: Int16 = 0
    var moveYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var gravity: Float = -4
    var health: Int16 = 4
    var wakeUpTimer: Int32 = 0
    var handTimer: Int32 = 0 // oEyerokHandUnkFC
    var eyeTimer: Int32 = 0 // oEyerokHandUnk100
    var animState: Int16 = 0
    var moveFlags: UInt32 = 0
    var collisionMode: Int32 = 0
    var renderScale: Float
    var timer: UInt32 = 0

    init(
        side: Int8,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        positionX: Float? = nil,
        positionY: Float? = nil,
        positionZ: Float? = nil,
        faceYaw: Int16 = 0,
        moveYaw: Int16 = 0
    ) {
        self.side = side
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = positionX ?? homeX
        self.positionY = positionY ?? homeY
        self.positionZ = positionZ ?? homeZ
        self.faceYaw = faceYaw
        self.moveYaw = moveYaw
        self.renderScale = 1.5 * Float(side)
    }
}

struct SM64EyerokHandInput: Equatable, Sendable {
    var parentAction: SM64EyerokBossAction
    var parentNumHands: Int32
    var parentActiveHand: Int32
    var parentBusyHand: Int32
    var parentHandSelectionPhase: Int32
    var parentHandSelectionDirection: Float
    var parentHandBlend: Float
    var parentHandTargetZ: Float
    var parentPositionX: Float
    var parentPositionZ: Float
    var marioRelativeZ: Float
    var marioPositionX: Float
    var marioPositionY: Float
    var marioPositionZ: Float
    var distanceToMario: Float
    var angleToMario: Int16
    var angleToHome: Int16
    var randomLowBit: Bool
    var randomLinearOffset: Int32
    var animationEnded: Bool
    var animationFrameOne: Bool
    var animationNearEnd: Bool
    var receivedAttack: Bool
    var onGround: Bool
    var hitEdge: Bool
    var hitWall: Bool

    init(
        parentAction: SM64EyerokBossAction = .sleep,
        parentNumHands: Int32 = 2,
        parentActiveHand: Int32 = 0,
        parentBusyHand: Int32 = 0,
        parentHandSelectionPhase: Int32 = 0,
        parentHandSelectionDirection: Float = 0,
        parentHandBlend: Float = 0,
        parentHandTargetZ: Float = 0,
        parentPositionX: Float = 0,
        parentPositionZ: Float = 0,
        marioRelativeZ: Float = 10_000,
        marioPositionX: Float = 0,
        marioPositionY: Float = 0,
        marioPositionZ: Float = 0,
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        angleToHome: Int16 = 0,
        randomLowBit: Bool = false,
        randomLinearOffset: Int32 = 20,
        animationEnded: Bool = false,
        animationFrameOne: Bool = false,
        animationNearEnd: Bool = false,
        receivedAttack: Bool = false,
        onGround: Bool = false,
        hitEdge: Bool = false,
        hitWall: Bool = false
    ) {
        self.parentAction = parentAction
        self.parentNumHands = parentNumHands
        self.parentActiveHand = parentActiveHand
        self.parentBusyHand = parentBusyHand
        self.parentHandSelectionPhase = parentHandSelectionPhase
        self.parentHandSelectionDirection = parentHandSelectionDirection
        self.parentHandBlend = parentHandBlend
        self.parentHandTargetZ = parentHandTargetZ
        self.parentPositionX = parentPositionX
        self.parentPositionZ = parentPositionZ
        self.marioRelativeZ = marioRelativeZ
        self.marioPositionX = marioPositionX
        self.marioPositionY = marioPositionY
        self.marioPositionZ = marioPositionZ
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.angleToHome = angleToHome
        self.randomLowBit = randomLowBit
        self.randomLinearOffset = randomLinearOffset
        self.animationEnded = animationEnded
        self.animationFrameOne = animationFrameOne
        self.animationNearEnd = animationNearEnd
        self.receivedAttack = receivedAttack
        self.onGround = onGround
        self.hitEdge = hitEdge
        self.hitWall = hitWall
    }
}

struct SM64EyerokHandEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let shortSound = Self(rawValue: 1 << 0)
    static let showEyeSound = Self(rawValue: 1 << 1)
    static let poundSound = Self(rawValue: 1 << 2)
    static let cameraShake = Self(rawValue: 1 << 3)
    static let mist = Self(rawValue: 1 << 4)
    static let explodeCoins = Self(rawValue: 1 << 5)
    static let soundSpawner = Self(rawValue: 1 << 6)
    static let deathPound = Self(rawValue: 1 << 7)
    static let idleAnimation = Self(rawValue: 1 << 8)
    static let openAnimation = Self(rawValue: 1 << 9)
    static let showEyeAnimation = Self(rawValue: 1 << 10)
    static let closeAnimation = Self(rawValue: 1 << 11)
    static let attackedAnimation = Self(rawValue: 1 << 12)
    static let recoverAnimation = Self(rawValue: 1 << 13)
    static let dieAnimation = Self(rawValue: 1 << 14)
}

struct SM64EyerokHandTickResult: Equatable, Sendable {
    let state: SM64EyerokHandState
    let effects: SM64EyerokHandEffect
    let parentNumHands: Int32
    let parentActiveHand: Int32
    let parentBusyHand: Int32
}

/// Value counterpart of `bhv_eyerok_hand_loop`. Collision and owner-thread
/// child scheduling are explicit inputs/outputs; this kernel owns the full
/// source action table and parent-counter mutations.
enum SM64EyerokHandKernel {
    private static let animStateCurve: [Int16] = [0, 1, 3, 2, 1, 0]

    static func tick(
        _ input: SM64EyerokHandInput,
        state: inout SM64EyerokHandState
    ) -> SM64EyerokHandTickResult {
        var parentNumHands = input.parentNumHands
        var parentActiveHand = input.parentActiveHand
        var parentBusyHand = input.parentBusyHand
        var effects: SM64EyerokHandEffect = []

        switch state.action {
        case .sleep:
            if input.parentAction != .sleep {
                state.wakeUpTimer &+= 1
                if state.wakeUpTimer > -3 * Int32(state.side) {
                    if input.animationNearEnd {
                        parentNumHands += 1
                        state.action = .idle
                        state.collisionMode = 0
                    } else {
                        state.positionX = approachValue(state.positionX, target: state.homeX, step: 15)
                        let distance = abs(state.positionX - state.homeX)
                        let angle = Int16(truncatingIfNeeded: Int32(distance / 724 * 0x8000))
                        state.positionY = state.homeY
                            + Float(200 * Int32(state.side) + 400) * SM64CanonicalTrig.sins(angle)
                        state.moveYaw = approachAngle(current: state.moveYaw, target: 0, increment: 400)
                    }
                } else {
                    state.collisionMode = state.side < 0 ? 1 : 2
                    state.positionX = state.homeX + 724 * Float(state.side)
                }
            } else {
                state.collisionMode = state.side < 0 ? 1 : 2
                state.positionX = state.homeX + 724 * Float(state.side)
            }

        case .idle:
            effects.insert(.idleAnimation)
            if input.parentAction == .fight {
                if input.parentHandSelectionPhase != 0 {
                    if input.parentHandSelectionPhase != 1 {
                        state.action = .beginDoublePound
                        state.gravity = 0
                    }
                } else if parentBusyHand == 0, parentActiveHand != 0 {
                    if parentActiveHand == Int32(state.side) {
                        if input.marioRelativeZ < 400 || input.randomLowBit {
                            state.action = .targetMario
                            state.moveYaw = input.angleToMario
                            state.gravity = 0
                        } else {
                            state.action = .fistPush
                            state.moveYaw = input.angleToMario
                                &+ (input.parentPositionX - input.marioPositionX < 0 ? -0x800 : 0x800)
                            state.gravity = -4
                        }
                    } else {
                        state.action = .open
                    }
                }
            } else {
                state.positionY = state.homeY + input.parentHandBlend
            }

        case .open:
            effects.insert(.openAnimation)
            parentBusyHand = Int32(state.side)
            if input.animationEnded {
                state.action = .showEye
                state.handTimer = 2
                state.eyeTimer = 60
                state.collisionMode = 3
                if parentNumHands != 2 {
                    state.moveYaw = clamp(input.angleToMario, lower: -0x3000, upper: 0x3000)
                    state.forwardVelocity = 50
                } else {
                    state.moveYaw = 0
                }
            }

        case .showEye:
            effects.insert([.showEyeAnimation, .showEyeSound])
            if !checkAttacked(
                input: input,
                state: &state,
                parentNumHands: &parentNumHands,
                effects: &effects
            ) {
                if parentActiveHand == 0 {
                    if state.animState < 3 {
                        state.animState += 1
                    } else if input.animationNearEnd {
                        state.action = .close
                    }
                } else {
                    if state.eyeTimer > 0 {
                        state.eyeTimer -= 1
                        if state.handTimer != 0 { state.handTimer -= 1 }
                        let index = max(0, min(animStateCurve.count - 1, Int(state.handTimer)))
                        state.animState = animStateCurve[index]
                    } else {
                        state.handTimer = 5
                        state.eyeTimer = input.randomLinearOffset
                    }
                    if parentNumHands != 2 {
                        state.moveYaw = approachAngle(current: state.moveYaw, target: 0, increment: 0x800)
                        if state.timer > 10,
                           state.positionZ - input.marioPositionZ > 0 || input.hitEdge {
                            parentActiveHand = 0
                            state.forwardVelocity = 0
                        }
                    }
                }
            }

        case .close:
            effects.insert(.closeAnimation)
            if input.animationFrameOne {
                state.collisionMode = 0
                if parentNumHands != 2 {
                    state.action = .retreat
                    parentActiveHand = Int32(state.side)
                } else if parentActiveHand == 0 {
                    state.action = .idle
                    parentBusyHand = 0
                }
            }

        case .retreat:
            let distance = max(0, lateralDistanceToHome(state: state, angleToHome: input.angleToHome) - 40)
            let homeAngle = input.angleToHome
            state.positionX = state.homeX - distance * SM64CanonicalTrig.sins(homeAngle)
            state.positionZ = state.homeZ - distance * SM64CanonicalTrig.coss(homeAngle)
            state.faceYaw = approachAngle(current: state.faceYaw, target: 0, increment: 400)
            state.positionY = approachValue(state.positionY, target: state.homeY, step: 20)
            if state.positionY == state.homeY,
               distance == 0,
               state.faceYaw == 0 {
                state.action = .idle
                parentActiveHand -= Int32(state.side)
                if parentBusyHand == Int32(state.side) { parentBusyHand = 0 }
            }

        case .targetMario:
            if input.marioRelativeZ < 400
                || state.positionZ - input.marioPositionZ > 0
                || state.positionZ - input.parentPositionZ > 1_700
                || abs(state.positionX - input.marioPositionX) > 900
                || input.hitWall {
                state.forwardVelocity = 0
                state.positionY = approachValue(state.positionY, target: state.homeY + 300, step: 20)
                if state.positionY == state.homeY + 300 {
                    state.action = .smash
                }
            } else {
                state.forwardVelocity = approachValue(state.forwardVelocity, target: 50, step: 5)
                state.positionY = approachValue(state.positionY, target: state.homeY + 300, step: 20)
                state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToMario, increment: 4_000)
            }

        case .smash:
            if state.timer > 20 {
                if input.onGround {
                    if state.gravity < -4 {
                        poundGround(effects: &effects)
                        state.gravity = -4
                    } else {
                        let angle = absAngleDiff(state.faceYaw, input.angleToMario)
                        if input.distanceToMario < 300, angle > 0x2000, angle < 0x6000 {
                            state.action = .fistSweep
                            state.moveYaw = Int16(state.faceYaw - input.angleToMario < 0 ? 0x4000 : -0x4000)
                        } else {
                            state.action = .retreat
                        }
                    }
                } else {
                    state.gravity = -20
                }
            }

        case .fistPush:
            if state.timer > 5,
               state.positionZ - input.marioPositionZ > 0 || input.hitEdge {
                state.action = .fistSweep
                state.forwardVelocity = 0
                state.moveYaw = state.positionX - input.marioPositionX < 0 ? 0x4000 : -0x4000
            } else {
                state.forwardVelocity = 50
            }

        case .fistSweep:
            if state.positionZ - input.parentPositionZ < 1_000 || input.hitEdge {
                state.action = .retreat
                state.forwardVelocity = 0
            } else {
                state.forwardVelocity = approachValue(state.forwardVelocity, target: 5, step: 0.02) * 1.08
                state.timer = 0
            }

        case .beginDoublePound:
            if input.parentHandSelectionPhase < 0 || parentActiveHand == Int32(state.side) {
                state.action = .doublePound
                state.moveYaw = Int16(
                    truncatingIfNeeded: Int32(state.faceYaw)
                        - Int32(0x4000 * input.parentHandSelectionDirection)
                )
            } else {
                let x = input.parentPositionX + 400 * input.parentHandSelectionDirection
                    - 180 * Float(state.side)
                state.positionX = state.homeX + (x - state.homeX) * input.parentHandBlend
                state.positionY = state.homeY + 300 * input.parentHandBlend
                state.positionZ = state.homeZ
                    + (input.parentHandTargetZ - state.homeZ) * input.parentHandBlend
            }

        case .doublePound:
            if parentNumHands != 2 { parentActiveHand = Int32(state.side) }
            if input.parentHandSelectionPhase == 1 {
                state.action = .retreat
                parentBusyHand = Int32(state.side)
            } else if parentActiveHand == Int32(state.side) {
                if input.onGround {
                    if state.gravity < -15 {
                        parentActiveHand = 0
                        poundGround(effects: &effects)
                        state.forwardVelocity = 0
                        state.gravity = -15
                    } else {
                        state.forwardVelocity = 30 * abs(input.parentHandSelectionDirection)
                        state.velocityY = 100
                        state.moveFlags = 0
                    }
                } else if state.velocityY <= 0 {
                    state.gravity = -20
                }
            }

        case .attacked:
            effects.insert(.attackedAnimation)
            if input.animationEnded {
                state.action = .recover
                state.collisionMode = 0
            }
            if input.onGround { state.forwardVelocity = 0 }

        case .recover:
            effects.insert(.recoverAnimation)
            if input.animationEnded { state.action = .becomeActive }

        case .becomeActive:
            if parentActiveHand == 0 || parentNumHands != 2 {
                state.action = .retreat
                parentActiveHand = Int32(state.side)
            }

        case .die:
            effects.insert(.dieAnimation)
            if input.animationEnded {
                parentBusyHand = 0
                effects.insert([.explodeCoins, .soundSpawner])
            }
            if input.onGround {
                effects.insert(.deathPound)
                state.forwardVelocity = 0
            }
        }

        state.timer = state.timer < 0x3FFF_FFFF ? state.timer &+ 1 : state.timer
        return SM64EyerokHandTickResult(
            state: state,
            effects: effects,
            parentNumHands: parentNumHands,
            parentActiveHand: parentActiveHand,
            parentBusyHand: parentBusyHand
        )
    }

    private static func checkAttacked(
        input: SM64EyerokHandInput,
        state: inout SM64EyerokHandState,
        parentNumHands: inout Int32,
        effects: inout SM64EyerokHandEffect
    ) -> Bool {
        guard input.receivedAttack, absAngleDiff(input.angleToMario, state.faceYaw) < 0x3000 else {
            return false
        }
        effects.insert(.shortSound)
        state.health -= 1
        if state.health >= 2 {
            state.action = .attacked
            state.velocityY = 30
        } else {
            parentNumHands -= 1
            state.action = .die
            state.velocityY = 50
        }
        state.forwardVelocity *= 0.2
        state.moveYaw = state.faceYaw &+ Int16.min
        state.moveFlags = 0
        state.gravity = -4
        state.animState = 3
        return true
    }

    private static func poundGround(effects: inout SM64EyerokHandEffect) {
        effects.insert([.poundSound, .cameraShake, .mist])
    }

    private static func lateralDistanceToHome(state: SM64EyerokHandState, angleToHome: Int16) -> Float {
        let dx = state.positionX - state.homeX
        let dz = state.positionZ - state.homeZ
        _ = angleToHome
        return (dx * dx + dz * dz).squareRoot()
    }

    private static func approachValue(_ current: Float, target: Float, step: Float) -> Float {
        if current < target { return min(target, current + step) }
        if current > target { return max(target, current - step) }
        return current
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }

    private static func clamp(_ value: Int16, lower: Int16, upper: Int16) -> Int16 {
        min(upper, max(lower, value))
    }

    private static func absAngleDiff(_ lhs: Int16, _ rhs: Int16) -> Int32 {
        let distance = abs(Int32(lhs) - Int32(rhs))
        return min(distance, 0x1_0000 - distance)
    }
}
