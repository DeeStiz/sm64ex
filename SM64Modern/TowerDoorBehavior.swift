import Foundation

struct SM64TowerDoorInput: Equatable, Sendable {
    let timer: Int32
    let faceYaw: Int32
    let marioAttacking: Bool
}

struct SM64TowerDoorOutput: Equatable, Sendable {
    let timer: Int32
    let faceYaw: Int32
    let spawnMist: Bool
    let spawnTriangleBreak: Bool
    let spawnedCoins: Int32
    let playWallExplosionSound: Bool
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_tower_door_loop`.
enum SM64TowerDoorBehavior {
    static func update(_ input: SM64TowerDoorInput) -> SM64TowerDoorOutput {
        .init(
            timer: input.timer &+ 1,
            faceYaw: input.timer == 0 ? input.faceYaw &- 0x4000 : input.faceYaw,
            spawnMist: input.marioAttacking,
            spawnTriangleBreak: input.marioAttacking,
            spawnedCoins: input.marioAttacking ? 0 : 0,
            playWallExplosionSound: input.marioAttacking,
            shouldDelete: input.marioAttacking
        )
    }
}
