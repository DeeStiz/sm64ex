import Foundation

enum SM64EyerokBossAction: UInt8, Equatable, Sendable {
    case sleep = 0
    case wakeUp = 1
    case showIntroText = 2
    case fight = 3
    case die = 4
}

struct SM64EyerokHandSpawn: Equatable, Sendable {
    let side: Int8
    let model: UInt32
    let position: SM64ObjectVector3
    let faceYaw: Int16
    let scale: Float
}

struct SM64EyerokBossState: Equatable, Sendable {
    var action: SM64EyerokBossAction = .sleep
    var subAction: Int32 = 0
    var numHands: Int32 = 2
    var activeHand: Int32 = 0
    var busyHand: Int32 = 0 // oEyerokBossUnk1AC
    var handSelectionCounter: Int32 = 0 // oEyerokBossUnkFC
    var handSelectionPhase: Int32 = 0 // oEyerokBossUnk104
    var handSelectionDirection: Float = 0 // oEyerokBossUnk108
    var handTargetZ: Float = 0 // oEyerokBossUnk10C
    var handBlend: Float = 0 // oEyerokBossUnk110
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var faceYaw: Int16 = 0
    var timer: UInt32 = 0
    var markedForDeletion = false

    init(
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        positionX: Float? = nil,
        positionY: Float? = nil,
        positionZ: Float? = nil,
        faceYaw: Int16 = 0
    ) {
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = positionX ?? homeX
        self.positionY = positionY ?? homeY
        self.positionZ = positionZ ?? homeZ
        self.faceYaw = faceYaw
    }
}

struct SM64EyerokBossInput: Equatable, Sendable {
    var distanceToMario: Float
    var marioRelativeZ: Float
    var marioPositionZ: Float
    var marioReadyToSpeak: Bool
    var dialogComplete: Bool
    var randomLowBit: Bool

    init(
        distanceToMario: Float = 10_000,
        marioRelativeZ: Float = 10_000,
        marioPositionZ: Float = 0,
        marioReadyToSpeak: Bool = false,
        dialogComplete: Bool = false,
        randomLowBit: Bool = false
    ) {
        self.distanceToMario = distanceToMario
        self.marioRelativeZ = marioRelativeZ
        self.marioPositionZ = marioPositionZ
        self.marioReadyToSpeak = marioReadyToSpeak
        self.dialogComplete = dialogComplete
        self.randomLowBit = randomLowBit
    }
}

struct SM64EyerokBossEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let spawnHands = Self(rawValue: 1 << 0)
    static let explodeSound = Self(rawValue: 1 << 1)
    static let bossMusic = Self(rawValue: 1 << 2)
    static let dialog = Self(rawValue: 1 << 3)
    static let selectLeftHand = Self(rawValue: 1 << 4)
    static let selectRightHand = Self(rawValue: 1 << 5)
    static let selectDoublePound = Self(rawValue: 1 << 6)
    static let star = Self(rawValue: 1 << 7)
    static let stopBossMusic = Self(rawValue: 1 << 8)
    static let markForDeletion = Self(rawValue: 1 << 9)
}

struct SM64EyerokBossTickResult: Equatable, Sendable {
    let state: SM64EyerokBossState
    let effects: SM64EyerokBossEffect
    let dialogID: Int32
    let spawnedHands: [SM64EyerokHandSpawn]
    let starPosition: SM64ObjectVector3?
}

/// Value counterpart of `bhv_eyerok_boss_loop`. Hand object behavior and
/// arena/camera ownership remain separate seams; this controller owns only
/// the source boss state and its typed child/reward/effect intents.
enum SM64EyerokBossKernel {
    static let leftHandModel: UInt32 = 0x58 // MODEL_EYEROK_LEFT_HAND
    static let rightHandModel: UInt32 = 0x59 // MODEL_EYEROK_RIGHT_HAND
    static let introDialogID: Int32 = 117 // DIALOG_117
    static let defeatDialogID: Int32 = 118 // DIALOG_118
    static let starPosition = SM64ObjectVector3(x: 0, y: -900, z: -3_700)

