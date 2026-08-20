import Foundation

enum SM64SmallPiranhaFlameMode: UInt8, Equatable, Sendable { case ephemeral = 0; case projectile = 1 }

struct SM64SmallPiranhaFlameInput: Equatable, Sendable {
    let mode: SM64SmallPiranhaFlameMode
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let currentSpeed: Float
    let targetSpeed: Float
    let targetYaw: Int32
    let timer: Int32
    let scaleZ: Float
    let animationState: Int32
    let graphYOffset: Float
    let distanceTravelled: Float
    let flyGuySpawnTimer: Int32
    let flyGuySpawnInterval: Int32
    let randomScaleJitter: Float
    let initialAnimationState: Int32
    let moveFlags: UInt32
}

struct SM64SmallPiranhaFlameOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let currentSpeed: Float
    let velocityY: Float
    let scaleX: Float
    let scaleY: Float
    let animationState: Int32
    let graphYOffset: Float
    let distanceTravelled: Float
    let spawnChildFlame: Bool
    let spawnFlyGuyFlame: Bool
    let nextFlyGuySpawnTimer: Int32
    let shouldDelete: Bool
}

enum SM64SmallPiranhaFlameBehavior {
    private static func approach(_ value: Float, _ target: Float, _ amount: Float) -> Float {
        if value < target { return min(value + amount, target) }
        return max(value - amount, target)
    }

    private static func approachYaw(_ value: Int32, _ target: Int32, _ amount: Int32) -> Int32 {
        let delta = Int16(truncatingIfNeeded: target &- value)
        if abs(Int(delta)) <= amount { return target }
        return value &+ (delta > 0 ? amount : -amount)
    }

    static func update(_ input: SM64SmallPiranhaFlameInput) -> SM64SmallPiranhaFlameOutput {
        if input.mode == .ephemeral {
            let jitter = input.randomScaleJitter
            let scaleY = input.scaleZ * (1 + 0.7 * jitter)
            return SM64SmallPiranhaFlameOutput(position: input.position, moveYaw: input.moveYaw, currentSpeed: input.currentSpeed, velocityY: 0, scaleX: input.scaleZ * (0.9 - 0.5 * jitter), scaleY: scaleY, animationState: input.timer == 0 ? input.initialAnimationState : input.animationState, graphYOffset: 15 * scaleY, distanceTravelled: input.distanceTravelled, spawnChildFlame: false, spawnFlyGuyFlame: false, nextFlyGuySpawnTimer: input.flyGuySpawnTimer, shouldDelete: input.timer > 0)
        }
        let speed = approach(input.currentSpeed, input.targetSpeed, 0.6)
        var yaw = input.moveYaw
        if speed == input.targetSpeed { yaw = approachYaw(yaw, input.targetYaw, 0x200) }
        let pitch = Int16(truncatingIfNeeded: input.movePitch)
        let yaw16 = Int16(truncatingIfNeeded: yaw)
        let forward = speed * SM64CanonicalTrig.coss(pitch)
        let velocityY = speed * -SM64CanonicalTrig.sins(pitch)
        var position = input.position
        position.x += forward * SM64CanonicalTrig.sins(yaw16)
        position.y += velocityY
        position.z += forward * SM64CanonicalTrig.coss(yaw16)
        let distance = input.distanceTravelled + abs(speed)
        let spawnFly = input.timer > input.flyGuySpawnTimer
        let nextTimer = spawnFly ? input.timer : input.flyGuySpawnTimer
        return SM64SmallPiranhaFlameOutput(position: position, moveYaw: yaw, currentSpeed: speed, velocityY: velocityY, scaleX: input.scaleZ, scaleY: input.scaleZ, animationState: input.animationState &+ 1, graphYOffset: 15 * input.scaleZ, distanceTravelled: distance, spawnChildFlame: true, spawnFlyGuyFlame: spawnFly, nextFlyGuySpawnTimer: nextTimer, shouldDelete: distance > 1500 || input.moveFlags & 0x0000_0003 != 0)
    }
}
