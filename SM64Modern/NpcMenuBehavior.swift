import Foundation

// MARK: - Ukiki

struct SM64UkikiInput: Equatable, Sendable {
    let action: Int32
    let subAction: Int32
    let behaviorParam: Int32
    let textState: Int32
    let hasHat: Bool
    let heldState: Int32
    let distanceToMario: Float
    let angleToMario: Int32
    let moveYaw: Int32
    let positionY: Float
    let marioHasHat: Bool
    let marioFarAway: Bool
    let floorAhead: Bool
    let wallHit: Bool
    let edgeHit: Bool
    let marioMovingFastOrInAir: Bool
    let animationNearEnd: Bool
    let dialogResult: Int32
    let canActivateText: Bool
    let cageDistance: Float
    let cageYaw: Int32
    let timer: Int32
    let tauntCounter: Int32
    let tauntsToBeDone: Int32
}

struct SM64UkikiOutput: Equatable, Sendable {
    let action: Int32
    let subAction: Int32
    let textState: Int32
    let hasHat: Bool
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let animation: Int32
    let animState: Int32
    let intangible: Bool
    let interactionSubtype: UInt32
    let dialogID: Int32
    let dialogRequested: Bool
    let interactionMask: UInt32
    let resetToHome: Bool
    let markForDeletion: Bool
    let cageNextAction: Int32
}

/// Value counterpart of `bhvUkiki` and the shared `bhvMacroUkiki` script.
///
/// The source script aliases `bhvUkiki` into the macro body, so both
/// identities intentionally use this one deterministic kernel. Random taunt
/// selection remains an owner-supplied input; no global RNG crosses the seam.
enum SM64UkikiBehavior {
    static let actionIdle: Int32 = 0
    static let actionRun: Int32 = 1
    static let actionTurnToMario: Int32 = 2
    static let actionJump: Int32 = 3
    static let actionGoToCage: Int32 = 4
    static let actionWaitToRespawn: Int32 = 5
    static let actionUnusedTurn: Int32 = 6
    static let actionReturnHome: Int32 = 7

    static let tauntNone: Int32 = 0
    static let tauntItch: Int32 = 1
    static let tauntScreech: Int32 = 2
    static let tauntJumpClap: Int32 = 3
    static let tauntHandstand: Int32 = 4

    static let textDefault: Int32 = 0
    static let textCageTextbox: Int32 = 1
    static let textGoToCage: Int32 = 2
    static let textStoleHat: Int32 = 3
    static let textHasHat: Int32 = 4
    static let textGaveHatBack: Int32 = 5
    static let textDoNotLetGo: Int32 = 6
    static let textStealHat: Int32 = 7

    static let cageParam: Int32 = 0
    static let hatParam: Int32 = 1
    static let heldFree: Int32 = 0
    static let heldHeld: Int32 = 1
    static let heldThrown: Int32 = 2
    static let heldDropped: Int32 = 3
    static let dropImmediately: UInt32 = 0x40
    static let holdableNPC: UInt32 = 0x0000_0008

