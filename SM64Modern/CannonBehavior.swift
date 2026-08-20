import Foundation

struct SM64CannonInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let cannonPhase: Int32
    let distanceToMario: Float
    let interacted: Bool
    let touchedBobomb: Bool
    let behaviorByte: Int32
}

struct SM64CannonOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let movePitch: Int32
    let cannonPhase: Int32
    let tangible: Bool
    let visible: Bool
    let interactionAccepted: Bool
}

enum SM64CannonBehavior {
    static func update(_ input: SM64CannonInput) -> SM64CannonOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var yaw = input.moveYaw
        var pitch = input.movePitch
        var phase = input.cannonPhase
        var tangible = true
        var visible = true
        var accepted = false

        switch input.action {
        case 0:
            if input.interacted && !input.touchedBobomb && input.distanceToMario < 500 {
                action = 4; timer = 0; accepted = true
            }
        case 1:
            tangible = false; visible = false
        case 2:
            action = 3; timer = 0
        case 3:
            tangible = false; visible = false
            if input.timer > 3 { action = 0; timer = 0 }
        case 4:
            position.y += 5
            if input.timer > 67 { action = 6; timer = 0 }
        case 5:
            if input.timer >= 4 && input.timer < 20 { phase &+= 0x400; pitch = Int32(SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: phase)) * 0x2000) }
            if input.timer >= 25 { action = 1; timer = 0 }
        case 6:
            if input.timer >= 6 && input.timer < 22 { yaw = Int32(SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: phase)) * 0x4000) &+ (input.behaviorByte << 8); phase &+= 0x400 }
            if input.timer >= 26 { action = 5; timer = 0; phase = 0 }
        default:
            break
        }
        return .init(action: action, timer: timer, position: position, moveYaw: yaw, movePitch: pitch, cannonPhase: phase, tangible: tangible, visible: visible, interactionAccepted: accepted)
    }
}
