import Foundation

struct SM64KickableBoardInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let phase: Int32
    let rockSpeed: Float
    let facePitch: Int32
    let angleVelocityPitch: Int32
    let attacked: Bool
    let attackType: Int32
    let attackAboveBoard: Bool
}

struct SM64KickableBoardOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let phase: Int32
    let rockSpeed: Float
    let facePitch: Int32
    let angleVelocityPitch: Int32
    let tangible: Bool
    let fellModel: Bool
    let shouldDelete: Bool
    let playImpactSound: Bool
    let playFallSound: Bool
}

/// Value counterpart of `bhv_kickable_board_loop`.
enum SM64KickableBoardBehavior {
    static func update(_ input: SM64KickableBoardInput) -> SM64KickableBoardOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var phase = input.phase
        var rockSpeed = input.rockSpeed
        var pitch = input.facePitch
        var angleVelocity = input.angleVelocityPitch
        var tangible = true
        var fellModel = false
        var delete = false
        var impact = false
        var fallSound = false
        if input.action == 0 {
            pitch = 0
            if input.attacked { action = 1; timer = 0; phase = 0; rockSpeed = 1600 }
        } else if input.action == 1 {
            pitch = 0
            if input.timer > 30 && input.attacked {
                if input.attackAboveBoard && input.attackType == 2 { action = 2; timer = 0; impact = true }
                else { timer = 0; phase = 0; rockSpeed = 1600 }
            }
            if input.timer != 0 {
                rockSpeed -= 8
                if rockSpeed < 0 { action = 0 }
            } else { phase = 0; rockSpeed = 1600 }
            pitch = Int32(-SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: phase)) * rockSpeed)
            if phase & 0x7FFF == 0 { impact = true }
            phase &+= 0x400
        } else if input.action == 2 {
            tangible = false; fellModel = true
            angleVelocity -= 0x80
            pitch += angleVelocity
            if pitch < -0x4000 { pitch = -0x4000; angleVelocity = 0; action = 3; fallSound = true }
        } else if input.action == 3 {
            fellModel = true
        } else { delete = true }
        return .init(action: action, timer: timer, phase: phase, rockSpeed: rockSpeed, facePitch: pitch, angleVelocityPitch: angleVelocity, tangible: tangible, fellModel: fellModel, shouldDelete: delete, playImpactSound: impact, playFallSound: fallSound)
    }
}
