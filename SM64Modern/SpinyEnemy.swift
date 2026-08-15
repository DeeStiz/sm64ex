import Foundation

enum SM64SpinyAction: UInt8, Equatable, Sendable {
    case walk = 0
    case heldByLakitu = 1
    case thrownByLakitu = 2
    case attackedMario = 3
}

enum SM64SpinyAttack: UInt8, Equatable, Sendable {
    case none = 0
    case punch = 1
    case kickOrTrip = 2
    case fromAbove = 3
    case groundPound = 4
    case fastAttack = 5
    case fromBelow = 6
}

enum SM64SpinyAttackHandler: UInt8, Equatable, Sendable {
    case nop = 0
    case knockback = 2
}

struct SM64SpinyHitbox: Equatable, Sendable {
    let damageOrCoinValue: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float
}

struct SM64SpinyState: Equatable, Sendable {
    let hitbox: SM64SpinyHitbox

    var action: SM64SpinyAction
    var moveAngleYaw: Int16
    var faceAngleYaw: Int16
    var faceAnglePitch: Int16 = 0
    var targetYaw: Int16
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var turningAwayFromWall = false
    var setFaceYawToMoveYaw = false
    var timeUntilTurn: Int16 = 0
    var graphYOffset: Float = -17
    var moveFlags: UInt32 = 0
    var timer: UInt32 = 0
    var markedForDeletion = false

    init(
        action: SM64SpinyAction = .walk,
        moveAngleYaw: Int16 = 0,
        faceAngleYaw: Int16 = 0
    ) {
        self.hitbox = SM64SpinyHitbox(
            damageOrCoinValue: 2,
            numLootCoins: 0,
            radius: 80,
            height: 50,
            hurtboxRadius: 40,
            hurtboxHeight: 40
        )
        self.action = action
        self.moveAngleYaw = moveAngleYaw
        self.faceAngleYaw = faceAngleYaw
        self.targetYaw = moveAngleYaw
    }
}

struct SM64SpinyTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var hasParent: Bool
    var parentPreviousObjectExists: Bool
    var parentForwardVelocity: Float
    var parentMoveAngleYaw: Int16
    var parentFaceAngleYaw: Int16
    var onGround: Bool
    var landed: Bool
    var hitWall: Bool
    var reflectedYaw: Int16
    var hitEdge: Bool
    var objectCollision: Bool
    var randomU16: UInt16
    var randomFraction: Float
    var attack: SM64SpinyAttack

    init(
        distanceToMario: Float = 10_000,
        hasParent: Bool = false,
        parentPreviousObjectExists: Bool = false,
        parentForwardVelocity: Float = 0,
        parentMoveAngleYaw: Int16 = 0,
        parentFaceAngleYaw: Int16 = 0,
        onGround: Bool = true,
        landed: Bool = false,
        hitWall: Bool = false,
        reflectedYaw: Int16 = 0,
        hitEdge: Bool = false,
        objectCollision: Bool = false,
        randomU16: UInt16 = 0,
        randomFraction: Float = 0,
        attack: SM64SpinyAttack = .none
    ) {
        self.distanceToMario = distanceToMario
        self.hasParent = hasParent
        self.parentPreviousObjectExists = parentPreviousObjectExists
        self.parentForwardVelocity = parentForwardVelocity
        self.parentMoveAngleYaw = parentMoveAngleYaw
        self.parentFaceAngleYaw = parentFaceAngleYaw
        self.onGround = onGround
        self.landed = landed
        self.hitWall = hitWall
        self.reflectedYaw = reflectedYaw
        self.hitEdge = hitEdge
        self.objectCollision = objectCollision
        self.randomU16 = randomU16
        self.randomFraction = randomFraction
        self.attack = attack
    }
}

struct SM64SpinyEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let turn = Self(rawValue: 1 << 1)
    static let attackResponse = Self(rawValue: 1 << 2)
    static let throwFromLakitu = Self(rawValue: 1 << 3)
    static let landed = Self(rawValue: 1 << 4)
    static let markForDeletion = Self(rawValue: 1 << 5)
    static let decrementParentCount = Self(rawValue: 1 << 6)
    static let wallReflect = Self(rawValue: 1 << 7)
}

struct SM64SpinyTickResult: Equatable, Sendable {
    let state: SM64SpinyState
    let effects: SM64SpinyEffect
    let attackHandler: SM64SpinyAttackHandler
    let attackAccepted: Bool
}

enum SM64SpinyAttackTable {
    static func decision(_ attack: SM64SpinyAttack) -> SM64SpinyAttackHandler {
        switch attack {
        case .punch, .kickOrTrip, .fastAttack, .fromBelow:
            return .knockback
        case .none, .fromAbove, .groundPound:
            return .nop
        }
    }
}

