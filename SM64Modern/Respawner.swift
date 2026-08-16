import Foundation

/// Value-only counterpart of `bhv_respawner_loop`. The C loop spawns its
/// configured object once Mario is outside the minimum radius, copies the
/// behavior parameters, and deactivates the respawner in the same callback.
struct SM64RespawnerState: Equatable, Sendable {
    let modelToRespawn: UInt32
    let behaviorToRespawn: UInt64
    let minSpawnDistance: Float
    let behaviorParams: Int32
    var timer: UInt32 = 0
    var markedForDeletion = false
}

struct SM64RespawnerTickInput: Equatable, Sendable {
    let distanceToMario: Float

    init(distanceToMario: Float = .greatestFiniteMagnitude) {
        self.distanceToMario = distanceToMario
    }
}

struct SM64RespawnerEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let spawnObject = Self(rawValue: 1 << 0)
    static let markForDeletion = Self(rawValue: 1 << 1)
}

struct SM64RespawnerTickResult: Equatable, Sendable {
    let effects: SM64RespawnerEffect
    let state: SM64RespawnerState
}

enum SM64RespawnerKernel {
    static func tick(
        _ input: SM64RespawnerTickInput,
        state: inout SM64RespawnerState
    ) -> SM64RespawnerTickResult {
        var effects: SM64RespawnerEffect = []
        if !state.markedForDeletion,
           input.distanceToMario.isFinite,
           state.minSpawnDistance.isFinite,
           input.distanceToMario > state.minSpawnDistance {
            state.markedForDeletion = true
            effects.insert([.spawnObject, .markForDeletion])
        }
        state.timer &+= 1
        return SM64RespawnerTickResult(effects: effects, state: state)
    }
}
