import Foundation

enum SM64MarioPunchAnimationID {
    static let firstPunch: UInt16 = 0x67
    static let secondPunch: UInt16 = 0x68
    static let firstPunchFast: UInt16 = 0x69
    static let secondPunchFast: UInt16 = 0x6A
    static let groundKick: UInt16 = 0x66
    static let breakdance: UInt16 = 0x71
}

enum SM64MarioPunchSoundKind: UInt8, Equatable, Sendable {
    case none = 0
    case yah = 1
    case wah = 2
    case hoo = 3
}

struct SM64MarioPunchSequenceInput: Equatable, Sendable {
    let movingAction: Bool
    let actionArgument: UInt32
    let animationFrame: Int16
    let animationAtEnd: Bool
    let animationPastEnd: Bool
    let bPressed: Bool
}

struct SM64MarioPunchSequenceResult: Equatable, Sendable {
    let actionArgument: UInt32
    let animationID: UInt16
    let transitionAction: UInt32?
    let flags: UInt32
    let punchState: UInt8?
    let sound: SM64MarioPunchSoundKind
}

/// Value counterpart of `mario_update_punch_sequence`. Object interaction and
/// audio delivery remain intents; the action-argument/animation/flag order is
/// owned here so moving and stationary punch bodies share one contract.
enum SM64MarioPunchSequence {
    static let punchingFlag: UInt32 = 0x00100000
    static let kickingFlag: UInt32 = 0x00200000
    static let trippingFlag: UInt32 = 0x00400000

    static func update(_ input: SM64MarioPunchSequenceInput) -> SM64MarioPunchSequenceResult? {
        guard input.animationFrame >= -1 else { return nil }

        let endAction = input.movingAction ? SM64MarioActionID.walking : SM64MarioActionID.idle
        let crouchEndAction = input.movingAction
            ? SM64MarioActionID.crouchSlide
            : SM64MarioActionID.crouching
        let argument = input.actionArgument

        switch argument {
        case 0, 1:
            let nextArgument: UInt32 = input.animationPastEnd ? 2 : 1
            return result(
                actionArgument: nextArgument,
                animationID: SM64MarioPunchAnimationID.firstPunch,
                transitionAction: nil,
                flags: input.animationFrame >= 2 ? punchingFlag : 0,
                punchState: nextArgument == 2 ? 4 : nil,
                sound: argument == 0 ? .yah : .none
            )

        case 2:
            if input.animationAtEnd {
                return result(
                    actionArgument: 0,
                    animationID: SM64MarioPunchAnimationID.firstPunchFast,
                    transitionAction: endAction,
                    flags: input.animationFrame <= 0 ? punchingFlag : 0,
                    punchState: nil,
                    sound: .none
                )
            }
            return result(
                actionArgument: input.bPressed ? 3 : 2,
                animationID: SM64MarioPunchAnimationID.firstPunchFast,
                transitionAction: nil,
                flags: input.animationFrame <= 0 ? punchingFlag : 0,
                punchState: nil,
                sound: .none
            )

        case 3, 4:
            let nextArgument: UInt32 = input.animationPastEnd ? 5 : 4
            return result(
                actionArgument: nextArgument,
                animationID: SM64MarioPunchAnimationID.secondPunch,
                transitionAction: nil,
                flags: input.animationFrame > 0 ? punchingFlag : 0,
                punchState: nextArgument == 5 ? (1 << 6) | 4 : nil,
                sound: argument == 3 ? .wah : .none
            )

        case 5:
            if input.animationAtEnd {
                return result(
                    actionArgument: 0,
                    animationID: SM64MarioPunchAnimationID.secondPunchFast,
                    transitionAction: endAction,
                    flags: input.animationFrame <= 0 ? punchingFlag : 0,
                    punchState: nil,
                    sound: .none
                )
            }
            return result(
                actionArgument: input.bPressed ? 6 : 5,
                animationID: SM64MarioPunchAnimationID.secondPunchFast,
                transitionAction: nil,
                flags: input.animationFrame <= 0 ? punchingFlag : 0,
                punchState: nil,
                sound: .none
            )

        case 6:
            return result(
                actionArgument: 6,
                animationID: SM64MarioPunchAnimationID.groundKick,
                transitionAction: input.animationAtEnd ? endAction : nil,
                flags: input.animationFrame >= 0 && input.animationFrame < 8 ? kickingFlag : 0,
                punchState: input.animationFrame == 0 ? (2 << 6) | 6 : nil,
                sound: .hoo
            )

        case 9:
            return result(
                actionArgument: 9,
                animationID: SM64MarioPunchAnimationID.breakdance,
                transitionAction: input.animationAtEnd ? crouchEndAction : nil,
                flags: input.animationFrame >= 2 && input.animationFrame < 8 ? trippingFlag : 0,
                punchState: nil,
                sound: .hoo
            )

        default:
            return nil
        }
    }

    private static func result(
        actionArgument: UInt32,
        animationID: UInt16,
        transitionAction: UInt32?,
        flags: UInt32,
        punchState: UInt8?,
        sound: SM64MarioPunchSoundKind
    ) -> SM64MarioPunchSequenceResult {
        SM64MarioPunchSequenceResult(
            actionArgument: actionArgument,
            animationID: animationID,
            transitionAction: transitionAction,
            flags: flags,
            punchState: punchState,
            sound: sound
        )
    }
}
