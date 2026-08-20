import Foundation

enum SM64BlueFishAction: Int32, Equatable, Sendable {
    case dive = 0
    case turn = 1
    case ascend = 2
    case turnBack = 3
}

struct SM64BlueFishInput: Equatable, Sendable {
    let action: SM64BlueFishAction
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let facePitch: Int32
    let angleVelocityPitch: Int32
    let forwardVelocity: Float
    let randomAngle: Int32
    let randomVelocity: Float
    let randomTime: Int32
    let parentDuplicate: Bool
}

struct SM64BlueFishOutput: Equatable, Sendable {
    let action: SM64BlueFishAction
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let facePitch: Int32
    let angleVelocityPitch: Int32
    let forwardVelocity: Float
    let velocity: SM64ObjectVector3
    let animationAcceleration: Float
    let shouldDelete: Bool
}

struct SM64TankFishGroupOutput: Equatable, Sendable {
    let action: Int32
    let spawnFish: Bool
    let childCount: Int
}

enum SM64BlueFishBehavior {
    static func update(_ input: SM64BlueFishInput) -> SM64BlueFishOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var moveYaw = input.moveYaw
        var facePitch = input.facePitch
        var forwardVelocity = input.forwardVelocity
        var velocity = SM64ObjectVector3.zero
        var animationAcceleration: Float = 1

        switch input.action {
        case .dive:
            forwardVelocity = input.randomVelocity + 3
            animationAcceleration = 1
            if input.timer >= input.randomTime + 60 { action = .turn; timer = 0 }
            if input.timer < (input.randomTime + 60) / 2 {
                facePitch &+= input.angleVelocityPitch
            } else {
                facePitch &-= input.angleVelocityPitch
            }
        case .turn:
            animationAcceleration = 2
            moveYaw &+= input.randomAngle
            if input.timer == 15 { action = .ascend; timer = 0 }
        case .ascend:
            animationAcceleration = 1
            if input.timer >= input.randomTime + 60 { action = .turnBack; timer = 0 }
            if input.timer < (input.randomTime + 60) / 2 {
                facePitch &-= input.angleVelocityPitch
            } else {
                facePitch &+= input.angleVelocityPitch
            }
        case .turnBack:
            animationAcceleration = 2
            moveYaw &+= input.randomAngle
            if input.timer == 15 { action = .dive; timer = 0 }
        }

        velocity.y = -SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: facePitch)) * forwardVelocity
        position.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw)) * forwardVelocity
        position.y += velocity.y
        position.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw)) * forwardVelocity

        return .init(
            action: action,
            timer: timer,
            position: position,
            moveYaw: moveYaw,
            facePitch: facePitch,
            angleVelocityPitch: facePitch &- input.facePitch,
            forwardVelocity: forwardVelocity,
            velocity: velocity,
            animationAcceleration: animationAcceleration,
            shouldDelete: input.parentDuplicate
        )
    }

    static func updateTankFishGroup(action: Int32, room: Int32) -> SM64TankFishGroupOutput {
        switch action {
        case 0 where room == 15 || room == 7:
            return .init(action: 1, spawnFish: true, childCount: 15)
        case 1 where room != 15 && room != 7:
            return .init(action: 2, spawnFish: false, childCount: 0)
        case 2:
            return .init(action: 0, spawnFish: false, childCount: 0)
        default:
            return .init(action: action, spawnFish: false, childCount: 0)
        }
    }
}