    static func update(_ input: SM64UkikiInput) -> SM64UkikiOutput {
        var action = input.action
        var subAction = input.subAction
        var textState = input.textState
        var hasHat = input.hasHat
        var moveYaw = input.moveYaw
        var forwardVelocity: Float = 0
        var velocityY: Float = 0
        var animation: Int32 = 0
        var animState: Int32 = hasHat ? 2 : 0
        var intangible = false
        var interactionSubtype: UInt32 = holdableNPC
        var dialogID: Int32 = 0
        var dialogRequested = false
        var interactionMask: UInt32 = 0
        var resetToHome = false
        var markForDeletion = false
        var cageNextAction: Int32 = 0

        if input.heldState == heldHeld {
            intangible = true
            interactionSubtype = holdableNPC
            animation = 12
            if input.behaviorParam == hatParam {
                switch textState {
                case textDefault:
                    if !input.marioHasHat {
                        textState = textStealHat
                        hasHat = true
                    }
                case textStealHat:
                    if input.dialogResult != 0 {
                        interactionMask = dropImmediately
                        textState = textStoleHat
                    }
                case textHasHat:
                    if input.dialogResult != 0 {
                        hasHat = false
                        textState = textGaveHatBack
                    }
                case textGaveHatBack:
                    textState = textDefault
                    action = actionIdle
                default:
                    break
                }
            } else {
                switch textState {
                case textDefault:
                    if input.canActivateText {
                        dialogID = 79
                        dialogRequested = true
                        textState = textCageTextbox
                    }
                case textCageTextbox:
                    if input.dialogResult != 0 {
                        if input.dialogResult == 1 {
                            interactionMask = dropImmediately
                            textState = textGoToCage
                        } else {
                            textState = textDoNotLetGo
                        }
                    }
                case textDoNotLetGo:
                    if input.timer > 60 { textState = textDefault }
                default:
                    break
                }
            }
        } else if input.heldState == heldThrown {
            intangible = false
            interactionSubtype = 0
            velocityY = 20
            forwardVelocity = 25
            action = actionJump
        } else if input.heldState == heldDropped {
            intangible = false
            interactionSubtype = holdableNPC
            forwardVelocity = 3
            action = actionIdle
        } else {
            switch action {
            case actionIdle:
                animation = input.subAction == tauntItch ? 9 :
                    input.subAction == tauntScreech ? 4 :
                    input.subAction == tauntJumpClap ? 5 :
                    input.subAction == tauntHandstand ? 10 : 0
                if input.subAction != tauntNone, input.animationNearEnd {
                    subAction = tauntNone
                }
                let chasingHat = input.behaviorParam == hatParam && input.marioHasHat
                if chasingHat {
                    if input.distanceToMario > 700 && input.distanceToMario < 1000 {
                        action = actionRun
                    } else if input.distanceToMario <= 700 && input.distanceToMario > 200,
                              angleDifference(input.angleToMario, moveYaw) > 0x1000 {
                        action = actionTurnToMario
                    }
                } else if input.distanceToMario < 300 {
                    action = actionRun
                }
                if textState == textGoToCage { action = actionGoToCage }
                if textState == textStoleHat {
                    if input.floorAhead {
                        action = actionJump
                    }
                    textState = textHasHat
                }
                if input.behaviorParam == hatParam, input.positionY < -1550 {
                    action = actionReturnHome
                }
            case actionRun:
                let flee = !(input.behaviorParam == hatParam && input.marioHasHat)
                let goalYaw = flee ? input.angleToMario &+ 0x8000 : input.angleToMario
                moveYaw = approachAngle(current: moveYaw, target: goalYaw, increment: 0x800)
                forwardVelocity = 20
                if flee {
                    if input.distanceToMario > 450 { action = actionTurnToMario }
                    if input.distanceToMario < 200, input.marioMovingFastOrInAir,
                       (input.wallHit || input.edgeHit) {
                        action = actionJump
                    }
                } else if input.distanceToMario < 350 {
                    action = actionTurnToMario
                }
                animation = 0
            case actionTurnToMario:
                animation = 11
                moveYaw = approachAngle(current: moveYaw, target: input.angleToMario, increment: 0x800)
                forwardVelocity = 2
                if angleDifference(input.angleToMario, moveYaw) == 0 { action = actionIdle }
                if input.behaviorParam == hatParam && input.marioHasHat {
                    if input.distanceToMario > 500 { action = actionRun }
                } else if input.distanceToMario < 300 {
                    action = actionRun
                }
            case actionJump:
                intangible = true
                forwardVelocity = 10
                animation = input.subAction == 0 ? 8 : 7
                if input.subAction == 0 {
                    if input.timer == 0 { velocityY = 45 }
                    if input.animationNearEnd { subAction = 1; velocityY = 0 }
                } else {
                    intangible = false
                    forwardVelocity = 0
                    if input.animationNearEnd { action = actionRun }
                }
            case actionGoToCage:
                intangible = true
                animation = input.subAction == 1 ? 5 : 0
                moveYaw = approachAngle(current: moveYaw, target: input.cageYaw, increment: 0x400)
                if input.cageDistance <= 50 {
                    forwardVelocity = 0
                    subAction = min(subAction &+ 1, 7)
                } else {
                    forwardVelocity = subAction == 0 ? 10 : 0
                }
                if subAction == 2, input.canActivateText { dialogID = 80; dialogRequested = true; subAction = 3 }
                if subAction == 5, input.animationNearEnd {
                    cageNextAction = 1
                    subAction = 6
                }
                if subAction == 6 {
                    moveYaw &+= 0x800
                    if input.timer > 32 { cageNextAction = 2; subAction = 7 }
                }
                if subAction == 7, input.positionY < -1300 { markForDeletion = true }
            case actionWaitToRespawn:
                animation = input.subAction == tauntNone ? 0 : 9
                if input.marioFarAway { action = actionIdle; resetToHome = true }
            case actionUnusedTurn:
                animation = 5
                if input.subAction == tauntJumpClap { moveYaw = approachAngle(current: moveYaw, target: input.angleToMario, increment: 0x400) }
            case actionReturnHome:
                animation = 0
                forwardVelocity = 10
                moveYaw = input.angleToMario
                if input.positionY > -1550 { action = actionIdle }
            default:
                break
            }
        }

        animState = hasHat ? 2 : 0
        return SM64UkikiOutput(
            action: action,
            subAction: subAction,
            textState: textState,
            hasHat: hasHat,
            moveYaw: moveYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            animation: animation,
            animState: animState,
            intangible: intangible,
            interactionSubtype: interactionSubtype,
            dialogID: dialogID,
            dialogRequested: dialogRequested,
            interactionMask: interactionMask,
            resetToHome: resetToHome,
            markForDeletion: markForDeletion,
            cageNextAction: cageNextAction
        )
    }

