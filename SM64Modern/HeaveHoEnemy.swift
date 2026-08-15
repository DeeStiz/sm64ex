import Foundation

enum SM64HeaveHoAction: UInt8, Equatable, Sendable {
    case submerged = 0
    case windUp = 1
    case chase = 2
    case throwMario = 3
}

enum SM64HeaveHoHeldState: UInt8, Equatable, Sendable {
    case free = 0
    case held = 1
    case thrown = 2
    case dropped = 3
}

struct SM64HeaveHoHitbox: Equatable, Sendable {
    let interactType: UInt32
    let interactionSubtype: UInt32
    let radius: Float
    let height: Float

    static let standard = Self(
        // INTERACT_GRABBABLE and INT_SUBTYPE_GRABS_MARIO.
        interactType: 1 << 1,
        interactionSubtype: 0x04,
        radius: 120,
        height: 100
    )
}

struct SM64HeaveHoState: Equatable, Sendable {
    let hitbox: SM64HeaveHoHitbox

    var action: SM64HeaveHoAction = .submerged
    var heldState: SM64HeaveHoHeldState = .free
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var moveYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var animationState: Int32 = 0
    var throwState: UInt8 = 0
    var collidedObjectCount: Int32 = 0
    var animationRate: Float = 1
    var tangible = false
    var hidden = true
    var markedForDeletion = false
    var timer: UInt32 = 0

    init(homeX: Float = 0, homeY: Float = 0, homeZ: Float = 0, moveYaw: Int16 = 0) {
        self.hitbox = .standard
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.moveYaw = moveYaw
    }
}

struct SM64HeaveHoTickInput: Equatable, Sendable {
    var waterLevelBelowObject: Bool
    var distanceToMario: Float
    var lateralDistanceHome: Float
    var angleToMario: Int16
    var angleToHome: Int16
    var moveFlags: UInt32
    var heldState: SM64HeaveHoHeldState
    var grabbedMario: Bool
    var animationNearEnd: Bool
    var animationFrame: UInt32

    init(
        waterLevelBelowObject: Bool = false,
        distanceToMario: Float = 10_000,
        lateralDistanceHome: Float = 0,
        angleToMario: Int16 = 0,
        angleToHome: Int16 = 0,
        moveFlags: UInt32 = 0,
        heldState: SM64HeaveHoHeldState = .free,
        grabbedMario: Bool = false,
        animationNearEnd: Bool = false,
        animationFrame: UInt32 = 0
    ) {
        self.waterLevelBelowObject = waterLevelBelowObject
        self.distanceToMario = distanceToMario
        self.lateralDistanceHome = lateralDistanceHome
        self.angleToMario = angleToMario
        self.angleToHome = angleToHome
        self.moveFlags = moveFlags
        self.heldState = heldState
        self.grabbedMario = grabbedMario
        self.animationNearEnd = animationNearEnd
        self.animationFrame = animationFrame
    }
}

struct SM64HeaveHoEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let resetHome = Self(rawValue: 1 << 0)
    static let tangible = Self(rawValue: 1 << 1)
    static let intangible = Self(rawValue: 1 << 2)
    static let hide = Self(rawValue: 1 << 3)
    static let unhide = Self(rawValue: 1 << 4)
    static let windUp = Self(rawValue: 1 << 5)
    static let chase = Self(rawValue: 1 << 6)
    static let moveSound = Self(rawValue: 1 << 7)
    static let throwAnimation = Self(rawValue: 1 << 8)
    static let throwMario = Self(rawValue: 1 << 9)
    static let marioThrown = Self(rawValue: 1 << 10)
    static let collisionBudget = Self(rawValue: 1 << 11)
    static let heldReset = Self(rawValue: 1 << 12)
    static let waterSubmerge = Self(rawValue: 1 << 13)
}

struct SM64HeaveHoTickResult: Equatable, Sendable {
    let state: SM64HeaveHoState
    let effects: SM64HeaveHoEffect
}

enum SM64HeaveHoKernel {
    static let inWaterFlag: UInt32 = 1 << 5

