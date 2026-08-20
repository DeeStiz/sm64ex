import Foundation

struct SM64WaterMistInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let opacity: Int32
    let timer: Int32
    let randomOffsetX: Float
    let randomOffsetZ: Float
}

struct SM64WaterMistOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let opacity: Int32
    let scale: Float
    let shouldDelete: Bool
}

/// Value counterpart of `bhv_water_mist_loop`.
enum SM64WaterMistBehavior {
    static func update(_ input: SM64WaterMistInput) -> SM64WaterMistOutput {
        var position = input.position
        if input.timer == 0 {
            position.x += input.randomOffsetX
            position.z += input.randomOffsetZ
        }
        let yaw = Int16(truncatingIfNeeded: input.moveYaw)
        position.x += input.forwardVelocity * SM64CanonicalTrig.coss(yaw)
        position.z += input.forwardVelocity * SM64CanonicalTrig.sins(yaw)
        position.y += input.velocityY
        let opacity = input.opacity - 42
        let scale = (Float(254 - opacity) / 254) + 0.5
        return SM64WaterMistOutput(position: position, opacity: opacity, scale: scale, shouldDelete: opacity < 2)
    }
}
