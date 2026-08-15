import Foundation

enum SM64AmpKind: UInt8, Equatable, Sendable {
    case homing = 0
    case circling = 1
    case fixed = 2
}

enum SM64AmpAction: UInt8, Equatable, Sendable {
    case inactive = 0
    case appear = 1
    case active = 2
    case giveUp = 3
    case attackCooldown = 4
}

struct SM64AmpHitbox: Equatable, Sendable {
    let downOffset: Float
    let damageOrCoinValue: Int16
    let health: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let standard = Self(
        downOffset: 40,
        damageOrCoinValue: 1,
        health: 0,
        numLootCoins: 0,
        radius: 40,
        height: 50,
        hurtboxRadius: 50,
        hurtboxHeight: 60
    )
}

struct SM64AmpState: Equatable, Sendable {
    let kind: SM64AmpKind
    let rotationRadius: Float
    let hitbox: SM64AmpHitbox

    var action: SM64AmpAction
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var averageY: Float
    var scale: Float
    var moveYaw: Int16
    var faceYaw: Int16
    var facePitch: Int16
    var forwardVelocity: Float
    var ampYPhase: Int32
    var homingLockedOn = false
    var animationState: Int32 = 0
    var invisible: Bool
    var tangible = true
    var timer: UInt32 = 0

    init(
        kind: SM64AmpKind,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        rotationRadius: Float = 0,
        initialMoveYaw: Int16 = 0,
        initialPhase: Int32 = 0
    ) {
        self.kind = kind
        self.rotationRadius = rotationRadius
        self.hitbox = .standard
        self.action = kind == .homing ? .inactive : .active
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.averageY = homeY
        self.scale = kind == .homing ? 0.1 : 1
        self.moveYaw = initialMoveYaw
        self.faceYaw = initialMoveYaw
        self.facePitch = 0
        self.forwardVelocity = 0
        self.ampYPhase = initialPhase
        self.invisible = kind == .homing
        self.animationState = kind == .homing ? 0 : 1
    }
}

struct SM64AmpTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var angleToMario: Int16
    var marioHeadY: Float
    var verticalAngleToMario: Int16
    var cameraTargetYaw: Int16
    var homeRadiusExceeded: Bool
    var interacted: Bool

    init(
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        marioHeadY: Float = 0,
        verticalAngleToMario: Int16 = 0,
        cameraTargetYaw: Int16 = 0,
        homeRadiusExceeded: Bool = false,
        interacted: Bool = false
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.marioHeadY = marioHeadY
        self.verticalAngleToMario = verticalAngleToMario
        self.cameraTargetYaw = cameraTargetYaw
        self.homeRadiusExceeded = homeRadiusExceeded
        self.interacted = interacted
    }
}

struct SM64AmpEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let reveal = Self(rawValue: 1 << 1)
    static let chase = Self(rawValue: 1 << 2)
    static let giveUp = Self(rawValue: 1 << 3)
    static let resetHome = Self(rawValue: 1 << 4)
    static let attackCooldown = Self(rawValue: 1 << 5)
    static let intangible = Self(rawValue: 1 << 6)
    static let tangible = Self(rawValue: 1 << 7)
    static let buzz = Self(rawValue: 1 << 8)
    static let setHitbox = Self(rawValue: 1 << 9)
    static let animationState = Self(rawValue: 1 << 10)
}

struct SM64AmpTickResult: Equatable, Sendable {
    let state: SM64AmpState
    let effects: SM64AmpEffect
}

