import Foundation

enum SM64ChuckyaAction: UInt8, Equatable, Sendable {
    case patrol = 0
    case grab = 1
    case death = 2
    case throwMario = 3
}

enum SM64ChuckyaHeldState: UInt8, Equatable, Sendable {
    case free = 0
    case held = 1
    case thrown = 2
    case dropped = 3
}

struct SM64ChuckyaHitbox: Equatable, Sendable {
    let interactType: UInt32
    let interactionSubtype: UInt32
    let radius: Float
    let height: Float

    static let standard = Self(
        interactType: 1 << 1,
        interactionSubtype: 0x04,
        radius: 150,
        height: 100
    )
}

struct SM64ChuckyaState: Equatable, Sendable {
    let hitbox: SM64ChuckyaHitbox

    var action: SM64ChuckyaAction = .patrol
    var heldState: SM64ChuckyaHeldState = .free
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var moveYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var subAction: UInt8 = 0
    var actionCounter: Int32 = 0
    var escapeCounter: Int32 = 0
    var throwState: UInt8 = 0
    var animationState: Int32 = 5
    var tangible = true
    var hidden = false
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

struct SM64ChuckyaTickInput: Equatable, Sendable {
    var distanceFromMarioHome: Float
    var lateralDistanceHome: Float
    var distanceToMario: Float
    var angleToMario: Int16
    var angleToHome: Int16
    var floorCollisionFlags: UInt32
    var grabbedMario: Bool
    var grabEscapeCount: Int32
    var overFloor: Bool
    var animationNearEnd: Bool
    var animationFrame: UInt32
    var heldState: SM64ChuckyaHeldState

    init(
        distanceFromMarioHome: Float = 10_000,
        lateralDistanceHome: Float = 0,
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        angleToHome: Int16 = 0,
        floorCollisionFlags: UInt32 = 0,
        grabbedMario: Bool = false,
        grabEscapeCount: Int32 = 0,
        overFloor: Bool = false,
        animationNearEnd: Bool = false,
        animationFrame: UInt32 = 0,
        heldState: SM64ChuckyaHeldState = .free
    ) {
        self.distanceFromMarioHome = distanceFromMarioHome
        self.lateralDistanceHome = lateralDistanceHome
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.angleToHome = angleToHome
        self.floorCollisionFlags = floorCollisionFlags
        self.grabbedMario = grabbedMario
        self.grabEscapeCount = grabEscapeCount
        self.overFloor = overFloor
        self.animationNearEnd = animationNearEnd
        self.animationFrame = animationFrame
        self.heldState = heldState
    }
}

struct SM64ChuckyaEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let move = Self(rawValue: 1 << 1)
    static let grab = Self(rawValue: 1 << 2)
    static let throwAnimation = Self(rawValue: 1 << 3)
    static let throwMario = Self(rawValue: 1 << 4)
    static let tossMario = Self(rawValue: 1 << 5)
    static let death = Self(rawValue: 1 << 6)
    static let coins = Self(rawValue: 1 << 7)
    static let mist = Self(rawValue: 1 << 8)
    static let intangible = Self(rawValue: 1 << 9)
    static let hide = Self(rawValue: 1 << 10)
    static let unhide = Self(rawValue: 1 << 11)
    static let heldReset = Self(rawValue: 1 << 12)
}

struct SM64ChuckyaTickResult: Equatable, Sendable {
    let state: SM64ChuckyaState
    let effects: SM64ChuckyaEffect
}

struct SM64ChuckyaAnchorState: Equatable, Sendable {
    var positionX: Float = 0
    var positionY: Float = 0
    var positionZ: Float = 0
    var moveYaw: Int16 = 0
    var throwConsumed = false
}

struct SM64ChuckyaAnchorResult: Equatable, Sendable {
    let state: SM64ChuckyaAnchorState
    let effects: SM64ChuckyaEffect
}

enum SM64ChuckyaKernel {
    static let hitWallFlag: UInt32 = 1 << 0
    static let inWaterFlag: UInt32 = 1 << 5
    static let landedFlag: UInt32 = 1 << 1

