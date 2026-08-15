import Foundation

enum SM64GoombaSize: UInt8, Equatable, Sendable {
    case regular = 0
    case huge = 1
    case tiny = 2
}

enum SM64GoombaAction: UInt8, Equatable, Sendable {
    case walk = 0
    case attackedMario = 1
    case jump = 2
}

enum SM64GoombaAttack: UInt8, Equatable, Sendable {
    case none = 0
    case weak = 1
    case fromAbove = 2
    case groundPound = 3
    case punch = 4
    case kickOrTrip = 5
    case fastAttack = 6
    case fromBelow = 7
}

enum SM64GoombaDeathSound: UInt8, Equatable, Sendable {
    case high = 0
    case low = 1
}

struct SM64GoombaHitbox: Equatable, Sendable {
    let damageOrCoinValue: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float
}

struct SM64GoombaState: Equatable, Sendable {
    let size: SM64GoombaSize
    let scale: Float
    let deathSound: SM64GoombaDeathSound
    let drawDistance: Float
    let damage: Int16
    let gravity: Float
    let hitbox: SM64GoombaHitbox

    var action: SM64GoombaAction = .walk
    var moveAngleYaw: Int16 = 0
    var targetYaw: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var relativeSpeed: Float = 4.0 / 3.0
    var walkTimer: Int16 = 0
    var turningAwayFromWall = false
    var timer: UInt32 = 0
    var health: Int16 = 1
    var numLootCoins: UInt8 = 1
    var markedForDeletion = false
    var respawnMarked = false
    var animationSpeed: Float = 1
    var animationState: UInt8 = 0

    init(size: SM64GoombaSize, moveAngleYaw: Int16 = 0) {
        self.size = size
        switch size {
        case .regular:
            scale = 1.5
            deathSound = .high
            drawDistance = 4000
            damage = 1
        case .huge:
            scale = 3.5
            deathSound = .low
            drawDistance = 4000
            damage = 2
        case .tiny:
            scale = 0.5
            deathSound = .high
            drawDistance = 1500
            damage = 0
        }
        gravity = -8.0 / 3.0 * scale
        hitbox = SM64GoombaHitbox(
            damageOrCoinValue: 1, numLootCoins: 1,
            radius: 72, height: 50,
            hurtboxRadius: 42, hurtboxHeight: 40
        )
        self.moveAngleYaw = moveAngleYaw
        self.targetYaw = moveAngleYaw
    }
}

struct SM64GoombaTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var angleToMario: Int16
    var onGround: Bool
    var hitWall: Bool
    var reflectedYaw: Int16
    var hitEdge: Bool
    var objectCollision: Bool
    var randomU16: UInt16
    var randomFraction: Float
    var attack: SM64GoombaAttack
    var attackedMario: Bool

    init(
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        onGround: Bool = true,
        hitWall: Bool = false,
        reflectedYaw: Int16 = 0,
        hitEdge: Bool = false,
        objectCollision: Bool = false,
        randomU16: UInt16 = 0,
        randomFraction: Float = 0,
        attack: SM64GoombaAttack = .none,
        attackedMario: Bool = false
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.onGround = onGround
        self.hitWall = hitWall
        self.reflectedYaw = reflectedYaw
        self.hitEdge = hitEdge
        self.objectCollision = objectCollision
        self.randomU16 = randomU16
        self.randomFraction = randomFraction
        self.attack = attack
        self.attackedMario = attackedMario
    }
}

struct SM64GoombaEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let alertSound = Self(rawValue: 1 << 0)
    static let walkSound = Self(rawValue: 1 << 1)
    static let jump = Self(rawValue: 1 << 2)
    static let attackResponse = Self(rawValue: 1 << 3)
    static let death = Self(rawValue: 1 << 4)
    static let coinDrop = Self(rawValue: 1 << 5)
    static let markRespawn = Self(rawValue: 1 << 6)
    static let animate = Self(rawValue: 1 << 7)
    static let landed = Self(rawValue: 1 << 8)
}

enum SM64GoombaAttackHandler: UInt8, Equatable, Sendable {
    case nop = 0
    case knockback = 2
    case squished = 3
    case hugeWeaklyAttacked = 7
    case squishedWithBlueCoin = 8
}

struct SM64GoombaAttackDecision: Equatable, Sendable {
    let handler: SM64GoombaAttackHandler
    let accepted: Bool
    let dropsBlueCoin: Bool
}

