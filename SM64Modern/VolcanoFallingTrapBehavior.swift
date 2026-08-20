import Foundation

struct SM64VolcanoFallingTrapInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let distanceToMario: Float
    let positionY: Float
    let homeY: Float
    let facePitch: Int32
    let angleVelocityPitch: Int32
    let acceleration: Float
}

struct SM64VolcanoFallingTrapOutput: Equatable, Sendable {
    let action: Int32
    let positionY: Float
    let facePitch: Int32
    let angleVelocityPitch: Int32
    let acceleration: Float
    let playQuietPound: Bool
    let playBigPound: Bool
    let playRiseSound: Bool
    let shakeCamera: Bool
}

/// Value counterpart of `bhv_volcano_trap_loop`.
enum SM64VolcanoFallingTrapBehavior {
    static func update(_ input: SM64VolcanoFallingTrapInput) -> SM64VolcanoFallingTrapOutput {
        var action = input.action
        var positionY = input.positionY
        var facePitch = input.facePitch
        var angleVelocityPitch = input.angleVelocityPitch
        var acceleration = input.acceleration
        var quietPound = false
        var bigPound = false
        var riseSound = false
        var shakeCamera = false

        switch action {
        case 0:
            if input.distanceToMario < 1_000 {
                action = 1
                quietPound = true
            }
        case 1:
            acceleration += 4
            angleVelocityPitch += Int32(acceleration)
            facePitch &-= angleVelocityPitch
            if facePitch < -0x4000 {
                facePitch = -0x4000
                angleVelocityPitch = 0
                acceleration = 0
                action = 2
                bigPound = true
                shakeCamera = true
            }
        case 2:
            if input.timer < 8 {
                let angle = Int16(truncatingIfNeeded: input.timer * 0x1000)
                positionY = input.homeY + SM64CanonicalTrig.sins(angle) * 10
            }
            if input.timer == 50 {
                action = 3
                riseSound = true
            }
        case 3:
            angleVelocityPitch = 0x90
            facePitch &+= angleVelocityPitch
            if facePitch > 0 { facePitch = 0 }
            if input.timer == 200 { action = 0 }
        default:
            action = 0
        }

        return .init(
            action: action,
            positionY: positionY,
            facePitch: facePitch,
            angleVelocityPitch: angleVelocityPitch,
            acceleration: acceleration,
            playQuietPound: quietPound,
            playBigPound: bigPound,
            playRiseSound: riseSound,
            shakeCamera: shakeCamera
        )
    }
}