    private static func angleDifference(_ lhs: Int32, _ rhs: Int32) -> Int32 {
        let raw = (lhs &- rhs) & 0xFFFF
        return min(raw, 0x1_0000 &- raw)
    }

    private static func approachAngle(current: Int32, target: Int32, increment: Int32) -> Int32 {
        let distance = ((target &- current) &+ 0x8000) & 0xFFFF &- 0x8000
        if distance > increment { return current &+ increment }
        if distance < -increment { return current &- increment }
        return target
    }
}

struct SM64UkikiCageInput: Equatable, Sendable {
    let action: Int32
    let nextAction: Int32
    let parentAction: Int32
    let parentPositionX: Float
    let parentPositionY: Float
    let parentPositionZ: Float
    let parentBehaviorParams: Int32
    let moveYaw: Int32
    let faceYaw: Int32
    let landedOrWater: Bool
    let timer: Int32
}

struct SM64UkikiCageOutput: Equatable, Sendable {
    let action: Int32
    let nextAction: Int32
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let behaviorParams: Int32
    let moveYaw: Int32
    let faceYaw: Int32
    let copyParent: Bool
    let hide: Bool
    let markForDeletion: Bool
    let spawnParticles: Bool
    let spawnStar: Bool
    let loadCollisionModel: Bool
}

/// Value counterpart of `bhvUkikiCage` and `bhvUkikiCageStar`.
enum SM64UkikiCageBehavior {
    static let cageWaitForUkiki: Int32 = 0
    static let cageSpin: Int32 = 1
    static let cageFall: Int32 = 2
    static let cageHide: Int32 = 3
    static let starInCage: Int32 = 0
    static let starSpawn: Int32 = 1

    static func updateCage(_ input: SM64UkikiCageInput) -> SM64UkikiCageOutput {
        var action = input.action
        var nextAction = input.nextAction
        var moveYaw = input.moveYaw
        var loadCollisionModel = true
        var hide = false
        switch input.action {
        case cageWaitForUkiki:
            if nextAction != cageWaitForUkiki { action = cageSpin }
        case cageSpin:
            moveYaw &+= 0x800
            if nextAction != cageSpin { action = cageFall }
        case cageFall:
            if input.landedOrWater { action = cageHide }
        case cageHide:
            hide = true
            loadCollisionModel = false
        default:
            break
        }
        nextAction = action == cageHide ? cageHide : nextAction
        return SM64UkikiCageOutput(
            action: action,
            nextAction: nextAction,
            positionX: input.parentPositionX,
            positionY: input.parentPositionY,
            positionZ: input.parentPositionZ,
            behaviorParams: input.parentBehaviorParams,
            moveYaw: moveYaw,
            faceYaw: input.faceYaw,
            copyParent: false,
            hide: hide,
            markForDeletion: false,
            spawnParticles: false,
            spawnStar: false,
            loadCollisionModel: loadCollisionModel
        )
    }

