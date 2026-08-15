import Foundation

struct SM64TuxiesMotherInput: Equatable, Sendable {
    let action: Int32
    let subAction: Int32
    let motherBehaviorParam: UInt8
    let childBehaviorParam: UInt8
    let childExists: Bool
    let childDistance: Float
    let childHeldState: Int32
    let nearbyHeldActor: Bool
    let lateralDistanceToMarioHome: Float
    let marioOnPlatform: Bool
    let canActivateText: Bool
    let dialogResult: Int32
    let angleToMario: Int16
    let moveYaw: Int16
    let soundStateID: Int32
    let animationFrameOne: Bool
}

struct SM64TuxiesMotherOutput: Equatable, Sendable {
    let action: Int32
    let subAction: Int32
    let scale: Float
    let animation: Int32
    let forwardVelocity: Float
    let moveYaw: Int16
    let angleVelocityYaw: Int16
    let dialogID: Int32
    let dialogRequested: Bool
    let childSmallPenguinUnk88: Bool
    let childInteractionSetMask: UInt32
    let clearChildDropImmediate: Bool
    let childBehavior: Int32
    let spawnStar: Bool
    let starHomePosition: SM64ObjectVector3?
    let starSpawnYOffset: Float
    let playWalkingSound: Bool
    let playYellSound: Bool
    let activeFlagUnk10: Bool
    let clearInteractionStatus: Bool
}

/// Value counterpart of the Snowman Land `bhv_tuxies_mother_loop` route.
///
/// The C callback searches the object graph for a held small penguin and a
/// held actor, updates dialog state, mutates the child behavior, and creates a
/// fixed-course reward star. This kernel keeps those relationships as explicit
/// owner-supplied facts and returns typed child/effect intents instead of
/// retaining C pointers.
enum SM64TuxiesMotherBehavior {
    static let followChild: Int32 = 0
    static let carryingChild: Int32 = 1
    static let chaseMario: Int32 = 2

    static let subIdle: Int32 = 0
    static let subDialog: Int32 = 1
    static let subWaitForDrop: Int32 = 2

    static let idleAnimation: Int32 = 3
    static let walkAnimation: Int32 = 1
    static let carryAnimation: Int32 = 0

    static let dialogInitial: Int32 = 57
    static let dialogCorrectChild: Int32 = 58
    static let dialogWrongChild: Int32 = 59

    static let heldFree: Int32 = 0
    static let interactionDropImmediately: UInt32 = 0x40
    static let childUnusedBehavior: Int32 = 0
    static let childBabyBehavior: Int32 = 1

    static let starHomePosition = SM64ObjectVector3(x: 3_167, y: -4_300, z: 5_108)
    static let starSpawnYOffset: Float = 200

    static func update(_ input: SM64TuxiesMotherInput) -> SM64TuxiesMotherOutput {
        var action = input.action
        var subAction = input.subAction
        var animation = idleAnimation
        var forwardVelocity: Float = 0
        var moveYaw = input.moveYaw
        var angleVelocityYaw: Int16 = 0
        var dialogID: Int32 = 0
        var dialogRequested = false
        var childSmallPenguinUnk88 = false
        var childInteractionSetMask: UInt32 = 0
        var clearChildDropImmediate = false
        var childBehavior: Int32 = -1
        var spawnStar = false

        let childHeld = input.childHeldState != heldFree
        let childNearby = input.childExists && input.childDistance < 300

        switch input.action {
        case followChild:
            animation = idleAnimation
            if childNearby && childHeld {
                action = carryingChild
                childSmallPenguinUnk88 = true
            } else {
                switch input.subAction {
                case subIdle:
                    if input.canActivateText, input.childDistance >= 500 {
                        subAction = subDialog
                    }
                case subDialog:
                    dialogID = dialogInitial
                    dialogRequested = true
                    if input.dialogResult != 0 {
                        subAction = subWaitForDrop
                    }
                case subWaitForDrop:
                    if input.childDistance > 450 {
                        subAction = subIdle
                    }
                default:
                    break
                }
            }

        case carryingChild:
            switch input.subAction {
            case subIdle:
                animation = idleAnimation
                if !input.marioOnPlatform {
                    dialogID = input.motherBehaviorParam == input.childBehaviorParam
                        ? dialogCorrectChild : dialogWrongChild
                    dialogRequested = true
                    if input.dialogResult != 0 {
                        subAction = dialogID == dialogCorrectChild ? subDialog : subWaitForDrop
                        childInteractionSetMask = interactionDropImmediately
                    }
                }
            case subDialog:
                if !childHeld {
                    clearChildDropImmediate = true
                    childBehavior = childUnusedBehavior
                    spawnStar = true
                    action = chaseMario
                }
            case subWaitForDrop:
                if !childHeld {
                    clearChildDropImmediate = true
                    childBehavior = childBabyBehavior
                    action = chaseMario
                }
            default:
                break
            }

        case chaseMario:
            if input.nearbyHeldActor {
                if input.subAction == subIdle {
                    animation = carryAnimation
                    forwardVelocity = 10
                    if input.lateralDistanceToMarioHome > 800 {
                        subAction = subDialog
                    }
                    let turn = approachAngle(
                        current: moveYaw,
                        target: input.angleToMario,
                        increment: 0x400
                    )
                    moveYaw = turn.value
                    angleVelocityYaw = turn.delta
                } else {
                    animation = idleAnimation
                    if input.lateralDistanceToMarioHome < 700 {
                        subAction = subIdle
                    }
                }
            } else {
                animation = idleAnimation
                forwardVelocity = 0
            }

        default:
            break
        }

        let playWalkingSound = input.soundStateID == 0
        if playWalkingSound {
            animation = walkAnimation
        }
        let playYellSound = input.action == followChild && input.animationFrameOne

        return SM64TuxiesMotherOutput(
            action: action,
            subAction: subAction,
            scale: 4,
            animation: animation,
            forwardVelocity: forwardVelocity,
            moveYaw: moveYaw,
            angleVelocityYaw: angleVelocityYaw,
            dialogID: dialogID,
            dialogRequested: dialogRequested,
            childSmallPenguinUnk88: childSmallPenguinUnk88,
            childInteractionSetMask: childInteractionSetMask,
            clearChildDropImmediate: clearChildDropImmediate,
            childBehavior: childBehavior,
            spawnStar: spawnStar,
            starHomePosition: spawnStar ? starHomePosition : nil,
            starSpawnYOffset: spawnStar ? starSpawnYOffset : 0,
            playWalkingSound: playWalkingSound,
            playYellSound: playYellSound,
            activeFlagUnk10: true,
            clearInteractionStatus: true
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
