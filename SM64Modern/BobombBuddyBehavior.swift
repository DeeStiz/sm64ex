import Foundation

struct SM64BobombBuddyState: Equatable, Sendable {
    var action: Int32 = SM64BobombBuddyBehavior.idleAction
    var role: Int32 = SM64BobombBuddyBehavior.adviceRole
    var cannonStatus: Int32 = SM64BobombBuddyBehavior.cannonUnopened
    var hasTalked: Bool = false
    var moveYaw: Int16 = 0
    var blinkTimer: UInt32 = 0
}

struct SM64BobombBuddyInput: Equatable, Sendable {
    let animationFrame: Int16
    let distanceToMario: Float
    let angleToMario: Int16
    let interacted: Bool
    let dialogOpenResult: Int32
    let adviceDialogResult: Int32
    let adviceDialogID: Int32
    let cannonFirstDialogResult: Int32
    var nearestCannonExists: Bool
    let cannonCutsceneResult: Int32
    let cannonSecondDialogResult: Int32
    let courseIsBob: Bool
    let randomBlinkTimer: UInt32

    init(
        animationFrame: Int16 = 0,
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        interacted: Bool = false,
        dialogOpenResult: Int32 = 0,
        adviceDialogResult: Int32 = 0,
        adviceDialogID: Int32 = 0,
        cannonFirstDialogResult: Int32 = 0,
        nearestCannonExists: Bool = false,
        cannonCutsceneResult: Int32 = 0,
        cannonSecondDialogResult: Int32 = 0,
        courseIsBob: Bool = true,
        randomBlinkTimer: UInt32 = 0
    ) {
        self.animationFrame = animationFrame
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.interacted = interacted
        self.dialogOpenResult = dialogOpenResult
        self.adviceDialogResult = adviceDialogResult
        self.adviceDialogID = adviceDialogID
        self.cannonFirstDialogResult = cannonFirstDialogResult
        self.nearestCannonExists = nearestCannonExists
        self.cannonCutsceneResult = cannonCutsceneResult
        self.cannonSecondDialogResult = cannonSecondDialogResult
        self.courseIsBob = courseIsBob
        self.randomBlinkTimer = randomBlinkTimer
    }
}

struct SM64BobombBuddyOutput: Equatable, Sendable {
    let state: SM64BobombBuddyState
    let playWalkingSound: Bool
    let playReadSignSound: Bool
    let dialogID: Int32
    let dialogRequested: Bool
    let cameraRequest: Int32
    let activeTimeStop: Bool
    let clearTimeStop: Bool
    let clearInteraction: Bool
    let visibilityDistance: Float
}

/// Value counterpart of `bhv_bobomb_buddy_loop` and its three actions.
/// Object stepping, camera/cutscene ownership, and dialog services remain
/// explicit inputs; this reducer owns the authored state transitions and
/// returns typed intents for the owner-thread bridge.
enum SM64BobombBuddyBehavior {
    static let idleAction: Int32 = 0
    static let turnToTalkAction: Int32 = 2
    static let talkAction: Int32 = 3

    static let adviceRole: Int32 = 0
    static let cannonRole: Int32 = 1

    static let cannonUnopened: Int32 = 0
    static let cannonOpening: Int32 = 1
    static let cannonOpened: Int32 = 2
    static let cannonStopTalking: Int32 = 3

    static let cannonPrepareCameraRequest: Int32 = 1
    static let bobombDialogID: Int32 = 4
    static let bobombReadyDialogID: Int32 = 105
    static let otherCourseDialogID: Int32 = 47
    static let otherCourseReadyDialogID: Int32 = 106

    static func update(
        _ input: SM64BobombBuddyInput,
        state initialState: SM64BobombBuddyState
    ) -> SM64BobombBuddyOutput {
        var state = initialState
        var dialogID: Int32 = 0
        var dialogRequested = false
        var cameraRequest: Int32 = 0
        var activeTimeStop = false
        var clearTimeStop = false
        var clearInteraction = false

        switch state.action {
        case idleAction:
            if input.distanceToMario < 1_000 {
                state.moveYaw = approachAngle(
                    current: state.moveYaw,
                    target: input.angleToMario,
                    increment: 0x140
                ).value
            }
            if input.interacted {
                state.action = turnToTalkAction
            }

        case turnToTalkAction:
            let turn = approachAngle(
                current: state.moveYaw,
                target: input.angleToMario,
                increment: 0x1_000
            )
            state.moveYaw = turn.value
            if state.moveYaw == input.angleToMario {
                state.action = talkAction
            }

        case talkAction:
            if input.dialogOpenResult == 2 {
                activeTimeStop = true
                switch state.role {
                case adviceRole:
                    dialogID = input.adviceDialogID
                    dialogRequested = true
                    if input.adviceDialogResult != 0 {
                        clearTimeStop = true
                        clearInteraction = true
                        state.hasTalked = true
                        state.action = idleAction
                    }

                case cannonRole:
                    switch state.cannonStatus {
                    case cannonUnopened:
                        dialogID = input.courseIsBob ? bobombDialogID : otherCourseDialogID
                        dialogRequested = true
                        if input.cannonFirstDialogResult != 0 {
                            state.cannonStatus = input.nearestCannonExists
                                ? cannonOpening : cannonStopTalking
                        }
                    case cannonOpening:
                        cameraRequest = cannonPrepareCameraRequest
                        if input.cannonCutsceneResult == -1 {
                            state.cannonStatus = cannonOpened
                        }
                    case cannonOpened:
                        dialogID = input.courseIsBob
                            ? bobombReadyDialogID : otherCourseReadyDialogID
                        dialogRequested = true
                        if input.cannonSecondDialogResult != 0 {
                            state.cannonStatus = cannonStopTalking
                        }
                    case cannonStopTalking:
                        clearTimeStop = true
                        clearInteraction = true
                        state.hasTalked = true
                        state.action = idleAction
                        state.cannonStatus = cannonOpened
                    default:
                        break
                    }

                default:
                    break
                }
            }

        default:
            break
        }

        state.blinkTimer = input.randomBlinkTimer
        return SM64BobombBuddyOutput(
            state: state,
            playWalkingSound: input.animationFrame == 5 || input.animationFrame == 16,
            playReadSignSound: state.action == turnToTalkAction,
            dialogID: dialogID,
            dialogRequested: dialogRequested,
            cameraRequest: cameraRequest,
            activeTimeStop: activeTimeStop,
            clearTimeStop: clearTimeStop,
            clearInteraction: clearInteraction,
            visibilityDistance: 3_000
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
