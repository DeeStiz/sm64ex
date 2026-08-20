import Foundation

enum SM64DoorAction: Int32, Equatable, Sendable {
    case closed = 0
    case openingWood = 1
    case openingIron = 2
    case warpOpening = 3
    case warpClosing = 4
}

enum SM64DoorSound: UInt8, Equatable, Sendable {
    case none = 0
    case openWood = 1
    case openIron = 2
    case closeWood = 3
    case closeIron = 4
    case warpClose = 5
}

enum SM64DoorCameraEvent: UInt8, Equatable, Sendable {
    case none = 0
    case door = 1
    case warpDoor = 2
}

struct SM64DoorInput: Equatable, Sendable {
    let action: SM64DoorAction
    let timer: Int32
    let interactionStatus: UInt32
    let animationNearEnd: Bool
    let metalDoor: Bool
    let warpDoor: Bool
    let roomVisible: Bool
}

struct SM64DoorOutput: Equatable, Sendable {
    let action: SM64DoorAction
    let timer: Int32
    let animationState: Int32
    let visible: Bool
    let loadCollisionModel: Bool
    let sound: SM64DoorSound
    let cameraEvent: SM64DoorCameraEvent
    let setMarioOpenedDoorTimeStop: Bool
    let clearInteractionStatus: Bool
}

/// Value counterpart of `bhv_door_loop` and its warp-door alias.
enum SM64DoorBehavior {
    private static let interactionOpenWarp: UInt32 = 0x40000
    private static let interactionCloseWarp: UInt32 = 0x80000
    private static let interactionOpenWood: UInt32 = 0x10000
    private static let interactionOpenIron: UInt32 = 0x20000

    static func update(_ input: SM64DoorInput) -> SM64DoorOutput {
        var action = input.action
        var timer = input.timer
        var cameraEvent: SM64DoorCameraEvent = .none
        var clearInteraction = false

        // The C loop visits all four masks in order; the last matching mask
        // wins if malformed status contains more than one interaction.
        if input.interactionStatus & interactionOpenWarp != 0 {
            action = .warpOpening; timer = 0; cameraEvent = input.warpDoor ? .warpDoor : .door; clearInteraction = true
        }
        if input.interactionStatus & interactionCloseWarp != 0 {
            action = .warpClosing; timer = 0; cameraEvent = input.warpDoor ? .warpDoor : .door; clearInteraction = true
        }
        if input.interactionStatus & interactionOpenWood != 0 {
            action = .openingWood; timer = 0; cameraEvent = input.warpDoor ? .warpDoor : .door; clearInteraction = true
        }
        if input.interactionStatus & interactionOpenIron != 0 {
            action = .openingIron; timer = 0; cameraEvent = input.warpDoor ? .warpDoor : .door; clearInteraction = true
        }

        var sound: SM64DoorSound = .none
        var animationState = action.rawValue
        var setTimeStop = false
        switch action {
        case .closed:
            animationState = 0
            timer &+= 1
        case .openingWood:
            animationState = 1
            if timer == 0 { sound = .openWood; setTimeStop = true }
            if timer == 70 { sound = .closeWood }
            if input.animationNearEnd { action = .closed; timer = 0; animationState = 0 }
            else { timer &+= 1 }
        case .openingIron:
            animationState = 2
            if timer == 0 { sound = .openIron; setTimeStop = true }
            if timer == 70 { sound = .closeIron }
            if input.animationNearEnd { action = .closed; timer = 0; animationState = 0 }
            else { timer &+= 1 }
        case .warpOpening:
            animationState = 3
            if timer == 30 { sound = .warpClose }
            if input.animationNearEnd { action = .closed; timer = 0; animationState = 0 }
            else { timer &+= 1 }
        case .warpClosing:
            animationState = 4
            if timer == 30 { sound = .warpClose }
            if input.animationNearEnd { action = .closed; timer = 0; animationState = 0 }
            else { timer &+= 1 }
        }
        return .init(action: action, timer: timer, animationState: animationState, visible: input.roomVisible, loadCollisionModel: action == .closed, sound: sound, cameraEvent: cameraEvent, setMarioOpenedDoorTimeStop: setTimeStop, clearInteractionStatus: clearInteraction)
    }
}
