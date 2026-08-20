import Foundation

enum SM64StarDoorAction: Int32, Equatable, Sendable {
    case closed = 0
    case opening = 1
    case open = 2
    case closing = 3
    case reset = 4
}

enum SM64StarDoorSound: UInt8, Equatable, Sendable {
    case none = 0
    case open = 1
    case close = 2
}

struct SM64StarDoorInput: Equatable, Sendable {
    let action: SM64StarDoorAction
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let interactionActivated: Bool
    let neighborAction: SM64StarDoorAction?
    let roomVisible: Bool
}

struct SM64StarDoorOutput: Equatable, Sendable {
    let action: SM64StarDoorAction
    let timer: Int32
    let position: SM64ObjectVector3
    let velocityX: Float
    let velocityZ: Float
    let tangible: Bool
    let visible: Bool
    let loadCollisionModel: Bool
    let sound: SM64StarDoorSound
    let rumble: Bool
    let clearInteraction: Bool
}

/// Value counterpart of `bhv_star_door_loop` plus `bhv_star_door_loop_2`.
enum SM64StarDoorBehavior {
    static func update(_ input: SM64StarDoorInput) -> SM64StarDoorOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var velocityX: Float = 0
        var velocityZ: Float = 0
        var tangible = false
        var sound: SM64StarDoorSound = .none
        var rumble = false
        var clearInteraction = false

        switch input.action {
        case .closed:
            tangible = true
            if input.interactionActivated || input.neighborAction.map({ $0 != .closed }) == true {
                action = .opening
                timer = 0
            }
        case .opening:
            if input.timer == 0 && input.moveYaw >= 0 {
                sound = .open
                rumble = true
            }
            let yaw = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
            let sinYaw = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            velocityX = -8 * yaw
            velocityZ = 8 * sinYaw
            position.x += velocityX
            position.z += velocityZ
            if input.timer >= 16 {
                action = .open
                timer = 0
            }
        case .open:
            if input.timer >= 31 {
                action = .closing
                timer = 0
            }
        case .closing:
            if input.timer == 0 && input.moveYaw >= 0 {
                sound = .close
                rumble = true
            }
            let yaw = SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
            let sinYaw = SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            velocityX = 8 * yaw
            velocityZ = -8 * sinYaw
            position.x += velocityX
            position.z += velocityZ
            if input.timer >= 16 {
                action = .reset
                timer = 0
            }
        case .reset:
            clearInteraction = true
            action = .closed
            timer = 0
        }

        return .init(
            action: action,
            timer: timer,
            position: position,
            velocityX: velocityX,
            velocityZ: velocityZ,
            tangible: tangible,
            visible: input.roomVisible,
            loadCollisionModel: tangible,
            sound: sound,
            rumble: rumble,
            clearInteraction: clearInteraction
        )
    }
}
