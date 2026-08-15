import Foundation

/// The water-bomb behavior is a three-node family: a proximity spawner, the
/// falling/bouncing bomb, and a parent-relative shadow.  The nodes remain
/// value-only here; allocation and parent links belong to
/// `SM64WaterBombObjectBridge`.
enum SM64WaterBombKind: UInt8, Equatable, Sendable {
    case spawner = 0
    case bomb = 1
    case shadow = 2
}

enum SM64WaterBombAction: UInt8, Equatable, Sendable {
    case shotFromCannon = 0
    case initialize = 1
    case drop = 2
    case explode = 3
}

struct SM64WaterBombHitbox: Equatable, Sendable {
    let interactType: UInt32
    let downOffset: Float
    let damageOrCoinValue: Int16
    let health: Int16
    let numLootCoins: UInt8
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let standard = Self(
        // INTERACT_MR_BLIZZARD (interaction.h).
        interactType: 1 << 21,
        downOffset: 25,
        damageOrCoinValue: 1,
        health: 99,
        numLootCoins: 0,
        radius: 80,
        height: 50,
        hurtboxRadius: 60,
        hurtboxHeight: 50
    )
}

struct SM64WaterBombSpawnerState: Equatable, Sendable {
    let kind: SM64WaterBombKind
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var radiusParameter: UInt16
    var bombActive = false
    var timeToSpawn: UInt16 = 0
    var timer: UInt32 = 0

    init(
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        radiusParameter: UInt16 = 0
    ) {
        self.kind = .spawner
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.radiusParameter = radiusParameter
    }
}

struct SM64WaterBombSpawnerTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var marioX: Float
    var marioY: Float
    var marioZ: Float
    var marioForwardVelocity: Float
    var marioMoveYaw: Int16
    var randomDelay: UInt16

    init(
        distanceToMario: Float = 10_000,
        marioX: Float = 0,
        marioY: Float = 0,
        marioZ: Float = 0,
        marioForwardVelocity: Float = 0,
        marioMoveYaw: Int16 = 0,
        randomDelay: UInt16 = 0
    ) {
        self.distanceToMario = distanceToMario
        self.marioX = marioX
        self.marioY = marioY
        self.marioZ = marioZ
        self.marioForwardVelocity = marioForwardVelocity
        self.marioMoveYaw = marioMoveYaw
        self.randomDelay = randomDelay
    }
}

struct SM64WaterBombState: Equatable, Sendable {
    let kind: SM64WaterBombKind
    let hitbox: SM64WaterBombHitbox

    var action: SM64WaterBombAction
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var floorHeight: Float
    var moveFlags: UInt32 = 0
    var moveYaw: Int16
    var angleToMario: Int16
    var forwardVelocity: Float
    var velocityY: Float
    var verticalStretch: Float = 0
    var stretchSpeed: Float = 0
    var onGround = false
    var numBounces: Float = 0
    var scaleX: Float = 1
    var scaleY: Float = 1
    var scaleZ: Float = 1
    var timer: UInt32 = 0
    var markedForDeletion = false

    init(
        action: SM64WaterBombAction = .initialize,
        positionX: Float = 0,
        positionY: Float = 0,
        positionZ: Float = 0,
        floorHeight: Float = 0,
        moveYaw: Int16 = 0,
        angleToMario: Int16 = 0,
        forwardVelocity: Float = 0,
        velocityY: Float = 0,
        scale: Float = 1
    ) {
        self.kind = .bomb
        self.hitbox = .standard
        self.action = action
        self.positionX = positionX
        self.positionY = positionY
        self.positionZ = positionZ
        self.floorHeight = floorHeight
        self.moveYaw = moveYaw
        self.angleToMario = angleToMario
        self.forwardVelocity = forwardVelocity
        self.velocityY = velocityY
        self.scaleX = scale
        self.scaleY = scale
        self.scaleZ = scale
    }
}

struct SM64WaterBombTickInput: Equatable, Sendable {
    var moveFlags: UInt32
    var interacted: Bool
    var angleToMario: Int16
    var floorHeight: Float
    var transformDeltaX: Float
    var transformDeltaY: Float
    var transformDeltaZ: Float

