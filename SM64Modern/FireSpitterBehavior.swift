import Foundation

struct SM64FireSpitterInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let action: Int32
    let timer: Int32
    let scale: Float
    let scaleVelocity: Float
    let distanceToMario: Float
    let targetYaw: Int32
    let inWater: Bool
}

struct SM64FireSpitterOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let action: Int32
    let timer: Int32
    let scale: Float
    let scaleVelocity: Float
    let spawnSmallFlame: Bool
    let smallFlameSpeedStart: Float
    let smallFlameSpeedEnd: Float
    let smallFlamePitch: Int32
}

enum SM64FireSpitterBehavior {
    static func update(_ input: SM64FireSpitterInput) -> SM64FireSpitterOutput {
        var action = input.action
        var timer = input.timer
        var scale = input.scale
        var scaleVelocity = input.scaleVelocity
        var moveYaw = input.moveYaw
        var spawn = false
        if action == 0 {
            scale = max(0.2, scale - 0.002)
            if timer > 150 && input.distanceToMario < 800 && !input.inWater {
                action = 1
                scaleVelocity = 0.05
                timer = 0
            } else {
                timer &+= 1
            }
        } else {
            moveYaw = input.targetYaw
            if timer < 2 {
                scale += scaleVelocity
                scaleVelocity -= 0.01
                if scaleVelocity > -0.03 { timer = 0 }
            } else if timer > 10 {
                if scale > 0.1 { scale = max(0.1, scale - 0.05) }
                if scale < 0.15 && scaleVelocity != 0 {
                    scaleVelocity = 0
                    spawn = true
                }
                if scale <= 0.1 && !spawn { action = 0; timer = 0 }
                else { timer &+= 1 }
            } else {
                timer &+= 1
            }
        }
        return SM64FireSpitterOutput(position: input.position, moveYaw: moveYaw, action: action, timer: timer, scale: scale, scaleVelocity: scaleVelocity, spawnSmallFlame: spawn, smallFlameSpeedStart: 20, smallFlameSpeedEnd: 15, smallFlamePitch: 0x1000)
    }
}
