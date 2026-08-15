import Foundation

struct SM64ArrowLiftInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let faceYaw: Int16
    let displacement: Float
    let marioIsOnPlatform: Bool
}

struct SM64ArrowLiftOutput: Equatable, Sendable {
    let action: Int32
    let moveYaw: Int16
    let velocityY: Float
    let forwardVelocity: Float
    let displacement: Float
    let deltaX: Float
    let deltaZ: Float
}

/// Value counterpart of `bhv_arrow_lift_loop` and its two movement helpers.
enum SM64ArrowLiftBehavior {
    private static let idle: Int32 = 0
    private static let movingAway: Int32 = 1
    private static let movingBack: Int32 = 2

    static func update(_ input: SM64ArrowLiftInput) -> SM64ArrowLiftOutput {
        var action = input.action
        var moveYaw: Int16 = input.faceYaw
        var velocityY: Float = 0
        var forwardVelocity: Float = 0
        var displacement = input.displacement
        var deltaX: Float = 0
        var deltaZ: Float = 0

        func move(using yaw: Int16) {
            deltaX = SM64CanonicalTrig.sins(yaw) * forwardVelocity
            deltaZ = SM64CanonicalTrig.coss(yaw) * forwardVelocity
        }

        switch input.action {
        case idle:
            if input.timer > 60 && input.marioIsOnPlatform {
                action = movingAway
            }
        case movingAway:
            moveYaw = Int16(truncatingIfNeeded: Int32(input.faceYaw) - 0x4000)
            velocityY = 0
            forwardVelocity = 12
            displacement += forwardVelocity
            if displacement > 384 {
                forwardVelocity = 0
                displacement = 384
                action = movingBack
            }
            move(using: moveYaw)
        case movingBack:
            if input.timer > 60 {
                moveYaw = Int16(truncatingIfNeeded: Int32(input.faceYaw) + 0x4000)
                velocityY = 0
                forwardVelocity = 12
                displacement -= forwardVelocity
                if displacement < 0 {
                    forwardVelocity = 0
                    displacement = 0
                    action = idle
                }
                move(using: moveYaw)
            }
        default:
            break
        }

        return SM64ArrowLiftOutput(
            action: action,
            moveYaw: moveYaw,
            velocityY: velocityY,
            forwardVelocity: forwardVelocity,
            displacement: displacement,
            deltaX: deltaX,
            deltaZ: deltaZ
        )
    }
}