enum SM64GoombaAttackTable {
    /// Direct transcription of `sGoombaAttackHandlers` in goomba.inc.c.
    static func decision(
        size: SM64GoombaSize,
        attack: SM64GoombaAttack
    ) -> SM64GoombaAttackDecision {
        let handler: SM64GoombaAttackHandler
        switch size {
        case .regular, .tiny:
            switch attack {
            case .none:
                handler = .nop
            case .fromAbove, .groundPound:
                handler = .squished
            case .weak, .punch, .kickOrTrip, .fastAttack, .fromBelow:
                handler = .knockback
            }
        case .huge:
            switch attack {
            case .none:
                handler = .nop
            case .fromAbove:
                handler = .squished
            case .groundPound:
                handler = .squishedWithBlueCoin
            case .weak, .punch, .kickOrTrip, .fastAttack, .fromBelow:
                handler = .hugeWeaklyAttacked
            }
        }
        return SM64GoombaAttackDecision(
            handler: handler,
            accepted: handler != .nop,
            dropsBlueCoin: handler == .squishedWithBlueCoin
        )
    }
}

struct SM64GoombaCollisionSnapshot: Equatable, Sendable {
    var distanceToMario: Float
    var angleToMario: Int16
    var onGround: Bool
    var hitWall: Bool
    var reflectedYaw: Int16
    var hitEdge: Bool
    var objectCollision: Bool
    var randomU16: UInt16
    var randomFraction: Float
    var interactionStatus: UInt32

    init(
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        onGround: Bool = true,
        hitWall: Bool = false,
        reflectedYaw: Int16 = 0,
        hitEdge: Bool = false,
        objectCollision: Bool = false,
        randomU16: UInt16 = 0,
        randomFraction: Float = 0,
        interactionStatus: UInt32 = 0
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.onGround = onGround
        self.hitWall = hitWall
        self.reflectedYaw = reflectedYaw
        self.hitEdge = hitEdge
        self.objectCollision = objectCollision
        self.randomU16 = randomU16
        self.randomFraction = randomFraction
        self.interactionStatus = interactionStatus
    }
}

enum SM64GoombaCollisionKernel {
    static let attackMask: UInt32 = 0x0000_00FF
    static let attackedMarioMask: UInt32 = 1 << 13
    static let interactedMask: UInt32 = 1 << 15

    static func input(from snapshot: SM64GoombaCollisionSnapshot) -> SM64GoombaTickInput {
        let interacted = snapshot.interactionStatus & interactedMask != 0
        let attackedMario = snapshot.interactionStatus & attackedMarioMask != 0
        let encodedAttack = UInt8(truncatingIfNeeded: snapshot.interactionStatus & attackMask)
        let attack: SM64GoombaAttack
        if interacted && !attackedMario {
            switch encodedAttack {
            case 1: attack = .punch
            case 2: attack = .kickOrTrip
            case 3: attack = .fromAbove
            case 4: attack = .groundPound
            case 5: attack = .fastAttack
            case 6: attack = .fromBelow
            default: attack = .none
            }
        } else {
            attack = .none
        }
        return SM64GoombaTickInput(
            distanceToMario: snapshot.distanceToMario,
            angleToMario: snapshot.angleToMario,
            onGround: snapshot.onGround,
            hitWall: snapshot.hitWall,
            reflectedYaw: snapshot.reflectedYaw,
            hitEdge: snapshot.hitEdge,
            objectCollision: snapshot.objectCollision,
            randomU16: snapshot.randomU16,
            randomFraction: snapshot.randomFraction,
            attack: attack,
            attackedMario: interacted && attackedMario
        )
    }
}

struct SM64GoombaTickResult: Equatable, Sendable {
    let state: SM64GoombaState
    let effects: SM64GoombaEffect
    let attackHandler: SM64GoombaAttackHandler
    let attackAccepted: Bool
    let attackDropsBlueCoin: Bool
}

