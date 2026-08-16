import Foundation

struct SM64SmallPenguinState: Equatable, Sendable {
    var action: Int32 = SM64SmallPenguinBehavior.idleAction
    var timer: Int32 = 0
    var moveYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var unknown104: Float = 0
    var unknown108: Float = 0
    var unknown110: Int32 = 0
    var diveReturnAction: Int32 = 0
    var linkFlag: UInt32 = 0
    var animation: Int32 = SM64SmallPenguinBehavior.idleAnimation
    var heldState: Int32 = SM64SmallPenguinBehavior.heldFree
}

struct SM64SmallPenguinInput: Equatable, Sendable {
    let distanceToMario: Float
    let angleToMario: Int16
    let nearestMotherExists: Bool
    let nearestMotherDistance: Float
    let angleToMother: Int16
    let marioDiveSliding: Bool
    let marioFarAway: Bool
    let marioPosition: SM64ObjectVector3
    let soundStateID: Int32
    let globalTimer: UInt64
    let hasBabyBehavior: Bool
    let randomUnknown110: Int32
    let randomUnknown108: Float
    let randomUnknown104: Float
    let heldState: Int32

    init(
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        nearestMotherExists: Bool = false,
        nearestMotherDistance: Float = .greatestFiniteMagnitude,
        angleToMother: Int16 = 0,
        marioDiveSliding: Bool = false,
        marioFarAway: Bool = false,
        marioPosition: SM64ObjectVector3 = .zero,
        soundStateID: Int32 = 1,
        globalTimer: UInt64 = 1,
        hasBabyBehavior: Bool = false,
        randomUnknown110: Int32 = 0,
        randomUnknown108: Float = 0,
        randomUnknown104: Float = 0,
        heldState: Int32 = SM64SmallPenguinBehavior.heldFree
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.nearestMotherExists = nearestMotherExists
        self.nearestMotherDistance = nearestMotherDistance
        self.angleToMother = angleToMother
        self.marioDiveSliding = marioDiveSliding
        self.marioFarAway = marioFarAway
        self.marioPosition = marioPosition
        self.soundStateID = soundStateID
        self.globalTimer = globalTimer
        self.hasBabyBehavior = hasBabyBehavior
        self.randomUnknown110 = randomUnknown110
        self.randomUnknown108 = randomUnknown108
        self.randomUnknown104 = randomUnknown104
        self.heldState = heldState
    }
}

struct SM64SmallPenguinOutput: Equatable, Sendable {
    let state: SM64SmallPenguinState
    let angleVelocityYaw: Int16
    let resetHome: Bool
    let playWalkingSound: Bool
    let playDiveSound: Bool
    let playHeldYellSound: Bool
    let unrenderHeldObject: Bool
    let copiedToMario: Bool
    let setSmallPenguinBehavior: Bool
    let thrown: Bool
    let dropped: Bool
}

/// Value counterpart of `bhv_small_penguin_loop` and its six free actions.
/// The owner thread supplies object relationships, Mario state, and random
/// draws; this kernel only reproduces the authored action/timer decisions.
enum SM64SmallPenguinBehavior {
    static let idleAction: Int32 = 0
    static let moveAwayAction: Int32 = 1
    static let moveTowardAction: Int32 = 2
    static let diveAction: Int32 = 3
    static let recoverAction: Int32 = 4
    static let followMotherAction: Int32 = 5

    static let heldFree: Int32 = 0
    static let heldHeld: Int32 = 1
    static let heldThrown: Int32 = 2
    static let heldDropped: Int32 = 3

    static let idleAnimation: Int32 = 3
    static let walkAnimation: Int32 = 0
    static let diveAnimation: Int32 = 1
    static let recoverAnimation: Int32 = 2