    static func tick(
        _ input: SM64EyerokBossInput,
        state: inout SM64EyerokBossState
    ) -> SM64EyerokBossTickResult {
        var effects: SM64EyerokBossEffect = []
        var dialogID: Int32 = 0
        var spawnedHands: [SM64EyerokHandSpawn] = []
        var starPosition: SM64ObjectVector3?

        switch state.action {
        case .sleep:
            if state.timer == 0 {
                spawnedHands = [spawnHand(side: -1, state: state), spawnHand(side: 1, state: state)]
                effects.insert(.spawnHands)
            } else if input.distanceToMario < 500 {
                effects.insert(.explodeSound)
                state.action = .wakeUp
            }

        case .wakeUp:
            if state.numHands == 2 {
                if state.timer > 5 {
                    if state.subAction == 0 {
                        state.subAction += 1
                        effects.insert(.bossMusic)
                    }

                    if state.handBlend == 0, input.marioReadyToSpeak {
                        state.action = .showIntroText
                        dialogID = Self.introDialogID
                        effects.insert(.dialog)
                    } else if state.timer > 150 {
                        if approach(&state.handBlend, target: 0, step: 10) {
                            state.timer = 0
                        }
                    } else if state.timer > 90 {
                        _ = approach(&state.handBlend, target: 300, step: 10)
                    }
                }
            } else {
                state.timer = 0
            }

        case .showIntroText:
            dialogID = Self.introDialogID
            effects.insert(.dialog)
            if input.dialogComplete { state.action = .fight }

        case .fight:
            if state.numHands == 0 {
                state.action = .die
            } else if state.busyHand == 0, state.activeHand == 0 {
                if state.handSelectionPhase != 0 {
                    if approach(&state.handBlend, target: 1, step: 0.02) {
                        if state.handSelectionPhase < 0 {
                            if input.marioRelativeZ < 400 {
                                state.handSelectionPhase += 1
                                if state.handSelectionPhase == 0 {
                                    state.handSelectionPhase = 1
                                }
                            }
                        } else {
                            state.handSelectionPhase -= 1
                        }

                        if state.handSelectionPhase != 0, state.handSelectionPhase != 1 {
                            state.handSelectionCounter += 1
                            state.activeHand = state.handSelectionCounter & 1 == 0 ? -1 : 1
                            effects.insert(state.activeHand < 0 ? .selectLeftHand : .selectRightHand)
                        }
                    }
                } else {
                    state.handSelectionCounter += 1
                    if input.marioRelativeZ < 400 {
                        state.handSelectionPhase = -8
                        state.handBlend = 1
                        state.handSelectionDirection = 0
                    } else if state.numHands == 2, state.handSelectionCounter % 6 == 0 {
                        state.handSelectionPhase = 8
                        state.handBlend = 0
                        state.handSelectionCounter = input.randomLowBit ? 1 : 0
                        state.handSelectionDirection = input.randomLowBit ? -1 : 1
                        state.handTargetZ = min(
                            max(input.marioPositionZ, state.positionZ + 400),
                            state.positionZ + 1_600
                        )
                        effects.insert(.selectDoublePound)
                    } else {
                        state.activeHand = state.handSelectionCounter & 1 == 0 ? -1 : 1
                        effects.insert(state.activeHand < 0 ? .selectLeftHand : .selectRightHand)
                    }
                }
            }

        case .die:
            if state.timer == 60 {
                dialogID = Self.defeatDialogID
                effects.insert(.dialog)
                if input.dialogComplete {
                    starPosition = Self.starPosition
                    effects.insert(.star)
                } else {
                    state.timer &-= 1
                }
            } else if state.timer > 120 {
                state.markedForDeletion = true
                effects.insert([.stopBossMusic, .markForDeletion])
            }
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64EyerokBossTickResult(
            state: state,
            effects: effects,
            dialogID: dialogID,
            spawnedHands: spawnedHands,
            starPosition: starPosition
        )
    }

    private static func spawnHand(side: Int8, state: SM64EyerokBossState) -> SM64EyerokHandSpawn {
        let sideValue = Float(side)
        return SM64EyerokHandSpawn(
            side: side,
            model: side < 0 ? leftHandModel : rightHandModel,
            position: SM64ObjectVector3(
                x: state.positionX - 500 * sideValue,
                y: state.positionY,
                z: state.positionZ + 300
            ),
            faceYaw: state.faceYaw &- Int16(truncatingIfNeeded: 0x4000 * Int16(side)),
            scale: 1.5
        )
    }

    @discardableResult
    private static func approach(_ value: inout Float, target: Float, step: Float) -> Bool {
        if value < target {
            value = min(target, value + step)
        } else if value > target {
            value = max(target, value - step)
        }
        return value == target
    }
}
