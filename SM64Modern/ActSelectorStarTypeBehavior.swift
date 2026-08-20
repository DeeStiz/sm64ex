import Foundation

enum SM64ActSelectorStarType: UInt8, Equatable, Sendable {
    case notSelected = 0
    case selected = 1
    case oneHundredCoins = 2
}

struct SM64ActSelectorStarTypeInput: Equatable, Sendable {
    let type: SM64ActSelectorStarType
    let size: Float
    let faceYaw: Int32
    let timer: Int32
}

struct SM64ActSelectorStarTypeOutput: Equatable, Sendable {
    let type: SM64ActSelectorStarType
    let size: Float
    let faceYaw: Int32
    let timer: Int32
    let scale: Float
}

/// Value counterpart of `bhv_act_selector_star_type_loop`.
enum SM64ActSelectorStarTypeBehavior {
    static func update(_ input: SM64ActSelectorStarTypeInput) -> SM64ActSelectorStarTypeOutput {
        var size = input.size
        var faceYaw = input.faceYaw
        switch input.type {
        case .notSelected:
            size = max(size - 0.1, 1)
            faceYaw = 0
        case .selected:
            size = min(size + 0.1, 1.3)
            faceYaw &+= 0x800
        case .oneHundredCoins:
            faceYaw &+= 0x800
        }
        return .init(type: input.type, size: size, faceYaw: faceYaw, timer: input.timer &+ 1, scale: size)
    }
}
