import Foundation

struct SM64WaterDropletInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocityY: Float
    let timer: Int32
    let waterLevel: Float
    let interacted: Bool
}

struct SM64WaterDropletOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let velocityY: Float
    let timer: Int32
    let shouldDelete: Bool
    let spawnSplash: Bool
}

/// Value counterpart of `bhv_water_droplet_loop`.
enum SM64WaterDropletBehavior {
    static func update(_ input: SM64WaterDropletInput) -> SM64WaterDropletOutput {
        let velocityY = input.velocityY - 4
        var position = input.position
        position.y += velocityY
        var spawnSplash = false
        var shouldDelete = false
        if velocityY < 0 {
            if input.waterLevel > position.y {
                spawnSplash = true
                shouldDelete = true
            } else if input.timer > 20 {
                shouldDelete = true
            }
        }
        if input.waterLevel < -10_000 { shouldDelete = true }
        if input.interacted { shouldDelete = true }
        return SM64WaterDropletOutput(
            position: position,
            velocityY: velocityY,
            timer: input.timer &+ 1,
            shouldDelete: shouldDelete,
            spawnSplash: spawnSplash
        )
    }
}
