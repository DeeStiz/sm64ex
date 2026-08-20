import Foundation

struct SM64BookSwitchInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let progress: Float
    let parentAction: Int32
    let parentSequence: Int32
    let parentEnabled: Bool
    let distanceToMario: Float
    let attacked: Bool
    let behaviorParam: Int32
    let parentForwardVelocity: Float
    let homeZ: Float
    let positionZ: Float
}

struct SM64BookSwitchOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let progress: Float
    let tangible: Bool
    let positionZ: Float
    let spawnFlyingBookend: Bool
    let shouldDelete: Bool
}

enum SM64BookSwitchBehavior {
    static func update(_ input: SM64BookSwitchInput) -> SM64BookSwitchOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var progress = input.progress
        var tangible = false
        var spawn = false
        var shouldDelete = false
        if input.parentAction == 4 { shouldDelete = true }
        else if input.parentEnabled || action == 1 {
            tangible = input.distanceToMario < 100
            action = 1
            if progress < 50 {
                progress = min(progress + 20, 50)
                timer = 0
            } else if input.parentSequence >= 0 && input.timer > 60 && input.attacked {
                action = 2
            }
        } else {
            progress = max(progress - 20, 0)
            tangible = false
            if progress == 0 && action != 0 {
                if input.parentSequence == input.behaviorParam {
                    action = 0
                } else {
                    action = 0
                    spawn = true
                }
            }
            if progress == 0 { timer = 0 }
        }
        return .init(action: action, timer: timer, progress: progress, tangible: tangible, positionZ: input.homeZ - progress, spawnFlyingBookend: spawn, shouldDelete: shouldDelete)
    }
}
