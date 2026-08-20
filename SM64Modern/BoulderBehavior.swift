import Foundation

enum SM64BoulderAction: UInt8, Equatable, Sendable { case initialize = 0; case rolling = 1 }

struct SM64BoulderInput: Equatable, Sendable {
    let action: SM64BoulderAction
    let position: SM64ObjectVector3
    let velocityY: Float
    let forwardVelocity: Float
    let moveYaw: Int32
    let facePitch: Int32
    let stepFlags: UInt32
}

struct SM64BoulderOutput: Equatable, Sendable {
    let action: SM64BoulderAction
    let position: SM64ObjectVector3
    let velocityY: Float
    let forwardVelocity: Float
    let moveYaw: Int32
    let facePitch: Int32
    let scale: Float
    let graphYOffset: Float
    let hitboxRadius: Float
    let hitboxHeight: Float
    let soundRoll: Bool
    let soundImpact: Bool
    let spawnMist: Bool
    let shouldDelete: Bool
}

enum SM64BoulderBehavior {
    static func update(_ input: SM64BoulderInput) -> SM64BoulderOutput {
        var action = input.action
        var forwardVelocity = input.forwardVelocity
        var facePitch = input.facePitch
        var soundRoll = false
        var soundImpact = false
        var spawnMist = false
        if input.action == .initialize {
            action = .rolling
            forwardVelocity = 40
        } else {
            if (input.stepFlags & 0x09) == 0x01 && input.velocityY > 10 { soundRoll = true; spawnMist = true }
            if forwardVelocity > 70 { forwardVelocity = 70 }
            facePitch &+= Int32(forwardVelocity * (100.0 / 1.5))
            soundImpact = true
        }
        return .init(
            action: action,
            position: input.position,
            velocityY: input.velocityY,
            forwardVelocity: forwardVelocity,
            moveYaw: input.moveYaw,
            facePitch: facePitch,
            scale: 1.5,
            graphYOffset: 270,
            hitboxRadius: 210,
            hitboxHeight: 350,
            soundRoll: soundRoll,
            soundImpact: soundImpact,
            spawnMist: spawnMist,
            shouldDelete: input.position.y < -1000
        )
    }
}
