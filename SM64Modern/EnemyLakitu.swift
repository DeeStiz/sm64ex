import Foundation

enum SM64EnemyLakituAction: UInt8, Equatable, Sendable {
    case uninitialized = 0
    case main = 1
}

enum SM64EnemyLakituSubAction: UInt8, Equatable, Sendable {
    case noSpiny = 0
    case holdSpiny = 1
    case throwSpiny = 2
}

struct SM64EnemyLakituState: Equatable, Sendable {
    var action: SM64EnemyLakituAction = .uninitialized
    var subAction: SM64EnemyLakituSubAction = .noSpiny
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var faceYaw: Int16 = 0
    var moveYaw: Int16 = 0
    var faceForwardCountdown: Int16 = 0
    var spinyCooldown: Int16 = 0
    var numSpinies: UInt8 = 0
    var timer: UInt32 = 0
    var previousSpinyAttached = false
}

struct SM64EnemyLakituTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var angleToMario: Int16
    var marioForwardVelocity: Float
    var lakituY: Float
    var marioY: Float
    var drawingDistance: Float
    var hitWall: Bool
    var reflectedYaw: Int16
    var animationFrameTwo: Bool
    var animationNearEnd: Bool
    var attacked: Bool
    var randomFraction: Float

    init(
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        marioForwardVelocity: Float = 0,
        lakituY: Float = 0,
        marioY: Float = 0,
        drawingDistance: Float = 4_000,
        hitWall: Bool = false,
        reflectedYaw: Int16 = 0,
        animationFrameTwo: Bool = false,
        animationNearEnd: Bool = false,
        attacked: Bool = false,
        randomFraction: Float = 0
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.marioForwardVelocity = marioForwardVelocity
        self.lakituY = lakituY
        self.marioY = marioY
        self.drawingDistance = drawingDistance
        self.hitWall = hitWall
        self.reflectedYaw = reflectedYaw
        self.animationFrameTwo = animationFrameTwo
        self.animationNearEnd = animationNearEnd
        self.attacked = attacked
        self.randomFraction = randomFraction
    }
}

struct SM64EnemyLakituEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let revealAndCloud = Self(rawValue: 1 << 0)
    static let animate = Self(rawValue: 1 << 1)
    static let spawnSpiny = Self(rawValue: 1 << 2)
    static let beginHold = Self(rawValue: 1 << 3)
    static let beginThrow = Self(rawValue: 1 << 4)
    static let throwSound = Self(rawValue: 1 << 5)
    static let clearPreviousSpiny = Self(rawValue: 1 << 6)
    static let wallReflect = Self(rawValue: 1 << 7)
    static let attacked = Self(rawValue: 1 << 8)
}

struct SM64EnemyLakituTickResult: Equatable, Sendable {
    let state: SM64EnemyLakituState
    let effects: SM64EnemyLakituEffect
}

