import Foundation

struct SM64BreakBoxTriangleInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let facePitch: Int32
    let faceYaw: Int32
    let faceRoll: Int32
    let angleVelocityPitch: Int32
    let angleVelocityYaw: Int32
    let angleVelocityRoll: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let timer: Int32
}

struct SM64BreakBoxTriangleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let facePitch: Int32
    let faceYaw: Int32
    let faceRoll: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let shouldDeactivate: Bool
}

/// Value counterpart of the generic break-box triangle behavior script.
enum SM64BreakBoxTriangleBehavior {
    static func update(_ input: SM64BreakBoxTriangleInput) -> SM64BreakBoxTriangleOutput {
        let velocityY = input.velocityY + input.gravity
        let forwardX = input.forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
        let forwardZ = input.forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
        return SM64BreakBoxTriangleOutput(
            position: .init(x: input.position.x + forwardX, y: input.position.y + velocityY, z: input.position.z + forwardZ),
            facePitch: input.facePitch &+ input.angleVelocityPitch,
            faceYaw: input.faceYaw &+ input.angleVelocityYaw,
            faceRoll: input.faceRoll &+ input.angleVelocityRoll,
            forwardVelocity: input.forwardVelocity,
            velocityY: velocityY,
            shouldDeactivate: input.timer >= 17
        )
    }
}
