import Foundation

/// The object-held values are the source `HELD_*` constants. Keeping them in
/// the value boundary makes a later owner bridge reject stale/foreign object
/// state without carrying a C pointer or enum.
enum SM64KingBobombHeldState: Int32, Equatable, Sendable {
    case free = 0
    case held = 1
    case thrown = 2
    case dropped = 3
}

struct SM64KingBobombState: Equatable, Sendable {
    var action: Int32 = SM64KingBobombBehavior.initializeAction
    var subAction: Int32 = 0
    var health: Int32 = 3
    var animationPhase: Int32 = 0 // oKingBobombUnk100
    var grabTurnTimer: Int32 = 0 // oKingBobombUnk104
    var grabEscapeCount: Int32 = 0 // oKingBobombUnkFC
    var releaseCooldown: Int32 = 0 // oKingBobombUnk108
    var interactionMode: Int32 = 0x02
    var moveYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var gravity: Float = -4
    var homeY: Float = 0
    var positionY: Float = 0
    var timer: UInt32 = 0
    var tangible = true
    var hidden = false
    var holdable = false
    var usingHomeMovement = false // oKingBobombUnkF8
    var interactionGrabCleared = false

    init(homeY: Float = 0, positionY: Float? = nil, moveYaw: Int16 = 0) {
        self.homeY = homeY
        self.positionY = positionY ?? homeY
        self.moveYaw = moveYaw
    }
}

struct SM64KingBobombInput: Equatable, Sendable {
    var distanceToMario: Float
    var angleToMario: Int16
    var angleToHome: Int16
    var positionY: Float
    var dialogCanActivate: Bool
    var dialogComplete: Bool
    var animationFrame: Int16
    var animationNearEnd: Bool
    var landed: Bool
    var onGround: Bool
    var grabbedMario: Bool
    var marioFarBelow: Bool
    var playerEscapeDelta: Int32
    var atHome: Bool
    var heldState: SM64KingBobombHeldState

    init(
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        angleToHome: Int16 = 0,
        positionY: Float = 0,
        dialogCanActivate: Bool = false,
        dialogComplete: Bool = false,
        animationFrame: Int16 = 0,
        animationNearEnd: Bool = false,
        landed: Bool = false,
        onGround: Bool = false,
        grabbedMario: Bool = false,
        marioFarBelow: Bool = false,
        playerEscapeDelta: Int32 = 0,
        atHome: Bool = false,
        heldState: SM64KingBobombHeldState = .free
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.angleToHome = angleToHome
        self.positionY = positionY
        self.dialogCanActivate = dialogCanActivate
        self.dialogComplete = dialogComplete
        self.animationFrame = animationFrame
        self.animationNearEnd = animationNearEnd
        self.landed = landed
        self.onGround = onGround
        self.grabbedMario = grabbedMario
        self.marioFarBelow = marioFarBelow
        self.playerEscapeDelta = playerEscapeDelta
        self.atHome = atHome
        self.heldState = heldState
    }
}

struct SM64KingBobombEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let resetHome = Self(rawValue: 1 << 0)
    static let cameraFocus = Self(rawValue: 1 << 1)
    static let bossMusic = Self(rawValue: 1 << 2)
    static let stopBossMusic = Self(rawValue: 1 << 3)
    static let shake = Self(rawValue: 1 << 4)
    static let mist = Self(rawValue: 1 << 5)
    static let triangleBreak = Self(rawValue: 1 << 6)
    static let star = Self(rawValue: 1 << 7)
    static let hide = Self(rawValue: 1 << 8)
    static let intangible = Self(rawValue: 1 << 9)
    static let tangible = Self(rawValue: 1 << 10)
    static let holdable = Self(rawValue: 1 << 11)
    static let clearGrab = Self(rawValue: 1 << 12)
    static let unrenderHeld = Self(rawValue: 1 << 13)
    static let thrownOrDropped = Self(rawValue: 1 << 14)
    static let soundSpawner = Self(rawValue: 1 << 15)
    static let renderingEnabled = Self(rawValue: 1 << 16)
    static let renderingDisabled = Self(rawValue: 1 << 17)
}

struct SM64KingBobombOutput: Equatable, Sendable {
    let state: SM64KingBobombState
    let animation: Int32
    let dialogID: Int32
    let dialogRequested: Bool
    let effects: SM64KingBobombEffect
    let soundValues: [Int32]
    let soundSpawnerValues: [Int32]
    let cameraShake: Int32
    let starPosition: (x: Float, y: Float, z: Float)?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.state == rhs.state
            && lhs.animation == rhs.animation
            && lhs.dialogID == rhs.dialogID
            && lhs.dialogRequested == rhs.dialogRequested
            && lhs.effects == rhs.effects
            && lhs.soundValues == rhs.soundValues
            && lhs.soundSpawnerValues == rhs.soundSpawnerValues
            && lhs.cameraShake == rhs.cameraShake
            && lhs.starPosition?.x.bitPattern == rhs.starPosition?.x.bitPattern
            && lhs.starPosition?.y.bitPattern == rhs.starPosition?.y.bitPattern
            && lhs.starPosition?.z.bitPattern == rhs.starPosition?.z.bitPattern
    }
}