    init(
        moveFlags: UInt32 = 0,
        interacted: Bool = false,
        angleToMario: Int16 = 0,
        floorHeight: Float = 0,
        transformDeltaX: Float = 0,
        transformDeltaY: Float = 0,
        transformDeltaZ: Float = 0
    ) {
        self.moveFlags = moveFlags
        self.interacted = interacted
        self.angleToMario = angleToMario
        self.floorHeight = floorHeight
        self.transformDeltaX = transformDeltaX
        self.transformDeltaY = transformDeltaY
        self.transformDeltaZ = transformDeltaZ
    }
}

struct SM64WaterBombShadowState: Equatable, Sendable {
    let kind: SM64WaterBombKind

    var positionX: Float = 0
    var positionY: Float = 0
    var positionZ: Float = 0
    var scaleX: Float = 1
    var scaleY: Float = 1
    var scaleZ: Float = 1
    var timer: UInt32 = 0
    var markedForDeletion = false

    init() {
        self.kind = .shadow
    }
}

struct SM64WaterBombEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let spawnBomb = Self(rawValue: 1 << 1)
    static let landingSound = Self(rawValue: 1 << 2)
    static let bounceSound = Self(rawValue: 1 << 3)
    static let diveSound = Self(rawValue: 1 << 4)
    static let screenShake = Self(rawValue: 1 << 5)
    static let spawnParticles = Self(rawValue: 1 << 6)
    static let cannonParticles = Self(rawValue: 1 << 7)
    static let clearSpawner = Self(rawValue: 1 << 8)
    static let markForDeletion = Self(rawValue: 1 << 9)
    static let shadowHidden = Self(rawValue: 1 << 10)
}

struct SM64WaterBombSpawnerTickResult: Equatable, Sendable {
    let state: SM64WaterBombSpawnerState
    let effects: SM64WaterBombEffect
}

struct SM64WaterBombTickResult: Equatable, Sendable {
    let state: SM64WaterBombState
    let effects: SM64WaterBombEffect
}

struct SM64WaterBombShadowTickResult: Equatable, Sendable {
    let state: SM64WaterBombShadowState
    let effects: SM64WaterBombEffect
}

enum SM64WaterBombKernel {
    // Values from object_constants.h.
    static let enteredWaterFlag: UInt32 = 1 << 3
    static let maskOnGround: UInt32 = (1 << 0) | (1 << 1)

