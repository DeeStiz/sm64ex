import Foundation

struct SM64ExplosionState: Equatable, Sendable {
    var timer: UInt32 = 0
    var opacity: Int32 = 255
    var scale: Float = 1
    var animationState: Int32 = -1
    var initialized = false
    var markedForDeletion = false
}

struct SM64ExplosionTickInput: Equatable, Sendable {
    let waterAbove: Bool

    init(waterAbove: Bool = false) {
        self.waterAbove = waterAbove
    }
}

struct SM64ExplosionEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    init(rawValue: UInt16) { self.rawValue = rawValue }

    static let sound = Self(rawValue: 1 << 0)
    static let cameraShake = Self(rawValue: 1 << 1)
    static let spawnBubbles = Self(rawValue: 1 << 2)
    static let spawnSmoke = Self(rawValue: 1 << 3)
    static let fade = Self(rawValue: 1 << 4)
    static let animate = Self(rawValue: 1 << 5)
    static let markForDeletion = Self(rawValue: 1 << 6)
}

struct SM64ExplosionTickResult: Equatable, Sendable {
    let state: SM64ExplosionState
    let effects: SM64ExplosionEffect
    let bubbleCount: Int32
    let spawnedSmoke: Bool
}

/// Value translation of `bhv_explosion_init` and `bhv_explosion_loop`.
enum SM64ExplosionKernel {
    static let model: UInt32 = 0xCD // MODEL_EXPLOSION
    static let behaviorIdentity: UInt64 = 0x6268_765F_657870
    static let soundValue: Int32 = Int32(bitPattern: 0x802E2081) // SOUND_GENERAL2_BOBOMB_EXPLOSION
    static let environmentalShake: Int32 = 1 // SHAKE_ENV_EXPLOSION
    static let interactionType: UInt32 = 1 << 3 // INTERACT_DAMAGE
    static let damageOrCoinValue: Int32 = 2
    static let hitboxRadius: Float = 150
    static let hitboxHeight: Float = 150
    static let hitboxDownOffset: Float = 150

    static func tick(
        _ input: SM64ExplosionTickInput,
        state: inout SM64ExplosionState
    ) -> SM64ExplosionTickResult {
        var effects: SM64ExplosionEffect = []
        if !state.initialized {
            state.initialized = true
            effects.formUnion([.sound, .cameraShake])
        }
        var bubbleCount: Int32 = 0
        var spawnedSmoke = false
        if state.timer == 9 {
            if input.waterAbove {
                bubbleCount = 40
                effects.insert(.spawnBubbles)
            } else {
                spawnedSmoke = true
                effects.insert(.spawnSmoke)
            }
            state.markedForDeletion = true
            effects.insert(.markForDeletion)
        }
        state.opacity = max(0, state.opacity - 14)
        effects.insert(.fade)
        state.scale = Float(state.timer) / 9 + 1
        state.animationState += 1
        effects.insert(.animate)
        state.timer = state.timer == UInt32.max ? 0 : state.timer + 1
        return SM64ExplosionTickResult(
            state: state,
            effects: effects,
            bubbleCount: bubbleCount,
            spawnedSmoke: spawnedSmoke
        )
    }
}