/// Value counterpart of `bhv_king_bobomb_loop` and its nine source action
/// functions. Collision, animation clocks, dialog cutscene ownership, and
/// audio presentation are explicit inputs/effects for the owner bridge.
enum SM64KingBobombBehavior {
    static let initializeAction: Int32 = 0
    static let chaseAction: Int32 = 1
    static let grabbedAction: Int32 = 2
    static let heldAction: Int32 = 3
    static let thrownAction: Int32 = 4
    static let returnHomeAction: Int32 = 5
    static let damagedAction: Int32 = 6
    static let deathAction: Int32 = 7
    static let bossWaitAction: Int32 = 8

    static let dialogIntro: Int32 = 17 // DIALOG_017
    static let dialogDefeat: Int32 = 116 // DIALOG_116
    static let dialogReturn: Int32 = 128 // DIALOG_128

    static let soundKingBobomb: Int32 = Int32(bitPattern: 0x5016_8081)
    static let soundKingBobombDamage: Int32 = Int32(bitPattern: 0x9142_4081)
    static let soundKingBobombJump: Int32 = Int32(bitPattern: 0x5046_8081)
    static let soundUnknown3: Int32 = Int32(bitPattern: 0x501D_8081)
    static let soundUnknown4: Int32 = Int32(bitPattern: 0x501E_A081)
    static let soundKingWhompDeath: Int32 = Int32(bitPattern: 0x5147_C081)

