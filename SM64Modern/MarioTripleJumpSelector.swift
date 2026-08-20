import Foundation

enum SM64MarioTripleJumpIntent: UInt8, Equatable, Sendable {
    case flyingTripleJump = 0
    case tripleJump = 1
    case jump = 2
}

struct SM64MarioTripleJumpSelectorInput: Equatable, Sendable {
    let marioFlags: UInt32
    let forwardVelocity: Float
}

struct SM64MarioTripleJumpSelectorResult: Equatable, Sendable {
    let action: UInt32
    let actionArgument: UInt32
    let intent: SM64MarioTripleJumpIntent
}

/// Value counterpart of `set_triple_jump_action`; C retains action install.
enum SM64MarioTripleJumpSelector {
    private static let marioWingCap: UInt32 = 0x0000_0008

    static func update(
        _ input: SM64MarioTripleJumpSelectorInput
    ) -> SM64MarioTripleJumpSelectorResult? {
        guard input.forwardVelocity.isFinite else { return nil }
        if input.marioFlags & marioWingCap != 0 {
            return SM64MarioTripleJumpSelectorResult(
                action: SM64MarioActionID.flyingTripleJump,
                actionArgument: 0,
                intent: .flyingTripleJump
            )
        }
        if input.forwardVelocity > 20 {
            return SM64MarioTripleJumpSelectorResult(
                action: SM64MarioActionID.tripleJump,
                actionArgument: 0,
                intent: .tripleJump
            )
        }
        return SM64MarioTripleJumpSelectorResult(
            action: SM64MarioActionID.jump,
            actionArgument: 0,
            intent: .jump
        )
    }
}
