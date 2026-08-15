import Foundation

enum SM64BirdKind: UInt8, Equatable, Sendable {
    case spawned = 0
    case spawner = 1
}

enum SM64BirdAction: UInt8, Equatable, Sendable {
    case inactive = 0
    case fly = 1
}

struct SM64BirdState: Equatable, Sendable {
    let kind: SM64BirdKind

    var action: SM64BirdAction = .inactive
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var moveYaw: Int16 = 0
    var movePitch: Int16 = 0
    var faceRoll: Int16 = 0
    var targetYaw: Int16 = 0
    var targetPitch: Int16 = 0
    var birdSpeed: Float = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var invisible: Bool = true
    var markedForDeletion = false
    var timer: UInt32 = 0

    init(
        kind: SM64BirdKind,
        homeX: Float = 0,
        homeY: Float = 0,
        homeZ: Float = 0,
        positionX: Float? = nil,
        positionY: Float? = nil,
        positionZ: Float? = nil,
        moveYaw: Int16 = 0,
        movePitch: Int16 = 0,
        birdSpeed: Float = 0,
        invisible: Bool = true
    ) {
        self.kind = kind
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = positionX ?? homeX
        self.positionY = positionY ?? homeY
        self.positionZ = positionZ ?? homeZ
        self.moveYaw = moveYaw
        self.movePitch = movePitch
        self.targetYaw = moveYaw
        self.birdSpeed = birdSpeed
        self.invisible = invisible
    }
}

struct SM64BirdTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var initialMoveYaw: Int16
    var initialMovePitch: Int16
    var homeDistance: Float
    var homeYaw: Int16
    var parentDistance: Float
    var parentY: Float
    var parentYaw: Int16
    var parentAbove8000: Bool

    init(
        distanceToMario: Float = 10_000,
        initialMoveYaw: Int16 = 0x1000,
        initialMovePitch: Int16 = 3_000,
        homeDistance: Float = 0,
        homeYaw: Int16 = 0,
        parentDistance: Float = 0,
        parentY: Float = 0,
        parentYaw: Int16 = 0,
        parentAbove8000: Bool = false
    ) {
        self.distanceToMario = distanceToMario
        self.initialMoveYaw = initialMoveYaw
        self.initialMovePitch = initialMovePitch
        self.homeDistance = homeDistance
        self.homeYaw = homeYaw
        self.parentDistance = parentDistance
        self.parentY = parentY
        self.parentYaw = parentYaw
        self.parentAbove8000 = parentAbove8000
    }
}

struct SM64BirdEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let reveal = Self(rawValue: 1 << 1)
    static let flyAwaySound = Self(rawValue: 1 << 2)
    static let spawnChildren = Self(rawValue: 1 << 3)
    static let markForDeletion = Self(rawValue: 1 << 4)
    static let flight = Self(rawValue: 1 << 5)
}

struct SM64BirdTickResult: Equatable, Sendable {
    let state: SM64BirdState
    let effects: SM64BirdEffect
}

enum SM64BirdKernel {
    static func tick(
        _ input: SM64BirdTickInput,
        state: inout SM64BirdState
    ) -> SM64BirdTickResult {
        var effects: SM64BirdEffect = [.animate]

        switch state.action {
        case .inactive:
            if state.kind == .spawned || input.distanceToMario < 2_000 {
                if state.kind == .spawner {
                    state.homeX = -20
                    state.homeZ = -3_990
                    effects.insert([.flyAwaySound, .spawnChildren])
                }
                state.action = .fly
                state.movePitch = input.initialMovePitch
                state.moveYaw = input.initialMoveYaw
                state.targetPitch = state.movePitch
                state.targetYaw = state.moveYaw
                state.birdSpeed = 40
                state.invisible = false
                effects.insert([.reveal, .flight])
            }
        case .fly:
            state.forwardVelocity = state.birdSpeed * SM64CanonicalTrig.coss(state.movePitch)
            state.velocityY = state.birdSpeed * -SM64CanonicalTrig.sins(state.movePitch)

            if input.parentAbove8000 {
                state.markedForDeletion = true
                effects.insert(.markForDeletion)
            } else if state.kind == .spawner {
                state.targetPitch = SM64CanonicalTrig.atan2s(
                    y: input.homeDistance,
                    x: state.positionY - 10_000
                )
                state.targetYaw = input.homeYaw
                approachFlightAngles(state: &state)
            } else {
                state.targetPitch = SM64CanonicalTrig.atan2s(
                    y: input.parentDistance,
                    x: state.positionY - input.parentY
                )
                state.targetYaw = input.parentYaw
                state.birdSpeed = 0.04 * input.parentDistance + 20
                approachFlightAngles(state: &state)
            }

            state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
            state.positionY += state.velocityY
            state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64BirdTickResult(state: state, effects: effects)
    }

    private static func approachFlightAngles(state: inout SM64BirdState) {
        state.movePitch = approachAngle(current: state.movePitch, target: state.targetPitch, increment: 140)
        let yawBefore = state.moveYaw
        state.moveYaw = approachAngle(current: state.moveYaw, target: state.targetYaw, increment: 800)
        let targetRoll = clamp(
            Int32(yawBefore) - Int32(state.targetYaw),
            minimum: -0x3000,
            maximum: 0x3000
        )
        state.faceRoll = approachAngle(
            current: state.faceRoll,
            target: Int16(targetRoll),
            increment: 600
        )
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }

    private static func clamp(_ value: Int32, minimum: Int32, maximum: Int32) -> Int32 {
        min(maximum, max(minimum, value))
    }
}
