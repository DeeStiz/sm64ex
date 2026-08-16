import Foundation

struct SM64YoshiState: Equatable, Sendable {
    var action: Int32 = SM64YoshiBehavior.idleAction
    var timer: Int32 = 0
    var chosenHome: Int32 = 0
    var homeX: Float = 0
    var homeZ: Float = -5_625
    var targetYaw: Int16 = 0
    var moveYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var blinkTimer: UInt32 = 0
}

struct SM64YoshiInput: Equatable, Sendable {
    let totalStars: Int32
    let yoshiDead: Bool
    let animationFrame: Int16
    let timer: Int32
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let closeToHome: Bool
    let angleToMario: Int16
    let interacted: Bool
    let dialogOpenResult: Int32
    let dialogResult: Int32
    let endingCameraEvent: Bool
    let globalTimer: UInt64
    let lives: Int32
    let randomChosenHome: Int32
    let randomBlinkTimer: UInt32

    init(
        totalStars: Int32 = 120,
        yoshiDead: Bool = false,
        animationFrame: Int16 = 0,
        timer: Int32 = 0,
        positionX: Float = 0,
        positionY: Float = 3_174,
        positionZ: Float = -5_625,
        closeToHome: Bool = false,
        angleToMario: Int16 = 0,
        interacted: Bool = false,
        dialogOpenResult: Int32 = 0,
        dialogResult: Int32 = 0,
        endingCameraEvent: Bool = false,
        globalTimer: UInt64 = 0,
        lives: Int32 = 3,
        randomChosenHome: Int32 = 0,
        randomBlinkTimer: UInt32 = 0
    ) {
        self.totalStars = totalStars
        self.yoshiDead = yoshiDead
        self.animationFrame = animationFrame
        self.timer = timer
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.closeToHome = closeToHome
        self.angleToMario = angleToMario
        self.interacted = interacted
        self.dialogOpenResult = dialogOpenResult
        self.dialogResult = dialogResult
        self.endingCameraEvent = endingCameraEvent
        self.globalTimer = globalTimer
        self.lives = lives
        self.randomChosenHome = randomChosenHome
        self.randomBlinkTimer = randomBlinkTimer
    }
}

struct SM64YoshiOutput: Equatable, Sendable {
    let state: SM64YoshiState
    let animation: Int32
    let dialogID: Int32
    let dialogRequested: Bool
    let activeTimeStop: Bool
    let clearTimeStop: Bool
    let clearInteraction: Bool
    let playWalkSound: Bool
    let playPuzzleJingle: Bool
    let playAlertSound: Bool
    let playExtraLifeSound: Bool
    let livesDelta: Int32
    let specialTripleJump: Bool
    let cameraRequest: Int32
    let respawnerRequested: Bool
    let deactivated: Bool
}

/// Value counterpart of `bhv_yoshi_loop` and its initialization gate. Save,
/// camera, dialog, object-step, and audio services remain explicit inputs or
/// typed effects so the reducer stays pointer-free and Swift 6 Sendable.
enum SM64YoshiBehavior {
    static let idleAction: Int32 = 0
    static let walkAction: Int32 = 1
    static let talkAction: Int32 = 2
    static let walkJumpOffRoofAction: Int32 = 3
    static let finishJumpingAndDespawnAction: Int32 = 4
    static let givePresentAction: Int32 = 5
    static let creditsAction: Int32 = 10

    static let dialogID: Int32 = 161
    static let cameraStarSpawnRequest: Int32 = 1
    static let yoshiRequiredStars: Int32 = 120
    static let roofHeight: Float = 2_100

    static let homeLocations: [(x: Float, z: Float)] = [
        (0, -5_625),
        (-1_364, -5_912),
        (-1_403, -4_609),
        (-1_004, -5_308),
    ]

