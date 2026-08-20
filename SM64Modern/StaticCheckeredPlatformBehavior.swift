import Foundation

struct SM64StaticCheckeredPlatformInput: Equatable, Sendable {
    let mode: Int32
    let facePitch: Int32
    let faceYaw: Int32
    let faceRoll: Int32
    let velocityPitch: Int32
    let velocityYaw: Int32
    let velocityRoll: Int32
    let debugPitch: Int32
    let debugYaw: Int32
    let debugRoll: Int32
    let debugVelocityPitch: Int32
    let debugVelocityYaw: Int32
    let debugVelocityRoll: Int32
}

struct SM64StaticCheckeredPlatformOutput: Equatable, Sendable {
    let facePitch: Int32
    let faceYaw: Int32
    let faceRoll: Int32
    let velocityPitch: Int32
    let velocityYaw: Int32
    let velocityRoll: Int32
}

/// Value counterpart of `bhv_static_checkered_platform_loop`. The C debug
/// row is supplied explicitly by the owner so this reducer never reaches into
/// a process-global debug array.
enum SM64StaticCheckeredPlatformBehavior {
    static func update(_ input: SM64StaticCheckeredPlatformInput)
        -> SM64StaticCheckeredPlatformOutput
    {
        var pitch = input.facePitch
        var yaw = input.faceYaw
        var roll = input.faceRoll
        var velocityPitch = input.velocityPitch
        var velocityYaw = input.velocityYaw
        var velocityRoll = input.velocityRoll

        if input.mode == 1 {
            pitch = 0
            yaw = 0
            roll = 0
            velocityPitch = 0
            velocityYaw = 0
            velocityRoll = 0
        }
        if input.mode == 2 {
            pitch = input.debugPitch &* 0x1000
            yaw = input.debugYaw &* 0x1000
            roll = input.debugRoll &* 0x1000
        }
        velocityPitch = input.debugVelocityPitch
        velocityYaw = input.debugVelocityYaw
        velocityRoll = input.debugVelocityRoll
        if input.mode == 3 {
            pitch = pitch &+ velocityPitch
            yaw = yaw &+ velocityYaw
            roll = roll &+ velocityRoll
        }
        return SM64StaticCheckeredPlatformOutput(
            facePitch: pitch,
            faceYaw: yaw,
            faceRoll: roll,
            velocityPitch: velocityPitch,
            velocityYaw: velocityYaw,
            velocityRoll: velocityRoll
        )
    }
}
