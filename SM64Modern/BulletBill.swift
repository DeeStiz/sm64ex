import Foundation

enum SM64BulletBillAction: UInt8, Equatable, Sendable {
    case reset = 0
    case waiting = 1
    case launching = 2
    case ended = 3
    case returning = 4
}

struct SM64BulletBillState: Equatable, Sendable {
    static let hitWallFlag: UInt32 = 1 << 9 // OBJ_MOVE_HIT_WALL

    var action: SM64BulletBillAction = .reset
    var initialMoveYaw: Int16 = 0
    var moveYaw: Int16 = 0
    var facePitch: Int16 = 0
    var faceRoll: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var positionY: Float = 0
    var timer: UInt32 = 0
    var intangible = false

    init(initialMoveYaw: Int16 = 0, moveYaw: Int16? = nil) {
        self.initialMoveYaw = initialMoveYaw
        self.moveYaw = moveYaw ?? initialMoveYaw
    }
}

struct SM64BulletBillTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var angleToMario: Int16
    var moveFlags: UInt32
    var homeY: Float
    var interacted: Bool

    init(
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        moveFlags: UInt32 = 0,
        homeY: Float = 0,
        interacted: Bool = false
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.moveFlags = moveFlags
        self.homeY = homeY
        self.interacted = interacted
    }
}

struct SM64BulletBillEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let resetToHome = Self(rawValue: 1 << 1)
    static let launch = Self(rawValue: 1 << 2)
    static let spawnSmoke = Self(rawValue: 1 << 3)
    static let launchSound = Self(rawValue: 1 << 4)
    static let screenShake = Self(rawValue: 1 << 5)
    static let spawnMist = Self(rawValue: 1 << 6)
    static let intangible = Self(rawValue: 1 << 7)
    static let tangible = Self(rawValue: 1 << 8)
    static let interactionReturn = Self(rawValue: 1 << 9)
    static let resetAction = Self(rawValue: 1 << 10)
}

struct SM64BulletBillTickResult: Equatable, Sendable {
    let state: SM64BulletBillState
    let effects: SM64BulletBillEffect
}

enum SM64BulletBillKernel {
    static func tick(
        _ input: SM64BulletBillTickInput,
        state: inout SM64BulletBillState
    ) -> SM64BulletBillTickResult {
        var effects: SM64BulletBillEffect = [.animate]

        switch state.action {
        case .reset:
            state.intangible = false
            state.forwardVelocity = 0
            state.moveYaw = state.initialMoveYaw
            state.facePitch = 0
            state.faceRoll = 0
            state.positionY = input.homeY
            state.timer = 0
            state.action = .waiting
            effects.insert([.resetToHome, .tangible])
        case .waiting:
            let angle = absAngleDiff(input.angleToMario, state.moveYaw)
            if angle < 0x2000,
               input.distanceToMario > 400,
               input.distanceToMario < 1_500 {
                state.action = .launching
                effects.insert(.launch)
            }
        case .launching:
            if state.timer < 40 {
                state.forwardVelocity = 3
            } else if state.timer < 50 {
                state.forwardVelocity = state.timer % 2 == 1 ? 3 : -3
            } else {
                effects.insert(.spawnSmoke)
                state.forwardVelocity = 30
                if input.distanceToMario > 300 {
                    _ = rotateYaw(
                        current: &state.moveYaw,
                        target: input.angleToMario,
                        increment: 0x100
                    )
                }
                if state.timer == 50 {
                    effects.insert([.launchSound, .screenShake])
                }
                if state.timer > 150 || input.moveFlags & SM64BulletBillState.hitWallFlag != 0 {
                    state.action = .ended
                    effects.insert(.spawnMist)
                }
            }
        case .ended:
            state.action = .reset
            effects.insert(.resetAction)
        case .returning:
            if state.timer == 0 {
                state.forwardVelocity = -30
                state.intangible = true
                effects.insert(.intangible)
            }
            state.facePitch &+= 0x1000
            state.faceRoll &+= 0x1000
            state.positionY += 20
            if state.timer > 90 {
                state.action = .reset
                effects.insert(.resetAction)
            }
        }

        // `cur_obj_check_interacted` runs after the action callback and can
        // therefore override an ended/launching action with action 4.
        if input.interacted {
            state.action = .returning
            effects.insert(.interactionReturn)
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64BulletBillTickResult(state: state, effects: effects)
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
}