enum SM64SpinyKernel {
    static func tick(
        _ input: SM64SpinyTickInput,
        state: inout SM64SpinyState
    ) -> SM64SpinyTickResult {
        var effects: SM64SpinyEffect = [.animate]
        let handler = SM64SpinyAttackTable.decision(input.attack)

        switch state.action {
        case .walk:
            walk(input: input, state: &state, effects: &effects)
            if handler == .knockback {
                state.action = .walk
                state.forwardVelocity *= 0.1
                state.velocityY *= 0.7
                state.moveFlags = 0
                effects.insert(.attackResponse)
            }
        case .heldByLakitu:
            state.graphYOffset = 15
            if !input.parentPreviousObjectExists {
                state.action = .thrownByLakitu
                state.moveAngleYaw = input.parentFaceAngleYaw
                let delta = Int16(truncatingIfNeeded: Int32(state.moveAngleYaw) - Int32(input.parentMoveAngleYaw))
                state.forwardVelocity = input.parentForwardVelocity * SM64CanonicalTrig.coss(delta) + 10
                state.velocityY = 30
                state.moveFlags = 0
                effects.insert(.throwFromLakitu)
            }
        case .thrownByLakitu:
            if checkActive(input: input, state: &state, effects: &effects) {
                state.graphYOffset = 15
                if input.landed || input.onGround {
                    state.action = .walk
                    state.graphYOffset = -17
                    state.faceAnglePitch = 0
                    effects.insert(.landed)
                } else if input.hitWall {
                    state.moveAngleYaw = input.reflectedYaw
                    effects.insert(.wallReflect)
                }
                if handler != .nop && input.hasParent {
                    effects.insert(.decrementParentCount)
                }
            }
        case .attackedMario:
            if state.timer >= 30 {
                state.action = .walk
                state.timer = 0
            }
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64SpinyTickResult(
            state: state,
            effects: effects,
            attackHandler: handler,
            attackAccepted: handler != .nop
        )
    }

    private static func walk(
        input: SM64SpinyTickInput,
        state: inout SM64SpinyState,
        effects: inout SM64SpinyEffect
    ) {
        guard checkActive(input: input, state: &state, effects: &effects) else { return }
        state.graphYOffset = -17

        if input.onGround {
            if !state.setFaceYawToMoveYaw {
                if approach(&state.forwardVelocity, target: 0, increment: 1) {
                    state.setFaceYawToMoveYaw = true
                    state.moveAngleYaw = state.faceAngleYaw
                }
            } else {
                _ = approach(&state.forwardVelocity, target: 1, increment: 0.2)
            }

            if state.turningAwayFromWall {
                state.turningAwayFromWall = !rotateYaw(
                    current: &state.moveAngleYaw,
                    target: state.targetYaw,
                    increment: 0x80
                )
            } else if input.hitWall || input.hitEdge || input.objectCollision {
                state.targetYaw = input.hitWall
                    ? input.reflectedYaw
                    : Int16(truncatingIfNeeded: Int32(state.moveAngleYaw) + 0x8000)
                state.turningAwayFromWall = true
                effects.insert(.turn)
            } else if state.timeUntilTurn != 0 {
                state.timeUntilTurn &-= 1
            } else {
                let sign: Int32 = input.randomU16 >= 0x7FFF ? 1 : -1
                state.targetYaw = Int16(
                    truncatingIfNeeded: Int32(state.moveAngleYaw) + sign * 0x2000
                )
                state.timeUntilTurn = randomOffset(
                    base: 100,
                    range: 100,
                    fraction: input.randomFraction
                )
                effects.insert(.turn)
            }
            _ = rotateYaw(
                current: &state.moveAngleYaw,
                target: state.targetYaw,
                increment: 0x80
            )
        } else if input.hitWall {
            state.moveAngleYaw = input.reflectedYaw
            effects.insert(.wallReflect)
        }
    }

    @discardableResult
    private static func checkActive(
        input: SM64SpinyTickInput,
        state: inout SM64SpinyState,
        effects: inout SM64SpinyEffect
    ) -> Bool {
        guard input.hasParent && input.distanceToMario > 2_500 else { return true }
        state.markedForDeletion = true
        effects.insert(.markForDeletion)
        return false
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

    private static func randomOffset(
        base: Int16,
        range: Int16,
        fraction: Float
    ) -> Int16 {
        let bounded = max(0, min(0.999_999, fraction))
        return base &+ Int16(truncatingIfNeeded: Int32(Float(range) * bounded))
    }
}