    static func update(
        _ input: SM64KingBobombInput,
        state initialState: SM64KingBobombState
    ) -> SM64KingBobombOutput {
        var state = initialState
        state.positionY = input.positionY
        state.interactionGrabCleared = false
        var animation: Int32 = 0
        var dialogID: Int32 = 0
        var dialogRequested = false
        var effects: SM64KingBobombEffect = []
        var soundValues: [Int32] = []
        var soundSpawnerValues: [Int32] = []
        var cameraShake: Int32 = 0
        var starPosition: (x: Float, y: Float, z: Float)?

        switch input.heldState {
        case .held:
            effects.insert(.unrenderHeld)
            state.tangible = false
            state.hidden = true
            animation = 0
        case .thrown, .dropped:
            effects.insert(.thrownOrDropped)
            state.tangible = false
            state.positionY += 20
        case .free:
            switch state.action {
            case initializeAction:
                state.forwardVelocity = 0
                state.velocityY = 0
                state.tangible = false
                state.positionY = state.homeY
                state.health = 3
                animation = 5
                effects.formUnion([.resetHome, .cameraFocus, .intangible])
                if state.subAction == 0 {
                    if input.dialogCanActivate {
                        state.subAction = 1
                        effects.insert(.bossMusic)
                    }
                } else if input.dialogComplete {
                    state.action = grabbedAction
                    state.holdable = true
                    state.tangible = true
                    effects.formUnion([.holdable, .tangible])
                    dialogID = dialogIntro
                }

            case chaseAction:
                state.forwardVelocity = 0
                state.velocityY = 0
                animation = 11
                state.moveYaw = approachAngle(
                    current: state.moveYaw,
                    target: input.angleToMario,
                    increment: 512
                )
                if input.distanceToMario < 2_500 { state.action = grabbedAction }
                if input.marioFarBelow {
                    state.action = initializeAction
                    effects.insert(.stopBossMusic)
                }

            case grabbedAction:
                state.tangible = true
                effects.insert(.tangible)
                if state.positionY - state.homeY < -100 {
                    state.action = returnHomeAction
                    state.tangible = false
                    effects.insert(.intangible)
                }
                if state.animationPhase == 0 {
                    animation = 4
                    if input.animationFrame == 15 { cameraShake = 1; effects.insert(.shake) }
                    if input.animationNearEnd { state.animationPhase += 1 }
                } else {
                    if state.animationPhase == 1 {
                        animation = 11
                        state.animationPhase = 2
                    } else {
                        animation = 11
                    }
                    if state.releaseCooldown == 0 {
                        state.forwardVelocity = 3
                        state.moveYaw = approachAngle(
                            current: state.moveYaw,
                            target: input.angleToMario,
                            increment: 256
                        )
                    } else {
                        state.forwardVelocity = 0
                        state.releaseCooldown -= 1
                    }
                }
                if input.grabbedMario { state.action = heldAction }
                if input.marioFarBelow {
                    state.action = initializeAction
                    effects.insert(.stopBossMusic)
                }

            case heldAction:
                if state.subAction == 0 {
                    state.forwardVelocity = 0
                    state.grabEscapeCount = 0
                    state.grabTurnTimer = 0
                    if state.timer == 0 { soundValues.append(soundUnknown3) }
                    animation = 0
                    if input.animationNearEnd { state.subAction += 1; animation = 1 }
                } else if state.subAction == 1 {
                    animation = 1
                    state.grabEscapeCount += input.playerEscapeDelta
                    if state.grabEscapeCount > 10 {
                        state.action = grabbedAction
                        state.releaseCooldown = 35
                        state.interactionGrabCleared = true
                        effects.insert(.clearGrab)
                    } else {
                        state.forwardVelocity = 3
                        state.grabTurnTimer += 1
                        if state.grabTurnTimer > 20 {
                            let next = approachAngle(current: state.moveYaw, target: 0, increment: 0x400)
                            state.moveYaw = next
                            if next == 0 {
                                state.subAction += 1
                                animation = 9
                            }
                        }
                    }
                } else {
                    animation = 9
                    if input.animationFrame == 31 { soundValues.append(soundUnknown4) }
                    if input.animationNearEnd {
                        state.action = chaseAction
                        state.interactionGrabCleared = true
                        effects.insert(.clearGrab)
                    }
                }

            case thrownAction:
                if state.positionY - state.homeY > -100 {
                    if input.landed {
                        state.health = max(0, state.health - 1)
                        state.forwardVelocity = 0
                        state.velocityY = 0
                        soundValues.append(soundKingBobomb)
                        state.action = state.health > 0 ? damagedAction : deathAction
                    }
                } else if state.subAction == 0 {
                    if input.onGround {
                        state.forwardVelocity = 0
                        state.velocityY = 0
                        state.subAction += 1
                    } else if input.landed {
                        soundValues.append(soundKingBobomb)
                    }
                } else {
                    animation = 10
                    if input.animationNearEnd { state.action = returnHomeAction }
                    state.subAction += 1
                }

            case returnHomeAction:
                switch state.subAction {
                case 0:
                    state.forwardVelocity = 0
                    state.usingHomeMovement = true
                    animation = 8
                    state.moveYaw = input.angleToHome
                    if state.positionY < state.homeY {
                        state.velocityY = 100
                    } else if input.atHome {
                        state.subAction += 1
                    }
                case 1:
                    animation = 8
                    if state.velocityY < 0 && state.positionY < state.homeY {
                        state.positionY = state.homeY
                        state.velocityY = 0
                        state.forwardVelocity = 0
                        state.gravity = -4
                        state.usingHomeMovement = false
                        animation = 7
                        soundValues.append(soundKingBobomb)
                        cameraShake = 1
                        effects.insert(.shake)
                        state.subAction += 1
                    }
                case 2:
                    animation = 7
                    if input.animationNearEnd { state.subAction += 1 }
                case 3:
                    if input.marioFarBelow {
                        state.action = initializeAction
                        effects.insert(.stopBossMusic)
                    } else if input.dialogCanActivate {
                        state.subAction += 1
                    }
                default:
                    if input.dialogComplete {
                        state.action = grabbedAction
                        dialogID = dialogReturn
                        state.holdable = true
                    }
                }

            case damagedAction:
                if state.subAction == 0 {
                    if state.timer == 0 {
                        soundValues.append(soundKingBobomb)
                        soundValues.append(soundKingBobombDamage)
                        cameraShake = 1
                        effects.formUnion([.shake, .mist, .tangible])
                    }
                    state.interactionMode = 8
                    state.tangible = true
                    animation = 2
                    if input.animationNearEnd { state.grabTurnTimer += 1 }
                    if state.grabTurnTimer > 3 { state.subAction += 1 }
                } else if state.subAction == 1 {
                    animation = 10
                    if input.animationNearEnd {
                        state.subAction += 1
                        state.interactionMode = 2
                        state.tangible = false
                        effects.insert(.intangible)
                    }
                } else {
                    animation = 11
                    state.moveYaw = approachAngle(
                        current: state.moveYaw,
                        target: input.angleToMario,
                        increment: 0x800
                    )
                    if state.moveYaw == input.angleToMario { state.action = grabbedAction }
                }

            case deathAction:
                animation = 2
                if input.dialogComplete {
                    soundSpawnerValues.append(soundKingWhompDeath)
                    state.hidden = true
                    state.tangible = false
                    state.positionY += 100
                    effects.formUnion([.hide, .intangible, .mist, .triangleBreak, .shake, .star, .soundSpawner])
                    starPosition = (2_000, 4_500, -4_500)
                    state.action = bossWaitAction
                }

            case bossWaitAction:
                state.tangible = false
                effects.insert(.intangible)
                if state.timer == 60 { effects.insert(.stopBossMusic) }

            default:
                break
            }
        }

        if input.heldState == .free {
            effects.insert(.renderingEnabled)
        } else if input.heldState == .held {
            effects.insert(.renderingDisabled)
        }
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        dialogRequested = dialogID != 0
        return SM64KingBobombOutput(
            state: state,
            animation: animation,
            dialogID: dialogID,
            dialogRequested: dialogRequested,
            effects: effects,
            soundValues: soundValues,
            soundSpawnerValues: soundSpawnerValues,
            cameraShake: cameraShake,
            starPosition: starPosition
        )
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }
}
