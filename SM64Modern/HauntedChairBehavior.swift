import Foundation

struct SM64HauntedChairInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
    let forwardVelocity: Float
    let hasPianoParent: Bool
    let nearPiano: Bool
    let distanceToMario: Float
    let launchCountdown: Int32
    let hitGroundOrWall: Bool
}

struct SM64HauntedChairOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
    let forwardVelocity: Float
    let launchCountdown: Int32
    let facePitch: Int32
    let faceRoll: Int32
    let shouldDelete: Bool
    let playMoveSound: Bool
    let playLaunchSound: Bool
}

/// Value counterpart of the Haunted Chair initialization and two action loop.
enum SM64HauntedChairBehavior {
    static func update(_ input: SM64HauntedChairInput) -> SM64HauntedChairOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var velocityY = input.velocityY
        var forwardVelocity = input.forwardVelocity
        var countdown = input.launchCountdown
        var pitch: Int32 = 0
        var roll: Int32 = 0
        var shouldDelete = false
        var moveSound = false
        var launchSound = false

        if input.action == 0 {
            if input.hasPianoParent {
                if input.nearPiano { roll = input.timer & 1 == 0 ? 0x400 : -0x400 }
            } else {
                if input.distanceToMario < 500 { timer = 0 }
                else if input.timer > 30 { action = 1; timer = 0; countdown = 40 }
                if input.timer & 8 != 0 { pitch = input.timer & 1 == 0 ? 200 : -200; roll = pitch; moveSound = pitch < 0 }
            }
        } else if input.action == 1 {
            if input.timer < 50 { velocityY = 6 }
            else { velocityY = 0 }
            position.y += velocityY
            if input.timer >= 70 && countdown > 0 {
                countdown -= 1
                if countdown == 0 { forwardVelocity = 50; launchSound = true }
                else if countdown > 20 { roll = input.timer &* 0x2710 }
            } else if countdown == 0 && input.hitGroundOrWall {
                shouldDelete = true
            }
        }
        return .init(action: action, timer: timer, position: position, velocityY: velocityY, forwardVelocity: forwardVelocity, launchCountdown: countdown, facePitch: pitch, faceRoll: roll, shouldDelete: shouldDelete, playMoveSound: moveSound, playLaunchSound: launchSound)
    }
}
