import Foundation

struct SM64SwingPlatformInput: Equatable, Sendable {
    let angle: Float
    let speed: Float
    let faceRoll: Int32
}

struct SM64SwingPlatformOutput: Equatable, Sendable {
    let angle: Float
    let speed: Float
    let faceRoll: Int32
    let angleVelocityRoll: Int32
}

/// Value counterpart of `bhv_swing_platform_update`.
///
/// The legacy object stores the accumulated swing angle and speed as `f32`,
/// but writes the render-facing roll through the signed object-angle field.
/// Keep that truncation boundary explicit so a copied-POD bridge does not
/// accidentally round or share the native object.
enum SM64SwingPlatformBehavior {
    static func initialize() -> Float { 0x2000 }

    static func update(_ input: SM64SwingPlatformInput) -> SM64SwingPlatformOutput {
        var speed = input.speed
        if input.faceRoll < 0 {
            speed += 4
        } else {
            speed -= 4
        }
        let angle = input.angle + speed
        let faceRoll = Int32(angle)
        return SM64SwingPlatformOutput(
            angle: angle,
            speed: speed,
            faceRoll: faceRoll,
            angleVelocityRoll: faceRoll &- input.faceRoll
        )
    }
}
