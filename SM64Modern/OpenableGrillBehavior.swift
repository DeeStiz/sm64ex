import Foundation

enum SM64OpenableGrillAction: Int32, Equatable, Sendable {
    case spawnChildren = 0
    case waitForSwitch = 1
    case open = 2
    case done = 3
}

struct SM64OpenableGrillInput: Equatable, Sendable {
    let action: SM64OpenableGrillAction
    let timer: Int32
    let variant: Int32
    let floorSwitchFound: Bool
    let floorSwitchAction: Int32?
}

struct SM64OpenableGrillOutput: Equatable, Sendable {
    let action: SM64OpenableGrillAction
    let timer: Int32
    let spawnChildren: Bool
    let signalChildren: Bool
    let playCageOpenSound: Bool
    let playPuzzleJingle: Bool
}

enum SM64OpenableGrillBehavior {
    static func update(_ input: SM64OpenableGrillInput) -> SM64OpenableGrillOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var spawnChildren = false
        var signalChildren = false
        var playSound = false
        var playJingle = false
        switch input.action {
        case .spawnChildren:
            spawnChildren = true
            action = .waitForSwitch
            timer = 0
        case .waitForSwitch:
            if input.floorSwitchFound { action = .open; timer = 0 }
        case .open:
            if input.floorSwitchAction == 2 {
                signalChildren = true
                playSound = true
                playJingle = input.variant != 0
                action = .done
                timer = 0
            }
        case .done:
            break
        }
        return .init(action: action, timer: timer, spawnChildren: spawnChildren, signalChildren: signalChildren, playCageOpenSound: playSound, playPuzzleJingle: playJingle)
    }
}

struct SM64OpenableCageDoorInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let faceYaw: Int32
    let yawDirection: Int32
    let parentOpenSignal: Int32
}
struct SM64OpenableCageDoorOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let faceYaw: Int32
    let loadCollisionModel: Bool
}
enum SM64OpenableCageDoorBehavior {
    static func update(_ input: SM64OpenableCageDoorInput) -> SM64OpenableCageDoorOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var yaw = input.faceYaw
        var loadCollision = true
        if input.action == 0 {
            if input.parentOpenSignal != 0 { action = 1; timer = 0 }
        } else if input.action == 1 {
            if input.timer < 64 { yaw &-= input.yawDirection &* 0x100 }
            else { action = 2; timer = 0 }
            loadCollision = true
        } else {
            loadCollision = true
        }
        return .init(action: action, timer: timer, faceYaw: yaw, loadCollisionModel: loadCollision)
    }
}
