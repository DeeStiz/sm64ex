import Foundation

enum SM64TreeParticleKind: UInt8, Equatable, Sendable { case leaf = 0, snow = 1 }

struct SM64TreeLeafInput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let floorHeight: Float
    let timer: Int32
    let prevFrameObjectCount: Int32
    let moveYaw: Int32
    let facePitch: Int32
    let faceRoll: Int32
    let angleVelocityPitch: Int32
    let angleVelocityRoll: Int32
    let phase: Int32
    let phaseRate: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let scale: Float
}

struct SM64TreeLeafOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let facePitch: Int32
    let faceRoll: Int32
    let phase: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let scale: Float
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_tree_snow_or_leaf_loop` for the leaf identity.
enum SM64TreeLeafBehavior {
    static func update(_ input: SM64TreeLeafInput) -> SM64TreeLeafOutput {
        var position = input.position
        let velocityY = max(input.velocityY - 3, -8)
        let forwardVelocity = max(input.forwardVelocity - 0.3, 0)
        let angle = Int16(truncatingIfNeeded: input.phase)
        let side = SM64CanonicalTrig.sins(angle)
        position.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw)) * side * 4
        position.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw)) * side * 4
        position.y += velocityY
        return SM64TreeLeafOutput(
            position: position,
            moveYaw: input.moveYaw,
            facePitch: input.facePitch &+ input.angleVelocityPitch,
            faceRoll: input.faceRoll &+ input.angleVelocityRoll,
            phase: input.phase &+ input.phaseRate,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            scale: input.scale,
            shouldDeactivate: position.y < input.floorHeight
                || input.floorHeight < -11_000
                || input.timer > 100
                || input.prevFrameObjectCount > 212
        )
    }
}