    static func update(
        _ input: SM64SmallPenguinInput,
        state initialState: SM64SmallPenguinState
    ) -> SM64SmallPenguinOutput {
        var state = initialState
        var angleVelocityYaw: Int16 = 0
        var resetHome = false
        var playDiveSound = false
        var playHeldYellSound = false
        var unrenderHeldObject = false
        var copiedToMario = false
        var setSmallPenguinBehavior = false
        var thrown = false
        var dropped = false

        switch state.heldState {
        case heldFree:
            if state.linkFlag != 0 {
                state.action = followMotherAction
                state.linkFlag = 0
            }

            switch state.action {
            case idleAction:
                state.animation = idleAnimation
                if state.timer == 0 {
                    state.unknown110 = input.randomUnknown110
                    state.unknown108 = input.randomUnknown108
                    state.unknown104 = input.randomUnknown104
                    state.forwardVelocity = 0
                    if input.nearestMotherExists && input.nearestMotherDistance < 1_000 {
                        state.action = followMotherAction
                    }
                }
                if state.action == idleAction {
                    if input.distanceToMario < 1_000,
                       state.unknown108 + 600 < input.distanceToMario {
                        state.action = moveAwayAction
                    } else if input.distanceToMario < state.unknown108 + 300 {
                        state.action = moveTowardAction
                    }
                }
                if input.marioFarAway {
                    resetHome = true
                }

            case moveAwayAction:
                state.animation = walkAnimation
                state.forwardVelocity = state.unknown104 + 3
                let turn = approachAngle(
                    current: state.moveYaw,
                    target: input.angleToMario,
                    increment: Int16(truncatingIfNeeded: state.unknown110 + 0x600)
                )
                state.moveYaw = turn.value
                angleVelocityYaw = turn.delta
                if input.distanceToMario < state.unknown108 + 300 ||
                    input.distanceToMario > 1_100 {
                    state.action = idleAction
                }
                if input.marioDiveSliding {
                    state.diveReturnAction = state.action
                    state.action = diveAction
                }

            case moveTowardAction:
                state.animation = walkAnimation
                state.forwardVelocity = state.unknown104 + 3
                let target = input.angleToMario &+ Int16(bitPattern: 0x8000)
                let turn = approachAngle(
                    current: state.moveYaw,
                    target: target,
                    increment: Int16(truncatingIfNeeded: state.unknown110 + 0x600)
                )
                state.moveYaw = turn.value
                angleVelocityYaw = turn.delta
                if input.distanceToMario > state.unknown108 + 500 {
                    state.action = idleAction
                }
                if input.marioDiveSliding {
                    state.diveReturnAction = state.action
                    state.action = diveAction
                }

            case diveAction:
                if state.timer > 5 {
                    if state.timer == 6 {
                        playDiveSound = true
                    }
                    state.animation = diveAnimation
                    if state.timer > 25, !input.marioDiveSliding {
                        state.action = recoverAction
                    }
                }

            case recoverAction:
                if state.timer > 20 {
                    state.forwardVelocity = 0
                    state.animation = recoverAnimation
                    if state.timer > 40 {
                        state.action = state.diveReturnAction
                    }
                }

            case followMotherAction:
                if input.nearestMotherExists {
                    state.forwardVelocity = input.distanceToMario < 1_000 ? 2 : 0
                    let target: Int16 = input.nearestMotherDistance > 200
                        ? input.angleToMother
                        : input.angleToMother &+ Int16(bitPattern: 0x8000)
                    let turn = approachAngle(current: state.moveYaw, target: target, increment: 0x400)
                    state.moveYaw = turn.value
                    angleVelocityYaw = turn.delta
                    state.animation = walkAnimation
                }
                if input.marioDiveSliding {
                    state.diveReturnAction = state.action
                    state.action = diveAction
                }

            default:
                break
            }

            // `play_penguin_walking_sound` runs after every free action and
            // also selects animation 1 when the sound state is ready.
            if input.soundStateID == 0 {
                state.animation = walkAnimation
            }

        case heldHeld:
            unrenderHeldObject = true
            setSmallPenguinBehavior = input.hasBabyBehavior
            copiedToMario = true
            playHeldYellSound = input.globalTimer % 30 == 0

        case heldThrown:
            thrown = true

        case heldDropped:
            dropped = true

        default:
            break
        }

        if state.timer < 0x3FFF_FFFF {
            state.timer &+= 1
        }
        return SM64SmallPenguinOutput(
            state: state,
            angleVelocityYaw: angleVelocityYaw,
            resetHome: resetHome,
            playWalkingSound: state.heldState == heldFree && input.soundStateID == 0,
            playDiveSound: playDiveSound,
            playHeldYellSound: playHeldYellSound,
            unrenderHeldObject: unrenderHeldObject,
            copiedToMario: copiedToMario,
            setSmallPenguinBehavior: setSmallPenguinBehavior,
            thrown: thrown,
            dropped: dropped
        )
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16)
        -> (value: Int16, delta: Int16)
    {
        let start = current
        let distance = Int32(target) - Int32(current)
        let value: Int16
        if distance >= 0 {
            value = distance > Int32(increment) ? current &+ increment : target
        } else {
            value = distance < -Int32(increment) ? current &- increment : target
        }
        return (value, value &- start)
    }
}