    static func tick(
        _ input: SM64ChuckyaTickInput,
        state: inout SM64ChuckyaState
    ) -> SM64ChuckyaTickResult {
        var effects: SM64ChuckyaEffect = [.animate]
        state.heldState = input.heldState

        if state.heldState != .free {
            state.forwardVelocity = 0
            state.tangible = false
            state.hidden = state.heldState == .held
            effects.insert(.heldReset)
            effects.insert(state.hidden ? .hide : .unhide)
        } else if input.grabbedMario, state.action == .patrol {
            state.action = .grab
            state.subAction = 0
            state.throwState = 1
            state.timer = 0
            effects.insert(.grab)
        } else {
            switch state.action {
            case .patrol:
                tickPatrol(input, state: &state, effects: &effects)
            case .grab:
                tickGrab(input, state: &state, effects: &effects)
            case .death:
                state.forwardVelocity = 0
                if input.floorCollisionFlags & (hitWallFlag | inWaterFlag | landedFlag) != 0 {
                    state.markedForDeletion = true
                    state.tangible = false
                    effects.insert([.death, .coins, .mist, .intangible])
                }
            case .throwMario:
                state.forwardVelocity = 0
                state.velocityY = 0
                effects.insert(.throwAnimation)
                if state.timer > 100 {
                    state.action = .patrol
                    state.timer = 0
                    state.throwState = 0
                }
            }
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64ChuckyaTickResult(state: state, effects: effects)
    }

    static func tickAnchor(
        parent: SM64ChuckyaState,
        state: inout SM64ChuckyaAnchorState
    ) -> SM64ChuckyaAnchorResult {
        var effects: SM64ChuckyaEffect = []
        state.positionX = parent.positionX
        state.positionY = parent.positionY - 60
        state.positionZ = parent.positionZ + 150
        state.moveYaw = parent.moveYaw
        if parent.throwState == 2, !state.throwConsumed {
            state.throwConsumed = true
            effects.insert(.throwMario)
        } else if parent.throwState == 3, !state.throwConsumed {
            state.throwConsumed = true
            effects.insert(.tossMario)
        }
        return SM64ChuckyaAnchorResult(state: state, effects: effects)
    }

    private static func tickPatrol(
        _ input: SM64ChuckyaTickInput,
        state: inout SM64ChuckyaState,
        effects: inout SM64ChuckyaEffect
    ) {
        switch state.subAction {
        case 0:
            state.forwardVelocity = 0
            state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToMario, increment: 0x400)
            if state.actionCounter > 40 || absAngleDiff(state.moveYaw, input.angleToMario) < 0x1000 {
                state.subAction = 1
            } else if input.lateralDistanceHome > 2_000 {
                state.subAction = 3
            }
        case 1:
            state.forwardVelocity = approach(state.forwardVelocity, target: 30, step: 4)
            if absAngleDiff(state.moveYaw, input.angleToMario) > 0x4000 { state.subAction = 2 }
            if input.lateralDistanceHome > 2_000 { state.subAction = 3 }
        case 2:
            state.forwardVelocity = approach(state.forwardVelocity, target: 0, step: 4)
            if state.actionCounter > 48 { state.subAction = 0 }
        default:
            if input.lateralDistanceHome < 500 {
                state.forwardVelocity = 0
            } else {
                state.forwardVelocity = approach(state.forwardVelocity, target: 10, step: 4)
                state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToHome, increment: 0x800)
            }
            if input.distanceFromMarioHome < 1_900 { state.subAction = 0 }
        }
        state.actionCounter = state.subAction == 0 ? state.actionCounter &+ 1 : state.actionCounter &+ 1
        if state.forwardVelocity > 1 { effects.insert(.move) }
        advance(&state)
    }

    private static func tickGrab(
        _ input: SM64ChuckyaTickInput,
        state: inout SM64ChuckyaState,
        effects: inout SM64ChuckyaEffect
    ) {
        state.forwardVelocity = 0
        if state.subAction == 0 {
            if input.animationNearEnd { state.subAction = 1 }
        } else if state.subAction == 1 {
            state.escapeCounter += input.grabEscapeCount
            if state.escapeCounter > 10 {
                state.throwState = 3
                state.action = .throwMario
                state.timer = 0
            } else if input.animationFrame == 18 {
                state.throwState = 2
                state.action = .throwMario
                state.timer = 0
            }
        }
        effects.insert(.grab)
        if state.action == .throwMario { effects.insert(.throwAnimation) }
    }

    private static func advance(_ state: inout SM64ChuckyaState) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionY += state.velocityY
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
    }

    private static func approach(_ current: Float, target: Float, step: Float) -> Float {
        if current < target { return min(target, current + step) }
        if current > target { return max(target, current - step) }
        return current
    }

    private static func absAngleDiff(_ lhs: Int16, _ rhs: Int16) -> Int32 {
        let distance = abs(Int32(lhs) - Int32(rhs))
        return min(distance, 0x1_0000 - distance)
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }
}
