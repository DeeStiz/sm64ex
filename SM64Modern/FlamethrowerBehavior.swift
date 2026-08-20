import Foundation

struct SM64FlamethrowerInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let action: Int32
    let timer: Int32
    let behaviorParam: Int32
    let distanceToMario: Float
    let activationAllowed: Bool
}

struct SM64FlamethrowerOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let action: Int32
    let timer: Int32
    let spawnFlame: Bool
    let flameBehaviorParam: Int32
    let flameVelocity: Float
    let flameLifetime: Int32
}

enum SM64FlamethrowerBehavior {
    static func update(_ input: SM64FlamethrowerInput) -> SM64FlamethrowerOutput {
        var action = input.action
        var timer = input.timer
        var spawn = false
        let flameParam = input.behaviorParam
        let velocity: Float = input.behaviorParam == 2 ? 50 : 95
        var lifetime: Int32 = 1
        if action == 0 {
            if input.activationAllowed && input.distanceToMario < 2000 {
                action = 1
                timer = 0
            } else {
                timer &+= 1
            }
        } else if action == 1 {
            spawn = true
            lifetime = timer < 60 ? 15 : (timer < 74 ? 75 - timer : 1)
            if timer >= 74 { action = 2 }
            timer &+= 1
        } else if timer > 60 {
            action = 0
            timer = 0
        } else {
            timer &+= 1
        }
        return SM64FlamethrowerOutput(position: input.position, action: action, timer: timer, spawnFlame: spawn, flameBehaviorParam: flameParam, flameVelocity: velocity, flameLifetime: lifetime)
    }
}
