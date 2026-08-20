import Foundation

struct SM64CcmTouchedStarSpawnInput: Equatable, Sendable {
    let enteredSlide: Bool
    let position: SM64ObjectVector3
}

struct SM64CcmTouchedStarSpawnOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let spawnStar: Bool
    let starPosition: SM64ObjectVector3
    let starHomePosition: SM64ObjectVector3
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_ccm_touched_star_spawn_loop`.
enum SM64CcmTouchedStarSpawnBehavior {
    static let starHomePosition = SM64ObjectVector3(x: 2_500, y: -4_350, z: 5_750)

    static func update(_ input: SM64CcmTouchedStarSpawnInput) -> SM64CcmTouchedStarSpawnOutput {
        guard input.enteredSlide else {
            return .init(position: input.position, spawnStar: false, starPosition: input.position, starHomePosition: starHomePosition, shouldDelete: false)
        }
        return .init(
            position: .init(x: 2_780, y: input.position.y + 100, z: 4_666),
            spawnStar: true,
            starPosition: .init(x: 2_500, y: -4_350, z: 5_750),
            starHomePosition: starHomePosition,
            shouldDelete: true
        )
    }
}
