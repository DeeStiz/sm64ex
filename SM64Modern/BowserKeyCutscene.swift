import Foundation

enum SM64BowserKeyCutsceneKind: UInt8, Equatable, Sendable {
    case unlockDoor = 0
    case courseExit = 1
}

struct SM64BowserKeyCutsceneState: Equatable, Sendable {
    var kind: SM64BowserKeyCutsceneKind
    var timer: UInt32 = 0
    var animationFrame: Int32 = 0
    var animation: Int32 = 0
    var scale: Float = 0.2
    var markedForDeletion = false

    init(kind: SM64BowserKeyCutsceneKind = .unlockDoor) {
        self.kind = kind
    }
}

struct SM64BowserKeyCutsceneTickInput: Equatable, Sendable {
    let animationFrame: Int32

    init(animationFrame: Int32 = 0) {
        self.animationFrame = animationFrame
    }
}

struct SM64BowserKeyCutsceneEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let setAnimation = Self(rawValue: 1 << 0)
    static let markForDeletion = Self(rawValue: 1 << 1)
}

struct SM64BowserKeyCutsceneTickResult: Equatable, Sendable {
    let state: SM64BowserKeyCutsceneState
    let effects: SM64BowserKeyCutsceneEffect
}

/// Value translation of `bhv_bowser_key_unlock_door_loop` and
/// `bhv_bowser_key_course_exit_loop` from the C behavior.
enum SM64BowserKeyCutsceneKernel {
    static func tick(
        _ input: SM64BowserKeyCutsceneTickInput,
        state: inout SM64BowserKeyCutsceneState
    ) -> SM64BowserKeyCutsceneTickResult {
        var effects: SM64BowserKeyCutsceneEffect = [.setAnimation]
        state.animationFrame = input.animationFrame
        switch state.kind {
        case .unlockDoor:
            state.animation = 0
            if input.animationFrame < 38 {
                state.scale = 0
            } else if input.animationFrame < 49 {
                state.scale = 0.2
            } else if input.animationFrame < 58 {
                state.scale = Float(input.animationFrame - 53) * 0.11875 + 0.2
            } else if input.animationFrame < 59 {
                state.scale = 1.1
            } else if input.animationFrame < 60 {
                state.scale = 1.05
            } else {
                state.scale = 1
            }
            if state.timer > 150 {
                state.markedForDeletion = true
            }
        case .courseExit:
            state.animation = 1
            if input.animationFrame < 38 {
                state.scale = 0.2
            } else if input.animationFrame < 52 {
                state.scale = Float(input.animationFrame - 42) * 0.042857 + 0.2
            } else if input.animationFrame < 94 {
                state.scale = 0.8
            } else if input.animationFrame < 101 {
                state.scale = Float(101 - input.animationFrame) * 0.085714 + 0.2
            } else {
                state.scale = 0.2
            }
            if state.timer > 138 {
                state.markedForDeletion = true
            }
        }
        if state.markedForDeletion {
            effects.insert(.markForDeletion)
        }
        state.timer = state.timer == UInt32.max ? 0 : state.timer + 1
        return SM64BowserKeyCutsceneTickResult(state: state, effects: effects)
    }
}
