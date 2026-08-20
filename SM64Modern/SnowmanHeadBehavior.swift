import Foundation

/// The value-only portion of `bhv_snowmans_head_loop`.
///
/// Dialog, sound, particle, and star delivery remain effect intents.  The
/// reducer owns the authored action/timer/landing boundaries and the scalar
/// physics constants so the owner thread never shares C object storage.
struct SM64SnowmanHeadInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let positionY: Float
    let moveFlags: UInt32
    let dialogTriggered: Bool
    let dialogCompleted: Bool
}

struct SM64SnowmanHeadOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let positionY: Float
    let gravity: Float
    let friction: Float
    let buoyancy: Float
    let scale: Float
    let explosionJingle: Bool
    let mistAndStar: Bool
    let pushMario: Bool
}

enum SM64SnowmanHeadBehavior {
    static func update(_ input: SM64SnowmanHeadInput) -> SM64SnowmanHeadOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var positionY = input.positionY
        var explosionJingle = false
        var mistAndStar = false

        switch input.action {
        case 0:
            if input.dialogTriggered {
                action = 1
                timer = 0
            }
        case 2:
            if (input.moveFlags & 0x08) != 0 {
                action = 3
                timer = 0
            }
        case 3:
            if input.positionY < -994 {
                positionY = -994
                action = 4
                timer = 0
                explosionJingle = true
            }
        case 4:
            if input.dialogCompleted {
                action = 1
                timer = 0
                mistAndStar = true
            }
        default:
            break
        }

        return .init(
            action: action,
            timer: timer,
            positionY: positionY,
            gravity: 5,
            friction: 0.999,
            buoyancy: 2,
            scale: 0.7,
            explosionJingle: explosionJingle,
            mistAndStar: mistAndStar,
            pushMario: true
        )
    }
}
