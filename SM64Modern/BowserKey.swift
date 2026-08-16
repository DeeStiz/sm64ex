import Foundation

enum SM64BowserKeyAction: UInt8, Equatable, Sendable {
    case airborne = 0
    case landed = 1
}

struct SM64BowserKeyState: Equatable, Sendable {
    var action: SM64BowserKeyAction = .airborne
    var timer: UInt32 = 0
    var angleVelocityYaw: Int16 = 0
    var faceYaw: Int16 = 0
    var faceRoll: Int16 = -0x4000
    var graphYOffset: Float = 165
    var velocityY: Float = 0
    var scale: Float = 0.5
    var tangible = false
    var markedForDeletion = false
}

struct SM64BowserKeyTickInput: Equatable, Sendable {
    let onGround: Bool
    let landed: Bool
    let interacted: Bool

    init(onGround: Bool = false, landed: Bool = false, interacted: Bool = false) {
        self.onGround = onGround
        self.landed = landed
        self.interacted = interacted
    }
}

struct SM64BowserKeyEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let sparkleParticles = Self(rawValue: 1 << 0)
    static let sparkleSpawn = Self(rawValue: 1 << 1)
    static let landingSound = Self(rawValue: 1 << 2)
    static let setHitbox = Self(rawValue: 1 << 3)
    static let clearInteraction = Self(rawValue: 1 << 4)
    static let markForDeletion = Self(rawValue: 1 << 5)
}

struct SM64BowserKeyTickResult: Equatable, Sendable {
    let state: SM64BowserKeyState
    let effects: SM64BowserKeyEffect
}

/// Value translation of `bhv_bowser_key_loop` from the C behavior.
enum SM64BowserKeyKernel {
    static let initialVelocityY: Float = 70
    static let interactionType: UInt32 = 1 << 12 // INTERACT_STAR_OR_KEY
    static let hitboxRadius: Float = 160
    static let hitboxHeight: Float = 100
    static let sparkleCount: Int32 = 3
    static let sparkleRadius: Int32 = 200
    static let sparkleHeight: Int32 = 80
    static let sparkleOffset: Int32 = -60

    static func tick(
        _ input: SM64BowserKeyTickInput,
        state: inout SM64BowserKeyState
    ) -> SM64BowserKeyTickResult {
        var effects: SM64BowserKeyEffect = []
        state.scale = 0.5
        if state.angleVelocityYaw > 0x400 {
            state.angleVelocityYaw -= 0x100
        }
        state.faceYaw = Int16(
            bitPattern: UInt16(bitPattern: state.faceYaw)
                &+ UInt16(bitPattern: state.angleVelocityYaw)
        )
        state.faceRoll = -0x4000
        state.graphYOffset = 165

        switch state.action {
        case .airborne:
            if state.timer == 0 {
                state.velocityY = Self.initialVelocityY
            }
            effects.formUnion([.sparkleParticles, .sparkleSpawn])
            if input.onGround {
                state.action = .landed
            } else if input.landed {
                effects.insert(.landingSound)
            }
        case .landed:
            state.tangible = true
            effects.insert(.setHitbox)
            if input.interacted {
                effects.formUnion([.clearInteraction, .markForDeletion])
                state.markedForDeletion = true
            }
        }

        state.timer = state.timer == UInt32.max ? 0 : state.timer + 1
        return SM64BowserKeyTickResult(state: state, effects: effects)
    }
}
