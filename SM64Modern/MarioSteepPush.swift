import Foundation

struct SM64MarioSteepPushInput: Equatable, Sendable {
    let floorAngle: Int16
    let faceYaw: Int16
    let action: UInt32
    let actionArgument: UInt32
}

struct SM64MarioSteepPushResult: Equatable, Sendable {
    let forwardVelocity: Float
    let faceYaw: Int16
    let action: UInt32
    let actionArgument: UInt32
}

/// Value counterpart of `mario_push_off_steep_floor`; C installs the action.
enum SM64MarioSteepPush {
    static func update(_ input: SM64MarioSteepPushInput) -> SM64MarioSteepPushResult {
        let delta = Int16(truncatingIfNeeded:
            Int32(input.floorAngle) - Int32(input.faceYaw))
        let aligned = delta > -0x4000 && delta < 0x4000
        let faceYaw = aligned
            ? input.floorAngle
            : Int16(truncatingIfNeeded: Int32(input.floorAngle) + Int32(Int16(bitPattern: 0x8000)))
        return SM64MarioSteepPushResult(
            forwardVelocity: aligned ? 16 : -16,
            faceYaw: faceYaw,
            action: input.action,
            actionArgument: input.actionArgument
        )
    }
}
