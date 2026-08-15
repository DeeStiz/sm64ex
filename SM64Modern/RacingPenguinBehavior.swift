import Foundation

/// Inputs supplied by the owner thread for one racing-penguin behavior tick.
///
/// Path following, dialog, animation completion, and Mario's race state are
/// deliberately explicit.  The value kernel does not retain pointers to
/// waypoint objects, Mario, cameras, or the dialog system.
struct SM64RacingPenguinInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let positionY: Float
    let marioPositionY: Float
    let initTextCooldown: Int32
    let canActivateInitialText: Bool
    let initialDialogResponse: Int32
    let raceBeginComplete: Bool
    let pathStatus: Int32
    let pathWaypointFlags: UInt32
    let pathTargetYaw: Int16
    let moveFlags: UInt32
    let animationAtEnd: Bool
    let finalAnimationAtEnd: Bool
    let canActivateFinalText: Bool
    let finalDialogResult: Int32
    let finalTextbox: Int32
    let marioWon: Bool
    let marioCheated: Bool
    let weightedTargetSpeed: Float
    let forwardVelocity: Float
    let moveYaw: Int16
    let marioInAirAction: Bool
}

struct SM64RacingPenguinOutput: Equatable, Sendable {
    let action: Int32
    let initTextCooldown: Int32
    let forwardVelocity: Float
    let weightedTargetSpeed: Float
    let moveYaw: Int16
    let angleVelocityYaw: Int16
    let animation: Int32
    let animationSpeed: Float
    let finalTextbox: Int32
    let marioWon: Bool
    let marioCheated: Bool
    let reachedBottom: Bool
    let resetTimer: Bool
    let setVelocityY: Float?
    let attachRaceObjects: Bool
    let initializePath: Bool
    let playRoughSlideSound: Bool
    let playWalkingSound: Bool
    let playPoundingSound: Bool
    let cameraShakeSmall: Bool
    let spawnSmoke: Bool
    let spawnStar: Bool
    let finalDialogCompleted: Bool
}

/// Value counterpart of `bhv_racing_penguin_update`.
///
/// The caller owns the C object graph and supplies path/dialog results.  All
/// state transitions and scalar movement decisions remain deterministic and
/// strict-concurrency safe, making the route suitable for an owner-thread
/// bridge and an independent C oracle.
enum SM64RacingPenguinBehavior {
    static let waitForMario: Int32 = 0
    static let showInitText: Int32 = 1
    static let prepareForRace: Int32 = 2
    static let race: Int32 = 3
    static let finishRace: Int32 = 4
    static let showFinalText: Int32 = 5

    static let walkAnimation: Int32 = 1
    static let idleAnimation: Int32 = 0
    static let finalAnimation: Int32 = 3

    static let pathNone: Int32 = 0
    static let pathReachedEnd: Int32 = -1
    static let dialogNoResponse: Int32 = 0

    static let dialogCheatedWin: Int32 = 132
    static let dialogWin: Int32 = 56
    static let dialogLose: Int32 = 37

    static let moveLanded: UInt32 = 1 << 0
    static let moveOnGround: UInt32 = 1 << 1
    static let moveHitWall: UInt32 = 1 << 9
    static let waypointLowByteMask: UInt32 = 0x00ff

