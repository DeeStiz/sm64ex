import Foundation

struct SM64DddWarpInput: Equatable, Sendable {
    let paintingBeaten: Bool
}

struct SM64DddWarpOutput: Equatable, Sendable {
    let collisionDataIdentity: UInt64
    let collisionDistance: Float
    let shouldLoadCollisionModel: Bool
}

/// Value counterpart of `bhv_ddd_warp_loop`.
enum SM64DddWarpBehavior {
    static let preBossCollisionIdentity: UInt64 = 0x6464_645F_777031
    static let postBossCollisionIdentity: UInt64 = 0x6464_645F_777032
    static let collisionDistance: Float = 30_000

    static func update(_ input: SM64DddWarpInput) -> SM64DddWarpOutput {
        SM64DddWarpOutput(
            collisionDataIdentity: input.paintingBeaten ? postBossCollisionIdentity : preBossCollisionIdentity,
            collisionDistance: collisionDistance,
            shouldLoadCollisionModel: true
        )
    }
}
