import Foundation

struct SM64SlidingSnowMoundInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let homeZ: Float
}

struct SM64SlidingSnowMoundOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let velocity: SM64ObjectVector3
    let scale: Float
    let playSinkSound: Bool
    let shouldDelete: Bool
}

struct SM64SnowMoundSpawnerInput: Equatable, Sendable {
    let timer: Int32
    let distanceToMario: Float
    let marioY: Float
    let positionY: Float
}

struct SM64SnowMoundSpawnerOutput: Equatable, Sendable {
    let timer: Int32
    let spawnChild: Bool
    let childScale: Float
}

enum SM64SnowMoundBehavior {
    static func updateSliding(_ input: SM64SlidingSnowMoundInput) -> SM64SlidingSnowMoundOutput {
        var action = input.action
        var position = input.position
        var velocity = SM64ObjectVector3.zero
        var sound = false
        var shouldDelete = false
        if input.action == 0 {
            velocity.x = -40
            position.x += velocity.x
            sound = true
            if input.timer >= 118 { action = 1 }
        } else if input.action == 1 {
            velocity = .init(x: -5, y: -10, z: 0)
            position.x += velocity.x
            position.y += velocity.y
            position.z = input.homeZ - 2
            if input.timer > 50 { shouldDelete = true }
        }
        return .init(action: action, timer: input.timer &+ 1, position: position, velocity: velocity, scale: 1, playSinkSound: sound, shouldDelete: shouldDelete)
    }

    static func updateSpawner(_ input: SM64SnowMoundSpawnerInput) -> SM64SnowMoundSpawnerOutput {
        let admitted = input.distanceToMario <= 6_000 && input.positionY + 1_000 >= input.marioY
        let cadence = input.timer == 64 || input.timer == 128 || input.timer == 192 || input.timer == 224 || input.timer == 256
        let spawn = admitted && cadence
        return .init(timer: input.timer >= 256 ? 0 : input.timer &+ 1, spawnChild: spawn, childScale: input.timer == 256 ? 2 : 1)
    }
}