    static func update(
        _ input: SM64YoshiInput,
        state initialState: SM64YoshiState
    ) -> SM64YoshiOutput {
        var state = initialState
        state.timer = input.timer
        state.blinkTimer = input.randomBlinkTimer
        var animation: Int32 = 0
        var dialogID: Int32 = 0
        var dialogRequested = false
        var activeTimeStop = false
        var clearTimeStop = false
        var clearInteraction = false
        var playWalkSound = false
        var playPuzzleJingle = false
        var playAlertSound = false
        var playExtraLifeSound = false
        var livesDelta: Int32 = 0
        var specialTripleJump = false
        var cameraRequest: Int32 = 0
        var respawnerRequested = false
        var deactivated = input.totalStars < yoshiRequiredStars || input.yoshiDead

        if !deactivated {
            switch state.action {
            case idleAction:
                var returnedEarly = false
                if input.timer > 90 {
                    let selected = min(max(input.randomChosenHome, 0), 3)
                    if state.chosenHome == selected {
                        returnedEarly = true
                    } else {
                        state.chosenHome = selected
                        let home = homeLocations[Int(selected)]
                        state.homeX = home.x
                        state.homeZ = home.z
                        state.targetYaw = SM64CanonicalTrig.atan2s(
                            y: home.z - input.positionZ,
                            x: home.x - input.positionX
                        )
                        state.action = walkAction
                    }
                }
                if !returnedEarly {
                    animation = 0
                    if input.interacted {
                        state.action = talkAction
                    }
                    if input.endingCameraEvent {
                        state.action = creditsAction
                        state.homeX = -1_798
                        state.homeZ = -3_644
                    }
                }

            case walkAction:
                state.forwardVelocity = 10
                state.moveYaw = approachAngle(
                    current: state.moveYaw,
                    target: state.targetYaw,
                    increment: 0x500
                ).value
                animation = 1
                playWalkSound = input.animationFrame == 0 || input.animationFrame == 15
                if input.closeToHome {
                    state.action = idleAction
                }
                if input.interacted {
                    state.action = talkAction
                }
                if input.positionY < roofHeight {
                    respawnerRequested = true
                    deactivated = true
                }

            case talkAction:
                if state.moveYaw == input.angleToMario {
                    animation = 0
                    if input.dialogOpenResult == 2 {
                        activeTimeStop = true
                        dialogID = Self.dialogID
                        dialogRequested = true
                        if input.dialogResult != 0 {
                            clearTimeStop = true
                            clearInteraction = true
                            state.homeX = homeLocations[2].x
                            state.homeZ = homeLocations[2].z
                            state.targetYaw = SM64CanonicalTrig.atan2s(
                                y: state.homeZ - input.positionZ,
                                x: state.homeX - input.positionX
                            )
                            state.action = givePresentAction
                        }
                    }
                } else {
                    animation = 1
                    playPuzzleJingle = true
                    state.moveYaw = approachAngle(
                        current: state.moveYaw,
                        target: input.angleToMario,
                        increment: 0x500
                    ).value
                }

            case walkJumpOffRoofAction:
                state.forwardVelocity = 10
                animation = 1
                if input.timer == 0 {
                    cameraRequest = cameraStarSpawnRequest
                }
                state.moveYaw = approachAngle(
                    current: state.moveYaw,
                    target: state.targetYaw,
                    increment: 0x500
                ).value
                playWalkSound = input.animationFrame == 0 || input.animationFrame == 15
                if input.closeToHome {
                    animation = 2
                    playAlertSound = true
                    state.forwardVelocity = 50
                    state.velocityY = 40
                    state.moveYaw = -0x3FFF
                    state.action = finishJumpingAndDespawnAction
                }

            case finishJumpingAndDespawnAction:
                animation = 2
                state.velocityY -= 2
                state.forwardVelocity = 50
                if input.positionY < roofHeight {
                    clearTimeStop = true
                    deactivated = true
                }

            case givePresentAction:
                animation = 0
                if input.lives == 100 {
                    playExtraLifeSound = true
                    specialTripleJump = true
                    state.action = walkJumpOffRoofAction
                } else if input.globalTimer & 0x03 == 0 {
                    playExtraLifeSound = true
                    livesDelta = 1
                }

            case creditsAction:
                animation = 0

            default:
                break
            }
        }

        return SM64YoshiOutput(
            state: state,
            animation: animation,
            dialogID: dialogID,
            dialogRequested: dialogRequested,
            activeTimeStop: activeTimeStop,
            clearTimeStop: clearTimeStop,
            clearInteraction: clearInteraction,
            playWalkSound: playWalkSound,
            playPuzzleJingle: playPuzzleJingle,
            playAlertSound: playAlertSound,
            playExtraLifeSound: playExtraLifeSound,
            livesDelta: livesDelta,
            specialTripleJump: specialTripleJump,
            cameraRequest: cameraRequest,
            respawnerRequested: respawnerRequested,
            deactivated: deactivated
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
