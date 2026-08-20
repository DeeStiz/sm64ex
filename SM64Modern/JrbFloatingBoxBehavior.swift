import Foundation

struct SM64JrbFloatingBoxInput: Equatable, Sendable {
    let timer: Int32
    let homeY: Float
}

struct SM64JrbFloatingBoxOutput: Equatable, Sendable {
    let timer: Int32
    let positionY: Float
}

/// Value counterpart of `bhv_jrb_floating_box_loop`.
enum SM64JrbFloatingBoxBehavior {
    static func update(_ input: SM64JrbFloatingBoxInput) -> SM64JrbFloatingBoxOutput {
        .init(timer: input.timer &+ 1, positionY: input.homeY + SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.timer &* 0x400)) * 10)
    }
}