    static func update(_ input: SM64RacingPenguinInput) -> SM64RacingPenguinOutput {
        var action = input.action
        var initTextCooldown = input.initTextCooldown
        var forwardVelocity = input.forwardVelocity
        var weightedTargetSpeed = input.weightedTargetSpeed
        var moveYaw = input.moveYaw
        var angleVelocityYaw: Int16 = 0
        var animation = idleAnimation
        let animationSpeed: Float = 1
        var finalTextbox = input.finalTextbox
        var marioWon = input.marioWon
        var marioCheated = input.marioCheated
        var reachedBottom = false
        var resetTimer = false
        var setVelocityY: Float?
        var attachRaceObjects = false
        var initializePath = false
        var playRoughSlideSound = false
        var playWalkingSound = false
        var playPoundingSound = false
        var cameraShakeSmall = false
        var spawnSmoke = false
        var spawnStar = false
        var finalDialogCompleted = false

        switch input.action {
        case waitForMario:
            if input.timer > input.initTextCooldown,
               input.positionY - input.marioPositionY <= 0,
               input.canActivateInitialText {
                action = showInitText
            }

        case showInitText:
            if input.initialDialogResponse == 1 {
                attachRaceObjects = true
                initializePath = true
                action = prepareForRace
                setVelocityY = 60
            } else if input.initialDialogResponse == 2 {
                action = waitForMario
                initTextCooldown = 60
            }

        case prepareForRace:
            if input.raceBeginComplete {
                action = race
                forwardVelocity = 20
            }
            let turn = approachAngle(current: moveYaw, target: 0x4000, increment: 2_500)
            angleVelocityYaw = turn.delta
            moveYaw = turn.value

        case race:
            if input.pathStatus == pathReachedEnd {
                reachedBottom = true
                action = finishRace
            } else {
                var targetSpeed = input.positionY - input.marioPositionY
                var minSpeed: Float = 70
                playRoughSlideSound = true

                if targetSpeed < 100 || (input.pathWaypointFlags & waypointLowByteMask) >= 35 {
                    if (input.pathWaypointFlags & waypointLowByteMask) >= 35 {
                        minSpeed = 60
                    }
                    weightedTargetSpeed = approachFloat(
                        current: weightedTargetSpeed,
                        target: -500,
                        increment: 100
                    )
                } else {
                    weightedTargetSpeed = approachFloat(
                        current: weightedTargetSpeed,
                        target: 1_000,
                        increment: 30
                    )
                }

                targetSpeed = 0.1 * (weightedTargetSpeed + targetSpeed)
                targetSpeed = min(max(targetSpeed, minSpeed), 150)
                forwardVelocity = approachFloat(
                    current: forwardVelocity,
                    target: targetSpeed,
                    increment: 0.4
                )
                animation = walkAnimation
                let turnIncrement = Int16(truncatingIfNeeded: Int32(15 * forwardVelocity))
                let turn = approachAngle(
                    current: moveYaw,
                    target: input.pathTargetYaw,
                    increment: turnIncrement
                )
                angleVelocityYaw = turn.delta
                moveYaw = turn.value

                if input.animationAtEnd && (input.moveFlags & (moveLanded | moveOnGround)) != 0 {
                    spawnSmoke = true
                }
            }

            if input.marioInAirAction {
                if input.timer > 60 {
                    marioCheated = true
                }
            } else {
                resetTimer = true
            }

        case finishRace:
            if forwardVelocity != 0 {
                if input.timer > 5 && (input.moveFlags & moveHitWall) != 0 {
                    playPoundingSound = true
                    cameraShakeSmall = true
                    forwardVelocity = 0
                }
            } else if input.finalAnimationAtEnd {
                action = showFinalText
            }

        case showFinalText:
            if finalTextbox == 0 {
                let turn = approachAngle(current: moveYaw, target: 0, increment: 200)
                angleVelocityYaw = turn.delta
                moveYaw = turn.value
                if turn.completed {
                    animation = finalAnimation
                    forwardVelocity = 0
                    if input.canActivateFinalText {
                        if marioWon {
                            if marioCheated {
                                finalTextbox = dialogCheatedWin
                                marioWon = false
                            } else {
                                finalTextbox = dialogWin
                            }
                        } else {
                            finalTextbox = dialogLose
                        }
                    }
                } else {
                    animation = idleAnimation
                    playWalkingSound = true
                    forwardVelocity = 4
                }
            } else if finalTextbox > 0 {
                if input.finalDialogResult != dialogNoResponse {
                    finalTextbox = -1
                    resetTimer = true
                    finalDialogCompleted = true
                }
            } else if marioWon {
                spawnStar = true
                marioWon = false
            }

        default:
            break
        }

        return SM64RacingPenguinOutput(
            action: action,
            initTextCooldown: initTextCooldown,
            forwardVelocity: forwardVelocity,
            weightedTargetSpeed: weightedTargetSpeed,
            moveYaw: moveYaw,
            angleVelocityYaw: angleVelocityYaw,
            animation: animation,
            animationSpeed: animationSpeed,
            finalTextbox: finalTextbox,
            marioWon: marioWon,
            marioCheated: marioCheated,
            reachedBottom: reachedBottom,
            resetTimer: resetTimer,
            setVelocityY: setVelocityY,
            attachRaceObjects: attachRaceObjects,
            initializePath: initializePath,
            playRoughSlideSound: playRoughSlideSound,
            playWalkingSound: playWalkingSound,
            playPoundingSound: playPoundingSound,
            cameraShakeSmall: cameraShakeSmall,
            spawnSmoke: spawnSmoke,
            spawnStar: spawnStar,
            finalDialogCompleted: finalDialogCompleted
        )
    }

    private static func approachFloat(current: Float, target: Float, increment: Float) -> Float {
        SM64DeterministicPrimitives.approachFloat(
            current: current,
            target: target,
            increment: increment,
            decrement: increment
        )
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16)
        -> (value: Int16, delta: Int16, completed: Bool)
    {
        let start = current
        let distance = Int32(target) - Int32(current)
        let value: Int16
        if distance >= 0 {
            if distance > Int32(increment) {
                value = current &+ increment
            } else {
                value = target
            }
        } else if distance < -Int32(increment) {
            value = current &- increment
        } else {
            value = target
        }
        return (value, value &- start, value == target)
    }
}
