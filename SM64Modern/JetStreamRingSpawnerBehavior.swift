import Foundation

struct SM64JetStreamRingSpawnerInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let nextRingIndex: Int32
    let ringsCollected: Int32
}

struct SM64JetStreamRingSpawnerOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let nextRingIndex: Int32
    let spawnRing: Bool
    let ringIndex: Int32
    let spawnStar: Bool
}

/// Value counterpart of `bhv_jet_stream_ring_spawner_loop`.
enum SM64JetStreamRingSpawnerBehavior {
    static func update(_ input: SM64JetStreamRingSpawnerInput) -> SM64JetStreamRingSpawnerOutput {
        var action = input.action
        let timer = input.timer == 300 ? 0 : input.timer
        var nextIndex = input.nextRingIndex
        var spawn = false
        var ringIndex = nextIndex
        var star = false
        if input.action == 0 {
            if input.ringsCollected == 5 {
                action = 1
                star = true
            } else if timer == 0 || timer == 50 || timer == 150 || timer == 200 || timer == 250 {
                spawn = true
                ringIndex = nextIndex
                nextIndex = nextIndex >= 10_000 ? 0 : nextIndex + 1
            }
        }
        return .init(action: action, timer: timer &+ 1, nextRingIndex: nextIndex, spawnRing: spawn, ringIndex: ringIndex, spawnStar: star)
    }
}
