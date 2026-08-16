import Foundation

enum SM64BowserBombKind: UInt8, Equatable, Sendable {
    case bomb = 0
    case explosion = 1
    case smoke = 2
}

struct SM64BowserBombSmokeSpawn: Equatable, Sendable {
    let offset: SM64ObjectVector3
    let velocityY: Float

    init(offset: SM64ObjectVector3 = .zero, velocityY: Float = 0) {
        self.offset = offset
        self.velocityY = velocityY
    }
}

struct SM64BowserBombState: Equatable, Sendable {
    var timer: UInt32 = 0
    var visibilityDistance: Float = 7_000
    var markedForDeletion = false
}

struct SM64BowserBombTickInput: Equatable, Sendable {
    let collidedWithMario: Bool
    let hitMine: Bool

    init(collidedWithMario: Bool = false, hitMine: Bool = false) {
        self.collidedWithMario = collidedWithMario
        self.hitMine = hitMine
    }
}

struct SM64BowserBombExplosionState: Equatable, Sendable {
    var timer: UInt32 = 0
    var scale: Float = 1
    var animationState: Int32 = -1
    var markedForDeletion = false
}

struct SM64BowserBombExplosionTickInput: Equatable, Sendable {
    let smokeSpawn: SM64BowserBombSmokeSpawn

    init(smokeSpawn: SM64BowserBombSmokeSpawn = SM64BowserBombSmokeSpawn()) {
        self.smokeSpawn = smokeSpawn
    }
}

struct SM64BowserBombSmokeState: Equatable, Sendable {
    var position: SM64ObjectVector3 = .zero
    var velocityY: Float = 0
    var timer: UInt32 = 0
    var scale: Float = 1
    var opacity: Int32 = 255
    var animationState: Int32 = -1
    var markedForDeletion = false
}

struct SM64BowserBombEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let spawnExplosion = Self(rawValue: 1 << 0)
    static let spawnFlames = Self(rawValue: 1 << 1)
    static let sound = Self(rawValue: 1 << 2)
    static let cameraShake = Self(rawValue: 1 << 3)
    static let clearInteraction = Self(rawValue: 1 << 4)
    static let spawnSmoke = Self(rawValue: 1 << 5)
    static let animate = Self(rawValue: 1 << 6)
    static let fade = Self(rawValue: 1 << 7)
    static let markForDeletion = Self(rawValue: 1 << 8)
}

struct SM64BowserBombTickResult: Equatable, Sendable {
    let state: SM64BowserBombState
    let effects: SM64BowserBombEffect
}

struct SM64BowserBombExplosionTickResult: Equatable, Sendable {
    let state: SM64BowserBombExplosionState
    let effects: SM64BowserBombEffect
    let smokeSpawn: SM64BowserBombSmokeSpawn?
}

struct SM64BowserBombSmokeTickResult: Equatable, Sendable {
    let state: SM64BowserBombSmokeState
    let effects: SM64BowserBombEffect
}

/// Value translation of `bowser_bomb.inc.c`. Random smoke placement is an
/// explicit input so the owner bridge never reaches a process-global RNG.
enum SM64BowserBombKernel {
    static let interactedStatus: Int32 = 1 << 15
    static let hitMineStatus: Int32 = 1 << 21
    static let visibilityDistance: Float = 7_000
    static let explosionSound: Int32 = 0x312F0081 // SOUND_GENERAL_BOWSER_BOMB_EXPLOSION
    static let largeCameraShake: Int32 = 3 // SHAKE_POS_LARGE
    static let bombHitboxRadius: Float = 40
    static let bombHitboxHeight: Float = 40
    static let bombHitboxDownOffset: Float = 40
    static let explosionGraphYOffset: Float = -288
    static let smokeGraphYOffset: Float = -288

    static func tickBomb(
        _ input: SM64BowserBombTickInput,
        state: inout SM64BowserBombState
    ) -> SM64BowserBombTickResult {
        var effects: SM64BowserBombEffect = []
        if input.collidedWithMario {
            effects.formUnion([.clearInteraction, .spawnExplosion, .markForDeletion])
            state.markedForDeletion = true
        }
        if input.hitMine {
            effects.formUnion([.spawnFlames, .sound, .cameraShake, .markForDeletion])
            state.markedForDeletion = true
        }
        state.visibilityDistance = Self.visibilityDistance
        if state.markedForDeletion {
            effects.insert(.markForDeletion)
        }
        state.timer = state.timer == UInt32.max ? 0 : state.timer + 1
        return SM64BowserBombTickResult(state: state, effects: effects)
    }

    static func tickExplosion(
        _ input: SM64BowserBombExplosionTickInput,
        state: inout SM64BowserBombExplosionState
    ) -> SM64BowserBombExplosionTickResult {
        var effects: SM64BowserBombEffect = []
        state.scale = Float(state.timer) / 14 * 9 + 1
        let smokeSpawn: SM64BowserBombSmokeSpawn?
        if state.timer % 4 == 0, state.timer < 20 {
            effects.insert(.spawnSmoke)
            smokeSpawn = input.smokeSpawn
        } else {
            smokeSpawn = nil
        }
        if state.timer % 2 == 0 {
            state.animationState += 1
            effects.insert(.animate)
        }
        if state.timer == 28 {
            state.markedForDeletion = true
            effects.insert(.markForDeletion)
        }
        state.timer = state.timer == UInt32.max ? 0 : state.timer + 1
        return SM64BowserBombExplosionTickResult(
            state: state,
            effects: effects,
            smokeSpawn: smokeSpawn
        )
    }

    static func tickSmoke(
        state: inout SM64BowserBombSmokeState
    ) -> SM64BowserBombSmokeTickResult {
        var effects: SM64BowserBombEffect = []
        state.scale = Float(state.timer) / 14 * 9 + 1
        if state.timer % 2 == 0 {
            state.animationState += 1
            effects.insert(.animate)
        }
        state.opacity = max(0, state.opacity - 10)
        effects.insert(.fade)
        state.position.y += state.velocityY
        if state.timer == 28 {
            state.markedForDeletion = true
            effects.insert(.markForDeletion)
        }
        state.timer = state.timer == UInt32.max ? 0 : state.timer + 1
        return SM64BowserBombSmokeTickResult(state: state, effects: effects)
    }
}