    static func updateStar(_ input: SM64UkikiCageInput) -> SM64UkikiCageOutput {
        var action = input.action
        var markForDeletion = false
        var spawnParticles = false
        var spawnStar = false
        if action == starInCage, input.parentAction == cageHide { action = starSpawn }
        if action == starSpawn {
            markForDeletion = true
            spawnParticles = true
            spawnStar = true
        }
        return SM64UkikiCageOutput(
            action: action,
            nextAction: input.nextAction,
            positionX: input.parentPositionX,
            positionY: input.parentPositionY,
            positionZ: input.parentPositionZ,
            behaviorParams: input.parentBehaviorParams,
            moveYaw: input.moveYaw,
            faceYaw: input.faceYaw &+ 0x400,
            copyParent: true,
            hide: false,
            markForDeletion: markForDeletion,
            spawnParticles: spawnParticles,
            spawnStar: spawnStar,
            loadCollisionModel: false
        )
    }
}

// MARK: - MIPS

struct SM64MipsInitialization: Equatable, Sendable {
    let active: Bool
    let encounter: Int32
    let forwardVelocity: Float
    let gravity: Float
    let friction: Float
    let buoyancy: Float
    let interactionSubtype: UInt32
    let animation: Int32
}

struct SM64MipsInput: Equatable, Sendable {
    let action: Int32
    let heldState: Int32
    let encounter: Int32
    let starStatus: Int32
    let forwardVelocity: Float
    let nearbyMario: Bool
    let waypointAvailable: Bool
    let pathReachedEnd: Bool
    let animationNearEnd: Bool
    let grounded: Bool
    let underwater: Bool
    let dialogReady: Bool
    let dialogCompleted: Bool
    let timer: Int32
}

struct SM64MipsOutput: Equatable, Sendable {
    let action: Int32
    let heldState: Int32
    let starStatus: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let animation: Int32
    let hidden: Bool
    let intangible: Bool
    let faceYawToMoveYaw: Bool
    let interactionSubtype: UInt32
    let dialogID: Int32
    let dialogRequested: Bool
    let interactionMask: UInt32
    let spawnStar: Bool
    let spawnWaterSplash: Bool
    let playSound: Bool
}

enum SM64MipsBehavior {
    static let waitForNearbyMario: Int32 = 0
    static let followPath: Int32 = 1
    static let waitForAnimationDone: Int32 = 2
    static let fallDown: Int32 = 3
    static let idle: Int32 = 4
    static let starNotSpawned: Int32 = 0
    static let starShouldSpawn: Int32 = 1
    static let starAlreadySpawned: Int32 = 2
    static let heldFree: Int32 = 0
    static let heldHeld: Int32 = 1
    static let heldThrown: Int32 = 2
    static let heldDropped: Int32 = 3
    static let holdableNPC: UInt32 = 0x0000_0008
    static let dropImmediately: UInt32 = 0x40

    static func initialize(starCount: Int32, starFlags: UInt8) -> SM64MipsInitialization {
        if starCount >= 15, starFlags & 0x08 == 0 {
            return .init(active: true, encounter: 0, forwardVelocity: 40, gravity: 15, friction: 0.89, buoyancy: 1.2, interactionSubtype: holdableNPC, animation: 0)
        }
        if starCount >= 50, starFlags & 0x10 == 0 {
            return .init(active: true, encounter: 1, forwardVelocity: 45, gravity: 15, friction: 0.89, buoyancy: 1.2, interactionSubtype: holdableNPC, animation: 0)
        }
        return .init(active: false, encounter: 0, forwardVelocity: 0, gravity: 15, friction: 0.89, buoyancy: 1.2, interactionSubtype: holdableNPC, animation: 0)
    }

