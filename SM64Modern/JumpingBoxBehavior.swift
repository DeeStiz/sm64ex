import Foundation

struct SM64JumpingBoxInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let subAction: Int32
    let heldState: UInt32
    let position: SM64ObjectVector3
    let marioPosition: SM64ObjectVector3
    let velocityY: Float
    let countdown: Int32
    let threshold: Int32
    let onGround: Bool
    let hitWall: Bool
    let inWater: Bool
    let landed: Bool
    let stopRiding: Bool
}

struct SM64JumpingBoxOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let subAction: Int32
    let position: SM64ObjectVector3
    let velocityY: Float
    let countdown: Int32
    let model: UInt32
    let scale: Float
    let visible: Bool
    let shouldDelete: Bool
    let explode: Bool
    let jump: Bool
}

/// Value counterpart of `bhv_jumping_box_loop`.
enum SM64JumpingBoxBehavior {
    static func update(_ input: SM64JumpingBoxInput) -> SM64JumpingBoxOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var subAction = input.subAction
        var position = input.position
        var velocityY = input.velocityY
        var countdown = input.countdown
        var model: UInt32 = 0x3B
        let scale: Float = 0.5
        var visible = true
        var shouldDelete = false
        let explode = input.stopRiding
        var jump = false
        switch input.heldState {
        case 1:
            position = input.marioPosition
            model = 0x3A
            visible = false
        case 2:
            velocityY = 20
            action = 0
            timer = 0
        case 3:
            action = 1
            timer = 0
        default:
            position.y += velocityY
            velocityY -= 4
            if action == 0 {
                if subAction == 0 {
                    countdown -= 1
                    if countdown < 0 || input.timer > input.threshold { velocityY = 15; subAction = 1; jump = true }
                }
                if input.onGround { subAction = 0; countdown = 30 }
            } else if action == 1 && (input.hitWall || input.inWater || input.landed) {
                shouldDelete = true
            }
        }
        if explode { shouldDelete = true }
        return .init(action: action, timer: timer, subAction: subAction, position: position, velocityY: velocityY, countdown: countdown, model: model, scale: scale, visible: visible, shouldDelete: shouldDelete, explode: explode, jump: jump)
    }
}
