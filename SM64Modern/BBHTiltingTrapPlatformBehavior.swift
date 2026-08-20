import Foundation

struct SM64BBHTiltingTrapPlatformInput: Equatable, Sendable {
    let timer: Int32
    let previousAction: Int32
    let distanceToMario: Float
    let angleToMario: Int16
    let facePitch: Int32
    let angleVelocityPitch: Int32
    let marioOnPlatform: Bool
}

struct SM64BBHTiltingTrapPlatformOutput: Equatable, Sendable {
    let action: Int32
    let facePitch: Int32
    let angleVelocityPitch: Int32
}

/// Value counterpart of `bhv_bbh_tilting_trap_platform_loop`. The US timer
/// grace window and Mario/platform relation are explicit inputs; the owner
/// applies only the resulting angle/action mutation.
enum SM64BBHTiltingTrapPlatformBehavior {
    static func update(_ input: SM64BBHTiltingTrapPlatformInput)
        -> SM64BBHTiltingTrapPlatformOutput
    {
        let action: Int32 = input.marioOnPlatform ? 0 : 1
        var facePitch = input.facePitch
        var angleVelocityPitch = input.angleVelocityPitch

        if input.marioOnPlatform {
            let product = SM64DeterministicPrimitives.cFloatMultiply(
                input.distanceToMario,
                SM64CanonicalTrig.coss(input.angleToMario)
            )
            angleVelocityPitch = Int32(product)
            facePitch = facePitch &+ angleVelocityPitch
        } else {
            if abs(facePitch) < 3000 || input.timer >= 16 {
                angleVelocityPitch = 0
                if facePitch > 0 {
                    if facePitch < 200 {
                        facePitch = 0
                    } else {
                        angleVelocityPitch = -200
                    }
                } else if facePitch > -200 {
                    facePitch = 0
                } else {
                    angleVelocityPitch = 200
                }
            }
            facePitch = facePitch &+ angleVelocityPitch
        }
        return SM64BBHTiltingTrapPlatformOutput(
            action: action,
            facePitch: facePitch,
            angleVelocityPitch: angleVelocityPitch
        )
    }
}
