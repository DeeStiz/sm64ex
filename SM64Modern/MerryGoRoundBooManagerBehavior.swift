import Foundation

struct SM64MerryGoRoundBooManagerOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let spawnSmallBoo: Bool
    let spawnBigBoo: Bool
}

enum SM64MerryGoRoundBooManagerBehavior {
    static func update(action: Int32, timer: Int32, distanceToMario: Float, boosKilled: Int32, boosSpawned: Int32) -> SM64MerryGoRoundBooManagerOutput {
        if action == 0, distanceToMario < 1_000 {
            if boosKilled > 4 { return .init(action: 2, timer: timer &+ 1, spawnSmallBoo: false, spawnBigBoo: true) }
            if boosSpawned != 5 && boosSpawned - boosKilled < 2 { return .init(action: 1, timer: 0, spawnSmallBoo: true, spawnBigBoo: false) }
        } else if action == 1, timer > 60 {
            return .init(action: 0, timer: 0, spawnSmallBoo: false, spawnBigBoo: false)
        }
        return .init(action: action, timer: timer &+ 1, spawnSmallBoo: false, spawnBigBoo: false)
    }
}
