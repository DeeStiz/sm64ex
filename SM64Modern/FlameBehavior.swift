import Foundation

struct SM64FlameInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let timer: Int32
    let animationState: Int32
}

struct SM64FlameOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let animationState: Int32
    let interactionStatus: Int32
}

enum SM64FlameBehavior {
    static func update(_ input: SM64FlameInput) -> SM64FlameOutput {
        SM64FlameOutput(
            position: input.position,
            // Source `ANIMATE_TEXTURE(oAnimState, 2)` advances every 2 frames.
            animationState: input.timer % 2 == 0 ? input.animationState &+ 1 : input.animationState,
            // The behavior clears this every loop before interaction handling.
            interactionStatus: 0
        )
    }
}
