import Foundation

struct SM64LLLSinkingPlatformInput: Equatable, Sendable {
    let rectangularMode: Bool
    let action: Int32
    let oscillationTimer: Int32
    let positionY: Float
    let facePitch: Int32
}

struct SM64LLLSinkingPlatformOutput: Equatable, Sendable {
    let action: Int32
    let oscillationTimer: Int32
    let positionY: Float
    let facePitch: Int32
}

/// Value counterpart of `bhv_lll_sinking_rectangular_platform_loop` and
/// `bhv_lll_sinking_square_platforms_loop`. The authored yaw/identity branch
/// is reduced to an explicit rectangular-mode input.
enum SM64LLLSinkingPlatformBehavior {
    static func update(_ input: SM64LLLSinkingPlatformInput)
        -> SM64LLLSinkingPlatformOutput
    {
        var action = input.action
        var oscillationTimer = input.oscillationTimer
        var positionY = input.positionY
        var facePitch = input.facePitch

        if input.rectangularMode {
            switch input.action {
            case 0:
                action = 1
            case 1:
                let displacement = SM64DeterministicPrimitives.cFloatMultiply(
                    SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: oscillationTimer)),
                    0.4
                )
                positionY -= displacement
                oscillationTimer &+= 0x100
            default:
                break
            }
        } else {
            facePitch = Int32(
                SM64DeterministicPrimitives.cFloatMultiply(
                    SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: oscillationTimer)),
                    512
                )
            )
            oscillationTimer &+= 0x100
        }

        return SM64LLLSinkingPlatformOutput(
            action: action,
            oscillationTimer: oscillationTimer,
            positionY: positionY,
            facePitch: facePitch
        )
    }
}