    static func update(_ input: SM64MipsInput) -> SM64MipsOutput {
        var action = input.action
        var heldState = input.heldState
        var starStatus = input.starStatus
        var velocity = input.forwardVelocity
        var velocityY: Float = 0
        var animation: Int32 = 0
        var hidden = false
        var intangible = false
        var faceYawToMoveYaw = false
        let interactionSubtype = holdableNPC
        var dialogID: Int32 = 0
        var dialogRequested = false
        var interactionMask: UInt32 = 0
        var spawnStar = false
        var spawnWaterSplash = false
        var playSound = false

        switch input.heldState {
        case heldFree:
            switch input.action {
            case waitForNearbyMario:
                velocity = 0
                if input.nearbyMario {
                    action = input.waypointAvailable ? followPath : waitForAnimationDone
                    animation = input.waypointAvailable ? 1 : 0
                }
            case followPath:
                velocity = input.forwardVelocity == 0 ? 40 : input.forwardVelocity
                animation = 1
                playSound = input.animationNearEnd
                spawnWaterSplash = playSound && input.underwater
                if input.pathReachedEnd { action = waitForNearbyMario; animation = 0 }
            case waitForAnimationDone:
                if input.animationNearEnd { action = idle; animation = 0 }
            case fallDown:
                animation = 2
                velocity = 0
                if input.grounded {
                    action = waitForAnimationDone
                    faceYawToMoveYaw = true
                    spawnWaterSplash = input.underwater
                }
            case idle:
                velocity = 0
                if starStatus == starShouldSpawn {
                    spawnStar = true
                    starStatus = starAlreadySpawned
                }
            default:
                break
            }
        case heldHeld:
            hidden = true
            intangible = true
            animation = 4
            velocity = 0
            if starStatus == starNotSpawned, input.dialogReady {
                dialogID = input.encounter == 0 ? 84 : 162
                dialogRequested = true
                if input.dialogCompleted {
                    interactionMask = dropImmediately
                    starStatus = starShouldSpawn
                }
            }
        case heldThrown:
            hidden = false
            velocity = 25
            velocityY = 20
            animation = 2
            heldState = heldFree
            action = fallDown
        case heldDropped:
            hidden = false
            velocity = 3
            animation = 0
            heldState = heldFree
            action = idle
        default:
            break
        }

        return SM64MipsOutput(
            action: action,
            heldState: heldState,
            starStatus: starStatus,
            forwardVelocity: velocity,
            velocityY: velocityY,
            animation: animation,
            hidden: hidden,
            intangible: intangible,
            faceYawToMoveYaw: faceYawToMoveYaw,
            interactionSubtype: interactionSubtype,
            dialogID: dialogID,
            dialogRequested: dialogRequested,
            interactionMask: interactionMask,
            spawnStar: spawnStar,
            spawnWaterSplash: spawnWaterSplash,
            playSound: playSound
        )
    }
}

// MARK: - Toad message

struct SM64ToadMessageInitialization: Equatable, Sendable {
    let active: Bool
    let state: Int32
    let dialogID: Int32
    let recentlyTalked: Bool
    let opacity: Int32
}

struct SM64ToadMessageInput: Equatable, Sendable {
    let state: Int32
    let dialogID: Int32
    let recentlyTalked: Bool
    let opacity: Int32
    let distanceToMario: Float
    let interacted: Bool
    let dialogCompleted: Bool
    let renderActive: Bool
}

struct SM64ToadMessageOutput: Equatable, Sendable {
    let state: Int32
    let dialogID: Int32
    let recentlyTalked: Bool
    let opacity: Int32
    let interactionSubtype: UInt32
    let clearInteraction: Bool
    let dialogRequested: Bool
    let dialogJingle: Bool
    let spawnStar: Bool
    let markForDeletion: Bool
}

