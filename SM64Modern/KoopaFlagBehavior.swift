import Foundation

struct SM64KoopaFlagInput: Equatable, Sendable {
    let timer: Int32
    let positionY: Float
    let hitboxHeight: Float
    let marioY: Float
    let marioPunching: Bool
}

struct SM64KoopaFlagOutput: Equatable, Sendable {
    let timer: Int32
    let pushMarioAway: Bool
}

/// Value counterpart of the shared `bhv_pole_base_loop` used by
/// `bhvKoopaFlag`. C keeps the pointer mutation and presentation; Swift owns
/// the fixed-width collision gate and its per-tick decision.
enum SM64KoopaFlagBehavior {
    static func update(_ input: SM64KoopaFlagInput) -> SM64KoopaFlagOutput {
        let insideVerticalRange = input.positionY - 10.0 < input.marioY
            && input.marioY < input.positionY + input.hitboxHeight + 30.0
        let push = input.timer > 10 && insideVerticalRange && !input.marioPunching
        return .init(timer: input.timer &+ 1, pushMarioAway: push)
    }
}