enum SM64AmpKernel {
    static func tick(
        _ input: SM64AmpTickInput,
        state: inout SM64AmpState
    ) -> SM64AmpTickResult {
        var effects: SM64AmpEffect = [.animate]

        switch state.kind {
        case .homing:
            tickHoming(input, state: &state, effects: &effects)
        case .circling, .fixed:
            tickCircling(input, state: &state, effects: &effects)
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64AmpTickResult(state: state, effects: effects)
    }

    private static func tickHoming(
        _ input: SM64AmpTickInput,
        state: inout SM64AmpState,
        effects: inout SM64AmpEffect
    ) {
        switch state.action {
        case .inactive:
            if input.distanceToMario < 800 {
                state.action = .appear
                state.invisible = false
                effects.insert(.reveal)
            }
        case .appear:
            state.moveYaw = approachAngle(
                current: state.moveYaw,
                target: input.cameraTargetYaw,
                increment: 0x1000
            )
            if state.timer < 30 {
                state.scale = 0.1 + 0.9 * (Float(state.timer) / 30)
            } else {
                state.animationState = 1
                effects.insert(.animationState)
            }
            if state.timer >= 91 {
                state.scale = 1
                state.action = .active
                state.ampYPhase = 0
                effects.insert(.chase)
            }
        case .active:
            if angleWithin(input.angleToMario, state.moveYaw, window: 0x400) {
                state.homingLockedOn = true
                state.timer = 0
            }

            if state.homingLockedOn {
                state.forwardVelocity = 15
                if state.averageY > input.marioHeadY + 150 {
                    state.averageY -= 10
                } else {
                    state.averageY = input.marioHeadY + 150
                }
                if state.timer >= 31 {
                    state.homingLockedOn = false
                }
            } else {
                state.forwardVelocity = 10
                state.moveYaw = approachAngle(
                    current: state.moveYaw,
                    target: input.angleToMario,
                    increment: 0x400
                )
                if state.averageY < input.marioHeadY + 250 {
                    state.averageY += 10
                }
            }

            state.positionY = state.averageY
                + SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: state.ampYPhase &* 0x400)) * 20
            moveForward(&state)
            effects.insert([.setHitbox, .buzz])

            if input.homeRadiusExceeded {
                state.action = .giveUp
                effects.insert(.giveUp)
            } else if input.interacted {
                state.action = .attackCooldown
                effects.insert(.attackCooldown)
            }
        case .giveUp:
            state.forwardVelocity = 15
            moveForward(&state)
            if state.timer >= 151 {
                state.positionX = state.homeX
                state.positionY = state.homeY
                state.positionZ = state.homeZ
                state.invisible = true
                state.action = .inactive
                state.animationState = 0
                state.forwardVelocity = 0
                state.averageY = state.homeY
                effects.insert(.resetHome)
            }
        case .attackCooldown:
            state.forwardVelocity = 0
            state.tangible = false
            effects.insert(.intangible)
            if state.timer >= 31 { state.animationState = 0 }
            if state.timer >= 91 {
                state.animationState = 1
                state.tangible = true
                state.action = .active
                effects.insert(.tangible)
            }
        }

        state.faceYaw = state.moveYaw
        state.ampYPhase &+= 1
    }

    private static func tickCircling(
        _ input: SM64AmpTickInput,
        state: inout SM64AmpState,
        effects: inout SM64AmpEffect
    ) {
        switch state.action {
        case .active:
            if state.kind == .fixed {
                state.faceYaw = approachAngle(
                    current: state.faceYaw,
                    target: input.angleToMario,
                    increment: 0x1000
                )
                state.facePitch = approachAngle(
                    current: state.facePitch,
                    target: input.verticalAngleToMario,
                    increment: 0x1000
                )
                state.positionY = state.homeY
                    + SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: state.ampYPhase &* 0x458)) * 20
            } else {
                state.positionX = state.homeX
                    + SM64CanonicalTrig.sins(state.moveYaw) * state.rotationRadius
                state.positionZ = state.homeZ
                    + SM64CanonicalTrig.coss(state.moveYaw) * state.rotationRadius
                state.positionY = state.homeY
                    + SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: state.ampYPhase &* 0x8B0)) * 30
                state.moveYaw &+= 0x400
                state.faceYaw = state.moveYaw &+ 0x4000
            }
            effects.insert(.setHitbox)
            if state.kind != .fixed { effects.insert(.buzz) }
            if input.interacted {
                state.action = .attackCooldown
                effects.insert(.attackCooldown)
            }
            state.ampYPhase &+= 1
        case .attackCooldown:
            state.forwardVelocity = 0
            state.tangible = false
            effects.insert(.intangible)
            if state.timer >= 31 { state.animationState = 0 }
            if state.timer >= 91 {
                state.animationState = 1
                state.tangible = true
                state.action = .active
                effects.insert(.tangible)
            }
        case .inactive, .appear, .giveUp:
            break
        }
    }

    private static func moveForward(_ state: inout SM64AmpState) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
    }

    private static func angleWithin(_ lhs: Int16, _ rhs: Int16, window: Int16) -> Bool {
        let distance = abs(Int32(lhs) - Int32(rhs))
        return distance < Int32(window)
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }
}
