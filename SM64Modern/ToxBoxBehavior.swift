import Foundation

struct SM64ToxBoxInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let positionY: Float
    let homeY: Float
    let facePitch: Int32
    let faceRoll: Int32
    let initialDirectionAction: Int32
    let nextDirectionAction: Int32
    let behaviorVariant: Int32
}

struct SM64ToxBoxOutput: Equatable, Sendable {
    let action: Int32
    let positionY: Float
    let forwardVelocity: Float
    let transformOffset: Float
    let facePitch: Int32
    let faceRoll: Int32
    let playMoveSound: Bool
    let shakeScreen: Bool
    let loadCollisionModel: Bool
}

/// Value counterpart of `bhv_tox_box_loop` and its direction-table actions.
enum SM64ToxBoxBehavior {
    static func update(_ input: SM64ToxBoxInput) -> SM64ToxBoxOutput {
        var action = input.action
        var positionY = input.positionY
        var forwardVelocity: Float = 0
        var transformOffset: Float = 0
        var facePitch = input.facePitch
        var faceRoll = input.faceRoll
        var playMoveSound = false
        var shakeScreen = false
        switch action {
        case 0:
            action = input.initialDirectionAction
        case 1:
            if input.timer == 0 { shakeScreen = true }
            positionY = input.homeY + 3
            if input.timer == 20 { action = input.nextDirectionAction }
        case 2, 3:
            if input.timer == 20 { action = input.nextDirectionAction }
        case 4:
            positionY = input.homeY + 3 + SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: ((input.timer + 1) * 0x8000) / 8)) * 99.41124
            forwardVelocity = 64
            facePitch &+= 0x800
            if input.timer == 7 { action = input.nextDirectionAction; playMoveSound = true }
        case 5:
            positionY = input.homeY + 3 + SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: ((input.timer + 1) * 0x8000) / 8)) * 99.41124
            forwardVelocity = -64
            facePitch &-= 0x800
            if input.timer == 7 { action = input.nextDirectionAction; playMoveSound = true }
        case 6:
            transformOffset = -64
            faceRoll &+= 0x800
            if input.timer == 7 { action = input.nextDirectionAction; playMoveSound = true }
        case 7:
            transformOffset = 64
            faceRoll &-= 0x800
            if input.timer == 7 { action = input.nextDirectionAction; playMoveSound = true }
        default:
            action = input.initialDirectionAction
        }
        return .init(action: action, positionY: positionY, forwardVelocity: forwardVelocity, transformOffset: transformOffset, facePitch: facePitch, faceRoll: faceRoll, playMoveSound: playMoveSound, shakeScreen: shakeScreen, loadCollisionModel: true)
    }
}
