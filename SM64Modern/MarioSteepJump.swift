import Foundation

struct SM64MarioSteepJumpInput: Equatable, Sendable {
    let faceYaw: Int16
    let floorAngle: Int16
    let forwardVelocity: Float
}

struct SM64MarioSteepJumpResult: Equatable, Sendable {
    let action: UInt32
    let steepJumpYaw: Int16
    let forwardVelocity: Float
    let faceYaw: Int16
    let shouldDropHeldObject: Bool
}

/// Value counterpart of `set_steep_jump_action`. Action application and the
/// owner-thread drop operation are returned as intents; this kernel owns the
/// C yaw/velocity projection and canonical trig order.
enum SM64MarioSteepJump {
    static func update(_ input: SM64MarioSteepJumpInput) -> SM64MarioSteepJumpResult? {
        guard input.forwardVelocity.isFinite else { return nil }

        let steepJumpYaw = input.faceYaw
        var forwardVelocity = input.forwardVelocity
        var faceYaw = input.faceYaw
        if forwardVelocity > 0 {
            let angleTemp = Int16(truncatingIfNeeded: Int32(input.floorAngle) + 0x8000)
            let faceAngleTemp = Int16(
                truncatingIfNeeded: Int32(input.faceYaw) - Int32(angleTemp)
            )
            let y = SM64CanonicalTrig.sins(faceAngleTemp) * forwardVelocity
            let x = SM64CanonicalTrig.coss(faceAngleTemp) * forwardVelocity * 0.75
            forwardVelocity = sqrt(y * y + x * x)
            let turned = SM64CanonicalTrig.atan2s(y: x, x: y)
            faceYaw = Int16(truncatingIfNeeded: Int32(turned) + Int32(angleTemp))
        }

        return SM64MarioSteepJumpResult(
            action: SM64MarioActionID.steepJump,
            steepJumpYaw: steepJumpYaw,
            forwardVelocity: forwardVelocity,
            faceYaw: faceYaw,
            shouldDropHeldObject: true
        )
    }
}
