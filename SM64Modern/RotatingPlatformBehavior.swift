import Foundation

struct SM64RotatingPlatformInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    /// The signed high behavior byte (`oBehParams >> 24`).
    let speedByte: Int8
    let faceYaw: Int16
}

struct SM64RotatingPlatformOutput: Equatable, Sendable {
    let action: Int32
    let angleVelocityYaw: Int16
    let faceYaw: Int16
    let playsLoopSound: Bool
}

/// Value counterpart of `bhv_wf_rotating_wooden_platform_loop`'s action
/// machine and the common `bhv_rotating_platform_loop` yaw update.
enum SM64RotatingPlatformBehavior {
    static func update(_ input: SM64RotatingPlatformInput) -> SM64RotatingPlatformOutput {
        var action = input.action
        var angleVelocityYaw: Int16 = 0
        var playsLoopSound = false
        if input.action == 0 {
            if input.timer > 60 { action += 1 }
        } else {
            angleVelocityYaw = Int16(truncatingIfNeeded: Int32(input.speedByte) << 4)
            if input.timer > 126 { action = 0 }
            playsLoopSound = true
        }
        let faceYaw = Int16(
            bitPattern: UInt16(bitPattern: input.faceYaw)
                &+ UInt16(bitPattern: angleVelocityYaw)
        )
        return SM64RotatingPlatformOutput(
            action: action,
            angleVelocityYaw: angleVelocityYaw,
            faceYaw: faceYaw,
            playsLoopSound: playsLoopSound
        )
    }
}
