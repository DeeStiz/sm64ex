import Foundation

struct SM64GiantPoleInput: Equatable, Sendable {
    let timer: Int32
    let position: SM64ObjectVector3
    let hitboxHeight: Float
    let topBallPresent: Bool
}

struct SM64GiantPoleOutput: Equatable, Sendable {
    let timer: Int32
    let position: SM64ObjectVector3
    let hitboxRadius: Float
    let hitboxHeight: Float
    let spawnTopBall: Bool
    let topBallPosition: SM64ObjectVector3
}

/// Value counterpart of the Giant Pole extension around
/// `bhv_pole_base_loop`.
enum SM64GiantPoleBehavior {
    static func update(_ input: SM64GiantPoleInput) -> SM64GiantPoleOutput {
        let spawn = input.timer == 0 && !input.topBallPresent
        return .init(
            timer: input.timer &+ 1,
            position: input.position,
            hitboxRadius: 80,
            hitboxHeight: input.hitboxHeight,
            spawnTopBall: spawn,
            topBallPosition: .init(x: input.position.x, y: input.position.y + input.hitboxHeight + 50, z: input.position.z)
        )
    }
}
