import Foundation

enum SM64EndBirdsRole: UInt8, Equatable, Sendable { case birds1 = 0; case birds2 = 1 }

struct SM64EndBirdsInput: Equatable, Sendable {
    let role: SM64EndBirdsRole
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let targetPosition: SM64ObjectVector3
    let cutsceneTimer: Int32
    let endBirdVelocity: Float
}

struct SM64EndBirdsOutput: Equatable, Sendable {
    let role: SM64EndBirdsRole
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let scale: Float
    let forwardVelocity: Float
    let shouldDelete: Bool
    let playFlyAwaySound: Bool
}

/// Value counterpart of `bhv_end_birds_1_loop` and `bhv_end_birds_2_loop`.
enum SM64EndBirdsBehavior {
    static func update(_ input: SM64EndBirdsInput) -> SM64EndBirdsOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        let scale: Float = 0.7
        var forwardVelocity = input.endBirdVelocity
        var shouldDelete = false
        var sound = false

        if input.action == 0 {
            action = 1
            timer = 0
            if input.role == .birds2 { forwardVelocity = 30 }
        } else {
            if input.role == .birds1 {
                if input.timer < 100 { position = approach(position, target: input.targetPosition, fraction: 0.08) }
                if input.cutsceneTimer == 0 { shouldDelete = true }
            } else {
                position = approach(position, target: input.targetPosition, fraction: 0.04)
            }
            sound = timer == 1
        }
        return .init(role: input.role, action: action, timer: timer, position: position, scale: scale, forwardVelocity: forwardVelocity, shouldDelete: shouldDelete, playFlyAwaySound: sound)
    }

    private static func approach(_ value: SM64ObjectVector3, target: SM64ObjectVector3, fraction: Float) -> SM64ObjectVector3 {
        .init(x: value.x + (target.x - value.x) * fraction, y: value.y + (target.y - value.y) * fraction, z: value.z + (target.z - value.z) * fraction)
    }
}
