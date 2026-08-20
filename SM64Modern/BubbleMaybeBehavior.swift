import Foundation

struct SM64BubbleMaybeInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let randomOffsetX: Float
    let randomOffsetY: Float
    let randomOffsetZ: Float
    let randomStepX: Float
    let randomStepY: Float
    let randomStepZ: Float
    let angleF4: Int32
    let angleF8: Int32
    let expansionRateX: Int32
    let expansionRateY: Int32
    let timer: Int32
    let animationState: Int32
}

struct SM64BubbleMaybeOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let scaleX: Float
    let scaleY: Float
    let angleF4: Int32
    let angleF8: Int32
    let animationState: Int32
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_bubble_wave_init` plus
/// `bhv_bubble_maybe_loop`.
enum SM64BubbleMaybeBehavior {
    static func update(_ input: SM64BubbleMaybeInput) -> SM64BubbleMaybeOutput {
        var position = input.position
        if input.timer == 0 {
            position.x += input.randomOffsetX
            position.y += input.randomOffsetY
            position.z += input.randomOffsetZ
        }
        position.x += input.randomStepX
        position.y += input.randomStepY
        position.z += input.randomStepZ
        let scaleX = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.angleF4)) * 0.2 + 1
        let scaleY = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.angleF8)) * 0.2 + 1
        return SM64BubbleMaybeOutput(
            position: position,
            scaleX: scaleX,
            scaleY: scaleY,
            angleF4: input.angleF4 &+ input.expansionRateX,
            angleF8: input.angleF8 &+ input.expansionRateY,
            animationState: input.animationState &+ 1,
            shouldDelete: input.timer >= 59
        )
    }
}
