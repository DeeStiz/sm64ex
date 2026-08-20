import Foundation

struct SM64LllSinkingRockBlockInput: Equatable, Sendable {
    let oscillationAngle: Int32
    let positionY: Float
    let homeY: Float
    let marioOnPlatform: Bool
}

struct SM64LllSinkingRockBlockOutput: Equatable, Sendable {
    let oscillationAngle: Int32
    let verticalOffset: Float
    let positionY: Float
    let reachedEndpoint: Bool
}

/// Value counterpart of `bhv_lll_sinking_rock_block_loop` and its shared
/// `lll_octagonal_mesh_find_y_offset` helper.
enum SM64LllSinkingRockBlockBehavior {
    static func update(_ input: SM64LllSinkingRockBlockInput)
        -> SM64LllSinkingRockBlockOutput
    {
        var angle = input.oscillationAngle
        if input.marioOnPlatform { angle = min(angle &+ 124, 0x4000) }
        else { angle = max(angle &- 124, 0) }
        let offset = SM64DeterministicPrimitives.cFloatMultiply(
            SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: angle)),
            -110
        )
        return SM64LllSinkingRockBlockOutput(
            oscillationAngle: angle,
            verticalOffset: offset,
            positionY: input.homeY + offset,
            reachedEndpoint: angle == 0 || angle == 0x4000
        )
    }
}
