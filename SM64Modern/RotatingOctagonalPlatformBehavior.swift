import Foundation

struct SM64RotatingOctagonalPlatformInitialization: Equatable, Sendable {
    let collisionModelIndex: UInt8
    let angleVelocityYaw: Int32
}

struct SM64RotatingOctagonalPlatformInput: Equatable, Sendable {
    let faceYaw: Int32
    let angleVelocityYaw: Int32
}

struct SM64RotatingOctagonalPlatformOutput: Equatable, Sendable {
    let faceYaw: Int32
    let angleVelocityYaw: Int32
}

/// Value counterpart of `bhv_rotating_octagonal_plat_init/loop`.
enum SM64RotatingOctagonalPlatformBehavior {
    private static let speeds: [Int32] = [300, -300, 600, -600]

    static func initialize(
        collisionModelIndex: UInt8,
        speedIndex: UInt8
    ) -> SM64RotatingOctagonalPlatformInitialization {
        precondition(speedIndex < speeds.count)
        return SM64RotatingOctagonalPlatformInitialization(
            collisionModelIndex: collisionModelIndex,
            angleVelocityYaw: speeds[Int(speedIndex)]
        )
    }

    static func update(_ input: SM64RotatingOctagonalPlatformInput)
        -> SM64RotatingOctagonalPlatformOutput
    {
        SM64RotatingOctagonalPlatformOutput(
            faceYaw: input.faceYaw &+ input.angleVelocityYaw,
            angleVelocityYaw: input.angleVelocityYaw
        )
    }
}
