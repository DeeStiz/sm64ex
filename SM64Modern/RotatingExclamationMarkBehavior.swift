import Foundation

struct SM64RotatingExclamationMarkInput: Equatable, Sendable {
    let parentAction: Int32
    let moveYaw: Int32
}

struct SM64RotatingExclamationMarkOutput: Equatable, Sendable {
    let moveYaw: Int32
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_rotating_exclamation_box_loop` plus the
/// following script-authored `ADD_INT(oMoveAngleYaw, 0x800)` command.
enum SM64RotatingExclamationMarkBehavior {
    static func update(_ input: SM64RotatingExclamationMarkInput) -> SM64RotatingExclamationMarkOutput {
        SM64RotatingExclamationMarkOutput(
            moveYaw: input.moveYaw &+ 0x800,
            shouldDelete: input.parentAction != 1
        )
    }
}
