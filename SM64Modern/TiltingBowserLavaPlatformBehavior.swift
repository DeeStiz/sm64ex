import Foundation

struct SM64TiltingBowserLavaPlatformInput: Equatable, Sendable {
    let faceAngles: SM64ObjectAngles
    let angleVelocity: SM64ObjectAngles
}

struct SM64TiltingBowserLavaPlatformOutput: Equatable, Sendable {
    let faceAngles: SM64ObjectAngles
    let collisionModelRequested: Bool
}

/// Value counterpart of the arena platform's native loop. The C callback is
/// intentionally small: rotate face angles by their per-frame velocities and
/// ask the owner to submit the arena collision model.
enum SM64TiltingBowserLavaPlatformBehavior {
    static func update(_ input: SM64TiltingBowserLavaPlatformInput)
        -> SM64TiltingBowserLavaPlatformOutput
    {
        .init(
            faceAngles: .init(
                pitch: input.faceAngles.pitch &+ input.angleVelocity.pitch,
                yaw: input.faceAngles.yaw &+ input.angleVelocity.yaw,
                roll: input.faceAngles.roll &+ input.angleVelocity.roll
            ),
            collisionModelRequested: true
        )
    }
}
