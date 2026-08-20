import Foundation

/// Value-only reducer for `bhv_snowmans_bottom_loop`.
struct SM64SnowmanBottomInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let forwardVelocity: Float
    let moveYaw: Int32
    let facePitch: Int32
    let scale: Float
    let pathComplete: Bool
    let nearBouncePoint: Bool
    let movementFlags: UInt32
    let dialogTriggered: Bool
}

struct SM64SnowmanBottomOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let forwardVelocity: Float
    let moveYaw: Int32
    let facePitch: Int32
    let verticalVelocity: Float
    let scale: Float
    let gravity: Float
    let friction: Float
    let buoyancy: Float
    let tangible: Bool
    let deactivated: Bool
    let parentBounce: Bool
    let checkpointActive: Bool
    let pushMario: Bool
}

enum SM64SnowmanBottomBehavior {
    static func update(_ input: SM64SnowmanBottomInput) -> SM64SnowmanBottomOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var forwardVelocity = input.forwardVelocity
        var moveYaw = input.moveYaw
        var facePitch = input.facePitch
        var verticalVelocity: Float = 0
        var scale = input.scale
        var tangible = true
        var deactivated = false
        var parentBounce = false

        switch input.action {
        case 0:
            if input.dialogTriggered {
                forwardVelocity = 10
                action = 1
                timer = 0
            }
        case 1:
            forwardVelocity = min(forwardVelocity, 70)
            if input.pathComplete {
                action = 2
                timer = 0
                moveYaw = moveYaw &+ 0x400
            }
        case 2:
            forwardVelocity = min(forwardVelocity, 70)
            if input.nearBouncePoint {
                moveYaw = 0x4000
                verticalVelocity = 80
                forwardVelocity = 15
                action = 3
                timer = 0
                parentBounce = true
            } else if input.timer == 200 {
                deactivated = true
            }
        case 3:
            verticalVelocity = input.movementFlags & 1 != 0 ? 0 : -10
            if (input.movementFlags & 0x09) == 0x09 {
                action = 4
                timer = 0
                tangible = false
            }
            if (input.movementFlags & 1) != 0 {
                position.x = -4230
                position.z = 1813
                forwardVelocity = 0
            }
        case 4:
            break
        default:
            break
        }

        if input.action == 1 || input.action == 2 {
            facePitch = facePitch &+ Int32(input.forwardVelocity * (100 / max(input.scale, 0.0001)))
            scale = min(1, input.scale + input.forwardVelocity * 0.0001)
        }

        return .init(
            action: action,
            timer: timer,
            position: position,
            forwardVelocity: forwardVelocity,
            moveYaw: moveYaw,
            facePitch: facePitch,
            verticalVelocity: verticalVelocity,
            scale: scale,
            gravity: 10,
            friction: 0.999,
            buoyancy: 2,
            tangible: tangible,
            deactivated: deactivated,
            parentBounce: parentBounce,
            checkpointActive: action != 4,
            pushMario: action == 4
        )
    }
}
