import Foundation

enum SM64WarpVariant: UInt8, Equatable, Sendable {
    case normal = 0
    case fading = 1
    case pipe = 2
    case exitPodium = 3
}

struct SM64WarpInput: Equatable, Sendable {
    let variant: SM64WarpVariant
    let behaviorByte: UInt8
    let timer: Int32
    let interactionStatus: Int32
}

struct SM64WarpOutput: Equatable, Sendable {
    let variant: SM64WarpVariant
    let hitboxRadius: Float
    let hitboxHeight: Float
    let interactionSubtype: UInt32
    let clearInteraction: Bool
    let collisionModel: Bool
    let collisionDataIdentity: UInt64
}

/// Value counterpart of `bhv_warp_loop` and `bhv_fading_warp_loop`.
enum SM64WarpBehavior {
    static func update(_ input: SM64WarpInput) -> SM64WarpOutput {
        let radius: Float
        switch input.variant {
        case .exitPodium:
            radius = 50
        case .normal, .fading, .pipe:
            switch input.behaviorByte {
            case 0x00:
                radius = input.variant == .fading ? 85 : 50
            case 0xFF:
                radius = 10_000
            default:
                radius = Float(input.behaviorByte) * 10
            }
        }
        return SM64WarpOutput(
            variant: input.variant,
            hitboxRadius: radius,
            hitboxHeight: input.variant == .pipe ? 50 : 50,
            interactionSubtype: input.variant == .fading ? 1 : 0,
            clearInteraction: true,
            collisionModel: input.variant == .pipe || input.variant == .exitPodium,
            collisionDataIdentity: input.variant == .exitPodium ? 0x74746D5F706F6469 : 0
        )
    }
}