enum SM64ToadMessageBehavior {
    static let faded: Int32 = 0
    static let opaque: Int32 = 1
    static let opacifying: Int32 = 2
    static let fading: Int32 = 3
    static let talking: Int32 = 4
    static let npcInteraction: UInt32 = 0x0000_0001

    static func initialize(dialogID: Int32, starCount: Int32, saveFlags: UInt32) -> SM64ToadMessageInitialization {
        var selected = dialogID
        var required: Int32 = 0
        var completedMask: UInt32 = 0
        switch dialogID {
        case 82: required = 12; completedMask = 1 << 24; if saveFlags & completedMask != 0 { selected = 154 }
        case 76: required = 25; completedMask = 1 << 25; if saveFlags & completedMask != 0 { selected = 155 }
        case 83: required = 35; completedMask = 1 << 26; if saveFlags & completedMask != 0 { selected = 156 }
        default: break
        }
        guard starCount >= required else { return .init(active: false, state: faded, dialogID: selected, recentlyTalked: false, opacity: 0) }
        return .init(active: true, state: faded, dialogID: selected, recentlyTalked: false, opacity: 81)
    }

    static func update(_ input: SM64ToadMessageInput) -> SM64ToadMessageOutput {
        var state = input.state
        var recentlyTalked = input.recentlyTalked
        var opacity = input.opacity
        var dialogID = input.dialogID
        var interactionSubtype: UInt32 = 0
        var clearInteraction = false
        var dialogRequested = false
        var dialogJingle = false
        var spawnStar = false
        if input.renderActive {
            switch input.state {
            case faded:
                if input.distanceToMario > 700 { recentlyTalked = false }
                if !recentlyTalked, input.distanceToMario < 600 { state = opacifying }
            case opaque:
                if input.distanceToMario > 700 {
                    state = fading
                } else if !recentlyTalked {
                    interactionSubtype = npcInteraction
                    if input.interacted {
                        clearInteraction = true
                        state = talking
                        dialogJingle = true
                    }
                }
            case opacifying:
                opacity = min(opacity &+ 6, 255)
                if opacity == 255 { state = opaque }
            case fading:
                opacity = max(opacity &- 6, 81)
                if opacity == 81 { state = faded }
            case talking:
                dialogRequested = true
                if input.dialogCompleted {
                    recentlyTalked = true
                    state = fading
                    switch dialogID {
                    case 82: dialogID = 154; spawnStar = true
                    case 76: dialogID = 155; spawnStar = true
                    case 83: dialogID = 156; spawnStar = true
                    default: break
                    }
                }
            default:
                break
            }
        }
        return .init(
            state: state,
            dialogID: dialogID,
            recentlyTalked: recentlyTalked,
            opacity: opacity,
            interactionSubtype: interactionSubtype,
            clearInteraction: clearInteraction,
            dialogRequested: dialogRequested,
            dialogJingle: dialogJingle,
            spawnStar: spawnStar,
            markForDeletion: false
        )
    }
}

// MARK: - File-select menu buttons

struct SM64MenuButtonInput: Equatable, Sendable {
    let state: Int32
    let timer: Int32
    let menuLevel: Int32
    let originalX: Float
    let originalY: Float
    let originalZ: Float
    let relativeX: Float
    let relativeY: Float
    let relativeZ: Float
    let facePitch: Int32
    let faceYaw: Int32
    let scale: Float
    let legacyDomainAdvances: Bool
}

struct SM64MenuButtonOutput: Equatable, Sendable {
    let state: Int32
    let timer: Int32
    let originalX: Float
    let originalY: Float
    let originalZ: Float
    let relativeX: Float
    let relativeY: Float
    let relativeZ: Float
    let facePitch: Int32
    let faceYaw: Int32
    let scale: Float
}

enum SM64MenuButtonBehavior {
    static let defaultState: Int32 = 0
    static let growing: Int32 = 1
    static let fullscreen: Int32 = 2
    static let shrinking: Int32 = 3
    static let zoomInOut: Int32 = 4
    static let zoomIn: Int32 = 5
    static let zoomOut: Int32 = 6
    static let mainMenu: Int32 = 1
    static let submenu: Int32 = 2

