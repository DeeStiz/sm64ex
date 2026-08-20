import Foundation

enum SM64FloorSwitchAction: Int32, Equatable, Sendable {
    case idle = 0
    case pressed = 1
    case ticking = 2
    case unpressed = 3
    case waitForMario = 4
}

enum SM64FloorSwitchSound: UInt8, Equatable, Sendable {
    case none = 0
    case activate = 1
    case tickFast = 2
    case tickSlow = 3
}

struct SM64FloorSwitchInput: Equatable, Sendable {
    let action: SM64FloorSwitchAction
    let timer: Int32
    let behaviorByte: Int32
    let platformOn: Bool
    let lateralDistance: Float
    let marioUnknown13: Bool
}

struct SM64FloorSwitchOutput: Equatable, Sendable {
    let action: SM64FloorSwitchAction
    let timer: Int32
    let scale: Float
    let sound: SM64FloorSwitchSound
    let rumble: Bool
    let loadCollisionModel: Bool
}

enum SM64FloorSwitchBehavior {
    static func update(_ input: SM64FloorSwitchInput) -> SM64FloorSwitchOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var scale: Float = 1.5
        var sound: SM64FloorSwitchSound = .none
        var rumble = false
        switch input.action {
        case .idle:
            if input.platformOn && !input.marioUnknown13 && input.lateralDistance < 127.5 {
                action = .pressed; timer = 0
            }
        case .pressed:
            scale = max(0.2, 1.5 - (Float(input.timer) * 1.3 / 3))
            if input.timer == 3 {
                scale = 0.2; sound = .activate; rumble = true; action = .ticking; timer = 0
            }
        case .ticking:
            scale = 0.2
            if input.behaviorByte != 0 {
                if input.behaviorByte == 1 && !input.platformOn {
                    action = .unpressed; timer = 0
                } else {
                    sound = input.timer < 360 ? .tickFast : .tickSlow
                    if input.timer > 400 { action = .waitForMario; timer = 0 }
                }
            }
        case .unpressed:
            scale = min(1.5, 0.2 + (Float(input.timer) * 1.3 / 3))
            if input.timer == 3 { scale = 1.5; action = .idle; timer = 0 }
        case .waitForMario:
            scale = 0.2
            if !input.platformOn { action = .unpressed; timer = 0 }
        }
        return .init(action: action, timer: timer, scale: scale, sound: sound, rumble: rumble, loadCollisionModel: true)
    }
}
