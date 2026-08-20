import Foundation

enum SM64FirePiranhaPlantAction: Int32, Equatable, Sendable { case hide = 0; case grow = 1 }

struct SM64FirePiranhaPlantInput: Equatable, Sendable {
    let neutralScale: Float
    let scale: Float
    let action: SM64FirePiranhaPlantAction
    let timer: Int32
    let moveYaw: Int32
    let angleToMario: Int32
    let distanceToMario: Float
    let active: Bool
    let activePlantCount: Int32
    let health: Int32
    let behaviorVariant: Int32
    let deathSpinTimer: Int32
    let deathSpinVelocity: Float
    let animationFrame: Int32
    let renderingEnabled: Bool
    let nearAnimationEnd: Bool
    let attacked: Bool
    let killedCount: Int32
}

struct SM64FirePiranhaPlantOutput: Equatable, Sendable {
    let neutralScale: Float
    let scale: Float
    let action: SM64FirePiranhaPlantAction
    let timer: Int32
    let moveYaw: Int32
    let active: Bool
    let activePlantCount: Int32
    let health: Int32
    let deathSpinTimer: Int32
    let deathSpinVelocity: Float
    let animationState: Int32
    let spawnFlame: Bool
    let shouldDelete: Bool
    let killedCount: Int32
}

enum SM64FirePiranhaPlantBehavior {
    private static func approach(_ value: Float, _ target: Float, _ amount: Float) -> (Float, Bool) {
        if abs(value - target) <= amount { return (target, true) }
        return (value + (value < target ? amount : -amount), false)
    }
    private static func approachYaw(_ value: Int32, _ target: Int32, _ amount: Int32) -> Int32 {
        let delta = Int16(truncatingIfNeeded: target &- value)
        if abs(Int(delta)) <= amount { return target }
        return value &+ (delta > 0 ? amount : -amount)
    }

    static func update(_ input: SM64FirePiranhaPlantInput) -> SM64FirePiranhaPlantOutput {
        var scale = input.scale
        var action = input.action
        var timer = input.timer
        var yaw = input.moveYaw
        var active = input.active
        var activeCount = input.activePlantCount
        var health = input.health
        var spinTimer = input.deathSpinTimer
        var spinVelocity = input.deathSpinVelocity
        var killedCount = input.killedCount
        var spawn = false
        var shouldDelete = false

        if input.attacked {
            health -= 1
            action = .hide
            spinTimer = 10
            spinVelocity = 8000
        }
        if spinTimer != 0 {
            yaw &+= Int32(spinVelocity)
            spinVelocity += spinVelocity > 0 ? -min(spinVelocity, 200) : min(-spinVelocity, 200)
            if input.nearAnimationEnd { spinTimer -= 1 }
        } else if action == .hide {
            let result = approach(scale, 0, 0.04 * input.neutralScale)
            scale = result.0
            if result.1 {
                if active { active = false; activeCount = max(0, activeCount - 1); if input.behaviorVariant != 0 && health == 0 { killedCount += 1; shouldDelete = true } }
                else if activeCount < 2 && timer > 100 && input.distanceToMario > 100 && input.distanceToMario < 800 { active = true; activeCount += 1; action = .grow; yaw = input.angleToMario }
            }
        } else {
            let result = approach(scale, input.neutralScale, 0.04 * input.neutralScale)
            scale = result.0
            if result.1 {
                if timer > 80 { action = .hide }
                else if timer < 50 { yaw = approachYaw(yaw, input.angleToMario, 0x400) }
                else if input.renderingEnabled && input.animationFrame == 56 { spawn = true }
            }
        }
        timer = action == input.action ? timer + 1 : 0
        return SM64FirePiranhaPlantOutput(neutralScale: input.neutralScale, scale: scale, action: action, timer: timer, moveYaw: yaw, active: active, activePlantCount: activeCount, health: health, deathSpinTimer: spinTimer, deathSpinVelocity: spinVelocity, animationState: input.animationFrame, spawnFlame: spawn, shouldDelete: shouldDelete, killedCount: killedCount)
    }
}