    static func tick(
        _ input: SM64HeaveHoTickInput,
        state: inout SM64HeaveHoState
    ) -> SM64HeaveHoTickResult {
        var effects: SM64HeaveHoEffect = []
        state.heldState = input.heldState

        if state.heldState != .free {
            state.forwardVelocity = 0
            state.tangible = false
            state.hidden = state.heldState == .held
            effects.insert(.heldReset)
            if state.heldState == .thrown || state.heldState == .dropped {
                state.action = .chase
                state.hidden = false
                state.tangible = true
                effects.insert(.unhide)
            } else {
                effects.insert(.hide)
            }
        } else if input.grabbedMario {
            state.throwState = 1
            state.action = .throwMario
            state.timer = 0
            effects.insert(.throwAnimation)
        } else {
            switch state.action {
            case .submerged:
                if input.waterLevelBelowObject && input.distanceToMario < 4_000 {
                    state.positionX = state.homeX
                    state.positionY = state.homeY
                    state.positionZ = state.homeZ
                    state.tangible = true
                    state.hidden = false
                    state.action = .windUp
                    effects.insert([.resetHome, .tangible, .unhide])
                } else {
                    state.tangible = false
                    state.hidden = true
                    effects.insert([.intangible, .hide])
                }

            case .windUp:
                state.forwardVelocity = 0
                state.animationState = 2
                state.animationRate = input.animationFrame < 30 ? 0 : 1
                effects.insert(.windUp)
                if state.timer >= 118 {
                    state.action = .chase
                    state.timer = 0
                }

            case .chase:
                if input.lateralDistanceHome > 1_000 { state.moveYaw = input.angleToHome }
                if state.timer > 150 {
                    state.animationRate = max(0.1, Float(302 - Int(state.timer)) / 152)
                    if state.animationRate <= 0.1 {
                        state.action = .windUp
                        state.timer = 0
                    }
                } else {
                    state.animationRate = 1
                }
                state.animationState = 0
                state.forwardVelocity = state.animationRate * 10
                let angleVelocity = Int16(max(1, Int(state.animationRate * 0x400)))
                state.moveYaw = approachAngle(
                    current: state.moveYaw,
                    target: input.angleToMario,
                    increment: angleVelocity
                )
                advance(&state)
                if state.forwardVelocity > 3 { effects.insert(.moveSound) }
                effects.insert(.chase)
                if input.moveFlags & inWaterFlag != 0 {
                    state.action = .submerged
                    state.timer = 0
                    state.tangible = false
                    state.hidden = true
                    effects.insert(.waterSubmerge)
                }

            case .throwMario:
                state.forwardVelocity = 0
                if state.timer == 0 {
                    state.throwState = 2
                    effects.insert(.throwMario)
                }
                if state.timer == 1 {
                    state.animationState = 1
                    state.collidedObjectCount = 20
                    effects.insert(.collisionBudget)
                }
                effects.insert(.throwAnimation)
                if input.animationNearEnd {
                    state.action = .windUp
                    state.timer = 0
                    state.throwState = 0
                }
            }
        }

        // The C wrapper forces any active Heave Ho back into the submerged
        // action when the movement step reports water contact.
        if state.action != .submerged, input.moveFlags & inWaterFlag != 0 {
            state.action = .submerged
            state.timer = 0
            state.tangible = false
            state.hidden = true
            effects.insert(.waterSubmerge)
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64HeaveHoTickResult(state: state, effects: effects)
    }

    static func tickThrowChild(
        parent: SM64HeaveHoState,
        state: inout SM64HeaveHoThrowChildState
    ) -> SM64HeaveHoThrowChildResult {
        var effects: SM64HeaveHoEffect = []
        state.positionX = parent.positionX + 200
        state.positionY = parent.positionY - 50
        state.positionZ = parent.positionZ
        state.moveYaw = parent.moveYaw
        if parent.throwState == 2, !state.throwConsumed {
            effects.insert(.marioThrown)
            state.throwConsumed = true
        }
        return SM64HeaveHoThrowChildResult(state: state, effects: effects)
    }

    private static func advance(_ state: inout SM64HeaveHoState) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionY += state.velocityY
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }
}

struct SM64HeaveHoThrowChildState: Equatable, Sendable {
    var positionX: Float = 0
    var positionY: Float = 0
    var positionZ: Float = 0
    var moveYaw: Int16 = 0
    var throwConsumed = false
}

struct SM64HeaveHoThrowChildResult: Equatable, Sendable {
    let state: SM64HeaveHoThrowChildState
    let effects: SM64HeaveHoEffect
}