enum SM64EnemyLakituKernel {
    static func tick(
        _ input: SM64EnemyLakituTickInput,
        state: inout SM64EnemyLakituState
    ) -> SM64EnemyLakituTickResult {
        var effects: SM64EnemyLakituEffect = [.animate]

        switch state.action {
        case .uninitialized:
            if input.distanceToMario < 2_000 {
                state.action = .main
                effects.insert(.revealAndCloud)
            }
        case .main:
            updateSpeedAndAngle(input: input, state: &state, effects: &effects)
            switch state.subAction {
            case .noSpiny:
                noSpiny(input: input, state: &state, effects: &effects)
            case .holdSpiny:
                holdSpiny(input: input, state: &state, effects: &effects)
            case .throwSpiny:
                throwSpiny(input: input, state: &state, effects: &effects)
            }
            if input.attacked {
                state.previousSpinyAttached = false
                effects.insert(.attacked)
            }
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64EnemyLakituTickResult(state: state, effects: effects)
    }

    private static func updateSpeedAndAngle(
        input: SM64EnemyLakituTickInput,
        state: inout SM64EnemyLakituState,
        effects: inout SM64EnemyLakituEffect
    ) {
        let distance = min(input.distanceToMario, 500)
        let minimumSpeed = max(1.2 * input.marioForwardVelocity, 8)
        state.forwardVelocity = min(max(distance * 0.04, minimumSpeed), 40)

        let margin: Float = state.velocityY < 0 ? -3 : 3
        let targetY = input.marioY + 300 + margin
        let targetVelocity: Float = input.lakituY < targetY ? 4 : -4
        _ = approach(&state.velocityY, target: targetVelocity, increment: 0.4)

        if state.faceForwardCountdown != 0 {
            state.faceForwardCountdown &-= 1
        } else {
            _ = rotateYaw(current: &state.faceYaw, target: input.angleToMario, increment: 0x600)
        }
        let turnSpeed = Int16(clamping: Int(distance * 2)).clamped(to: 0xC8...0xFA0)
        if input.hitWall {
            state.moveYaw = input.reflectedYaw
            effects.insert(.wallReflect)
        } else {
            _ = rotateYaw(current: &state.moveYaw, target: input.angleToMario, increment: turnSpeed)
        }
    }

    private static func noSpiny(
        input: SM64EnemyLakituTickInput,
        state: inout SM64EnemyLakituState,
        effects: inout SM64EnemyLakituEffect
    ) {
        if state.spinyCooldown != 0 {
            state.spinyCooldown &-= 1
        } else if state.numSpinies < 3,
                  input.distanceToMario < 800,
                  absAngleDiff(input.angleToMario, state.faceYaw) < 0x4000 {
            state.numSpinies &+= 1
            state.subAction = .holdSpiny
            state.spinyCooldown = 30
            state.previousSpinyAttached = true
            effects.insert([.spawnSpiny, .beginHold])
        }
    }

    private static func holdSpiny(
        input: SM64EnemyLakituTickInput,
        state: inout SM64EnemyLakituState,
        effects: inout SM64EnemyLakituEffect
    ) {
        if state.spinyCooldown != 0 {
            state.spinyCooldown &-= 1
        } else if input.distanceToMario > input.drawingDistance - 100
                    || (input.distanceToMario < 500
                        && absAngleDiff(input.angleToMario, state.faceYaw) < 0x2000) {
            state.subAction = .throwSpiny
            state.faceForwardCountdown = 20
            effects.insert(.beginThrow)
        }
    }

    private static func throwSpiny(
        input: SM64EnemyLakituTickInput,
        state: inout SM64EnemyLakituState,
        effects: inout SM64EnemyLakituEffect
    ) {
        if input.animationFrameTwo {
            state.previousSpinyAttached = false
            effects.insert([.throwSound, .clearPreviousSpiny])
        }
        if input.animationNearEnd {
            state.subAction = .noSpiny
            state.spinyCooldown = randomOffset(
                base: 100,
                range: 100,
                fraction: input.randomFraction
            )
        }
    }

    @discardableResult
    private static func approach(
        _ value: inout Float,
        target: Float,
        increment: Float
    ) -> Bool {
        let distance = target - value
        if distance > increment {
            value += increment
            return false
        }
        if distance < -increment {
            value -= increment
            return false
        }
        value = target
        return true
    }

    @discardableResult
    private static func rotateYaw(
        current: inout Int16,
        target: Int16,
        increment: Int16
    ) -> Bool {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) {
            current = current &+ increment
            return false
        }
        if distance < -Int32(increment) {
            current = current &- increment
            return false
        }
        current = target
        return true
    }

    private static func absAngleDiff(_ lhs: Int16, _ rhs: Int16) -> Int32 {
        let distance = abs(Int32(lhs) - Int32(rhs))
        return min(distance, 0x1_0000 - distance)
    }

    private static func randomOffset(
        base: Int16,
        range: Int16,
        fraction: Float
    ) -> Int16 {
        let bounded = max(0, min(0.999_999, fraction))
        return base &+ Int16(truncatingIfNeeded: Int32(Float(range) * bounded))
    }
}

private extension Int16 {
    func clamped(to range: ClosedRange<Int16>) -> Int16 {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
