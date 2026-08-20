import Foundation

struct SM64AnimatedTextureInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let animationState: Int32
    let globalFrame: UInt64
}

struct SM64AnimatedTextureOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let animationState: Int32
}

/// Value counterpart of `bhv_animated_texture_loop` plus the behavior-script
/// `ADD_INT` and `ANIMATE_TEXTURE(oAnimState, 2)` commands.
enum SM64AnimatedTextureBehavior {
    static func update(_ input: SM64AnimatedTextureInput) -> SM64AnimatedTextureOutput {
        var animationState = input.animationState &+ 1
        if input.globalFrame % 2 == 0 {
            animationState &+= 1
        }
        return SM64AnimatedTextureOutput(
            position: input.homePosition,
            animationState: animationState
        )
    }
}