    static func tickSpawner(
        _ input: SM64WaterBombSpawnerTickInput,
        state: inout SM64WaterBombSpawnerState
    ) -> SM64WaterBombSpawnerTickResult {
        var effects: SM64WaterBombEffect = [.animate]
        let radius = 50 * Float(state.radiusParameter) + 200
        let dx = input.marioX - state.positionX
        let dz = input.marioZ - state.positionZ
        let lateralDistance = (dx * dx + dz * dz).squareRoot()

        // This deliberately mirrors the C gate: the vertical comparison is
        // one-sided, so a Mario below the spawner remains eligible.
        if !state.bombActive,
           lateralDistance < radius,
           input.marioY - state.positionY < 1_000 {
            if state.timeToSpawn != 0 {
                state.timeToSpawn &-= 1
            } else {
                state.bombActive = true
                state.timeToSpawn = min(input.randomDelay, 50)
                effects.insert(.spawnBomb)
            }
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64WaterBombSpawnerTickResult(state: state, effects: effects)
    }

    static func tickBomb(
        _ input: SM64WaterBombTickInput,
        state: inout SM64WaterBombState
    ) -> SM64WaterBombTickResult {
        var effects: SM64WaterBombEffect = [.animate]
        state.floorHeight = input.floorHeight
        state.angleToMario = input.angleToMario

        switch state.action {
        case .shotFromCannon:
            tickShotFromCannon(input, state: &state, effects: &effects)

        case .initialize:
            state.action = .drop
            state.velocityY = -40
            state.forwardVelocity = 0
            state.verticalStretch = 0
            state.scaleX = 1
            state.scaleY = 1
            state.scaleZ = 1
            effects.insert(.landingSound)

        case .drop:
            state.moveFlags = input.moveFlags
            if input.interacted || input.moveFlags & Self.enteredWaterFlag != 0 {
                state.action = .explode
                effects.insert([.diveSound, .screenShake])
            } else if input.moveFlags & Self.maskOnGround != 0 {
                if !state.onGround {
                    state.onGround = true
                    state.numBounces += 1
                    if state.numBounces < 3 {
                        effects.insert(.bounceSound)
                    } else {
                        effects.insert(.diveSound)
                    }
                    effects.insert(.screenShake)
                    state.moveYaw = state.angleToMario
                    state.forwardVelocity = 10
                    state.stretchSpeed = -40
                }

                state.stretchSpeed += 15 - state.numBounces * 2.8
                state.verticalStretch += state.stretchSpeed * 0.01
                if state.verticalStretch < -0.8 {
                    state.action = .explode
                } else if state.verticalStretch > 0.1 {
                    state.velocityY = 1.8 * state.stretchSpeed
                }
            } else {
                approach(&state.verticalStretch, target: 0, increment: 0.008)
                state.onGround = false
            }

            state.scaleY = state.verticalStretch + 1
            var stretch = state.verticalStretch
            if state.numBounces == 3 { stretch *= 4 }
            state.scaleX = 1 - stretch
            state.scaleZ = state.scaleX
            moveStandard(state: &state)

        case .explode:
            effects.insert([.spawnParticles, .clearSpawner, .markForDeletion])
            state.markedForDeletion = true
        }

        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        return SM64WaterBombTickResult(state: state, effects: effects)
    }

    static func tickShadow(
        parent: SM64WaterBombState,
        state: inout SM64WaterBombShadowState
    ) -> SM64WaterBombShadowTickResult {
        var effects: SM64WaterBombEffect = [.animate]
        if parent.action == .explode || parent.markedForDeletion {
            state.markedForDeletion = true
            effects.insert(.shadowHidden)
        } else {
            let bombHeight = min(parent.positionY - parent.floorHeight, 500)
            state.positionX = parent.positionX
            state.positionY = parent.floorHeight + bombHeight
            state.positionZ = parent.positionZ
            state.scaleX = parent.scaleX
            state.scaleY = parent.scaleY
            state.scaleZ = parent.scaleZ
        }
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
        if state.markedForDeletion { effects.insert(.markForDeletion) }
        return SM64WaterBombShadowTickResult(state: state, effects: effects)
    }

    private static func tickShotFromCannon(
        _ input: SM64WaterBombTickInput,
        state: inout SM64WaterBombState,
        effects: inout SM64WaterBombEffect
    ) {
        if state.timer > 100 {
            state.markedForDeletion = true
            effects.insert(.markForDeletion)
            return
        }

        if state.timer < 7 {
            effects.insert(.cannonParticles)
            if state.timer == 1 { effects.insert(.spawnParticles) }
        }
        if state.scaleY > 1.2 {
            state.scaleY -= 0.1
        }
        state.scaleX = 2 - state.scaleY
        state.scaleZ = state.scaleX
        state.positionX += input.transformDeltaX
        state.positionY += input.transformDeltaY
        state.positionZ += input.transformDeltaZ
    }

    private static func moveStandard(state: inout SM64WaterBombState) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
        // SET_OBJ_PHYSICS installs -4 gravity and 2 buoyancy. Water-entry is
        // supplied by the collision boundary above, so the normal path uses
        // the legacy -4 acceleration and terminal velocity of -78.
        state.velocityY = max(state.velocityY - 4, -78)
        state.positionY += state.velocityY
    }

    private static func approach(
        _ value: inout Float,
        target: Float,
        increment: Float
    ) {
        let distance = target - value
        if distance > increment {
            value += increment
        } else if distance < -increment {
            value -= increment
        } else {
            value = target
        }
    }
}