    static func initialize(relativeX: Float, relativeY: Float) -> SM64MenuButtonOutput {
        .init(state: defaultState, timer: 0, originalX: relativeX, originalY: relativeY, originalZ: 0,
              relativeX: relativeX, relativeY: relativeY, relativeZ: 0,
              facePitch: 0, faceYaw: 0, scale: 1)
    }

    static func update(_ input: SM64MenuButtonInput) -> SM64MenuButtonOutput {
        var state = input.state
        var timer = input.timer
        var relativeX = input.relativeX
        var relativeY = input.relativeY
        var relativeZ = input.relativeZ
        var facePitch = input.facePitch
        var faceYaw = input.faceYaw
        var scale = input.scale
        var originalZ = input.originalZ
        guard input.legacyDomainAdvances else {
            return .init(state: state, timer: timer, originalX: input.originalX, originalY: input.originalY, originalZ: originalZ,
                         relativeX: relativeX, relativeY: relativeY, relativeZ: relativeZ,
                         facePitch: facePitch, faceYaw: faceYaw, scale: scale)
        }
        switch input.state {
        case defaultState:
            originalZ = input.relativeZ
        case growing, shrinking:
            let growing = input.state == growing
            let sign: Int32 = growing ? 1 : -1
            if timer < 16 { faceYaw &+= sign * 0x800 }
            if timer < 8 { facePitch &+= sign * 0x800 }
            if timer >= 8 && timer < 16 { facePitch &-= sign * 0x800 }
            relativeX -= growing ? input.originalX / 16 : -input.originalX / 16
            relativeY -= growing ? input.originalY / 16 : -input.originalY / 16
            let zStep: Float = input.menuLevel == mainMenu ? 1112.5 : 116.25
            relativeZ += growing ? zStep : -zStep
            timer &+= 1
            if timer == 16 {
                relativeX = growing ? 0 : input.originalX
                relativeY = growing ? 0 : input.originalY
                state = growing ? fullscreen : defaultState
                timer = 0
            }
        case fullscreen:
            break
        case zoomInOut:
            let delta: Float = input.menuLevel == mainMenu ? -20 : 20
            relativeZ += timer < 4 ? delta : -delta
            timer &+= 1
            if timer == 8 { state = defaultState; timer = 0 }
        case zoomIn:
            scale += 0.0022
            timer &+= 1
            if timer == 10 { state = defaultState; timer = 0 }
        case zoomOut:
            scale -= 0.0022
            timer &+= 1
            if timer == 10 { state = defaultState; timer = 0 }
        default:
            break
        }
        return .init(state: state, timer: timer, originalX: input.originalX, originalY: input.originalY, originalZ: originalZ,
                     relativeX: relativeX, relativeY: relativeY, relativeZ: relativeZ,
                     facePitch: facePitch, faceYaw: faceYaw, scale: scale)
    }
}

struct SM64MenuButtonManagerInput: Equatable, Sendable {
    let selectedButtonID: Int32
    let legacyDomainAdvances: Bool
}

struct SM64MenuButtonManagerOutput: Equatable, Sendable {
    let selectedButtonID: Int32
    let initializedChildCount: Int32
    let acceptedTick: Bool
}

enum SM64MenuButtonManagerBehavior {
    static let none: Int32 = -1

    static func initialize() -> SM64MenuButtonManagerOutput {
        .init(selectedButtonID: none, initializedChildCount: 8, acceptedTick: false)
    }

    /// The C manager delegates the selected-button state machine to the
    /// file-select module. Keeping this value boundary explicit prevents a
    /// Swift owner from guessing at save/menu globals before central wiring.
    static func update(_ input: SM64MenuButtonManagerInput) -> SM64MenuButtonManagerOutput {
        .init(selectedButtonID: input.selectedButtonID,
              initializedChildCount: 0,
              acceptedTick: input.legacyDomainAdvances)
    }
}

typealias SM64MacroUkikiBehavior = SM64UkikiBehavior
typealias SM64UkikiCageStarBehavior = SM64UkikiCageBehavior