/// Bounded Swift shadow of `bhv_goomba_init` and its walk/attacked/jump action
/// boundaries. Collision resolution, object-list traversal, and effect
/// delivery remain owner-thread inputs/effects; no C object pointer crosses it.
enum SM64GoombaKernel {
    static func tick(
        _ input: SM64GoombaTickInput,
        state: inout SM64GoombaState
    ) -> SM64GoombaTickResult {
        var effects: SM64GoombaEffect = [.animate]
        let attackDecision = SM64GoombaAttackTable.decision(
            size: state.size,
            attack: input.attack
        )
        state.animationSpeed = max(
            1, state.forwardVelocity / state.scale * 0.4
        )

        switch state.action {
        case .walk:
            effects.formUnion(walk(input: input, state: &state))
        case .attackedMario:
            if state.size == .tiny {
                state.numLootCoins = 0
                state.markedForDeletion = true
                state.respawnMarked = true
                effects.formUnion([.markRespawn, .death, .coinDrop])
            } else {
                beginJump(state: &state, effects: &effects)
                state.targetYaw = input.angleToMario
                state.turningAwayFromWall = false
            }
        case .jump:
            if input.onGround {
                state.action = .walk
                effects.insert(.landed)
            } else {
                _ = rotateYaw(
                    current: &state.moveAngleYaw,
                    target: state.targetYaw,
                    increment: 0x800
                )
            }
        }

        if input.attackedMario {
            state.action = .attackedMario
            effects.insert(.attackResponse)
        }

        switch input.attack {
        case .none:
            break
        case .weak, .punch, .kickOrTrip, .fastAttack, .fromBelow:
            state.action = .attackedMario
            effects.insert(.attackResponse)
        case .fromAbove, .groundPound:
            state.action = .attackedMario
            effects.insert(.attackResponse)
            if state.size == .tiny {
                state.health = 0
            }
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64GoombaTickResult(
            state: state,
            effects: effects,
            attackHandler: attackDecision.handler,
            attackAccepted: attackDecision.accepted,
            attackDropsBlueCoin: attackDecision.dropsBlueCoin
        )
    }

    private static func walk(
        input: SM64GoombaTickInput,
        state: inout SM64GoombaState
    ) -> SM64GoombaEffect {
        var effects: SM64GoombaEffect = []
        state.forwardVelocity = approach(
            state.forwardVelocity,
            state.relativeSpeed * state.scale,
            0.4
        )

        if state.relativeSpeed > 4.0 / 3.0 {
            effects.insert(.walkSound)
        }

        if state.turningAwayFromWall {
            let done = rotateYaw(
                current: &state.moveAngleYaw,
                target: state.targetYaw,
                increment: 0x200
            )
            if done { state.turningAwayFromWall = false }
            return effects
        }

        if input.distanceToMario >= 25_000 {
            state.targetYaw = input.angleToMario
            state.walkTimer = randomOffset(
                base: 20, range: 30, fraction: input.randomFraction
            )
        }

        if input.hitWall {
            state.targetYaw = input.reflectedYaw
            state.turningAwayFromWall = true
        } else if input.hitEdge {
            state.targetYaw = addAngle(state.moveAngleYaw, 0x8000)
            state.turningAwayFromWall = true
        } else if input.objectCollision {
            state.turningAwayFromWall = true
        } else if input.distanceToMario < 500 {
            if state.relativeSpeed <= 2 {
                state.action = .jump
                state.forwardVelocity = 0
                state.velocityY = 50.0 / 3.0 * state.scale
                effects.insert([.alertSound, .jump])
            }
            state.targetYaw = input.angleToMario
            state.relativeSpeed = 20
        } else {
            state.relativeSpeed = 4.0 / 3.0
            if state.walkTimer != 0 {
                state.walkTimer &-= 1
            } else if input.randomU16 & 3 != 0 {
                let sign: Int16 = input.randomU16 >= 0x7FFF ? 1 : -1
                state.targetYaw = addAngle(
                    state.moveAngleYaw,
                    Int32(sign) * 0x2000
                )
                state.walkTimer = randomOffset(
                    base: 100, range: 100, fraction: input.randomFraction
                )
            } else {
                state.action = .jump
                state.forwardVelocity = 0
                state.velocityY = 50.0 / 3.0 * state.scale
                effects.insert([.alertSound, .jump])
                let sign: Int16 = input.randomU16 >= 0x7FFF ? 1 : -1
                state.targetYaw = addAngle(
                    state.moveAngleYaw,
                    Int32(sign) * 0x6000
                )
            }
        }

        _ = rotateYaw(
            current: &state.moveAngleYaw,
            target: state.targetYaw,
            increment: 0x200
        )
        return effects
    }

    private static func beginJump(
        state: inout SM64GoombaState,
        effects: inout SM64GoombaEffect
    ) {
        state.action = .jump
        state.forwardVelocity = 0
        state.velocityY = 50.0 / 3.0 * state.scale
        effects.formUnion([.alertSound, .jump])
    }

    private static func approach(
        _ value: Float, _ target: Float, _ increment: Float
    ) -> Float {
        let distance = target - value
        if distance > increment { return value + increment }
        if distance < -increment { return value - increment }
        return target
    }

    private static func rotateYaw(
        current: inout Int16, target: Int16, increment: Int16
    ) -> Bool {
        let next = approachYaw(current, target, increment)
        let done = next == current
        current = next
        return done
    }

    private static func approachYaw(
        _ value: Int16, _ target: Int16, _ increment: Int16
    ) -> Int16 {
        let distance = Int32(target) - Int32(value)
        if distance > Int32(increment) {
            return value &+ increment
        }
        if distance < -Int32(increment) {
            return value &- increment
        }
        return target
    }

    private static func addAngle(_ value: Int16, _ delta: Int32) -> Int16 {
        Int16(truncatingIfNeeded: Int32(value) &+ delta)
    }

    private static func randomOffset(
        base: Int16, range: Int16, fraction: Float
    ) -> Int16 {
        let bounded = max(0, min(0.999_999, fraction))
        return base &+ Int16(truncatingIfNeeded: Int32(Float(range) * bounded))
    }
}
