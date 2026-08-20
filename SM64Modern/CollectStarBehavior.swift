import Foundation

enum SM64CollectStarModel: UInt8, Equatable, Sendable {
    case star = 0
    case transparentStar = 1
}

struct SM64CollectStarInput: Equatable, Sendable {
    let starCollected: Bool
    let faceYaw: Int32
    let interactionStatus: Int32
}

struct SM64CollectStarOutput: Equatable, Sendable {
    let model: SM64CollectStarModel
    let faceYaw: Int32
    let hitboxRadius: Float
    let hitboxHeight: Float
    let shouldDelete: Bool
    let clearInteraction: Bool
}

/// Value counterpart of `bhv_collect_star_init` and `bhv_collect_star_loop`.
enum SM64CollectStarBehavior {
    static func update(_ input: SM64CollectStarInput) -> SM64CollectStarOutput {
        SM64CollectStarOutput(
            model: input.starCollected ? .transparentStar : .star,
            faceYaw: input.faceYaw &+ 0x800,
            hitboxRadius: 80,
            hitboxHeight: 50,
            shouldDelete: input.interactionStatus != 0,
            clearInteraction: true
        )
    }
}
