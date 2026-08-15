import Foundation

/// Value effects emitted by `bhv_wooden_post_update`.  The post does not
/// mutate a Chain Chomp or the respawn table directly; those are owner-thread
/// deliveries made by the object bridge after this copied result is produced.
struct SM64ChainChompPostEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let poundSound = Self(rawValue: 1 << 0)
    static let updatePosition = Self(rawValue: 1 << 1)
    static let releaseChain = Self(rawValue: 1 << 2)
    static let spawnCoins = Self(rawValue: 1 << 3)
    static let setRespawnBit = Self(rawValue: 1 << 4)
}

struct SM64ChainChompPostState: Equatable, Sendable {
    var homeY: Float
    var offsetY: Float = 0
    var speedY: Float = 0
    var marioPounding = false
    var totalMarioAngle: Int32 = 0
    var previousAngleToMario: Int16 = 0
    var timer: UInt32 = 0
    var numLootCoins: UInt8 = 5
    var respawnInfoBits: UInt8 = 0
    var parentIsSelf = false

    init(homeY: Float = 0) {
        self.homeY = homeY
    }

    var positionY: Float { homeY + offsetY }
}

struct SM64ChainChompPostTickInput: Equatable, Sendable {
    var marioGroundPounding: Bool
    var distanceToMario: Float
    var angleToMario: Int16
    var noCoins: Bool

    init(
        marioGroundPounding: Bool = false,
        distanceToMario: Float = 1_000,
        angleToMario: Int16 = 0,
        noCoins: Bool = false
    ) {
        self.marioGroundPounding = marioGroundPounding
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.noCoins = noCoins
    }
}

struct SM64ChainChompPostTickResult: Equatable, Sendable {
    let state: SM64ChainChompPostState
    let effects: SM64ChainChompPostEffect
}

/// Finite value translation of `bhv_wooden_post_update` from
/// `src/game/behaviors/chain_chomp.inc.c`.
enum SM64ChainChompPostKernel {
    static func tick(
        _ input: SM64ChainChompPostTickInput,
        state: inout SM64ChainChompPostState
    ) -> SM64ChainChompPostTickResult {
        var effects: SM64ChainChompPostEffect = []

        if !state.marioPounding {
            if input.marioGroundPounding {
                state.marioPounding = true
                state.speedY = -70
                effects.insert(.poundSound)
            }
        } else if approach(&state.speedY, target: 0, delta: 25) {
            // C samples the platform-pounding predicate again only when the
            // speed reaches zero; preserve that branch ordering exactly.
            state.marioPounding = input.marioGroundPounding
        } else if state.offsetY + state.speedY < -190 {
            state.offsetY = -190
            if !state.parentIsSelf {
                state.parentIsSelf = true
                effects.insert(.releaseChain)
            }
        } else {
            state.offsetY += state.speedY
        }

        if state.offsetY != 0 {
            effects.insert(.updatePosition)
        } else if !input.noCoins {
            if input.distanceToMario > 400 {
                state.timer = 0
                state.totalMarioAngle = 0
            } else {
                let delta = Int16(truncatingIfNeeded: Int32(input.angleToMario) - Int32(state.previousAngleToMario))
                state.totalMarioAngle &+= Int32(delta)
                if abs(Int64(state.totalMarioAngle)) > 0x30_000,
                   state.timer < 200,
                   state.numLootCoins > 0 {
                    effects.insert([.spawnCoins, .setRespawnBit])
                    state.numLootCoins = 0
                    state.respawnInfoBits |= 1
                }
            }
            state.previousAngleToMario = input.angleToMario
        }

        state.timer &+= 1
        return SM64ChainChompPostTickResult(state: state, effects: effects)
    }

    private static func approach(_ value: inout Float, target: Float, delta: Float) -> Bool {
        var step = delta
        if value > target { step = -delta }
        value += step
        if (value - target) * step >= 0 {
            value = target
            return true
        }
        return false
    }
}

struct SM64ChainChompGateEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let wallExplosionSound = Self(rawValue: 1 << 0)
    static let cameraShake = Self(rawValue: 1 << 1)
    static let mist = Self(rawValue: 1 << 2)
    static let breakParticles = Self(rawValue: 1 << 3)
    static let markForDeletion = Self(rawValue: 1 << 4)
}

struct SM64ChainChompGateState: Equatable, Sendable {
    var markedForDeletion = false
}

struct SM64ChainChompGateTickResult: Equatable, Sendable {
    let state: SM64ChainChompGateState
    let effects: SM64ChainChompGateEffect
}

/// Finite value translation of `bhv_chain_chomp_gate_update`.
enum SM64ChainChompGateKernel {
    static func tick(
        hitGate: Bool,
        state: inout SM64ChainChompGateState
    ) -> SM64ChainChompGateTickResult {
        guard hitGate, !state.markedForDeletion else {
            return SM64ChainChompGateTickResult(state: state, effects: [])
        }
        state.markedForDeletion = true
        return SM64ChainChompGateTickResult(
            state: state,
            effects: [.wallExplosionSound, .cameraShake, .mist, .breakParticles, .markForDeletion]
        )
    }
}
