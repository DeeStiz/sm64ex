import Foundation

enum SM64SimpleAnimationKind: UInt8, Equatable, Sendable {
    case randomTexture = 0
    case unusedSixFrame = 1
}

struct SM64SimpleAnimationInput: Equatable, Sendable {
    let kind: SM64SimpleAnimationKind
    let position: SM64ObjectVector3
    let timer: Int32
    let animationState: Int32
}

struct SM64SimpleAnimationOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let animationState: Int32
    let graphYOffset: Float
    let shouldDeactivate: Bool
}

enum SM64SimpleAnimationBehavior {
    static func update(_ input: SM64SimpleAnimationInput) -> SM64SimpleAnimationOutput {
        let animationState = input.animationState &+ 1
        return SM64SimpleAnimationOutput(
            position: input.position,
            animationState: animationState,
            graphYOffset: input.kind == .randomTexture ? -16 : 0,
            shouldDeactivate: input.kind == .unusedSixFrame && input.timer >= 5
        )
    }
}
