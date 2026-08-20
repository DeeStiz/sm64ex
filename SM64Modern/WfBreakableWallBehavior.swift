import Foundation

struct SM64WfBreakableWallInput: Equatable, Sendable {
    let marioShotFromCannon: Bool
    let collidedWithMario: Bool
    let rightVariant: Bool
}

struct SM64WfBreakableWallOutput: Equatable, Sendable {
    let tangible: Bool
    let exploded: Bool
    let playPuzzleJingle: Bool
    let playWallExplosion: Bool
    let interactionType: UInt32
    let damageOrCoinValue: Int32
    let spawnCoins: Int32
}

/// Value counterpart of `bhv_wf_breakable_wall_loop`.
enum SM64WfBreakableWallBehavior {
    static func update(_ input: SM64WfBreakableWallInput) -> SM64WfBreakableWallOutput {
        let tangible = input.marioShotFromCannon
        let exploded = tangible && input.collidedWithMario
        return .init(
            tangible: tangible,
            exploded: exploded,
            playPuzzleJingle: exploded && input.rightVariant,
            playWallExplosion: exploded,
            interactionType: exploded ? 8 : 0,
            damageOrCoinValue: exploded ? 1 : 0,
            spawnCoins: exploded ? 1 : 0
        )
    }
}
